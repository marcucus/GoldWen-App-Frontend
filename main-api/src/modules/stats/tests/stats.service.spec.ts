import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';

import { StatsService } from '../stats.service';
import { CustomLoggerService } from '../../../common/logger';

import { User } from '../../../database/entities/user.entity';
import { Match } from '../../../database/entities/match.entity';
import { Chat } from '../../../database/entities/chat.entity';
import { Message } from '../../../database/entities/message.entity';
import { Subscription } from '../../../database/entities/subscription.entity';
import { Report } from '../../../database/entities/report.entity';
import { DailySelection } from '../../../database/entities/daily-selection.entity';

import {
  UserStatus,
  MatchStatus,
  ChatStatus,
  SubscriptionStatus,
  ReportStatus,
} from '../../../common/enums';

describe('StatsService', () => {
  let service: StatsService;
  let userRepository: Repository<User>;
  let matchRepository: Repository<Match>;
  let chatRepository: Repository<Chat>;
  let messageRepository: Repository<Message>;
  let subscriptionRepository: Repository<Subscription>;
  let reportRepository: Repository<Report>;
  let dailySelectionRepository: Repository<DailySelection>;

  const mockRepository = () => ({
    count: jest.fn(),
    find: jest.fn(),
    findOne: jest.fn(),
    createQueryBuilder: jest.fn(() => ({
      select: jest.fn().mockReturnThis(),
      innerJoin: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      groupBy: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      getRawMany: jest.fn(),
      getRawOne: jest.fn(),
      getCount: jest.fn(),
    })),
  });

  const mockLogger = {
    log: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StatsService,
        {
          provide: getRepositoryToken(User),
          useFactory: mockRepository,
        },
        {
          provide: getRepositoryToken(Match),
          useFactory: mockRepository,
        },
        {
          provide: getRepositoryToken(Chat),
          useFactory: mockRepository,
        },
        {
          provide: getRepositoryToken(Message),
          useFactory: mockRepository,
        },
        {
          provide: getRepositoryToken(Subscription),
          useFactory: mockRepository,
        },
        {
          provide: getRepositoryToken(Report),
          useFactory: mockRepository,
        },
        {
          provide: getRepositoryToken(DailySelection),
          useFactory: mockRepository,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    service = module.get<StatsService>(StatsService);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    matchRepository = module.get<Repository<Match>>(getRepositoryToken(Match));
    chatRepository = module.get<Repository<Chat>>(getRepositoryToken(Chat));
    messageRepository = module.get<Repository<Message>>(
      getRepositoryToken(Message),
    );
    subscriptionRepository = module.get<Repository<Subscription>>(
      getRepositoryToken(Subscription),
    );
    reportRepository = module.get<Repository<Report>>(
      getRepositoryToken(Report),
    );
    dailySelectionRepository = module.get<Repository<DailySelection>>(
      getRepositoryToken(DailySelection),
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getGlobalStats', () => {
    it('should return global statistics', async () => {
      // Mock all count methods
      jest.spyOn(userRepository, 'count').mockResolvedValueOnce(1000); // totalUsers
      jest.spyOn(userRepository, 'count').mockResolvedValueOnce(950); // activeUsers
      jest.spyOn(userRepository, 'count').mockResolvedValueOnce(50); // suspendedUsers
      jest.spyOn(matchRepository, 'count').mockResolvedValueOnce(500); // totalMatches
      jest.spyOn(chatRepository, 'count').mockResolvedValueOnce(300); // activeChats
      jest.spyOn(reportRepository, 'count').mockResolvedValueOnce(10); // pendingReports
      jest.spyOn(subscriptionRepository, 'count').mockResolvedValueOnce(200); // activeSubscriptions
      jest.spyOn(userRepository, 'count').mockResolvedValueOnce(25); // newRegistrationsToday
      jest.spyOn(matchRepository, 'count').mockResolvedValueOnce(15); // newMatchesToday
      jest.spyOn(messageRepository, 'count').mockResolvedValueOnce(100); // messagesSentToday
      jest.spyOn(userRepository, 'count').mockResolvedValueOnce(600); // dailyActiveUsers
      jest.spyOn(userRepository, 'count').mockResolvedValueOnce(800); // monthlyActiveUsers

      // Mock subscriptions for revenue calculation
      jest
        .spyOn(subscriptionRepository, 'find')
        .mockResolvedValueOnce([
          { price: 10 } as any,
          { price: 15 } as any,
          { price: 20 } as any,
        ]);

      const result = await service.getGlobalStats();

      expect(result).toEqual({
        totalUsers: 1000,
        activeUsers: 950,
        suspendedUsers: 50,
        totalMatches: 500,
        activeChats: 300,
        pendingReports: 10,
        totalRevenue: 45,
        activeSubscriptions: 200,
        newRegistrationsToday: 25,
        newMatchesToday: 15,
        messagesSentToday: 100,
        avgMatchesPerUser: 0.5,
        dailyActiveUsers: 600,
        monthlyActiveUsers: 800,
      });

      expect(mockLogger.log).toHaveBeenCalledWith('Fetching global statistics');
      expect(mockLogger.log).toHaveBeenCalledWith(
        'Global statistics fetched successfully',
      );
    });

    it('should handle errors', async () => {
      const error = new Error('Database error');
      jest.spyOn(userRepository, 'count').mockRejectedValueOnce(error);

      await expect(service.getGlobalStats()).rejects.toThrow(error);
      expect(mockLogger.error).toHaveBeenCalledWith(
        'Failed to fetch global statistics',
        error,
      );
    });
  });

  describe('getUserStats', () => {
    const userId = 'test-user-id';
    const mockUser = {
      id: userId,
      createdAt: new Date(),
      lastActiveAt: new Date(),
      profile: {
        firstName: 'John',
        lastName: 'Doe',
        birthDate: new Date(),
        bio: 'Test bio',
        location: 'Test location',
      },
    };

    it('should return user statistics', async () => {
      jest
        .spyOn(userRepository, 'findOne')
        .mockResolvedValueOnce(mockUser as any);
      jest.spyOn(matchRepository, 'count').mockResolvedValueOnce(5);

      // Mock chat query builder
      const mockChatQueryBuilder = {
        createQueryBuilder: jest.fn().mockReturnThis(),
        innerJoin: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getCount: jest.fn().mockResolvedValue(3),
      };
      jest
        .spyOn(chatRepository, 'createQueryBuilder')
        .mockReturnValue(mockChatQueryBuilder as any);

      jest.spyOn(messageRepository, 'count').mockResolvedValueOnce(20); // messagesSent

      // Mock message query builder for received messages
      const mockMessageQueryBuilder = {
        createQueryBuilder: jest.fn().mockReturnThis(),
        innerJoin: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getCount: jest.fn().mockResolvedValue(15),
      };
      jest
        .spyOn(messageRepository, 'createQueryBuilder')
        .mockReturnValue(mockMessageQueryBuilder as any);

      jest.spyOn(dailySelectionRepository, 'count').mockResolvedValueOnce(10);

      // Mock daily selection query builder
      const mockDailySelectionQueryBuilder = {
        createQueryBuilder: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getRawOne: jest.fn().mockResolvedValue({ total: '30' }),
      };
      jest
        .spyOn(dailySelectionRepository, 'createQueryBuilder')
        .mockReturnValue(mockDailySelectionQueryBuilder as any);

      jest.spyOn(subscriptionRepository, 'findOne').mockResolvedValueOnce({
        plan: 'premium',
      } as any);

      const result = await service.getUserStats(userId);

      expect(result).toEqual(
        expect.objectContaining({
          userId,
          totalMatches: 5,
          activeChats: 3,
          messagesSent: 20,
          messagesReceived: 15,
          dailySelectionsUsed: 10,
          totalChoicesUsed: 30,
          averageChoicesPerSelection: 3,
          matchRate: 0.5,
          hasActiveSubscription: true,
          subscriptionPlan: 'premium',
          profileCompletionPercent: 100,
        }),
      );
    });

    it('should throw NotFoundException when user does not exist', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValueOnce(null);

      await expect(service.getUserStats(userId)).rejects.toThrow(
        NotFoundException,
      );
      expect(mockLogger.error).toHaveBeenCalledWith(
        `Failed to fetch user statistics for user: ${userId}`,
        expect.any(NotFoundException),
      );
    });
  });

  describe('getActivityStats', () => {
    it('should return activity statistics with default parameters', async () => {
      const mockData = [
        { date: '2024-01-01', count: '10' },
        { date: '2024-01-02', count: '15' },
      ];

      // Mock query builders for each activity type
      const mockQueryBuilder = {
        createQueryBuilder: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        groupBy: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getRawMany: jest.fn().mockResolvedValue(mockData),
      };

      jest
        .spyOn(userRepository, 'createQueryBuilder')
        .mockReturnValue(mockQueryBuilder as any);
      jest
        .spyOn(matchRepository, 'createQueryBuilder')
        .mockReturnValue(mockQueryBuilder as any);
      jest
        .spyOn(messageRepository, 'createQueryBuilder')
        .mockReturnValue(mockQueryBuilder as any);
      jest
        .spyOn(subscriptionRepository, 'createQueryBuilder')
        .mockReturnValue(mockQueryBuilder as any);

      const result = await service.getActivityStats({});

      expect(result).toEqual(
        expect.objectContaining({
          dateRange: expect.any(Object),
          userRegistrations: expect.any(Array),
          matchesCreated: expect.any(Array),
          messagesSent: expect.any(Array),
          dailyActiveUsers: expect.any(Array),
          subscriptionConversions: expect.any(Array),
          summary: expect.objectContaining({
            totalActivity: expect.any(Number),
            averageDailyActivity: expect.any(Number),
            peakActivityDate: expect.any(String),
            peakActivityCount: expect.any(Number),
          }),
        }),
      );
    });
  });

  describe('exportStats', () => {
    it('should export global statistics', async () => {
      const mockGlobalStats = {
        totalUsers: 1000,
        activeUsers: 950,
      };

      jest
        .spyOn(service, 'getGlobalStats')
        .mockResolvedValueOnce(mockGlobalStats as any);

      const result = await service.exportStats('global');

      expect(result).toEqual({
        data: mockGlobalStats,
        format: 'json',
        filename: expect.stringContaining('global-stats-'),
      });
    });

    it('should export activity statistics', async () => {
      const mockActivityStats = {
        dateRange: { startDate: '2024-01-01', endDate: '2024-01-31' },
        userRegistrations: [],
      };

      jest
        .spyOn(service, 'getActivityStats')
        .mockResolvedValueOnce(mockActivityStats as any);

      const result = await service.exportStats('activity', {});

      expect(result).toEqual({
        data: mockActivityStats,
        format: 'json',
        filename: expect.stringContaining('activity-stats-'),
      });
    });
  });
});
