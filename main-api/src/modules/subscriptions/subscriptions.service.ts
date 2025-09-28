import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan, Not } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';

import { Subscription } from '../../database/entities/subscription.entity';
import { User } from '../../database/entities/user.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { SubscriptionStatus, SubscriptionPlan } from '../../common/enums';
import { CustomLoggerService } from '../../common/logger';

import {
  CreateSubscriptionDto,
  UpdateSubscriptionDto,
  RevenueCatWebhookDto,
} from './dto/subscription.dto';

@Injectable()
export class SubscriptionsService {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(DailySelection)
    private dailySelectionRepository: Repository<DailySelection>,
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {}

  // Check and expire subscriptions daily
  @Cron(CronExpression.EVERY_DAY_AT_1AM)
  async handleExpiredSubscriptions() {
    const now = new Date();

    const expiredSubscriptions = await this.subscriptionRepository.find({
      where: {
        status: SubscriptionStatus.ACTIVE,
        expiresAt: LessThan(now),
      },
    });

    for (const subscription of expiredSubscriptions) {
      subscription.status = SubscriptionStatus.EXPIRED;
      await this.subscriptionRepository.save(subscription);
    }
  }

  async createSubscription(
    userId: string,
    createSubscriptionDto: CreateSubscriptionDto,
  ): Promise<Subscription> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if user already has an active subscription
    const existingSubscription = await this.getActiveSubscription(userId);
    if (
      existingSubscription &&
      createSubscriptionDto.plan === existingSubscription.plan
    ) {
      throw new BadRequestException(
        'User already has an active subscription of this type',
      );
    }

    const subscription = this.subscriptionRepository.create({
      userId,
      plan: createSubscriptionDto.plan,
      status: SubscriptionStatus.PENDING,
      startDate: new Date(),
      expiresAt: this.calculateExpirationDate(createSubscriptionDto.plan),
      revenueCatCustomerId: createSubscriptionDto.revenueCatCustomerId,
      revenueCatSubscriptionId: createSubscriptionDto.revenueCatSubscriptionId,
      originalTransactionId: createSubscriptionDto.originalTransactionId,
      price: createSubscriptionDto.price,
      currency: createSubscriptionDto.currency,
      purchaseToken: createSubscriptionDto.purchaseToken,
      platform: createSubscriptionDto.platform,
      metadata: createSubscriptionDto.metadata,
    });

