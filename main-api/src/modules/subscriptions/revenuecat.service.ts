import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CustomLoggerService } from '../../common/logger';
import { SubscriptionsService } from './subscriptions.service';
import { RevenueCatWebhookDto } from './dto/subscription.dto';
import { SubscriptionStatus, SubscriptionPlan } from '../../common/enums';
import * as crypto from 'crypto';

@Injectable()
export class RevenueCatService {
  private readonly webhookSecret: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly subscriptionsService: SubscriptionsService,
    private readonly logger: CustomLoggerService,
  ) {
    this.webhookSecret =
      this.configService.get<string>('revenueCat.webhookSecret') || '';
  }

  /**
   * Verify RevenueCat webhook signature
   * @param signature The signature from the X-RevenueCat-Signature header
   * @param rawBody The raw request body
   * @returns True if signature is valid
   */
  verifyWebhookSignature(signature: string, rawBody: string): boolean {
    if (!this.webhookSecret) {
      this.logger.warn(
        'RevenueCat webhook secret not configured',
        'RevenueCatService',
      );
      // In development, allow webhooks without signature verification
      if (this.configService.get('app.environment') === 'development') {
        return true;
      }
      return false;
    }

    try {
      const hmac = crypto.createHmac('sha256', this.webhookSecret);
      hmac.update(rawBody);
      const expectedSignature = hmac.digest('hex');

      return crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(expectedSignature),
      );
    } catch (error) {
      this.logger.error(
        'Error verifying webhook signature',
        (error as Error).stack,
        'RevenueCatService',
      );
      return false;
    }
  }

  /**
   * Process RevenueCat webhook event
   * @param webhookData The webhook payload
   */
  async processWebhook(webhookData: RevenueCatWebhookDto): Promise<void> {
    const { event, app_user_id: userId } = webhookData;

    this.logger.info('Processing RevenueCat webhook', {
      eventType: event.type,
      userId,
      eventId: event.id,
    });

    try {
      await this.subscriptionsService.handleRevenueCatWebhook(webhookData);

      this.logger.logBusinessEvent('revenuecat_webhook_processed', {
        eventType: event.type,
        userId,
        eventId: event.id,
      });
    } catch (error) {
      this.logger.error(
        `Error processing RevenueCat webhook: ${(error as Error).message}`,
        (error as Error).stack,
        'RevenueCatService',
      );
      throw error;
    }
  }

  /**
   * Get available subscription offerings
   * Returns the available subscription plans that can be purchased
   */
  getOfferings(): {
    offerings: Array<{
      identifier: string;
      packages: Array<{
        identifier: string;
        platform_product_identifier: string;
      }>;
    }>;
  } {
    // Get the plans from subscriptions service
    const { plans } = this.subscriptionsService.getPlans();

    // Transform to RevenueCat offerings format
    const offerings = [
      {
        identifier: 'default',
        packages: plans.map((plan) => ({
          identifier: plan.duration,
          platform_product_identifier: plan.id,
        })),
      },
    ];

    this.logger.info('Retrieved RevenueCat offerings', {
      offeringsCount: offerings.length,
      packagesCount: offerings[0].packages.length,
    });

    return { offerings };
  }

  /**
   * Get subscription status for a user
   * @param userId The user ID
   */
  async getSubscriptionStatus(userId: string): Promise<{
    active: boolean;
    plan?: string;
    expiresAt?: Date;
    willRenew: boolean;
    platform?: string;
  }> {
    try {
      const subscription =
        await this.subscriptionsService.getActiveSubscription(userId);

      if (!subscription) {
        return {
          active: false,
          willRenew: false,
        };
      }

      const willRenew =
        subscription.status === SubscriptionStatus.ACTIVE &&
        subscription.cancelledAt === null;

      this.logger.info('Retrieved subscription status', {
        userId,
        active: subscription.isActive,
        plan: subscription.plan,
      });

      return {
        active: subscription.isActive,
        plan: subscription.plan,
        expiresAt: subscription.expiresAt,
        willRenew,
        platform: subscription.platform,
      };
    } catch (error) {
      this.logger.error(
        `Error getting subscription status: ${(error as Error).message}`,
        (error as Error).stack,
        'RevenueCatService',
      );
      throw error;
    }
  }

  /**
   * Validate and process a purchase from the client
   * @param userId The user ID
   * @param purchaseData The purchase data from the client
   */
  async validatePurchase(
    userId: string,
    purchaseData: {
      productId: string;
      transactionId: string;
      originalTransactionId?: string;
      purchaseToken?: string;
      price?: number;
      currency?: string;
      platform?: string;
    },
  ): Promise<{
    success: boolean;
    subscription?: any;
    message: string;
  }> {
    try {
      this.logger.info('Validating purchase', {
        userId,
        productId: purchaseData.productId,
        platform: purchaseData.platform,
      });

      // In a real implementation, you would verify the purchase with RevenueCat API or App Store/Play Store
      // For now, we'll create/update the subscription based on the provided data
      const plan = purchaseData.productId.includes('goldwen_plus')
        ? SubscriptionPlan.GOLDWEN_PLUS
        : SubscriptionPlan.FREE;

      const subscription = await this.subscriptionsService.createSubscription(
        userId,
        {
          plan,
          revenueCatSubscriptionId: purchaseData.transactionId,
          originalTransactionId: purchaseData.originalTransactionId,
          purchaseToken: purchaseData.purchaseToken,
          price: purchaseData.price,
          currency: purchaseData.currency,
          platform: purchaseData.platform,
        },
      );

      // Activate the subscription
      await this.subscriptionsService.activateSubscription(subscription.id);

      this.logger.logBusinessEvent('purchase_validated', {
        userId,
        productId: purchaseData.productId,
        subscriptionId: subscription.id,
      });

      return {
        success: true,
        subscription: {
          id: subscription.id,
          plan: subscription.plan,
          expiresAt: subscription.expiresAt,
          status: subscription.status,
        },
        message: 'Purchase validated and subscription activated successfully',
      };
    } catch (error) {
      this.logger.error(
        `Error validating purchase: ${(error as Error).message}`,
        (error as Error).stack,
        'RevenueCatService',
      );

      return {
        success: false,
        message: `Failed to validate purchase: ${(error as Error).message}`,
      };
    }
  }
}
