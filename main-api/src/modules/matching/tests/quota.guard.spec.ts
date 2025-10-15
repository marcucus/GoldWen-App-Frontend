import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { QuotaGuard } from '../guards/quota.guard';
import { DailySelection } from '../../../database/entities/daily-selection.entity';
import { Subscription } from '../../../database/entities/subscription.entity';
import { CustomLoggerService } from '../../../common/logger';

describe('QuotaGuard', () => {
  let guard: QuotaGuard;
  let dailySelectionRepository: Repository<DailySelection>;
  let subscriptionRepository: Repository<Subscription>;
  let logger: CustomLoggerService;

  const mockDailySelectionRepository = {
    findOne: jest.fn(),
  };

  const mockSubscriptionRepository = {
    findOne: jest.fn(),
  };

  const mockLogger = {
    logBusinessEvent: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        QuotaGuard,
        {
          provide: getRepositoryToken(DailySelection),
          useValue: mockDailySelectionRepository,
        },
        {
          provide: getRepositoryToken(Subscription),
          useValue: mockSubscriptionRepository,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    guard = module.get<QuotaGuard>(QuotaGuard);
    dailySelectionRepository = module.get<Repository<DailySelection>>(
      getRepositoryToken(DailySelection),
    );
    subscriptionRepository = module.get<Repository<Subscription>>(
      getRepositoryToken(Subscription),
    );
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  const createMockExecutionContext = (userId?: string): ExecutionContext => {
    return {
      switchToHttp: () => ({
        getRequest: () => ({
          user: userId ? { id: userId } : undefined,
        }),
      }),
    } as ExecutionContext;
  };

  describe('canActivate', () => {
    it('should throw ForbiddenException if user is not authenticated', async () => {
      const context = createMockExecutionContext();

      await expect(guard.canActivate(context)).rejects.toThrow(
        ForbiddenException,
      );
      await expect(guard.canActivate(context)).rejects.toThrow(
        'User not authenticated',
      );
    });

    it('should throw ForbiddenException if user has no daily selection for today', async () => {
      const userId = 'user-123';
      const context = createMockExecutionContext(userId);

      mockDailySelectionRepository.findOne.mockResolvedValue(null);

      await expect(guard.canActivate(context)).rejects.toThrow(
        ForbiddenException,
      );
      await expect(guard.canActivate(context)).rejects.toThrow(
        "Vous devez d'abord consulter votre sélection quotidienne",
      );
    });

    it('should throw ForbiddenException if free user has exhausted quota (1 choice)', async () => {
      const userId = 'user-123';
      const context = createMockExecutionContext(userId);

      const dailySelection = {
        id: 'selection-123',
        userId,
        choicesUsed: 1,
        maxChoicesAllowed: 1,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      await expect(guard.canActivate(context)).rejects.toThrow(
        ForbiddenException,
      );
      await expect(guard.canActivate(context)).rejects.toThrow(
        'Votre choix quotidien a été utilisé. Passez à GoldWen Plus pour 3 choix par jour ou revenez demain !',
      );

      expect(mockLogger.logBusinessEvent).toHaveBeenCalledWith(
        'daily_quota_exceeded',
        expect.objectContaining({
          userId,
          choicesUsed: 1,
          maxChoices: 1,
        }),
      );
    });

    it('should throw ForbiddenException if premium user has exhausted quota (3 choices)', async () => {
      const userId = 'user-123';
      const context = createMockExecutionContext(userId);

      const dailySelection = {
        id: 'selection-123',
        userId,
        choicesUsed: 3,
        maxChoicesAllowed: 3,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      await expect(guard.canActivate(context)).rejects.toThrow(
        ForbiddenException,
      );
      await expect(guard.canActivate(context)).rejects.toThrow(
        'Vous avez utilisé vos 3 choix quotidiens. Revenez demain pour de nouveaux profils !',
      );

      expect(mockLogger.logBusinessEvent).toHaveBeenCalledWith(
        'daily_quota_exceeded',
        expect.objectContaining({
          userId,
          choicesUsed: 3,
          maxChoices: 3,
        }),
      );
    });

    it('should allow request when free user has remaining choices', async () => {
      const userId = 'user-123';
      const mockRequest = {
        user: { id: userId },
      };
      const context = {
        switchToHttp: () => ({
          getRequest: () => mockRequest,
        }),
      } as ExecutionContext;

      const dailySelection = {
        id: 'selection-123',
        userId,
        choicesUsed: 0,
        maxChoicesAllowed: 1,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockRequest).toHaveProperty('quotaInfo');
      expect(mockRequest['quotaInfo']).toEqual({
        choicesUsed: 0,
        maxChoices: 1,
        choicesRemaining: 1,
      });
    });

    it('should allow request when premium user has remaining choices', async () => {
      const userId = 'user-123';
      const mockRequest = {
        user: { id: userId },
      };
      const context = {
        switchToHttp: () => ({
          getRequest: () => mockRequest,
        }),
      } as ExecutionContext;

      const dailySelection = {
        id: 'selection-123',
        userId,
        choicesUsed: 1,
        maxChoicesAllowed: 3,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockRequest).toHaveProperty('quotaInfo');
      expect(mockRequest['quotaInfo']).toEqual({
        choicesUsed: 1,
        maxChoices: 3,
        choicesRemaining: 2,
      });
    });

    it("should check for today's selection date at midnight", async () => {
      const userId = 'user-123';
      const context = createMockExecutionContext(userId);

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      mockDailySelectionRepository.findOne.mockResolvedValue(null);

      await expect(guard.canActivate(context)).rejects.toThrow();

      expect(mockDailySelectionRepository.findOne).toHaveBeenCalledWith({
        where: {
          userId,
          selectionDate: today,
        },
      });
    });

    it('should attach quota info to request for use in controllers', async () => {
      const userId = 'user-123';
      const mockRequest = {
        user: { id: userId },
      };
      const context = {
        switchToHttp: () => ({
          getRequest: () => mockRequest,
        }),
      } as ExecutionContext;

      const dailySelection = {
        id: 'selection-123',
        userId,
        choicesUsed: 2,
        maxChoicesAllowed: 3,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      await guard.canActivate(context);

      expect(mockRequest['quotaInfo']).toBeDefined();
      expect(mockRequest['quotaInfo'].choicesUsed).toBe(2);
      expect(mockRequest['quotaInfo'].maxChoices).toBe(3);
      expect(mockRequest['quotaInfo'].choicesRemaining).toBe(1);
    });
  });
});
