import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CustomLoggerService } from '../../common/logger/logger.service';

import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { Match } from '../../database/entities/match.entity';
import { Message } from '../../database/entities/message.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { PushToken } from '../../database/entities/push-token.entity';
import { UserConsent } from '../../database/entities/user-consent.entity';
import {
  UserStatus,
  MatchStatus,
  SubscriptionStatus,
  UserRole,
} from '../../common/enums';
import { UpdateUserDto, UpdateUserSettingsDto } from './dto/update-user.dto';
import { UpdateAccessibilitySettingsDto } from './dto/accessibility-settings.dto';
import { RegisterPushTokenDto } from './dto/push-token.dto';
import { ConsentDto } from './dto/consent.dto';
import {
  UpdateUserRoleDto,
  UserRoleResponseDto,
  UserRolesListResponseDto,
} from './dto/role-management.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Profile)
    private profileRepository: Repository<Profile>,
    @InjectRepository(Match)
    private matchRepository: Repository<Match>,
    @InjectRepository(Message)
    private messageRepository: Repository<Message>,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(DailySelection)
    private dailySelectionRepository: Repository<DailySelection>,
    @InjectRepository(PushToken)
    private pushTokenRepository: Repository<PushToken>,
    @InjectRepository(UserConsent)
    private userConsentRepository: Repository<UserConsent>,
    private logger: CustomLoggerService,
  ) {}

  async findById(id: string): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id },
      relations: ['profile', 'profile.photos', 'profile.promptAnswers'],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email },
      relations: ['profile'],
    });
  }

  async updateUser(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    const user = await this.findById(id);

    // Update user fields
    Object.assign(user, updateUserDto);
    await this.userRepository.save(user);

    // Update profile fields if they exist
    if (user.profile && (updateUserDto.firstName || updateUserDto.lastName)) {
      if (updateUserDto.firstName) {
        user.profile.firstName = updateUserDto.firstName;
      }
      if (updateUserDto.lastName) {
        user.profile.lastName = updateUserDto.lastName;
      }
      await this.profileRepository.save(user.profile);
    }

    return this.findById(id);
  }

  async updateSettings(
    id: string,
    settingsDto: UpdateUserSettingsDto,
  ): Promise<User> {
    const user = await this.findById(id);

    if (settingsDto.notificationsEnabled !== undefined) {
      user.notificationsEnabled = settingsDto.notificationsEnabled;
    }

    await this.userRepository.save(user);
    return this.findById(id);
  }

  async deactivateUser(id: string): Promise<void> {
    const user = await this.findById(id);
    user.status = UserStatus.INACTIVE;
    await this.userRepository.save(user);
  }

  async deleteUser(id: string): Promise<void> {
    const user = await this.findById(id);
    user.status = UserStatus.DELETED;
    await this.userRepository.save(user);
  }

  async getUserStats(id: string): Promise<any> {
    const user = await this.findById(id);

    // Get user's matches
    const totalMatches = await this.matchRepository.count({
      where: [
        { user1Id: id, status: MatchStatus.MATCHED },
        { user2Id: id, status: MatchStatus.MATCHED },
      ],
    });

    // Get user's sent messages
    const messagesSent = await this.messageRepository.count({
      where: { senderId: id },
    });

    // Get daily selections for the user
    const dailySelectionsUsed = await this.dailySelectionRepository
      .createQueryBuilder('ds')
      .where('ds.userId = :userId', { userId: id })
      .getCount();

    const totalChoicesUsed = await this.dailySelectionRepository
      .createQueryBuilder('ds')
      .select('SUM(ds.choicesUsed)', 'total')
      .where('ds.userId = :userId', { userId: id })
      .getRawOne();

    // Get current subscription
    const currentSubscription = await this.subscriptionRepository.findOne({
      where: {
        userId: id,
        status: SubscriptionStatus.ACTIVE,
      },
      order: { createdAt: 'DESC' },
    });

    // Get profile completion percentage
    const profile = user.profile;
    let profileCompletionPercent = 0;
    if (profile) {
      const profileFields = [
        profile.birthDate,
        profile.gender,
        profile.bio,
        profile.jobTitle,
        profile.education,
        profile.location,
        profile.interests?.length > 0,
        profile.photos?.length >= 3, // Minimum 3 photos
      ];
      const completedFields = profileFields.filter((field) =>
        Boolean(field),
      ).length;
      profileCompletionPercent = Math.round(
        (completedFields / profileFields.length) * 100,
      );
    }

    return {
      userId: user.id,
      memberSince: user.createdAt,
      lastActiveAt: user.lastActiveAt,
      isProfileCompleted: user.isProfileCompleted,
      isOnboardingCompleted: user.isOnboardingCompleted,
      emailVerified: user.isEmailVerified,

      // Profile stats
      profileCompletionPercent,
      totalPhotos: profile?.photos?.length || 0,

      // Matching stats
      totalMatches,
      dailySelectionsReceived: dailySelectionsUsed,
      totalChoicesUsed: parseInt(totalChoicesUsed?.total || '0'),

      // Communication stats
      messagesSent,

      // Subscription stats
      hasActiveSubscription: !!currentSubscription,
      subscriptionPlan: currentSubscription?.plan || null,
      subscriptionExpiresAt: currentSubscription?.expiresAt || null,

      // Calculated metrics
      averageChoicesPerSelection:
        dailySelectionsUsed > 0
          ? Math.round(
              (parseInt(totalChoicesUsed?.total || '0') / dailySelectionsUsed) *
                100,
            ) / 100
          : 0,
      matchRate:
        dailySelectionsUsed > 0
          ? Math.round((totalMatches / dailySelectionsUsed) * 100) / 100
          : 0,
    };
  }

  async registerPushToken(
    userId: string,
    registerPushTokenDto: RegisterPushTokenDto,
  ): Promise<PushToken> {
    const { token, platform, appVersion, deviceId } = registerPushTokenDto;

    // Check if token already exists for this user
    const existingToken = await this.pushTokenRepository.findOne({
      where: { userId, token },
    });

    if (existingToken) {
      // Update existing token
      existingToken.platform = platform;
      existingToken.appVersion = appVersion;
      existingToken.deviceId = deviceId;
      existingToken.isActive = true;
      existingToken.lastUsedAt = new Date();
      return this.pushTokenRepository.save(existingToken);
    }

    // Create new push token
    const pushToken = this.pushTokenRepository.create({
      userId,
      token,
      platform,
      appVersion,
      deviceId,
      isActive: true,
      lastUsedAt: new Date(),
    });

    return this.pushTokenRepository.save(pushToken);
  }

  async deletePushToken(userId: string, token: string): Promise<void> {
    const pushToken = await this.pushTokenRepository.findOne({
      where: { userId, token },
    });

    if (!pushToken) {
      throw new NotFoundException('Push token not found');
    }

    await this.pushTokenRepository.remove(pushToken);
  }

  async getUserPushTokens(userId: string): Promise<PushToken[]> {
    return this.pushTokenRepository.find({
      where: { userId, isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  async getAccessibilitySettings(userId: string) {
    const user = await this.findById(userId);

    return {
      fontSize: user.fontSize,
      highContrast: user.highContrast,
      reducedMotion: user.reducedMotion,
      screenReader: user.screenReader,
    };
  }

  async updateAccessibilitySettings(
    userId: string,
    settingsDto: UpdateAccessibilitySettingsDto,
  ): Promise<void> {
    const user = await this.findById(userId);

    // Update only the fields that are provided
    if (settingsDto.fontSize !== undefined) {
      user.fontSize = settingsDto.fontSize;
    }
    if (settingsDto.highContrast !== undefined) {
      user.highContrast = settingsDto.highContrast;
    }
    if (settingsDto.reducedMotion !== undefined) {
      user.reducedMotion = settingsDto.reducedMotion;
    }
    if (settingsDto.screenReader !== undefined) {
      user.screenReader = settingsDto.screenReader;
    }

    await this.userRepository.save(user);
  }

  async recordConsent(
    userId: string,
    consentDto: ConsentDto,
    ipAddress?: string,
  ): Promise<UserConsent> {
    // Deactivate previous consents
    await this.userConsentRepository.update(
      { userId, isActive: true },
      { isActive: false, revokedAt: new Date() },
    );

    // Create new consent record
    const consent = this.userConsentRepository.create({
      userId,
      dataProcessing: consentDto.dataProcessing,
      marketing: consentDto.marketing ?? false,
      analytics: consentDto.analytics ?? false,
      consentedAt: new Date(consentDto.consentedAt),
      ipAddress,
      isActive: true,
    });

    return this.userConsentRepository.save(consent);
  }

  async getCurrentConsent(userId: string): Promise<UserConsent | null> {
    return this.userConsentRepository.findOne({
      where: { userId, isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  // Role management methods
  async getUsersWithRoles(
    page: number = 1,
    limit: number = 10,
  ): Promise<UserRolesListResponseDto> {
    const [users, total] = await this.userRepository.findAndCount({
      select: ['id', 'email', 'role', 'updatedAt'],
      skip: (page - 1) * limit,
      take: limit,
      order: { updatedAt: 'DESC' },
    });

    return {
      users: users.map((user) => ({
        id: user.id,
        email: user.email,
        role: user.role || UserRole.USER,
        updatedAt: user.updatedAt || new Date(),
      })),
      total,
      page,
      limit,
    };
  }

  async updateUserRole(
    userId: string,
    updateRoleDto: UpdateUserRoleDto,
    adminUserId: string,
  ): Promise<UserRoleResponseDto> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: ['id', 'email', 'role', 'updatedAt'],
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    const oldRole = user.role || UserRole.USER;
    user.role = updateRoleDto.role;

    const updatedUser = await this.userRepository.save(user);

    // Log role change for audit trail
    this.logger.logAuditTrail('role_change', 'user', {
      targetUserId: userId,
      targetUserEmail: user.email,
      oldRole,
      newRole: updateRoleDto.role,
      adminUserId,
      timestamp: new Date().toISOString(),
    });

    return {
      id: updatedUser.id,
      email: updatedUser.email,
      role: updatedUser.role || UserRole.USER,
      updatedAt: updatedUser.updatedAt || new Date(),
    };
  }

  async getUserRole(userId: string): Promise<UserRole> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: ['role'],
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    return user.role || UserRole.USER;
  }
}