    return this.subscriptionRepository.save(subscription);
  }

  async getActiveSubscription(userId: string): Promise<Subscription | null> {
    return this.subscriptionRepository.findOne({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
      },
      order: { createdAt: 'DESC' },
    });
  }

  async getUserSubscriptions(userId: string): Promise<Subscription[]> {
    return this.subscriptionRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async activateSubscription(subscriptionId: string): Promise<Subscription> {
    const subscription = await this.subscriptionRepository.findOne({
      where: { id: subscriptionId },
    });

    if (!subscription) {
      throw new NotFoundException('Subscription not found');
    }

    subscription.status = SubscriptionStatus.ACTIVE;
    subscription.startDate = new Date();

    // Cancel any other active subscriptions for this user
    await this.subscriptionRepository.update(
      {
        userId: subscription.userId,
        status: SubscriptionStatus.ACTIVE,
        id: Not(subscriptionId),
      },
      {
        status: SubscriptionStatus.CANCELLED,
        cancelledAt: new Date(),
      },
    );

    return this.subscriptionRepository.save(subscription);
  }

  async cancelSubscription(
    subscriptionId: string,
    userId?: string,
  ): Promise<Subscription> {
    const where: any = { id: subscriptionId };
    if (userId) {
      where.userId = userId;
    }

    const subscription = await this.subscriptionRepository.findOne({ where });

    if (!subscription) {
      throw new NotFoundException('Subscription not found');
    }

    if (subscription.status === SubscriptionStatus.CANCELLED) {
      throw new BadRequestException('Subscription is already cancelled');
    }

    subscription.status = SubscriptionStatus.CANCELLED;
    subscription.cancelledAt = new Date();

    return this.subscriptionRepository.save(subscription);
  }

  async updateSubscription(
    subscriptionId: string,
    updateSubscriptionDto: UpdateSubscriptionDto,
  ): Promise<Subscription> {
    const subscription = await this.subscriptionRepository.findOne({
      where: { id: subscriptionId },
    });

    if (!subscription) {
      throw new NotFoundException('Subscription not found');
    }

    Object.assign(subscription, updateSubscriptionDto);
    return this.subscriptionRepository.save(subscription);
  }

  // RevenueCat webhook handler
  async handleRevenueCatWebhook(
    webhookData: RevenueCatWebhookDto,
  ): Promise<void> {
    const { event, app_user_id: userId } = webhookData;

    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      this.logger.error(
        `User not found for RevenueCat webhook: ${userId}`,
        '',
        'SubscriptionsService',
      );
      return;
    }

    switch (event.type) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
        await this.handlePurchaseOrRenewal(webhookData);
        break;
      case 'CANCELLATION':
        await this.handleCancellation(webhookData);
        break;
      case 'EXPIRATION':
        await this.handleExpiration(webhookData);
        break;
      case 'BILLING_ISSUE':
        await this.handleBillingIssue(webhookData);
        break;
      default:
        this.logger.info(`Unhandled RevenueCat event type: ${event.type}`, {
          eventType: event.type,
          userId,
        });
    }
  }

  private async handlePurchaseOrRenewal(
    webhookData: RevenueCatWebhookDto,
  ): Promise<void> {
    const { app_user_id: userId, event } = webhookData;
    const {
      product_id,
      price_in_purchased_currency,
      purchased_at,
      expiration_at,
    } = event;

    if (!product_id || !purchased_at || !expiration_at) {
      this.logger.error(
        'Missing required fields in webhook data',
        '',
        'SubscriptionsService',
      );
      return;
    }

    // Determine subscription plan from product ID
    const plan = this.getSubscriptionPlanFromProductId(product_id);

    // Find existing subscription or create new one
    let subscription = await this.subscriptionRepository.findOne({
      where: {
        userId,
        revenueCatSubscriptionId: event.id,
      },
    });

    if (!subscription) {
      subscription = this.subscriptionRepository.create({
        userId,
        plan,
        revenueCatSubscriptionId: event.id,
        originalTransactionId: event.original_transaction_id,
        platform: event.store === 'app_store' ? 'ios' : 'android',
      });
    }

    subscription.status = SubscriptionStatus.ACTIVE;
    subscription.startDate = new Date(purchased_at);
    subscription.expiresAt = new Date(expiration_at);
    subscription.price = price_in_purchased_currency || 0;
    subscription.currency = event.currency || 'USD';

    await this.subscriptionRepository.save(subscription);
  }

  private async handleCancellation(
    webhookData: RevenueCatWebhookDto,
  ): Promise<void> {
    const { app_user_id: userId, event } = webhookData;

    const subscription = await this.subscriptionRepository.findOne({
      where: {
        userId,
        revenueCatSubscriptionId: event.id,
      },
    });

    if (subscription) {
      subscription.status = SubscriptionStatus.CANCELLED;
      subscription.cancelledAt = new Date();
      await this.subscriptionRepository.save(subscription);
    }
  }

  private async handleExpiration(
    webhookData: RevenueCatWebhookDto,
  ): Promise<void> {
    const { app_user_id: userId, event } = webhookData;

    const subscription = await this.subscriptionRepository.findOne({
      where: {
        userId,
        revenueCatSubscriptionId: event.id,
      },
    });

    if (subscription) {
      subscription.status = SubscriptionStatus.EXPIRED;
      await this.subscriptionRepository.save(subscription);
    }
  }

  private async handleBillingIssue(
    webhookData: RevenueCatWebhookDto,
  ): Promise<void> {
    // Handle billing issues - could notify user, pause features, etc.
    this.logger.logBusinessEvent('billing_issue_detected', {
      userId: webhookData.app_user_id,
      eventType: webhookData.event.type,
    });

    // Additional billing issue handling could be added here
    return Promise.resolve();
  }

  private getSubscriptionPlanFromProductId(
    productId: string,
  ): SubscriptionPlan {
    // Map RevenueCat product IDs to our subscription plans
    const productMap: Record<string, SubscriptionPlan> = {
      goldwen_plus_monthly: SubscriptionPlan.GOLDWEN_PLUS,
      goldwen_plus_yearly: SubscriptionPlan.GOLDWEN_PLUS,
      goldwen_plus_quarterly: SubscriptionPlan.GOLDWEN_PLUS,
    };

    return productMap[productId] || SubscriptionPlan.FREE;
  }

  private calculateExpirationDate(plan: SubscriptionPlan): Date {
    const now = new Date();

    switch (plan) {
      case SubscriptionPlan.GOLDWEN_PLUS:
        // Default to monthly, this would be refined based on actual product ID
        return new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); // 30 days
      default:
        // Free plan never expires
        return new Date(now.getTime() + 100 * 365 * 24 * 60 * 60 * 1000); // 100 years
    }
  }

  async getSubscriptionFeatures(userId: string): Promise<{
    isActive: boolean;
    plan: SubscriptionPlan;
    maxDailyChoices: number;
    hasExtendChatFeature: boolean;
    hasPrioritySupport: boolean;
    expiresAt?: Date;
  }> {
    const subscription = await this.getActiveSubscription(userId);

    if (!subscription || !subscription.isActive) {
      return {
        isActive: false,
        plan: SubscriptionPlan.FREE,
        maxDailyChoices: 1,
        hasExtendChatFeature: false,
        hasPrioritySupport: false,
      };
    }

    return {
      isActive: true,
      plan: subscription.plan,
      maxDailyChoices:
        subscription.plan === SubscriptionPlan.GOLDWEN_PLUS ? 3 : 1,
      hasExtendChatFeature: subscription.plan === SubscriptionPlan.GOLDWEN_PLUS,
      hasPrioritySupport: subscription.plan === SubscriptionPlan.GOLDWEN_PLUS,
      expiresAt: subscription.expiresAt,
    };
  }

  async getSubscriptionStats(): Promise<{
    totalSubscriptions: number;
    activeSubscriptions: number;
    cancelledSubscriptions: number;
    expiredSubscriptions: number;
    revenue: number;
  }> {
    const [
      totalSubscriptions,
      activeSubscriptions,
      cancelledSubscriptions,
      expiredSubscriptions,
    ] = await Promise.all([
      this.subscriptionRepository.count(),
      this.subscriptionRepository.count({
        where: { status: SubscriptionStatus.ACTIVE },
      }),
      this.subscriptionRepository.count({
        where: { status: SubscriptionStatus.CANCELLED },
      }),
      this.subscriptionRepository.count({
        where: { status: SubscriptionStatus.EXPIRED },
      }),
    ]);

    // Calculate total revenue (this would be more complex in production)
    const subscriptionsWithRevenue = await this.subscriptionRepository.find({
      where: { status: SubscriptionStatus.ACTIVE },
    });

    const revenue = subscriptionsWithRevenue.reduce((total, sub) => {
      return total + (sub.price || 0);
    }, 0);

    return {
      totalSubscriptions,
      activeSubscriptions,
      cancelledSubscriptions,
      expiredSubscriptions,
      revenue,
    };
  }

  // Get available subscription plans
  getPlans(): {
    plans: Array<{
      id: string;
      name: string;
      price: number;
      currency: string;
      duration: string;
      features: string[];
    }>;
  } {
    // Based on specifications.md, we return the GoldWen Plus plans
    const plans = [
      {
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
      },
      {
        id: 'goldwen_plus_quarterly',
        name: 'GoldWen Plus',
        price: 49.99,
        currency: 'EUR',
        duration: 'quarterly',
        features: [
          '3 sélections par jour',
          'Chat illimité',
          'Voir qui vous a sélectionné',
          'Profil prioritaire',
        ],
      },
      {
        id: 'goldwen_plus_yearly',
        name: 'GoldWen Plus',
        price: 179.99,
        currency: 'EUR',
        duration: 'yearly',
        features: [
          '3 sélections par jour',
          'Chat illimité',
          'Voir qui vous a sélectionné',
          'Profil prioritaire',
        ],
      },
    ];

    return { plans };
  }

  // Get subscription usage for a user
  async getUsage(userId: string): Promise<{
    dailyChoices: {
      limit: number;
      used: number;
      remaining: number;
      resetTime: string;
    };
    subscription: {
      tier: 'free' | 'premium';
      isActive: boolean;
    };
  }> {
    const subscription = await this.getActiveSubscription(userId);
    const isPremium =
      subscription &&
      subscription.isActive &&
      subscription.plan === SubscriptionPlan.GOLDWEN_PLUS;

    // Get today's daily selection to check actual usage
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dailySelection = await this.dailySelectionRepository.findOne({
      where: {
        userId,
        selectionDate: today,
      },
    });

    const limit = isPremium ? 3 : 1;
    const used = dailySelection ? dailySelection.choicesUsed : 0;
    const remaining = Math.max(0, limit - used);

    // Calculate reset time (next day at noon)
    const resetTime = new Date();
    resetTime.setDate(resetTime.getDate() + 1);
    resetTime.setHours(12, 0, 0, 0);

    return {
      dailyChoices: {
        limit,
        used,
        remaining,
        resetTime: resetTime.toISOString(),
      },
      subscription: {
        tier: isPremium ? 'premium' : 'free',
        isActive: subscription ? subscription.isActive : false,
      },
    };
  }

  // Restore subscriptions from app stores
  async restoreSubscriptions(userId: string): Promise<{
    restored: boolean;
    subscriptions: Subscription[];
  }> {
    // This would integrate with RevenueCat or direct app store APIs
    // For now, we'll return the existing active subscriptions
    const subscriptions = await this.subscriptionRepository.find({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
      },
    });

    return {
      restored: true,
      subscriptions,
    };
  }

  // Cancel user's current subscription (simpler version for user-initiated cancellation)
  async cancelUserSubscription(
    userId: string,
    reason?: string,
  ): Promise<Subscription> {
    const activeSubscription = await this.getActiveSubscription(userId);

    if (!activeSubscription) {
      throw new NotFoundException('No active subscription found');
    }

    activeSubscription.status = SubscriptionStatus.CANCELLED;
    activeSubscription.cancelledAt = new Date();

    // Store cancellation reason in metadata
    if (reason) {
      activeSubscription.metadata = {
        ...activeSubscription.metadata,
        cancellationReason: reason,
        cancelledBy: 'user',
      };
    }

    return this.subscriptionRepository.save(activeSubscription);
  }

  // Get user subscription tier for use in other services
  async getUserSubscriptionTier(userId: string): Promise<{
    tier: SubscriptionPlan;
    isActive: boolean;
    features: {
      maxDailyChoices: number;
      hasExtendChatFeature: boolean;
      hasPrioritySupport: boolean;
      canSeeWhoLiked: boolean;
    };
  }> {
    const subscription = await this.getActiveSubscription(userId);
    const isActive = subscription?.isActive || false;
    const tier =
      isActive && subscription ? subscription.plan : SubscriptionPlan.FREE;

    return {
      tier,
      isActive,
      features: {
        maxDailyChoices: tier === SubscriptionPlan.GOLDWEN_PLUS ? 3 : 1,
        hasExtendChatFeature: tier === SubscriptionPlan.GOLDWEN_PLUS,
        hasPrioritySupport: tier === SubscriptionPlan.GOLDWEN_PLUS,
        canSeeWhoLiked: tier === SubscriptionPlan.GOLDWEN_PLUS,
      },
    };
  }

  // Helper method to check if user is premium (for use in other services)
  async isUserPremium(userId: string): Promise<boolean> {
    const subscription = await this.getActiveSubscription(userId);
    return Boolean(
      subscription?.isActive &&
        subscription.plan === SubscriptionPlan.GOLDWEN_PLUS,
    );
  }
}
