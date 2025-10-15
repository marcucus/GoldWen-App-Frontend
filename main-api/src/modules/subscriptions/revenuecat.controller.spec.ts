import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException, BadRequestException } from '@nestjs/common';

import { RevenueCatController } from './revenuecat.controller';
import { RevenueCatService } from './revenuecat.service';
import { CustomLoggerService } from '../../common/logger';
import { RevenueCatWebhookDto } from './dto/subscription.dto';
import { SubscriptionPlan } from '../../common/enums';

describe('RevenueCatController', () => {
  let controller: RevenueCatController;

  const mockRevenueCatService = {
    verifyWebhookSignature: jest.fn(),
    processWebhook: jest.fn(),
    getOfferings: jest.fn(),
    getSubscriptionStatus: jest.fn(),
    validatePurchase: jest.fn(),
  };

  const mockLogger = {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [RevenueCatController],
      providers: [
        {
          provide: RevenueCatService,
          useValue: mockRevenueCatService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    controller = module.get<RevenueCatController>(RevenueCatController);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('handleWebhook', () => {
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

    const mockRequest = {
      headers: {
        'x-revenuecat-signature': 'valid-signature',
      },
    } as any;

    it('should process webhook with valid signature', async () => {
      mockRevenueCatService.verifyWebhookSignature.mockReturnValue(true);
      mockRevenueCatService.processWebhook.mockResolvedValue(undefined);

      const result = await controller.handleWebhook(
        mockRequest,
        mockWebhookData,
      );

      expect(result).toEqual({ received: true });
      expect(mockRevenueCatService.verifyWebhookSignature).toHaveBeenCalledWith(
        'valid-signature',
        JSON.stringify(mockWebhookData),
      );
      expect(mockRevenueCatService.processWebhook).toHaveBeenCalledWith(
        mockWebhookData,
      );
    });

    it('should reject webhook with invalid signature', async () => {
      mockRevenueCatService.verifyWebhookSignature.mockReturnValue(false);

      await expect(
        controller.handleWebhook(mockRequest, mockWebhookData),
      ).rejects.toThrow(UnauthorizedException);

      expect(mockLogger.warn).toHaveBeenCalledWith(
        'Invalid RevenueCat webhook signature',
        'RevenueCatController',
      );
      expect(mockRevenueCatService.processWebhook).not.toHaveBeenCalled();
    });

    it('should process webhook without signature header', async () => {
      const requestWithoutSignature = {
        headers: {},
      } as any;

      mockRevenueCatService.processWebhook.mockResolvedValue(undefined);

      const result = await controller.handleWebhook(
        requestWithoutSignature,
        mockWebhookData,
      );

      expect(result).toEqual({ received: true });
      expect(
        mockRevenueCatService.verifyWebhookSignature,
      ).not.toHaveBeenCalled();
      expect(mockRevenueCatService.processWebhook).toHaveBeenCalledWith(
        mockWebhookData,
      );
    });

    it('should reject webhook with invalid payload (no event)', async () => {
      const invalidWebhookData = {
        app_user_id: 'user-123',
        api_version: '1.0',
      } as any;

      // Signature validation will pass
      mockRevenueCatService.verifyWebhookSignature.mockReturnValue(true);

      await expect(
        controller.handleWebhook(mockRequest, invalidWebhookData),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject webhook with invalid payload (no app_user_id)', async () => {
      const invalidWebhookData = {
        event: {
          type: 'INITIAL_PURCHASE',
          id: 'event-123',
        },
        api_version: '1.0',
      } as any;

      // Signature validation will pass
      mockRevenueCatService.verifyWebhookSignature.mockReturnValue(true);

      await expect(
        controller.handleWebhook(mockRequest, invalidWebhookData),
      ).rejects.toThrow(BadRequestException);
    });

    it('should handle processing errors', async () => {
      mockRevenueCatService.verifyWebhookSignature.mockReturnValue(true);
      mockRevenueCatService.processWebhook.mockRejectedValue(
        new Error('Processing failed'),
      );

      await expect(
        controller.handleWebhook(mockRequest, mockWebhookData),
      ).rejects.toThrow(BadRequestException);

      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('getOfferings', () => {
    it('should return offerings successfully', async () => {
      const mockOfferings = {
        offerings: [
          {
            identifier: 'default',
            packages: [
              {
                identifier: 'monthly',
                platform_product_identifier: 'goldwen_plus_monthly',
              },
              {
                identifier: 'yearly',
                platform_product_identifier: 'goldwen_plus_yearly',
              },
            ],
          },
        ],
      };

      mockRevenueCatService.getOfferings.mockResolvedValue(mockOfferings);

      const result = await controller.getOfferings();

      expect(result).toEqual(mockOfferings);
      expect(mockRevenueCatService.getOfferings).toHaveBeenCalled();
    });

    it('should handle errors when getting offerings', async () => {
      mockRevenueCatService.getOfferings.mockImplementation(() => {
        throw new Error('Service error');
      });

      await expect(controller.getOfferings()).rejects.toThrow(
        BadRequestException,
      );

      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('getSubscriptionStatus', () => {
    const mockRequest = {
      user: {
        id: 'user-123',
      },
    } as any;

    it('should return subscription status for authenticated user', async () => {
      const mockStatus = {
        active: true,
        plan: SubscriptionPlan.GOLDWEN_PLUS,
        expiresAt: new Date('2024-12-31'),
        willRenew: true,
        platform: 'ios',
      };

      mockRevenueCatService.getSubscriptionStatus.mockResolvedValue(mockStatus);

      const result = await controller.getSubscriptionStatus(mockRequest);

      expect(result).toEqual(mockStatus);
      expect(mockRevenueCatService.getSubscriptionStatus).toHaveBeenCalledWith(
        'user-123',
      );
    });

    it('should return inactive status when user has no subscription', async () => {
      const mockStatus = {
        active: false,
        willRenew: false,
      };

      mockRevenueCatService.getSubscriptionStatus.mockResolvedValue(mockStatus);

      const result = await controller.getSubscriptionStatus(mockRequest);

      expect(result).toEqual(mockStatus);
    });

    it('should handle errors when getting subscription status', async () => {
      mockRevenueCatService.getSubscriptionStatus.mockRejectedValue(
        new Error('Service error'),
      );

      await expect(
        controller.getSubscriptionStatus(mockRequest),
      ).rejects.toThrow(BadRequestException);

      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('validatePurchase', () => {
    const mockRequest = {
      user: {
        id: 'user-123',
      },
    } as any;

    const mockPurchaseData = {
      productId: 'goldwen_plus_monthly',
      transactionId: 'rc_transaction_123456',
      originalTransactionId: 'original_transaction_123456',
      purchaseToken: 'purchase_token_123',
      price: 19.99,
      currency: 'EUR',
      platform: 'ios',
    };

    it('should validate purchase successfully', async () => {
      const mockResponse = {
        success: true,
        subscription: {
          id: 'sub-123',
          plan: SubscriptionPlan.GOLDWEN_PLUS,
          expiresAt: new Date('2024-12-31'),
          status: 'active',
        },
        message: 'Purchase validated and subscription activated successfully',
      };

      mockRevenueCatService.validatePurchase.mockResolvedValue(mockResponse);

      const result = await controller.validatePurchase(
        mockRequest,
        mockPurchaseData,
      );

      expect(result).toEqual(mockResponse);
      expect(mockRevenueCatService.validatePurchase).toHaveBeenCalledWith(
        'user-123',
        expect.objectContaining({
          productId: 'goldwen_plus_monthly',
          transactionId: 'rc_transaction_123456',
          price: 19.99,
          currency: 'EUR',
          platform: 'ios',
        }),
      );
    });

    it('should handle validation failure', async () => {
      const mockResponse = {
        success: false,
        message: 'Failed to validate purchase: Invalid transaction',
      };

      mockRevenueCatService.validatePurchase.mockResolvedValue(mockResponse);

      const result = await controller.validatePurchase(
        mockRequest,
        mockPurchaseData,
      );

      expect(result).toEqual(mockResponse);
      expect(result.success).toBe(false);
    });

    it('should handle errors when validating purchase', async () => {
      mockRevenueCatService.validatePurchase.mockRejectedValue(
        new Error('Service error'),
      );

      await expect(
        controller.validatePurchase(mockRequest, mockPurchaseData),
      ).rejects.toThrow(BadRequestException);

      expect(mockLogger.error).toHaveBeenCalled();
    });
  });
});
