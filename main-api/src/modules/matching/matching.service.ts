import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Not, In } from 'typeorm';
import { Cron, CronExpression } from '@nestjs/schedule';

import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { Match } from '../../database/entities/match.entity';
import { PersonalityAnswer } from '../../database/entities/personality-answer.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { CustomLoggerService } from '../../common/logger';

import {
  MatchStatus,
  SubscriptionTier,
  SubscriptionStatus,
} from '../../common/enums';
import { ChatService } from '../chat/chat.service';
import { NotificationsService } from '../notifications/notifications.service';
import { MatchingIntegrationService } from './matching-integration.service';

@Injectable()
export class MatchingService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Profile)
    private profileRepository: Repository<Profile>,
    @InjectRepository(DailySelection)
    private dailySelectionRepository: Repository<DailySelection>,
    @InjectRepository(Match)
    private matchRepository: Repository<Match>,
    @InjectRepository(PersonalityAnswer)
    private personalityAnswerRepository: Repository<PersonalityAnswer>,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @Inject(forwardRef(() => ChatService))
    private chatService: ChatService,
    @Inject(forwardRef(() => NotificationsService))
    private notificationsService: NotificationsService,
    private matchingIntegrationService: MatchingIntegrationService,
    private logger: CustomLoggerService,
  ) {}

  // Daily selection generation - runs every day at 12:00 PM
  @Cron('0 12 * * *')
  async generateDailySelectionsForAllUsers() {
    const users = await this.userRepository.find({
      where: { isProfileCompleted: true },
    });

    this.logger.info('Starting daily selection generation for all users', {
      totalUsers: users.length,
    });

    let successCount = 0;
    let errorCount = 0;

    for (const user of users) {
      try {
        await this.generateDailySelection(user.id);

        // Send daily selection notification
        await this.notificationsService.sendDailySelectionNotification(user.id);

        successCount++;
      } catch (error) {
        this.logger.error(
          'Failed to generate daily selection for user',
          error.stack,
          'MatchingService',
        );
        errorCount++;
      }
    }

    this.logger.info('Daily selection generation completed', {
      totalUsers: users.length,
      successCount,
      errorCount,
    });
  }

  async generateDailySelection(userId: string): Promise<DailySelection> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: ['personalityAnswers', 'subscriptions'],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (!user.isProfileCompleted) {
      throw new BadRequestException(
        'Profile must be completed to receive daily selections',
      );
    }

    // Check if user already has a selection for today
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const existingSelection = await this.dailySelectionRepository.findOne({
      where: {
        userId,
        selectionDate: today,
      },
    });

    if (existingSelection) {
      return existingSelection;
    }

    // Get users that this user hasn't matched with yet
    const existingMatches = await this.matchRepository.find({
      where: [{ user1Id: userId }, { user2Id: userId }],
    });

    const excludedUserIds = [
      userId, // Exclude self
      ...existingMatches.map((match) =>
        match.user1Id === userId ? match.user2Id : match.user1Id,
      ),
    ];

    // Get potential matches (users with completed profiles)
    const potentialMatches = await this.userRepository.find({
      where: {
        id: Not(In(excludedUserIds.length > 0 ? excludedUserIds : [''])),
        isProfileCompleted: true,
      },
      relations: ['profile', 'personalityAnswers'],
      take: 50, // Get more than needed for better selection
    });

    if (potentialMatches.length === 0) {
      // Create empty selection
      return this.dailySelectionRepository.save(
        this.dailySelectionRepository.create({
          userId,
          selectionDate: today,
          selectedProfileIds: [],
          maxChoicesAllowed: await this.getMaxChoicesPerDay(userId),
        }),
      );
    }

    // Use external matching service to generate daily selection
    try {
      const userProfile = {
        personalityAnswers: user.personalityAnswers || [],
        preferences: {
          ageRange: {
            min: user.profile?.minAge || 18,
            max: user.profile?.maxAge || 80,
          },
          maxDistance: user.profile?.maxDistance || 50,
          interestedInGenders: user.profile?.interestedInGenders || [],
        },
      };

      const availableProfiles = potentialMatches.map((match) => ({
        userId: match.id,
        personalityAnswers: match.personalityAnswers || [],
        preferences: {
          ageRange: {
            min: match.profile?.minAge || 18,
            max: match.profile?.maxAge || 80,
          },
          maxDistance: match.profile?.maxDistance || 50,
          interestedInGenders: match.profile?.interestedInGenders || [],
        },
      }));

      const maxChoicesAllowed = await this.getMaxChoicesPerDay(userId);
      const selectionSize = Math.min(5, maxChoicesAllowed); // Max 5 per day

      const selectionResult =
        await this.matchingIntegrationService.generateDailySelection({
          userId,
          userProfile,
          availableProfiles,
          selectionSize,
        });

      const selectedProfileIds = selectionResult.selectedProfiles.map(
        (p) => p.userId,
      );

      // Create daily selection entry
      const dailySelection = this.dailySelectionRepository.create({
        userId,
        selectionDate: today,
        selectedProfileIds,
        maxChoicesAllowed,
      });

      return this.dailySelectionRepository.save(dailySelection);
    } catch (error) {
      this.logger.error(
        'Failed to generate daily selection using external service, falling back to local calculation',
        error.message,
        'MatchingService',
      );

      // Fallback to local calculation
      const compatibilityScores = await Promise.all(
        potentialMatches.map(async (potentialMatch) => {
          const score = await this.calculateCompatibilityScore(
            user,
            potentialMatch,
          );
          return { user: potentialMatch, score };
        }),
      );

      // Sort by compatibility score (highest first)
      compatibilityScores.sort((a, b) => b.score - a.score);

      // Determine selection size (always 5 for now)
      const selectionSize = 5;

      // Take top matches
      const selectedMatches = compatibilityScores.slice(0, selectionSize);
      const selectedProfileIds = selectedMatches.map((match) => match.user.id);

      // Create daily selection entry
      const dailySelection = this.dailySelectionRepository.create({
        userId,
        selectionDate: today,
        selectedProfileIds,
        maxChoicesAllowed: await this.getMaxChoicesPerDay(userId),
      });

      return this.dailySelectionRepository.save(dailySelection);
    }
  }

  async getDailySelection(userId: string): Promise<{
    selection: DailySelection;
    profiles: User[];
  }> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const selection = await this.dailySelectionRepository.findOne({
      where: {
        userId,
        selectionDate: today,
      },
    });

    if (!selection) {
      const newSelection = await this.generateDailySelection(userId);
      const profiles = await this.userRepository.find({
        where: { id: In(newSelection.selectedProfileIds) },
        relations: ['profile', 'profile.photos'],
      });
      return { selection: newSelection, profiles };
    }

    const profiles = await this.userRepository.find({
      where: { id: In(selection.selectedProfileIds) },
      relations: ['profile', 'profile.photos'],
    });

    return { selection, profiles };
  }

  async chooseProfile(userId: string, targetUserId: string): Promise<any> {
    // Check if target user is in today's selection
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dailySelection = await this.dailySelectionRepository.findOne({
      where: { userId, selectionDate: today },
    });

    if (
      !dailySelection ||
      !dailySelection.selectedProfileIds.includes(targetUserId)
    ) {
      throw new BadRequestException('Target user not in your daily selection');
    }

    // Check if user has remaining choices today
    if (dailySelection.choicesUsed >= dailySelection.maxChoicesAllowed) {
      throw new BadRequestException(
        `You have reached your daily limit of ${dailySelection.maxChoicesAllowed} choices`,
      );
    }

    // Check if already chosen
    if (dailySelection.chosenProfileIds.includes(targetUserId)) {
      throw new BadRequestException('You have already chosen this profile');
    }

    // Update daily selection
    dailySelection.chosenProfileIds.push(targetUserId);
    dailySelection.choicesUsed += 1;
    await this.dailySelectionRepository.save(dailySelection);

    // Create or update match
    let match = await this.matchRepository.findOne({
      where: [
        { user1Id: userId, user2Id: targetUserId },
        { user1Id: targetUserId, user2Id: userId },
      ],
    });

    if (!match) {
      // Create new match
      match = this.matchRepository.create({
        user1Id: userId,
        user2Id: targetUserId,
        status: MatchStatus.PENDING,
      });
    }

    match = await this.matchRepository.save(match);

    // Check if it's a mutual match
    const reverseMatch = await this.matchRepository.findOne({
      where: { user1Id: targetUserId, user2Id: userId },
    });

    if (reverseMatch) {
      // It's a mutual match!
      match.status = MatchStatus.MATCHED;
      match.matchedAt = new Date();
      await this.matchRepository.save(match);

      // Create chat for the match
      try {
        await this.chatService.createChatForMatch(match.id);
        this.logger.logBusinessEvent('chat_created_for_match', {
          matchId: match.id,
          user1Id: match.user1Id,
          user2Id: match.user2Id,
        });
      } catch (error) {
        this.logger.error(
          'Failed to create chat for match',
          error.stack,
          'MatchingService',
        );
      }

      // Send notifications to both users about the mutual match
      try {
        const user1 = await this.userRepository.findOne({
          where: { id: match.user1Id },
          relations: ['profile'],
        });
        const user2 = await this.userRepository.findOne({
          where: { id: match.user2Id },
          relations: ['profile'],
        });

        if (user1 && user2) {
          // Send notification to user1 about matching with user2
          await this.notificationsService.sendNewMatchNotification(
            user1.id,
            user2.profile?.firstName || 'Someone',
          );

          // Send notification to user2 about matching with user1
          await this.notificationsService.sendNewMatchNotification(
            user2.id,
            user1.profile?.firstName || 'Someone',
          );
        }
      } catch (error) {
        this.logger.error(
          'Failed to send match notifications',
          error.stack,
          'MatchingService',
        );
        // Don't throw error as match creation succeeded
      }

      return {
        match,
        isMutual: true,
        message: 'Congratulations! You have a mutual match!',
      };
    }

    return {
      match,
      isMutual: false,
      message: 'Your choice has been registered!',
    };
  }

  async getUserMatches(userId: string, status?: MatchStatus): Promise<Match[]> {
    const whereCondition: any = [{ user1Id: userId }, { user2Id: userId }];

    if (status) {
      whereCondition[0].status = status;
      whereCondition[1].status = status;
    }

    return this.matchRepository.find({
      where: whereCondition,
      relations: ['user1', 'user1.profile', 'user2', 'user2.profile', 'chat'],
      order: { createdAt: 'DESC' },
    });
  }

  async getCompatibilityScore(
    userId: string,
    targetUserId: string,
  ): Promise<number> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: ['personalityAnswers'],
    });

    const targetUser = await this.userRepository.findOne({
      where: { id: targetUserId },
      relations: ['personalityAnswers'],
    });

    if (!user || !targetUser) {
      throw new NotFoundException('User not found');
    }

    return this.calculateCompatibilityScore(user, targetUser);
  }

  private async calculateCompatibilityScore(
    user1: User,
    user2: User,
  ): Promise<number> {
    // Simple content-based filtering for MVP
    // In V2, this could be enhanced with ML algorithms

    const user1Answers = user1.personalityAnswers || [];
    const user2Answers = user2.personalityAnswers || [];

    if (user1Answers.length === 0 || user2Answers.length === 0) {
      return 0;
    }

    let totalScore = 0;
    let commonQuestions = 0;

    for (const answer1 of user1Answers) {
      const answer2 = user2Answers.find(
        (a) => a.questionId === answer1.questionId,
      );

      if (answer2) {
        commonQuestions++;

        // Calculate similarity based on answer type
        if (answer1.numericAnswer !== null && answer2.numericAnswer !== null) {
          // For scale questions, calculate distance
          const maxDistance = 10; // Assuming scale is 1-10
          const distance = Math.abs(
            answer1.numericAnswer - answer2.numericAnswer,
          );
          const similarity = (maxDistance - distance) / maxDistance;
          totalScore += similarity * 100;
        } else if (
          answer1.booleanAnswer !== null &&
          answer2.booleanAnswer !== null
        ) {
          // For yes/no questions
          totalScore +=
            answer1.booleanAnswer === answer2.booleanAnswer ? 100 : 0;
        } else if (
          answer1.multipleChoiceAnswer &&
          answer2.multipleChoiceAnswer
        ) {
          // For multiple choice, check for any common selections
          const common = answer1.multipleChoiceAnswer.filter((a) =>
            answer2.multipleChoiceAnswer?.includes(a),
          );
          totalScore +=
            (common.length /
              Math.max(
                answer1.multipleChoiceAnswer.length,
                answer2.multipleChoiceAnswer.length,
              )) *
            100;
        } else if (answer1.textAnswer && answer2.textAnswer) {
          // Basic text similarity (can be enhanced)
          const similarity =
            answer1.textAnswer.toLowerCase() ===
            answer2.textAnswer.toLowerCase()
              ? 100
              : 50;
          totalScore += similarity;
        }
      }
    }

    return commonQuestions > 0 ? Math.round(totalScore / commonQuestions) : 0;
  }

  private async getSelectionSize(userId: string): Promise<number> {
    // Default size is 5 profiles for free users
    // Premium users get 5 profiles but can choose from more
    return 5;
  }

  private async getMaxChoicesPerDay(userId: string): Promise<number> {
    const activeSubscription = await this.subscriptionRepository.findOne({
      where: {
        userId,
        isActive: true,
      },
    });

    // Free users: 1 choice per day
    // Premium users: 3 choices per day (as per specifications)
    return activeSubscription?.status === SubscriptionStatus.ACTIVE ? 3 : 1;
  }

  async deleteMatch(userId: string, matchId: string): Promise<void> {
    const match = await this.matchRepository.findOne({
      where: [
        { id: matchId, user1Id: userId },
        { id: matchId, user2Id: userId },
      ],
    });

    if (!match) {
      throw new NotFoundException('Match not found');
    }

    await this.matchRepository.remove(match);
  }
}
