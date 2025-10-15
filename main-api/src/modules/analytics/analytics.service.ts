import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Mixpanel from 'mixpanel';
import { GdprService } from '../gdpr/gdpr.service';

export interface AnalyticsEvent {
  name: string;
  userId?: string;
  properties?: Record<string, any>;
  timestamp?: Date;
}

export interface OnboardingEvent {
  step:
    | 'registration'
    | 'profile_creation'
    | 'questionnaire'
    | 'photos_upload'
    | 'completed';
  method?: 'google' | 'apple' | 'email';
  metadata?: Record<string, any>;
}

export interface MatchingEvent {
  action:
    | 'daily_selection_viewed'
    | 'profile_chosen'
    | 'match_created'
    | 'match_expired';
  matchId?: string;
  compatibilityScore?: number;
  metadata?: Record<string, any>;
}

export interface ChatEvent {
  action: 'conversation_started' | 'message_sent' | 'conversation_expired';
  conversationId?: string;
  metadata?: Record<string, any>;
}

export interface SubscriptionEvent {
  action:
    | 'subscription_started'
    | 'subscription_renewed'
    | 'subscription_cancelled'
    | 'subscription_upgraded';
  plan?: string;
  price?: number;
  currency?: string;
  metadata?: Record<string, any>;
}

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);
  private mixpanel: Mixpanel.Mixpanel | null = null;
  private enabled: boolean;

  constructor(
    private readonly configService: ConfigService,
    private readonly gdprService: GdprService,
  ) {
    const token = this.configService.get<string>('analytics.mixpanel.token');
    this.enabled =
      this.configService.get<boolean>('analytics.mixpanel.enabled') || false;

    if (!token || !this.enabled) {
      this.logger.warn('Mixpanel analytics not configured or disabled');
      return;
    }

    try {
      this.mixpanel = Mixpanel.init(token);
      this.logger.log('Mixpanel analytics service initialized');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.stack : String(error);
      this.logger.error('Failed to initialize Mixpanel', errorMessage);
      this.enabled = false;
    }
  }

  /**
   * Check if user has opted out of analytics via GDPR consent
   */
  private async hasAnalyticsConsent(userId: string): Promise<boolean> {
    try {
      const consent = await this.gdprService.getCurrentConsent(userId);

      // If no consent record exists, default to opt-out (GDPR compliant)
      if (!consent) {
        return false;
      }

      // Check if analytics consent is explicitly given
      return consent.analytics === true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.stack : String(error);
      this.logger.error(
        `Failed to check analytics consent for user ${userId}`,
        errorMessage,
      );
      // On error, default to opt-out for GDPR compliance
      return false;
    }
  }

  /**
   * Track a generic event
   */
  async trackEvent(event: AnalyticsEvent): Promise<void> {
    if (!this.enabled || !this.mixpanel) {
      this.logger.debug('Analytics disabled, skipping event tracking');
      return;
    }

    try {
      // Check GDPR consent if userId is provided
      if (event.userId) {
        const hasConsent = await this.hasAnalyticsConsent(event.userId);
        if (!hasConsent) {
          this.logger.debug(`User ${event.userId} has opted out of analytics`);
          return;
        }
      }

      const properties: Record<string, unknown> = {
        ...event.properties,
        timestamp: event.timestamp || new Date(),
        environment: this.configService.get('app.environment'),
      };

      if (event.userId) {
        this.mixpanel.track(event.name, {
          distinct_id: event.userId,
          ...properties,
        });
      } else {
        this.mixpanel.track(event.name, properties);
      }

      this.logger.debug(`Event tracked: ${event.name}`, {
        userId: event.userId,
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.stack : String(error);
      this.logger.error(`Failed to track event: ${event.name}`, errorMessage);
    }
  }

  /**
   * Identify a user in Mixpanel
   */
  async identifyUser(
    userId: string,
    userProperties?: Record<string, unknown>,
  ): Promise<void> {
    if (!this.enabled || !this.mixpanel) {
      return;
    }

    try {
      const hasConsent = await this.hasAnalyticsConsent(userId);
      if (!hasConsent) {
        return;
      }

      this.mixpanel.people.set(userId, {
        $name: userProperties?.name,
        $email: userProperties?.email,
        ...userProperties,
        last_seen: new Date(),
      });

      this.logger.debug(`User identified: ${userId}`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.stack : String(error);
      this.logger.error(`Failed to identify user: ${userId}`, errorMessage);
    }
  }

  /**
   * Track onboarding events
   */
  async trackOnboarding(userId: string, event: OnboardingEvent): Promise<void> {
    await this.trackEvent({
      name: `onboarding_${event.step}`,
      userId,
      properties: {
        step: event.step,
        method: event.method,
        ...event.metadata,
      },
    });
  }

  /**
   * Track matching events
   */
  async trackMatching(userId: string, event: MatchingEvent): Promise<void> {
    await this.trackEvent({
      name: `matching_${event.action}`,
      userId,
      properties: {
        action: event.action,
        matchId: event.matchId,
        compatibilityScore: event.compatibilityScore,
        ...event.metadata,
      },
    });
  }

  /**
   * Track chat/messaging events
   */
  async trackChat(userId: string, event: ChatEvent): Promise<void> {
    await this.trackEvent({
      name: `chat_${event.action}`,
      userId,
      properties: {
        action: event.action,
        conversationId: event.conversationId,
        ...event.metadata,
      },
    });
  }

  /**
   * Track subscription events
   */
  async trackSubscription(
    userId: string,
    event: SubscriptionEvent,
  ): Promise<void> {
    await this.trackEvent({
      name: `subscription_${event.action}`,
      userId,
      properties: {
        action: event.action,
        plan: event.plan,
        price: event.price,
        currency: event.currency,
        ...event.metadata,
      },
    });

    // Also update user profile with subscription status
    if (
      event.action === 'subscription_started' ||
      event.action === 'subscription_renewed'
    ) {
      await this.identifyUser(userId, {
        subscription_plan: event.plan,
        is_subscriber: true,
      });
    } else if (event.action === 'subscription_cancelled') {
      await this.identifyUser(userId, {
        is_subscriber: false,
      });
    }
  }

  /**
   * Opt user out of analytics (GDPR)
   */
  async optOut(userId: string): Promise<void> {
    if (!this.enabled || !this.mixpanel) {
      return;
    }

    try {
      // Mixpanel opt-out
      this.mixpanel.people.delete_user(userId);
      this.logger.log(`User ${userId} opted out of analytics`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.stack : String(error);
      this.logger.error(`Failed to opt out user ${userId}`, errorMessage);
    }
  }

  /**
   * Delete all analytics data for a user (GDPR - Right to be Forgotten)
   */
  async deleteUserData(userId: string): Promise<void> {
    if (!this.enabled || !this.mixpanel) {
      return;
    }

    try {
      // Delete user profile and all associated data in Mixpanel
      this.mixpanel.people.delete_user(userId);
      this.logger.log(`Analytics data deleted for user ${userId}`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.stack : String(error);
      this.logger.error(
        `Failed to delete analytics data for user ${userId}`,
        errorMessage,
      );
    }
  }
}
