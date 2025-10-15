import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ForbiddenException } from '@nestjs/common';

import { MatchingService } from '../matching.service';
import { MatchingController } from '../matching.controller';
import { PremiumGuard } from '../../auth/guards/premium.guard';
import { User } from '../../../database/entities/user.entity';
import { Profile } from '../../../database/entities/profile.entity';
import { DailySelection } from '../../../database/entities/daily-selection.entity';
import { Match } from '../../../database/entities/match.entity';
import { PersonalityAnswer } from '../../../database/entities/personality-answer.entity';
import { Subscription } from '../../../database/entities/subscription.entity';
import {
  UserChoice,
  ChoiceType,
} from '../../../database/entities/user-choice.entity';
import { ChatService } from '../../chat/chat.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { MatchingIntegrationService } from '../matching-integration.service';
import { CustomLoggerService } from '../../../common/logger';
import {
  MatchStatus,
  SubscriptionStatus,
  SubscriptionPlan,
} from '../../../common/enums';

describe('Advanced Matching Routes', () => {
  let service: MatchingService;
  let controller: MatchingController;
  let premiumGuard: PremiumGuard;
  let userRepository: Repository<User>;
  let dailySelectionRepository: Repository<DailySelection>;
  let matchRepository: Repository<Match>;
  let subscriptionRepository: Repository<Subscription>;
  let userChoiceRepository: Repository<UserChoice>;

  const mockUser: Partial<User> = {
    id: 'user-1',
    email: 'user@example.com',
    isProfileCompleted: true,
  };

  const mockRequest = {
    user: { id: 'user-1' },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MatchingController],
      providers: [
        MatchingService,
        PremiumGuard,
        {
          provide: getRepositoryToken(User),
          useValue: {
            findOne: jest.fn(),
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Profile),
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(DailySelection),
          useValue: {
            findOne: jest.fn(),
            find: jest.fn(),
            count: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Match),
          useValue: {
            findOne: jest.fn(),
            find: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(PersonalityAnswer),
          useValue: {
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Subscription),
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(UserChoice),
          useValue: {
            find: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: ChatService,
          useValue: {
            createChat: jest.fn(),
          },
        },
        {
          provide: NotificationsService,
          useValue: {
            sendNewMatchNotification: jest.fn(),
          },
        },
        {
          provide: MatchingIntegrationService,
          useValue: {
            generateDailySelection: jest.fn(),
          },
        },
        {
          provide: CustomLoggerService,
          useValue: {
            log: jest.fn(),
            error: jest.fn(),
            warn: jest.fn(),
            logBusinessEvent: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<MatchingController>(MatchingController);
    service = module.get<MatchingService>(MatchingService);
    premiumGuard = module.get<PremiumGuard>(PremiumGuard);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    dailySelectionRepository = module.get<Repository<DailySelection>>(
      getRepositoryToken(DailySelection),
    );
    matchRepository = module.get<Repository<Match>>(getRepositoryToken(Match));
    subscriptionRepository = module.get<Repository<Subscription>>(
      getRepositoryToken(Subscription),
    );
    userChoiceRepository = module.get<Repository<UserChoice>>(
      getRepositoryToken(UserChoice),
    );
  });

  describe('GET /matching/daily-selection/status', () => {
    it('should return status with new selection available', async () => {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      jest.spyOn(dailySelectionRepository, 'findOne').mockResolvedValue(null);

      const result = await controller.getDailySelectionStatus(mockRequest);

      expect(result.hasNewSelection).toBe(true);
      expect(result.lastSelectionDate).toBeNull();
      expect(result.nextSelectionTime).toBeDefined();
      expect(result.hoursUntilNext).toBeGreaterThanOrEqual(0);
    });

    it('should return status with no new selection when already fetched today', async () => {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const mockSelection: Partial<DailySelection> = {
        userId: 'user-1',
        selectionDate: today,
        selectedProfileIds: ['user-2', 'user-3'],
        chosenProfileIds: [],
        choicesUsed: 0,
        maxChoicesAllowed: 1,
      };

      jest
        .spyOn(dailySelectionRepository, 'findOne')
        .mockResolvedValue(mockSelection as DailySelection);

      const result = await controller.getDailySelectionStatus(mockRequest);

      expect(result.hasNewSelection).toBe(false);
      expect(result.lastSelectionDate).toBe(today.toISOString().split('T')[0]);
    });
  });

  describe('GET /matching/history', () => {
    it('should return paginated history with like and pass choices', async () => {
      const mockSelection: Partial<DailySelection> = {
        id: 'selection-1',
        userId: 'user-1',
        selectionDate: new Date('2025-01-15'),
        selectedProfileIds: ['user-2', 'user-3'],
        chosenProfileIds: ['user-2', 'user-3'],
        choicesUsed: 2,
        maxChoicesAllowed: 2,
        updatedAt: new Date('2025-01-15T14:00:00'),
      };

      const mockChoices: Partial<UserChoice>[] = [
        {
          id: 'choice-1',
          userId: 'user-1',
          targetUserId: 'user-2',
          dailySelectionId: 'selection-1',
          choiceType: ChoiceType.LIKE,
          createdAt: new Date('2025-01-15T12:00:00'),
        },
        {
          id: 'choice-2',
          userId: 'user-1',
          targetUserId: 'user-3',
          dailySelectionId: 'selection-1',
          choiceType: ChoiceType.PASS,
          createdAt: new Date('2025-01-15T12:05:00'),
        },
      ];

      const mockUser2: Partial<User> = {
        id: 'user-2',
        email: 'user2@example.com',
        profile: {
          firstName: 'Jane',
          lastName: 'Doe',
        } as Profile,
      };

      const mockUser3: Partial<User> = {
        id: 'user-3',
        email: 'user3@example.com',
        profile: {
          firstName: 'John',
          lastName: 'Smith',
        } as Profile,
      };

      const mockMatch: Partial<Match> = {
        id: 'match-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
        status: MatchStatus.MATCHED,
      };

      jest.spyOn(dailySelectionRepository, 'count').mockResolvedValue(1);
      jest
        .spyOn(dailySelectionRepository, 'find')
        .mockResolvedValue([mockSelection as DailySelection]);
      jest
        .spyOn(userChoiceRepository, 'find')
        .mockResolvedValue(mockChoices as UserChoice[]);
      jest
        .spyOn(userRepository, 'findOne')
        .mockImplementation(async ({ where }) => {
          if ((where as any).id === 'user-2') return mockUser2 as User;
          if ((where as any).id === 'user-3') return mockUser3 as User;
          return null;
        });
      jest
        .spyOn(matchRepository, 'findOne')
        .mockResolvedValue(mockMatch as Match);

      const result = await controller.getMatchingHistory(mockRequest);

      expect(result.history).toBeDefined();
      expect(result.history.length).toBe(1);
      expect(result.history[0].profiles.length).toBe(2);
      expect(result.history[0].profiles[0].userId).toBe('user-2');
      expect(result.history[0].profiles[0].choice).toBe('like');
      expect(result.history[0].profiles[0].wasMatch).toBe(true);
      expect(result.history[0].profiles[1].userId).toBe('user-3');
      expect(result.history[0].profiles[1].choice).toBe('pass');
      expect(result.history[0].profiles[1].wasMatch).toBe(false);
      expect(result.pagination).toBeDefined();
      expect(result.pagination.page).toBe(1);
      expect(result.pagination.limit).toBe(20);
      expect(result.pagination.total).toBe(1);
    });

    it('should handle pagination parameters', async () => {
      jest.spyOn(dailySelectionRepository, 'count').mockResolvedValue(50);
      jest.spyOn(dailySelectionRepository, 'find').mockResolvedValue([]);
      jest.spyOn(userChoiceRepository, 'find').mockResolvedValue([]);

      const result = await controller.getMatchingHistory(
        mockRequest,
        undefined,
        undefined,
        '2',
        '10',
      );

      expect(result.pagination.page).toBe(2);
      expect(result.pagination.limit).toBe(10);
      expect(result.pagination.total).toBe(50);
      expect(result.pagination.totalPages).toBe(5);
      expect(result.pagination.hasNext).toBe(true);
      expect(result.pagination.hasPrev).toBe(true);
    });

    it('should support date range filtering', async () => {
      const mockSelection: Partial<DailySelection> = {
        id: 'selection-1',
        userId: 'user-1',
        selectionDate: new Date('2025-01-15'),
        selectedProfileIds: ['user-2'],
        chosenProfileIds: ['user-2'],
        choicesUsed: 1,
        maxChoicesAllowed: 1,
      };

      const mockChoice: Partial<UserChoice> = {
        id: 'choice-1',
        userId: 'user-1',
        targetUserId: 'user-2',
        dailySelectionId: 'selection-1',
        choiceType: ChoiceType.LIKE,
        createdAt: new Date('2025-01-15T12:00:00'),
      };

      const mockUser2: Partial<User> = {
        id: 'user-2',
        email: 'user2@example.com',
        profile: {
          firstName: 'Jane',
          lastName: 'Doe',
        } as Profile,
      };

      jest.spyOn(dailySelectionRepository, 'count').mockResolvedValue(1);
      jest
        .spyOn(dailySelectionRepository, 'find')
        .mockResolvedValue([mockSelection as DailySelection]);
      jest
        .spyOn(userChoiceRepository, 'find')
        .mockResolvedValue([mockChoice as UserChoice]);
      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValue(mockUser2 as User);
      jest.spyOn(matchRepository, 'findOne').mockResolvedValue(null);

      const result = await controller.getMatchingHistory(
        mockRequest,
        '2025-01-01',
        '2025-01-31',
        '1',
        '20',
      );

      expect(result.history).toBeDefined();
      expect(result.history.length).toBe(1);
      expect(result.history[0].date).toBe('2025-01-15');
      expect(result.history[0].profiles.length).toBe(1);
      expect(result.history[0].profiles[0].choice).toBe('like');
    });
  });

  describe('GET /matching/who-liked-me', () => {
    it('should return users who liked me for premium users', async () => {
      const mockMatches: Partial<Match>[] = [
        {
          id: 'match-1',
          user1Id: 'user-2',
          user2Id: 'user-1',
          status: MatchStatus.MATCHED,
          matchedAt: new Date('2025-01-15T12:00:00'),
          user1: {
            id: 'user-2',
            email: 'user2@example.com',
            profile: {
              firstName: 'Jane',
              lastName: 'Doe',
            } as Profile,
          } as User,
        },
      ];

      jest
        .spyOn(matchRepository, 'find')
        .mockResolvedValue(mockMatches as Match[]);

      const result = await controller.getWhoLikedMe(mockRequest);

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
      expect(result.data.length).toBe(1);
      expect(result.data[0].userId).toBe('user-2');
      expect(result.data[0].user).toBeDefined();
      expect(result.data[0].likedAt).toBeDefined();
    });

    it('should return empty array when no one liked me', async () => {
      jest.spyOn(matchRepository, 'find').mockResolvedValue([]);

      const result = await controller.getWhoLikedMe(mockRequest);

      expect(result.success).toBe(true);
      expect(result.data).toEqual([]);
    });
  });

  describe('PremiumGuard', () => {
    it('should allow premium users', async () => {
      const mockSubscription: Partial<Subscription> = {
        userId: 'user-1',
        status: SubscriptionStatus.ACTIVE,
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        isActive: true,
      };

      jest
        .spyOn(subscriptionRepository, 'findOne')
        .mockResolvedValue(mockSubscription as Subscription);

      const mockExecutionContext = {
        switchToHttp: () => ({
          getRequest: () => mockRequest,
        }),
      } as any;

      const result = await premiumGuard.canActivate(mockExecutionContext);

      expect(result).toBe(true);
    });

    it('should block non-premium users', async () => {
      jest.spyOn(subscriptionRepository, 'findOne').mockResolvedValue(null);

      const mockExecutionContext = {
        switchToHttp: () => ({
          getRequest: () => mockRequest,
        }),
      } as any;

      await expect(
        premiumGuard.canActivate(mockExecutionContext),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should block users with expired subscription', async () => {
      const mockSubscription: Partial<Subscription> = {
        userId: 'user-1',
        status: SubscriptionStatus.EXPIRED,
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        isActive: false,
      };

      jest
        .spyOn(subscriptionRepository, 'findOne')
        .mockResolvedValue(mockSubscription as Subscription);

      const mockExecutionContext = {
        switchToHttp: () => ({
          getRequest: () => mockRequest,
        }),
      } as any;

      await expect(
        premiumGuard.canActivate(mockExecutionContext),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
