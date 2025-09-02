import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { Match } from '../../database/entities/match.entity';
import { Message } from '../../database/entities/message.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import {
  UserStatus,
  MatchStatus,
  SubscriptionStatus,
} from '../../common/enums';
import { UpdateUserDto, UpdateUserSettingsDto } from './dto/update-user.dto';

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
}
