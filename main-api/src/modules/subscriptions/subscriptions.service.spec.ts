import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { SubscriptionsService } from './subscriptions.service';
import { Subscription } from '../../database/entities/subscription.entity';
import { User } from '../../database/entities/user.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { SubscriptionStatus, SubscriptionPlan } from '../../common/enums';
import { CustomLoggerService } from '../../common/logger';

describe('SubscriptionsService', () => {
  let service: SubscriptionsService;

  const mockSubscriptionRepository = {
    create: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
    findOne: jest.fn(),
    count: jest.fn(),
    update: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockDailySelectionRepository = {
    findOne: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn(),
  };

  const mockLogger = {
    error: jest.fn(),
    info: jest.fn(),
    logBusinessEvent: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SubscriptionsService,
        {
          provide: getRepositoryToken(Subscription),
          useValue: mockSubscriptionRepository,
        },
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: getRepositoryToken(DailySelection),
          useValue: mockDailySelectionRepository,
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

    service = module.get<SubscriptionsService>(SubscriptionsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getPlans', () => {
    it('should return available subscription plans', async () => {
      const result = await service.getPlans();

      expect(result).toHaveProperty('plans');
      expect(result.plans).toHaveLength(3);
      expect(result.plans[0]).toEqual({
        id: 'goldwen_plus_monthly',
        name: 'GoldWen Plus',
        price: 19.99,
        currency: 'EUR',
        duration: 'monthly',
        features: [
          '3 sélections par jour',
          'Chat illimité',
          'Voir qui vous a sélectionné',
          'Profil prioritaire',
        ],
      });
    });
  });

  describe('getActiveSubscription', () => {
    it('should return active subscription for user', async () => {
      const mockSubscription = {
        id: '123',
        userId: 'user1',
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        status: SubscriptionStatus.ACTIVE,
        isActive: true,
      };

      mockSubscriptionRepository.findOne.mockResolvedValue(mockSubscription);

      const result = await service.getActiveSubscription('user1');

      expect(mockSubscriptionRepository.findOne).toHaveBeenCalledWith({
        where: {
          userId: 'user1',
          status: SubscriptionStatus.ACTIVE,
        },
        order: { createdAt: 'DESC' },
      });
      expect(result).toEqual(mockSubscription);
    });

    it('should return null if no active subscription', async () => {
      mockSubscriptionRepository.findOne.mockResolvedValue(null);

      const result = await service.getActiveSubscription('user1');

      expect(result).toBeNull();
    });
  });

  describe('getUserSubscriptionTier', () => {
    it('should return premium tier for active subscription', async () => {
      const mockSubscription = {
        id: '123',
        userId: 'user1',
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        status: SubscriptionStatus.ACTIVE,
        isActive: true,
      };

      mockSubscriptionRepository.findOne.mockResolvedValue(mockSubscription);

      const result = await service.getUserSubscriptionTier('user1');

      expect(result).toEqual({
        tier: SubscriptionPlan.GOLDWEN_PLUS,
        isActive: true,
        features: {
          maxDailyChoices: 3,
          hasExtendChatFeature: true,
          hasPrioritySupport: true,
          canSeeWhoLiked: true,
        },
      });
    });

    it('should return free tier for no active subscription', async () => {
      mockSubscriptionRepository.findOne.mockResolvedValue(null);

      const result = await service.getUserSubscriptionTier('user1');

      expect(result).toEqual({
        tier: SubscriptionPlan.FREE,
        isActive: false,
        features: {
          maxDailyChoices: 1,
          hasExtendChatFeature: false,
          hasPrioritySupport: false,
          canSeeWhoLiked: false,
        },
      });
    });
  });

  describe('isUserPremium', () => {
    it('should return true for premium user', async () => {
      const mockSubscription = {
        id: '123',
        userId: 'user1',
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        status: SubscriptionStatus.ACTIVE,
        isActive: true,
      };

      mockSubscriptionRepository.findOne.mockResolvedValue(mockSubscription);

      const result = await service.isUserPremium('user1');

      expect(result).toBe(true);
    });

    it('should return false for free user', async () => {
      mockSubscriptionRepository.findOne.mockResolvedValue(null);

      const result = await service.isUserPremium('user1');

      expect(result).toBe(false);
    });
  });

  describe('getUsage', () => {
    it('should return usage for premium user', async () => {
      const mockSubscription = {
        id: '123',
        userId: 'user1',
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        status: SubscriptionStatus.ACTIVE,
        isActive: true,
      };

      mockSubscriptionRepository.findOne.mockResolvedValue(mockSubscription);
      mockDailySelectionRepository.findOne.mockResolvedValue(null);

      const result = await service.getUsage('user1');

      expect(result).toHaveProperty('dailyChoices');
      expect(result.dailyChoices.limit).toBe(3);
      expect(result.dailyChoices.used).toBe(0);
      expect(result.dailyChoices.remaining).toBe(3);
      expect(result.subscription.tier).toBe('premium');
      expect(result.subscription.isActive).toBe(true);
    });

    it('should return usage for free user', async () => {
      mockSubscriptionRepository.findOne.mockResolvedValue(null);
      mockDailySelectionRepository.findOne.mockResolvedValue(null);

      const result = await service.getUsage('user1');

      expect(result).toHaveProperty('dailyChoices');
      expect(result.dailyChoices.limit).toBe(1);
      expect(result.dailyChoices.used).toBe(0);
      expect(result.dailyChoices.remaining).toBe(1);
      expect(result.subscription.tier).toBe('free');
      expect(result.subscription.isActive).toBe(false);
    });
  });

  describe('cancelUserSubscription', () => {
    it('should cancel active subscription', async () => {
      const mockSubscription = {
        id: '123',
        userId: 'user1',
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        status: SubscriptionStatus.ACTIVE,
        metadata: {},
      };

      mockSubscriptionRepository.findOne.mockResolvedValue(mockSubscription);
      mockSubscriptionRepository.save.mockResolvedValue({
        ...mockSubscription,
        status: SubscriptionStatus.CANCELLED,
        cancelledAt: new Date(),
        metadata: {
          cancellationReason: 'too_expensive',
          cancelledBy: 'user',
        },
      });

      await service.cancelUserSubscription('user1', 'too_expensive');

      expect(mockSubscription.status).toBe(SubscriptionStatus.CANCELLED);
      expect(mockSubscription.cancelledAt).toBeDefined();
      expect(mockSubscription.metadata.cancellationReason).toBe(
        'too_expensive',
      );
    });

    it('should throw error if no active subscription', async () => {
      mockSubscriptionRepository.findOne.mockResolvedValue(null);

      await expect(service.cancelUserSubscription('user1')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
