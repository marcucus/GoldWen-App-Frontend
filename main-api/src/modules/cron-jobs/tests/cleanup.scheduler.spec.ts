import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';

import { CleanupScheduler } from '../schedulers/cleanup.scheduler';
import { Notification } from '../../../database/entities/notification.entity';
import { CustomLoggerService } from '../../../common/logger';

describe('CleanupScheduler', () => {
  let scheduler: CleanupScheduler;
  let notificationRepository: Repository<Notification>;
  let configService: ConfigService;
  let logger: CustomLoggerService;

  const mockNotificationRepository = {
    createQueryBuilder: jest.fn(() => ({
      delete: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      execute: jest.fn().mockResolvedValue({ affected: 15 }),
    })),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === 'app.environment') return 'development';
      return undefined;
    }),
  };

  const mockLogger = {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CleanupScheduler,
        {
          provide: getRepositoryToken(Notification),
          useValue: mockNotificationRepository,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    scheduler = module.get<CleanupScheduler>(CleanupScheduler);
    notificationRepository = module.get<Repository<Notification>>(
      getRepositoryToken(Notification),
    );
    configService = module.get<ConfigService>(ConfigService);
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('cleanupOldData', () => {
    it('should successfully clean up old notifications', async () => {
      await scheduler.cleanupOldData();

      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('Starting general data cleanup job'),
        expect.any(Object),
      );

      expect(mockNotificationRepository.createQueryBuilder).toHaveBeenCalled();

      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('General data cleanup completed'),
        expect.objectContaining({
          results: expect.objectContaining({
            notifications: 15,
          }),
        }),
      );
    });

    it('should handle cleanup errors gracefully', async () => {
      mockNotificationRepository.createQueryBuilder.mockImplementationOnce(
        () => ({
          delete: jest.fn().mockReturnThis(),
          where: jest.fn().mockReturnThis(),
          execute: jest.fn().mockRejectedValue(new Error('Database error')),
        }),
      );

      await expect(scheduler.cleanupOldData()).rejects.toThrow(
        'Database error',
      );

      expect(mockLogger.error).toHaveBeenCalledWith(
        expect.stringContaining('General data cleanup job failed'),
        expect.any(String),
        'CleanupScheduler',
      );
    });

    it('should delete notifications older than 30 days', async () => {
      const mockQueryBuilder = {
        delete: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({ affected: 15 }),
      };

      mockNotificationRepository.createQueryBuilder.mockReturnValue(
        mockQueryBuilder,
      );

      await scheduler.cleanupOldData();

      expect(mockQueryBuilder.where).toHaveBeenCalledWith('createdAt < :date', {
        date: expect.any(Date),
      });
    });

    it('should track execution time', async () => {
      await scheduler.cleanupOldData();

      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('General data cleanup completed'),
        expect.objectContaining({
          executionTimeMs: expect.any(Number),
          executionTimeSec: expect.any(String),
        }),
      );
    });

    it('should handle empty result sets', async () => {
      mockNotificationRepository.createQueryBuilder.mockImplementationOnce(
        () => ({
          delete: jest.fn().mockReturnThis(),
          where: jest.fn().mockReturnThis(),
          execute: jest.fn().mockResolvedValue({ affected: 0 }),
        }),
      );

      await scheduler.cleanupOldData();

      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('General data cleanup completed'),
        expect.objectContaining({
          results: expect.objectContaining({
            notifications: 0,
          }),
        }),
      );
    });
  });

  describe('triggerCleanup', () => {
    it('should trigger cleanup in development environment', async () => {
      const cleanupSpy = jest
        .spyOn(scheduler, 'cleanupOldData')
        .mockResolvedValue(undefined);

      await scheduler.triggerCleanup();

      expect(cleanupSpy).toHaveBeenCalled();
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Manual trigger: General data cleanup',
        expect.any(Object),
      );
    });

    it('should prevent manual trigger in production', async () => {
      mockConfigService.get.mockImplementationOnce((key: string) => {
        if (key === 'app.environment') return 'production';
        return undefined;
      });

      await expect(scheduler.triggerCleanup()).rejects.toThrow(
        'Manual trigger not allowed in production',
      );
    });
  });
});
