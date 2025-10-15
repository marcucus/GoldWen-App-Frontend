import { Test, TestingModule } from '@nestjs/testing';
import { Response } from 'express';

import { StatsController } from '../stats.controller';
import { StatsService } from '../stats.service';
import {
  GlobalStatsResponseDto,
  UserStatsResponseDto,
  ActivityStatsResponseDto,
  ExportFormat,
} from '../dto';

describe('StatsController', () => {
  let controller: StatsController;
  let statsService: StatsService;

  const mockStatsService = {
    getGlobalStats: jest.fn(),
    getUserStats: jest.fn(),
    getActivityStats: jest.fn(),
    exportStats: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [StatsController],
      providers: [
        {
          provide: StatsService,
          useValue: mockStatsService,
        },
      ],
    }).compile();

    controller = module.get<StatsController>(StatsController);
    statsService = module.get<StatsService>(StatsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('getGlobalStats', () => {
    it('should return global statistics', async () => {
      const mockStats: GlobalStatsResponseDto = {
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
      };

      jest
        .spyOn(statsService, 'getGlobalStats')
        .mockResolvedValueOnce(mockStats);

      const result = await controller.getGlobalStats();

      expect(result).toEqual({
        success: true,
        data: mockStats,
      });
      expect(statsService.getGlobalStats).toHaveBeenCalledTimes(1);
    });
  });

  describe('getUserStats', () => {
    it('should return user statistics', async () => {
      const userId = 'test-user-id';
      const mockStats: UserStatsResponseDto = {
        userId,
        totalMatches: 5,
        activeChats: 3,
        profileViews: 50,
        loginStreak: 7,
        messagesSent: 20,
        messagesReceived: 15,
        dailySelectionsUsed: 10,
        totalChoicesUsed: 30,
        averageChoicesPerSelection: 3,
        matchRate: 0.5,
        createdAt: new Date(),
        lastActiveAt: new Date(),
        hasActiveSubscription: true,
        subscriptionPlan: 'premium',
        profileCompletionPercent: 100,
      };

      jest.spyOn(statsService, 'getUserStats').mockResolvedValueOnce(mockStats);

      const result = await controller.getUserStats(userId);

      expect(result).toEqual({
        success: true,
        data: mockStats,
      });
      expect(statsService.getUserStats).toHaveBeenCalledWith(userId);
    });
  });

  describe('getActivityStats', () => {
    it('should return activity statistics', async () => {
      const query = {
        startDate: '2024-01-01',
        endDate: '2024-01-31',
        period: 'daily' as const,
      };

      const mockStats: ActivityStatsResponseDto = {
        dateRange: {
          startDate: '2024-01-01',
          endDate: '2024-01-31',
        },
        userRegistrations: [
          { date: '2024-01-01', count: 10 },
          { date: '2024-01-02', count: 15 },
        ],
        matchesCreated: [
          { date: '2024-01-01', count: 5 },
          { date: '2024-01-02', count: 8 },
        ],
        messagesSent: [
          { date: '2024-01-01', count: 100 },
          { date: '2024-01-02', count: 120 },
        ],
        dailyActiveUsers: [
          { date: '2024-01-01', count: 200 },
          { date: '2024-01-02', count: 220 },
        ],
        subscriptionConversions: [
          { date: '2024-01-01', count: 2 },
          { date: '2024-01-02', count: 3 },
        ],
        summary: {
          totalActivity: 483,
          averageDailyActivity: 241.5,
          peakActivityDate: '2024-01-02',
          peakActivityCount: 366,
        },
      };

      jest
        .spyOn(statsService, 'getActivityStats')
        .mockResolvedValueOnce(mockStats);

      const result = await controller.getActivityStats(query);

      expect(result).toEqual({
        success: true,
        data: mockStats,
      });
      expect(statsService.getActivityStats).toHaveBeenCalledWith(query);
    });
  });

  describe('exportGlobalStats', () => {
    it('should export global statistics', async () => {
      const exportOptions = {
        format: ExportFormat.JSON,
        includeDetails: false,
      };

      const mockExportResult = {
        data: { totalUsers: 1000 },
        format: ExportFormat.JSON,
        filename: 'global-stats-2024-01-15.json',
      };

      const mockResponse = {
        setHeader: jest.fn(),
        json: jest.fn(),
      } as unknown as Response;

      jest
        .spyOn(statsService, 'exportStats')
        .mockResolvedValueOnce(mockExportResult);

      await controller.exportGlobalStats(exportOptions, mockResponse);

      expect(statsService.exportStats).toHaveBeenCalledWith(
        'global',
        undefined,
        exportOptions,
      );
      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'Content-Type',
        'application/json',
      );
      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'Content-Disposition',
        'attachment; filename="global-stats-2024-01-15.json"',
      );
      expect(mockResponse.json).toHaveBeenCalledWith(mockExportResult.data);
    });
  });

  describe('exportActivityStats', () => {
    it('should export activity statistics', async () => {
      const query = {
        startDate: '2024-01-01',
        endDate: '2024-01-31',
        period: 'daily' as const,
        format: ExportFormat.CSV,
        includeDetails: true,
      };

      const mockExportResult = {
        data: { userRegistrations: [] },
        format: ExportFormat.CSV,
        filename: 'activity-stats-2024-01-15.csv',
      };

      const mockResponse = {
        setHeader: jest.fn(),
        json: jest.fn(),
      } as unknown as Response;

      jest
        .spyOn(statsService, 'exportStats')
        .mockResolvedValueOnce(mockExportResult);

      await controller.exportActivityStats(query, mockResponse);

      const { format, includeDetails, ...activityQuery } = query;
      const exportOptions = { format, includeDetails };

      expect(statsService.exportStats).toHaveBeenCalledWith(
        'activity',
        activityQuery,
        exportOptions,
      );
      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'Content-Type',
        'text/csv',
      );
      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'Content-Disposition',
        'attachment; filename="activity-stats-2024-01-15.csv"',
      );
      expect(mockResponse.json).toHaveBeenCalledWith(mockExportResult.data);
    });
  });
});
