import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { User } from '../../database/entities/user.entity';
import { NotificationPreferences } from '../../database/entities/notification-preferences.entity';
import { UserConsent } from '../../database/entities/user-consent.entity';
import { Profile } from '../../database/entities/profile.entity';
import { CustomLoggerService } from '../../common/logger';
import { FontSize } from '../../common/enums';

import {
  UserPreferencesDto,
  UpdateUserPreferencesDto,
  NotificationPreferencesDto,
  PrivacyPreferencesDto,
  AccessibilityPreferencesDto,
  MatchingFiltersDto,
} from './dto/preferences.dto';

@Injectable()
export class PreferencesService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(NotificationPreferences)
    private notificationPreferencesRepository: Repository<NotificationPreferences>,
    @InjectRepository(UserConsent)
    private userConsentRepository: Repository<UserConsent>,
    @InjectRepository(Profile)
    private profileRepository: Repository<Profile>,
    private logger: CustomLoggerService,
  ) {}

  async getUserPreferences(userId: string): Promise<UserPreferencesDto> {
    // Get user with all related data
    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: [
        'id',
        'fontSize',
        'highContrast',
        'reducedMotion',
        'screenReader',
      ],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Get notification preferences
    let notificationPreferences =
      await this.notificationPreferencesRepository.findOne({
        where: { userId },
      });

    // Create default notification preferences if they don't exist
    if (!notificationPreferences) {
      notificationPreferences = this.notificationPreferencesRepository.create({
        userId,
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        subscriptionUpdates: true,
        marketingEmails: false,
        pushNotifications: true,
        emailNotifications: true,
      });
      await this.notificationPreferencesRepository.save(
        notificationPreferences,
      );
    }

    // Get current user consent (privacy preferences)
    let userConsent = await this.userConsentRepository.findOne({
      where: { userId, isActive: true },
    });

    // Create default consent if it doesn't exist
    if (!userConsent) {
      userConsent = this.userConsentRepository.create({
        userId,
        dataProcessing: true,
        marketing: false,
        analytics: false,
        consentedAt: new Date(),
        isActive: true,
      });
      await this.userConsentRepository.save(userConsent);
    }

    // Get profile for matching filters
    const profile = await this.profileRepository.findOne({
      where: { userId },
      select: [
        'minAge',
        'maxAge',
        'maxDistance',
        'interestedInGenders',
        'showMeInDiscovery',
      ],
    });

    // Build response
    const preferences: UserPreferencesDto = {
      notifications: {
        dailySelection: notificationPreferences.dailySelection,
        newMatches: notificationPreferences.newMatches,
        newMessages: notificationPreferences.newMessages,
        chatExpiring: notificationPreferences.chatExpiring,
        subscriptionUpdates: notificationPreferences.subscriptionUpdates,
        marketingEmails: notificationPreferences.marketingEmails,
        pushNotifications: notificationPreferences.pushNotifications,
        emailNotifications: notificationPreferences.emailNotifications,
      },
      privacy: {
        analytics: userConsent.analytics || false,
        marketing: userConsent.marketing || false,
        functionalCookies: true, // Always true for app functionality
        dataRetention: undefined, // Could be added later
      },
      accessibility: {
        fontSize: user.fontSize || FontSize.MEDIUM,
        highContrast: user.highContrast || false,
        reducedMotion: user.reducedMotion || false,
        screenReader: user.screenReader || false,
      },
      filters: {
        ageMin: profile?.minAge || undefined,
        ageMax: profile?.maxAge || undefined,
        maxDistance: profile?.maxDistance || undefined,
        preferredGenders: profile?.interestedInGenders || undefined,
        showMeInDiscovery: profile?.showMeInDiscovery !== false, // Default to true
      },
    };

    this.logger.logUserAction('get_user_preferences', { userId });

    return preferences;
  }

  async updateUserPreferences(
    userId: string,
    updateDto: UpdateUserPreferencesDto,
  ): Promise<{ message: string; preferences: UserPreferencesDto }> {
    // Verify user exists
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Update notification preferences
    if (updateDto.notifications) {
      await this.updateNotificationPreferences(userId, updateDto.notifications);
    }

    // Update privacy preferences
    if (updateDto.privacy) {
      await this.updatePrivacyPreferences(userId, updateDto.privacy);
    }

    // Update accessibility preferences
    if (updateDto.accessibility) {
      await this.updateAccessibilityPreferences(
        userId,
        updateDto.accessibility,
      );
    }

    // Update matching filters
    if (updateDto.filters) {
      await this.updateMatchingFilters(userId, updateDto.filters);
    }

    this.logger.logUserAction('update_user_preferences', { userId });

    // Return updated preferences
    const updatedPreferences = await this.getUserPreferences(userId);

    return {
      message: 'User preferences updated successfully',
      preferences: updatedPreferences,
    };
  }

  private async updateNotificationPreferences(
    userId: string,
    updates: UpdateUserPreferencesDto['notifications'],
  ): Promise<void> {
    if (!updates) return;

    let preferences = await this.notificationPreferencesRepository.findOne({
      where: { userId },
    });

    if (!preferences) {
      preferences = this.notificationPreferencesRepository.create({
        userId,
        ...updates,
      });
    } else {
      Object.assign(preferences, updates);
    }

    await this.notificationPreferencesRepository.save(preferences);
  }

  private async updatePrivacyPreferences(
    userId: string,
    updates: UpdateUserPreferencesDto['privacy'],
  ): Promise<void> {
    if (!updates) return;

    // Find active consent record
    let consent = await this.userConsentRepository.findOne({
      where: { userId, isActive: true },
    });

    if (!consent) {
      // Create new consent record
      consent = this.userConsentRepository.create({
        userId,
        dataProcessing: true, // Required for app functionality
        marketing: updates.marketing || false,
        analytics: updates.analytics || false,
        consentedAt: new Date(),
        isActive: true,
      });
    } else {
      // Update existing consent
      if (updates.marketing !== undefined) {
        consent.marketing = updates.marketing;
      }
      if (updates.analytics !== undefined) {
        consent.analytics = updates.analytics;
      }
      consent.consentedAt = new Date(); // Update consent timestamp
    }

    await this.userConsentRepository.save(consent);
  }

  private async updateAccessibilityPreferences(
    userId: string,
    updates: UpdateUserPreferencesDto['accessibility'],
  ): Promise<void> {
    if (!updates) return;

    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) return;

    if (updates.fontSize !== undefined) {
      user.fontSize = updates.fontSize;
    }
    if (updates.highContrast !== undefined) {
      user.highContrast = updates.highContrast;
    }
    if (updates.reducedMotion !== undefined) {
      user.reducedMotion = updates.reducedMotion;
    }
    if (updates.screenReader !== undefined) {
      user.screenReader = updates.screenReader;
    }

    await this.userRepository.save(user);
  }

  private async updateMatchingFilters(
    userId: string,
    updates: UpdateUserPreferencesDto['filters'],
  ): Promise<void> {
    if (!updates) return;

    const profile = await this.profileRepository.findOne({
      where: { userId },
    });

    if (!profile) {
      // If no profile exists, we can't update matching filters
      // This should not happen in normal flow as profiles are created during onboarding
      return;
    }

    if (updates.ageMin !== undefined) {
      profile.minAge = updates.ageMin;
    }
    if (updates.ageMax !== undefined) {
      profile.maxAge = updates.ageMax;
    }
    if (updates.maxDistance !== undefined) {
      profile.maxDistance = updates.maxDistance;
    }
    if (updates.preferredGenders !== undefined) {
      profile.interestedInGenders = updates.preferredGenders;
    }
    if (updates.showMeInDiscovery !== undefined) {
      profile.showMeInDiscovery = updates.showMeInDiscovery;
    }

    await this.profileRepository.save(profile);
  }
}
