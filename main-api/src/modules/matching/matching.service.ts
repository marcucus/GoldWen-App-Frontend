import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {
  Repository,
  Not,
  In,
  MoreThanOrEqual,
  LessThanOrEqual,
  Between,
} from 'typeorm';

import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { Match } from '../../database/entities/match.entity';
import { PersonalityAnswer } from '../../database/entities/personality-answer.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import {
  UserChoice,
  ChoiceType,
} from '../../database/entities/user-choice.entity';
import { CustomLoggerService } from '../../common/logger';

import {
  MatchStatus,
  SubscriptionTier,
  SubscriptionStatus,
  ChatStatus,
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
    @InjectRepository(UserChoice)
    private userChoiceRepository: Repository<UserChoice>,
    @Inject(forwardRef(() => ChatService))
    private chatService: ChatService,
    @Inject(forwardRef(() => NotificationsService))
    private notificationsService: NotificationsService,
    private matchingIntegrationService: MatchingIntegrationService,
    private logger: CustomLoggerService,
  ) {}

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

  async getDailySelection(
    userId: string,
    preload?: boolean,
  ): Promise<{
    profiles: User[];
    metadata: {
      date: string;
      choicesRemaining: number;
      choicesMade: number;
      maxChoices: number;
      refreshTime: string;
    };
  }> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const selection = await this.dailySelectionRepository.findOne({
      where: {
        userId,
        selectionDate: today,
      },
    });

    let currentSelection: DailySelection;
    if (!selection) {
      currentSelection = await this.generateDailySelection(userId);
    } else {
      currentSelection = selection;
    }

    // Get profiles that haven't been chosen yet
    const availableProfileIds = currentSelection.selectedProfileIds.filter(
      (profileId) => !currentSelection.chosenProfileIds.includes(profileId),
    );

    // If user has used all their choices, return empty profiles array (masking)
    const shouldMaskProfiles =
      currentSelection.choicesUsed >= currentSelection.maxChoicesAllowed;
    const profileIds = shouldMaskProfiles ? [] : availableProfileIds;

    const profiles =
      profileIds.length > 0
        ? await this.userRepository.find({
            where: { id: In(profileIds) },
            relations: ['profile', 'profile.photos'],
          })
        : [];

    // Calculate refresh time (next day at noon)
    const refreshTime = new Date();
    refreshTime.setDate(refreshTime.getDate() + 1);
    refreshTime.setHours(12, 0, 0, 0);

    return {
      profiles,
      metadata: {
        date: today.toISOString().split('T')[0], // YYYY-MM-DD format
        choicesRemaining: Math.max(
          0,
          currentSelection.maxChoicesAllowed - currentSelection.choicesUsed,
        ),
        choicesMade: currentSelection.choicesUsed,
        maxChoices: currentSelection.maxChoicesAllowed,
        refreshTime: refreshTime.toISOString(),
      },
    };
  }

  async chooseProfile(
    userId: string,
    targetUserId: string,
    choice: 'like' | 'pass' = 'like',
  ): Promise<{
    success: boolean;
    data: {
      isMatch: boolean;
      matchId?: string;
      choicesRemaining: number;
      message: string;
      canContinue: boolean;
    };
  }> {
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

    // Record the choice in UserChoice entity
    const userChoice = this.userChoiceRepository.create({
      userId,
      targetUserId,
      dailySelectionId: dailySelection.id,
      choiceType: choice === 'like' ? ChoiceType.LIKE : ChoiceType.PASS,
    });
    await this.userChoiceRepository.save(userChoice);

    const choicesRemaining =
      dailySelection.maxChoicesAllowed - dailySelection.choicesUsed;
    const canContinue = choicesRemaining > 0;

    const responseData = {
      isMatch: false,
      matchId: undefined as string | undefined,
      choicesRemaining,
      message: this.getChoiceMessage(
        choice,
        choicesRemaining,
        dailySelection.maxChoicesAllowed,
      ),
      canContinue,
    };

    // Only create match for 'like' choices
    if (choice === 'like') {
      // Create or update match
      let match = await this.matchRepository.findOne({
        where: [
          { user1Id: userId, user2Id: targetUserId },
          { user1Id: targetUserId, user2Id: userId },
        ],
      });

      if (!match) {
        // Create new match - in unidirectional system, this is immediately a match
        match = this.matchRepository.create({
          user1Id: userId,
          user2Id: targetUserId,
          status: MatchStatus.MATCHED,
          matchedAt: new Date(),
        });

        match = await this.matchRepository.save(match);
        responseData.matchId = match.id;
        responseData.isMatch = true;
        responseData.message = 'Félicitations ! Vous avez un match !';

        // In unidirectional system, chat is available immediately but requires acceptance
        // Chat will be created when the other user accepts the chat request
        this.logger.logBusinessEvent('unidirectional_match_created', {
          matchId: match.id,
          initiatorId: userId,
          targetId: targetUserId,
        });

        // Send notification to target user about the new match
        try {
          const initiatorUser = await this.userRepository.findOne({
            where: { id: userId },
            relations: ['profile'],
          });
          const targetUser = await this.userRepository.findOne({
            where: { id: targetUserId },
            relations: ['profile'],
          });

          if (initiatorUser && targetUser) {
            // Send notification to target user about getting a match
            await this.notificationsService.sendNewMatchNotification(
              targetUserId,
              initiatorUser.profile?.firstName || 'Someone',
            );

            // Also notify the initiator that they made a match
            await this.notificationsService.sendNewMatchNotification(
              userId,
              targetUser.profile?.firstName || 'Someone',
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
      } else {
        // Match already exists - this shouldn't happen in daily selection flow
        responseData.matchId = match.id;
        responseData.isMatch = true;
        responseData.message = 'Vous avez déjà un match avec ce profil !';
      }
    }

    return {
      success: true,
      data: responseData,
    };
  }

  private getChoiceMessage(
    choice: 'like' | 'pass',
    choicesRemaining: number,
    maxChoices: number,
  ): string {
    if (choicesRemaining === 0) {
      if (maxChoices === 1) {
        return 'Votre choix est fait. Revenez demain pour de nouveaux profils !';
      } else {
        return `Vos ${maxChoices} choix sont faits. Revenez demain pour de nouveaux profils !`;
      }
    }

    if (choice === 'like') {
      return `Votre choix a été enregistré ! Il vous reste ${choicesRemaining} choix${choicesRemaining > 1 ? 's' : ''} aujourd'hui.`;
    } else {
      return `Profil passé ! Il vous reste ${choicesRemaining} choix${choicesRemaining > 1 ? 's' : ''} aujourd'hui.`;
    }
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

  async getPendingMatches(userId: string): Promise<any[]> {
    // Get matches where user is the target (user2) and hasn't accepted the chat yet
    const matches = await this.matchRepository.find({
      where: {
        user2Id: userId,
        status: MatchStatus.MATCHED,
      },
      relations: ['user1', 'user1.profile', 'user2', 'user2.profile', 'chat'],
      order: { createdAt: 'DESC' },
    });

    // Filter matches that don't have an active chat (meaning chat hasn't been accepted yet)
    const pendingMatches = matches.filter(
      (match) => !match.chat || match.chat.status !== ChatStatus.ACTIVE,
    );

    return pendingMatches.map((match) => {
      const targetUser = match.user1; // The user who initiated the match
      return {
        matchId: match.id,
        targetUser: {
          id: targetUser.id,
          profile: targetUser.profile,
        },
        status: 'pending',
        matchedAt:
          match.matchedAt?.toISOString() || match.createdAt.toISOString(),
        canInitiateChat: true,
      };
    });
  }

  async getMutualMatch(userId: string, matchId: string): Promise<Match | null> {
    const match = await this.matchRepository.findOne({
      where: [
        { id: matchId, user1Id: userId, status: MatchStatus.MATCHED },
        { id: matchId, user2Id: userId, status: MatchStatus.MATCHED },
      ],
      relations: ['user1', 'user1.profile', 'user2', 'user2.profile'],
    });

    return match;
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

  async getUserChoices(
    userId: string,
    date?: string,
  ): Promise<{
    date: string;
    choicesRemaining: number;
    choicesMade: number;
    maxChoices: number;
    choices: Array<{
      targetUserId: string;
      chosenAt: string;
    }>;
  }> {
    let targetDate: Date;
    if (date) {
      targetDate = new Date(date);
      targetDate.setHours(0, 0, 0, 0);
    } else {
      targetDate = new Date();
      targetDate.setHours(0, 0, 0, 0);
    }

    const dailySelection = await this.dailySelectionRepository.findOne({
      where: {
        userId,
        selectionDate: targetDate,
      },
    });

    if (!dailySelection) {
      return {
        date: targetDate.toISOString().split('T')[0],
        choicesRemaining: 1, // Default for free users
        choicesMade: 0,
        maxChoices: 1,
        choices: [],
      };
    }

    // For now, we don't have individual timestamps for each choice
    // So we'll use the updatedAt timestamp for all choices
    const choices = dailySelection.chosenProfileIds.map((targetUserId) => ({
      targetUserId,
      chosenAt: dailySelection.updatedAt.toISOString(),
    }));

    return {
      date: targetDate.toISOString().split('T')[0],
      choicesRemaining: Math.max(
        0,
        dailySelection.maxChoicesAllowed - dailySelection.choicesUsed,
      ),
      choicesMade: dailySelection.choicesUsed,
      maxChoices: dailySelection.maxChoicesAllowed,
      choices,
    };
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

  async getDailySelectionStatus(userId: string): Promise<{
    hasNewSelection: boolean;
    lastSelectionDate: string | null;
    nextSelectionTime: string;
    hoursUntilNext: number;
  }> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const latestSelection = await this.dailySelectionRepository.findOne({
      where: { userId },
      order: { selectionDate: 'DESC' },
    });

    // Calculate next selection time (tomorrow at noon)
    const nextSelection = new Date();
    nextSelection.setDate(nextSelection.getDate() + 1);
    nextSelection.setHours(12, 0, 0, 0);

    const now = new Date();
    const hoursUntilNext = Math.max(
      0,
      Math.ceil((nextSelection.getTime() - now.getTime()) / (1000 * 60 * 60)),
    );

    // Check if user has a selection for today
    const hasNewSelection =
      !latestSelection ||
      latestSelection.selectionDate.getTime() < today.getTime();

    return {
      hasNewSelection,
      lastSelectionDate: latestSelection
        ? latestSelection.selectionDate.toISOString().split('T')[0]
        : null,
      nextSelectionTime: nextSelection.toISOString(),
      hoursUntilNext,
    };
  }

  async getHistory(
    userId: string,
    options: {
      startDate?: Date;
      endDate?: Date;
      page?: number;
      limit?: number;
    },
  ): Promise<{
    history: Array<{
      date: string;
      profiles: Array<{
        userId: string;
        user: User;
        choice: 'like' | 'pass';
        wasMatch: boolean;
      }>;
    }>;
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
      hasNext: boolean;
      hasPrev: boolean;
    };
  }> {
    const page = options.page || 1;
    const limit = options.limit || 20;
    const skip = (page - 1) * limit;

    // Build where clause for date range
    const whereClause: any = { userId };

    if (options.startDate && options.endDate) {
      const startDate = new Date(options.startDate);
      startDate.setHours(0, 0, 0, 0);
      const endDate = new Date(options.endDate);
      endDate.setHours(23, 59, 59, 999);
      whereClause.selectionDate = Between(startDate, endDate);
    } else if (options.startDate) {
      const startDate = new Date(options.startDate);
      startDate.setHours(0, 0, 0, 0);
      whereClause.selectionDate = MoreThanOrEqual(startDate);
    } else if (options.endDate) {
      const endDate = new Date(options.endDate);
      endDate.setHours(23, 59, 59, 999);
      whereClause.selectionDate = LessThanOrEqual(endDate);
    }

    // Get total count for pagination
    const totalSelections = await this.dailySelectionRepository.count({
      where: whereClause,
    });

    // Get paginated selections
    const selections = await this.dailySelectionRepository.find({
      where: whereClause,
      order: { selectionDate: 'DESC' },
      skip,
      take: limit,
    });

    // Build history with user profiles
    const history = await Promise.all(
      selections.map(async (selection) => {
        // Get all choices for this daily selection
        const choices = await this.userChoiceRepository.find({
          where: { dailySelectionId: selection.id },
          order: { createdAt: 'ASC' },
        });

        const profilesData = await Promise.all(
          choices.map(async (userChoice) => {
            const user = await this.userRepository.findOne({
              where: { id: userChoice.targetUserId },
              relations: ['profile', 'profile.photos'],
            });

            // Skip if user no longer exists
            if (!user) {
              return null;
            }

            // Check if this was a match (only relevant for 'like' choices)
            const match =
              userChoice.choiceType === ChoiceType.LIKE
                ? await this.matchRepository.findOne({
                    where: [
                      { user1Id: userId, user2Id: userChoice.targetUserId },
                      { user1Id: userChoice.targetUserId, user2Id: userId },
                    ],
                  })
                : null;

            return {
              userId: userChoice.targetUserId,
              user,
              choice: userChoice.choiceType as 'like' | 'pass',
              wasMatch: !!match,
            };
          }),
        );

        // Filter out null users
        const profiles = profilesData.filter((p) => p !== null) as Array<{
          userId: string;
          user: User;
          choice: 'like' | 'pass';
          wasMatch: boolean;
        }>;

        return {
          date: selection.selectionDate.toISOString().split('T')[0],
          profiles,
        };
      }),
    );

    const totalPages = Math.ceil(totalSelections / limit);

    return {
      history,
      pagination: {
        page,
        limit,
        total: totalSelections,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1,
      },
    };
  }

  async getWhoLikedMe(userId: string): Promise<
    Array<{
      userId: string;
      user: User;
      likedAt: string;
    }>
  > {
    // Find all matches where the current user is user2 (was chosen by user1)
    const matches = await this.matchRepository.find({
      where: {
        user2Id: userId,
        status: MatchStatus.MATCHED,
      },
      relations: ['user1', 'user1.profile', 'user1.profile.photos'],
      order: { createdAt: 'DESC' },
    });

    return matches.map((match) => ({
      userId: match.user1Id,
      user: match.user1,
      likedAt: match.matchedAt?.toISOString() || match.createdAt.toISOString(),
    }));
  }
}
