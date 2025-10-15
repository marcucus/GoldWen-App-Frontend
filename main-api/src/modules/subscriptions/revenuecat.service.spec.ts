import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

import { RevenueCatService } from './revenuecat.service';
import { SubscriptionsService } from './subscriptions.service';
import { CustomLoggerService } from '../../common/logger';
import { RevenueCatWebhookDto } from './dto/subscription.dto';
import { SubscriptionPlan } from '../../common/enums';

describe('RevenueCatService', () => {
  let service: RevenueCatService;

  const mockSubscriptionsService = {
    handleRevenueCatWebhook: jest.fn(),
    getPlans: jest.fn(),
    getActiveSubscription: jest.fn(),
    createSubscription: jest.fn(),
    activateSubscription: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === 'revenueCat.webhookSecret') return 'test-secret';
      if (key === 'app.environment') return 'development';
      return null;
    }),
  };

  const mockLogger = {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    logBusinessEvent: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RevenueCatService,
        {
          provide: SubscriptionsService,
          useValue: mockSubscriptionsService,
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

    service = module.get<RevenueCatService>(RevenueCatService);
    subscriptionsService =
      module.get<SubscriptionsService>(SubscriptionsService);
    configService = module.get<ConfigService>(ConfigService);
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('verifyWebhookSignature', () => {
    it('should verify valid webhook signature', () => {
      const webhookSecret = 'test-secret';
      mockConfigService.get.mockReturnValue(webhookSecret);

      const rawBody = JSON.stringify({ test: 'data' });
      const hmac = crypto.createHmac('sha256', webhookSecret);
      hmac.update(rawBody);
      const expectedSignature = hmac.digest('hex');

      const result = service.verifyWebhookSignature(expectedSignature, rawBody);

      expect(result).toBe(true);
    });

    it('should reject invalid webhook signature', () => {
      const webhookSecret = 'test-secret';
      mockConfigService.get.mockReturnValue(webhookSecret);

      const rawBody = JSON.stringify({ test: 'data' });
      const invalidSignature = 'invalid-signature';

      const result = service.verifyWebhookSignature(invalidSignature, rawBody);

      expect(result).toBe(false);
    });

    it('should return true in development without secret', async () => {
      // Create a new service instance with no webhook secret
      const noSecretConfigService = {
        get: jest.fn((key: string) => {
          if (key === 'revenueCat.webhookSecret') return '';
          if (key === 'app.environment') return 'development';
          return null;
        }),
      };

      const module: TestingModule = await Test.createTestingModule({
        providers: [
          RevenueCatService,
          {
            provide: SubscriptionsService,
            useValue: mockSubscriptionsService,
          },
          {
            provide: ConfigService,
            useValue: noSecretConfigService,
          },
          {
            provide: CustomLoggerService,
            useValue: mockLogger,
          },
        ],
      }).compile();

      const testService = module.get<RevenueCatService>(RevenueCatService);

      const result = testService.verifyWebhookSignature('any', 'body');

      expect(result).toBe(true);
      expect(mockLogger.warn).toHaveBeenCalled();
    });

    it('should return false in production without secret', async () => {
      // Create a new service instance with no webhook secret in production
      const noSecretProductionConfigService = {
        get: jest.fn((key: string) => {
          if (key === 'revenueCat.webhookSecret') return '';
          if (key === 'app.environment') return 'production';
          return null;
        }),
      };

      const module: TestingModule = await Test.createTestingModule({
        providers: [
          RevenueCatService,
          {
            provide: SubscriptionsService,
            useValue: mockSubscriptionsService,
          },
          {
            provide: ConfigService,
            useValue: noSecretProductionConfigService,
          },
          {
            provide: CustomLoggerService,
            useValue: mockLogger,
          },
        ],
      }).compile();

      const testService = module.get<RevenueCatService>(RevenueCatService);

      const result = testService.verifyWebhookSignature('any', 'body');

      expect(result).toBe(false);
    });
  });

  describe('processWebhook', () => {
    const mockWebhookData: RevenueCatWebhookDto = {
      event: {
        type: 'INITIAL_PURCHASE',
        id: 'event-123',
        product_id: 'goldwen_plus_monthly',
        purchased_at: '2024-01-01T00:00:00Z',
        expiration_at: '2024-02-01T00:00:00Z',
      },
      app_user_id: 'user-123',
      api_version: '1.0',
    };

    it('should process webhook successfully', async () => {
      mockSubscriptionsService.handleRevenueCatWebhook.mockResolvedValue(
        undefined,
      );

      await service.processWebhook(mockWebhookData);

      expect(
        mockSubscriptionsService.handleRevenueCatWebhook,
      ).toHaveBeenCalledWith(mockWebhookData);
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Processing RevenueCat webhook',
        expect.objectContaining({
          eventType: 'INITIAL_PURCHASE',
          userId: 'user-123',
          eventId: 'event-123',
        }),
      );
      expect(mockLogger.logBusinessEvent).toHaveBeenCalledWith(
        'revenuecat_webhook_processed',
        expect.objectContaining({
          eventType: 'INITIAL_PURCHASE',
          userId: 'user-123',
          eventId: 'event-123',
        }),
      );
    });

    it('should handle webhook processing errors', async () => {
      const error = new Error('Processing failed');
      mockSubscriptionsService.handleRevenueCatWebhook.mockRejectedValue(error);

      await expect(service.processWebhook(mockWebhookData)).rejects.toThrow(
        'Processing failed',
      );

      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('getOfferings', () => {
    it('should return offerings in RevenueCat format', () => {
      mockSubscriptionsService.getPlans.mockReturnValue({
        plans: [
          {
            id: 'goldwen_plus_monthly',
            name: 'GoldWen Plus',
            price: 19.99,
            currency: 'EUR',
            duration: 'monthly',
            features: [],
          },
          {
            id: 'goldwen_plus_yearly',
            name: 'GoldWen Plus',
            price: 179.99,
            currency: 'EUR',
            duration: 'yearly',
            features: [],
          },
        ],
      });

      const result = service.getOfferings();

      expect(result.offerings).toHaveLength(1);
      expect(result.offerings[0].identifier).toBe('default');
      expect(result.offerings[0].packages).toHaveLength(2);
      expect(result.offerings[0].packages[0]).toEqual({
        identifier: 'monthly',
        platform_product_identifier: 'goldwen_plus_monthly',
      });
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Retrieved RevenueCat offerings',
        expect.objectContaining({
          offeringsCount: 1,
          packagesCount: 2,
        }),
      );
    });
  });

  describe('getSubscriptionStatus', () => {
    it('should return active subscription status', async () => {
      const mockSubscription = {
        id: 'sub-123',
        userId: 'user-123',
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        status: 'active',
        isActive: true,
        expiresAt: new Date('2024-12-31'),
        platform: 'ios',
        cancelledAt: null,
      };

      mockSubscriptionsService.getActiveSubscription.mockResolvedValue(
        mockSubscription,
      );

      const result = await service.getSubscriptionStatus('user-123');

      expect(result).toEqual({
        active: true,
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        expiresAt: mockSubscription.expiresAt,
        willRenew: true,
        platform: 'ios',
      });
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Retrieved subscription status',
        expect.objectContaining({
          userId: 'user-123',
          active: true,
        }),
      );
    });

    it('should return inactive status when no subscription', async () => {
      mockSubscriptionsService.getActiveSubscription.mockResolvedValue(null);

      const result = await service.getSubscriptionStatus('user-123');

      expect(result).toEqual({
        active: false,
        willRenew: false,
      });
    });

    it('should indicate subscription will not renew if cancelled', async () => {
      const mockSubscription = {
        id: 'sub-123',
        userId: 'user-123',
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        status: 'active',
        isActive: true,
        expiresAt: new Date('2024-12-31'),
        platform: 'ios',
        cancelledAt: new Date('2024-11-01'),
      };

      mockSubscriptionsService.getActiveSubscription.mockResolvedValue(
        mockSubscription,
      );

      const result = await service.getSubscriptionStatus('user-123');

      expect(result.willRenew).toBe(false);
    });

    it('should handle errors when getting subscription status', async () => {
      const error = new Error('Database error');
      mockSubscriptionsService.getActiveSubscription.mockRejectedValue(error);

      await expect(service.getSubscriptionStatus('user-123')).rejects.toThrow(
        'Database error',
      );

      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('validatePurchase', () => {
    const mockPurchaseData = {
      productId: 'goldwen_plus_monthly',
      transactionId: 'rc_transaction_123456',
      originalTransactionId: 'original_transaction_123456',
      purchaseToken: 'purchase_token_123',
      price: 19.99,
      currency: 'EUR',
      platform: 'ios',
    };

    it('should validate and process purchase successfully', async () => {
      const mockSubscription = {
        id: 'sub-123',
        userId: 'user-123',
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        status: 'active',
        expiresAt: new Date('2024-12-31'),
      };

      mockSubscriptionsService.createSubscription.mockResolvedValue(
        mockSubscription,
      );
      mockSubscriptionsService.activateSubscription.mockResolvedValue({
        ...mockSubscription,
        status: 'active',
      });

      const result = await service.validatePurchase(
        'user-123',
        mockPurchaseData,
      );

      expect(result.success).toBe(true);
      expect(result.subscription).toBeDefined();
      expect(result.subscription?.id).toBe('sub-123');
      expect(result.subscription?.plan).toBe(SubscriptionPlan.GOLDWEN_PLUS);
      expect(mockSubscriptionsService.createSubscription).toHaveBeenCalledWith(
        'user-123',
        expect.objectContaining({
          plan: SubscriptionPlan.GOLDWEN_PLUS,
          revenueCatSubscriptionId: 'rc_transaction_123456',
          price: 19.99,
          currency: 'EUR',
          platform: 'ios',
        }),
      );
      expect(
        mockSubscriptionsService.activateSubscription,
      ).toHaveBeenCalledWith('sub-123');
      expect(mockLogger.logBusinessEvent).toHaveBeenCalledWith(
        'purchase_validated',
        expect.objectContaining({
          userId: 'user-123',
          productId: 'goldwen_plus_monthly',
        }),
      );
    });

    it('should handle validation errors gracefully', async () => {
      const error = new Error('Database error');
      mockSubscriptionsService.createSubscription.mockRejectedValue(error);

      const result = await service.validatePurchase(
        'user-123',
        mockPurchaseData,
      );

      expect(result.success).toBe(false);
      expect(result.message).toContain('Failed to validate purchase');
      expect(mockLogger.error).toHaveBeenCalled();
    });

    it('should handle non-goldwen_plus products correctly', async () => {
      const freePurchaseData = {
        ...mockPurchaseData,
        productId: 'some_free_product',
      };

      const mockSubscription = {
        id: 'sub-123',
        userId: 'user-123',
        plan: 'free',
        status: 'active',
        expiresAt: new Date('2024-12-31'),
      };

      mockSubscriptionsService.createSubscription.mockResolvedValue(
        mockSubscription,
      );
      mockSubscriptionsService.activateSubscription.mockResolvedValue(
        mockSubscription,
      );

      const result = await service.validatePurchase(
        'user-123',
        freePurchaseData,
      );

      expect(result.success).toBe(true);
      expect(mockSubscriptionsService.createSubscription).toHaveBeenCalledWith(
        'user-123',
        expect.objectContaining({
          plan: SubscriptionPlan.FREE,
        }),
      );
    });
  });
});
