import {
  Controller,
  Post,
  Get,
  Body,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiHeader,
} from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RevenueCatService } from './revenuecat.service';
import { RevenueCatWebhookDto, PurchaseDto } from './dto/subscription.dto';
import { CustomLoggerService } from '../../common/logger';

@Controller()
export class RevenueCatController {
  constructor(
    private readonly revenueCatService: RevenueCatService,
    private readonly logger: CustomLoggerService,
  ) {}

  /**
   * RevenueCat webhook endpoint
   * Handles subscription events from RevenueCat
   * Secured with signature verification
   */
  @Post('webhooks/revenuecat')
  @HttpCode(HttpStatus.OK)
  @ApiTags('webhooks')
  @ApiOperation({
    summary: 'Handle RevenueCat webhook events',
    description:
      'Receives and processes subscription events from RevenueCat (INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, BILLING_ISSUE)',
  })
  @ApiHeader({
    name: 'X-RevenueCat-Signature',
    description: 'HMAC signature for webhook verification',
    required: false,
  })
  @ApiResponse({
    status: 200,
    description: 'Webhook processed successfully',
    schema: {
      type: 'object',
      properties: {
        received: { type: 'boolean', example: true },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Invalid webhook signature',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid webhook payload',
  })
  async handleWebhook(
    @Req() req: Request,
    @Body() webhookData: RevenueCatWebhookDto,
  ): Promise<{ received: boolean }> {
    try {
      // Get the signature from headers
      const signature = req.headers['x-revenuecat-signature'] as string;

      // Get raw body for signature verification
      const rawBody = JSON.stringify(webhookData);

      // Verify webhook signature
      if (signature) {
        const isValid = this.revenueCatService.verifyWebhookSignature(
          signature,
          rawBody,
        );

        if (!isValid) {
          this.logger.warn(
            'Invalid RevenueCat webhook signature',
            'RevenueCatController',
          );
          throw new UnauthorizedException('Invalid webhook signature');
        }
      }

      // Validate webhook data
      if (!webhookData.event || !webhookData.app_user_id) {
        throw new BadRequestException('Invalid webhook payload');
      }

      // Process the webhook
      await this.revenueCatService.processWebhook(webhookData);

      return { received: true };
    } catch (error) {
      this.logger.error(
        `RevenueCat webhook processing error: ${(error as Error).message}`,
        (error as Error).stack,
        'RevenueCatController',
      );

      // Re-throw HTTP exceptions
      if (
        error instanceof UnauthorizedException ||
        error instanceof BadRequestException
      ) {
        throw error;
      }

      // For other errors, return 400
      throw new BadRequestException('Failed to process webhook');
    }
  }

  /**
   * Get available subscription offerings
   */
  @Get('subscriptions/offerings')
  @ApiTags('subscriptions')
  @ApiOperation({
    summary: 'Get available subscription offerings',
    description: 'Returns all available subscription plans and packages',
  })
  @ApiResponse({
    status: 200,
    description: 'Offerings retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        offerings: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              identifier: { type: 'string', example: 'default' },
              packages: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    identifier: { type: 'string', example: 'monthly' },
                    platform_product_identifier: {
                      type: 'string',
                      example: 'goldwen_plus_monthly',
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  })
  async getOfferings(): Promise<{
    offerings: Array<{
      identifier: string;
      packages: Array<{
        identifier: string;
        platform_product_identifier: string;
      }>;
    }>;
  }> {
    try {
      const result = this.revenueCatService.getOfferings();
      return Promise.resolve(result);
    } catch (error) {
      this.logger.error(
        `Error getting offerings: ${(error as Error).message}`,
        (error as Error).stack,
        'RevenueCatController',
      );
      throw new BadRequestException('Failed to retrieve offerings');
    }
  }

  /**
   * Get current subscription status for authenticated user
   */
  @Get('subscriptions/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiTags('subscriptions')
  @ApiOperation({
    summary: 'Get subscription status',
    description:
      'Returns the current subscription status for the authenticated user',
  })
  @ApiResponse({
    status: 200,
    description: 'Subscription status retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        active: { type: 'boolean', example: true },
        plan: { type: 'string', example: 'goldwen_plus' },
        expiresAt: {
          type: 'string',
          format: 'date-time',
          example: '2024-12-31T23:59:59Z',
        },
        willRenew: { type: 'boolean', example: true },
        platform: { type: 'string', example: 'ios' },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async getSubscriptionStatus(@Req() req: any): Promise<{
    active: boolean;
    plan?: string;
    expiresAt?: Date;
    willRenew: boolean;
    platform?: string;
  }> {
    try {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
      const userId = req.user.id;
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      return await this.revenueCatService.getSubscriptionStatus(userId);
    } catch (error) {
      this.logger.error(
        `Error getting subscription status: ${(error as Error).message}`,
        (error as Error).stack,
        'RevenueCatController',
      );
      throw new BadRequestException('Failed to retrieve subscription status');
    }
  }

  /**
   * Validate and process a purchase
   */
  @Post('subscriptions/purchase')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiTags('subscriptions')
  @ApiOperation({
    summary: 'Validate a purchase',
    description:
      'Validates a client-side purchase and activates the subscription',
  })
  @ApiResponse({
    status: 200,
    description: 'Purchase validated successfully',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        subscription: {
          type: 'object',
          properties: {
            id: { type: 'string', example: 'sub_123' },
            plan: { type: 'string', example: 'goldwen_plus' },
            expiresAt: {
              type: 'string',
              format: 'date-time',
              example: '2024-12-31T23:59:59Z',
            },
            status: { type: 'string', example: 'active' },
          },
        },
        message: {
          type: 'string',
          example: 'Purchase validated and subscription activated successfully',
        },
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid purchase data',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async validatePurchase(
    @Req() req: any,
    @Body() purchaseData: PurchaseDto,
  ): Promise<{
    success: boolean;
    subscription?: any;
    message: string;
  }> {
    try {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
      const userId = req.user.id;

      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      return await this.revenueCatService.validatePurchase(userId, {
        productId: purchaseData.productId,
        transactionId: purchaseData.transactionId,
        originalTransactionId: purchaseData.originalTransactionId,
        purchaseToken: purchaseData.purchaseToken,
        price: purchaseData.price,
        currency: purchaseData.currency,
        platform: purchaseData.platform,
      });
    } catch (error) {
      this.logger.error(
        `Error validating purchase: ${(error as Error).message}`,
        (error as Error).stack,
        'RevenueCatController',
      );

      // Re-throw HTTP exceptions
      if (error instanceof BadRequestException) {
        throw error;
      }

      throw new BadRequestException('Failed to validate purchase');
    }
  }
}
