# Analytics Module - Integration Examples

This document provides detailed examples of how to integrate the Analytics Module into existing GoldWen modules.

## Table of Contents

1. [Auth Module Integration](#auth-module-integration)
2. [Users Module Integration](#users-module-integration)
3. [Matching Module Integration](#matching-module-integration)
4. [Chat Module Integration](#chat-module-integration)
5. [Subscriptions Module Integration](#subscriptions-module-integration)
6. [GDPR Module Integration](#gdpr-module-integration)

---

## Auth Module Integration

Track user registration and authentication events.

### auth.service.ts

```typescript
import { Injectable } from '@nestjs/common';
import { AnalyticsService } from '../analytics';

@Injectable()
export class AuthService {
  constructor(
    // ... other dependencies
    private readonly analyticsService: AnalyticsService,
  ) {}

  async registerWithGoogle(googleToken: string) {
    // Registration logic
    const user = await this.createUser(userData);

    // Track registration
    await this.analyticsService.trackOnboarding(user.id, {
      step: 'registration',
      method: 'google',
    });

    return user;
  }

  async registerWithApple(appleToken: string) {
    // Registration logic
    const user = await this.createUser(userData);

    // Track registration
    await this.analyticsService.trackOnboarding(user.id, {
      step: 'registration',
      method: 'apple',
    });

    return user;
  }

  async login(userId: string) {
    // Login logic
    const token = await this.generateToken(userId);

    // Track login event
    await this.analyticsService.trackEvent({
      name: 'user_login',
      userId,
      properties: {
        timestamp: new Date(),
      },
    });

    return token;
  }
}
```

### auth.module.ts

```typescript
import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { AnalyticsModule } from '../analytics';

@Module({
  imports: [
    // ... other imports
    AnalyticsModule,
  ],
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}
```

---

## Users Module Integration

Track user profile creation and updates.

### users.service.ts

```typescript
import { Injectable } from '@nestjs/common';
import { AnalyticsService } from '../analytics';

@Injectable()
export class UsersService {
  constructor(
    // ... other dependencies
    private readonly analyticsService: AnalyticsService,
  ) {}

  async createProfile(userId: string, profileData: CreateProfileDto) {
    // Create profile logic
    const profile = await this.profileRepository.save(newProfile);

    // Track profile creation
    await this.analyticsService.trackOnboarding(userId, {
      step: 'profile_creation',
      metadata: {
        hasPhotos: profileData.photos?.length > 0,
        hasPrompts: profileData.prompts?.length > 0,
      },
    });

    // Identify user with profile data
    await this.analyticsService.identifyUser(userId, {
      age: profileData.age,
      gender: profileData.gender,
      city: profileData.city,
      profileComplete: true,
    });

    return profile;
  }

  async completeQuestionnaire(userId: string, answers: any) {
    // Save questionnaire answers
    await this.questionnaireRepository.save(answers);

    // Track questionnaire completion
    await this.analyticsService.trackOnboarding(userId, {
      step: 'questionnaire',
      metadata: {
        questionsAnswered: Object.keys(answers).length,
      },
    });

    return { success: true };
  }

  async uploadPhotos(userId: string, photos: any[]) {
    // Upload photos logic
    await this.photoRepository.save(photos);

    // Track photo upload
    await this.analyticsService.trackOnboarding(userId, {
      step: 'photos_upload',
      metadata: {
        photosCount: photos.length,
      },
    });

    return { success: true };
  }

  async completeOnboarding(userId: string) {
    // Mark onboarding as complete
    await this.userRepository.update(userId, { onboardingCompleted: true });

    // Track onboarding completion
    await this.analyticsService.trackOnboarding(userId, {
      step: 'completed',
    });

    return { success: true };
  }
}
```

---

## Matching Module Integration

Track matching algorithm events and user interactions.

### matching.service.ts

```typescript
import { Injectable } from '@nestjs/common';
import { AnalyticsService } from '../analytics';

@Injectable()
export class MatchingService {
  constructor(
    // ... other dependencies
    private readonly analyticsService: AnalyticsService,
  ) {}

  async generateDailySelection(userId: string) {
    // Generate daily selection logic
    const selection = await this.matchingAlgorithm.generateSelection(userId);

    // Track daily selection viewed
    await this.analyticsService.trackMatching(userId, {
      action: 'daily_selection_viewed',
      metadata: {
        profilesCount: selection.length,
        averageCompatibility: this.calculateAverage(selection),
      },
    });

    return selection;
  }

  async chooseProfile(userId: string, targetUserId: string) {
    // Choose profile logic
    const choice = await this.choiceRepository.save({
      userId,
      targetUserId,
    });

    // Get compatibility score
    const compatibility = await this.calculateCompatibility(userId, targetUserId);

    // Track profile chosen
    await this.analyticsService.trackMatching(userId, {
      action: 'profile_chosen',
      compatibilityScore: compatibility.score,
      metadata: {
        timeSpentViewing: choice.timeSpent,
      },
    });

    // Check if it's a mutual match
    const isMatch = await this.checkMutualMatch(userId, targetUserId);
    if (isMatch) {
      await this.createMatch(userId, targetUserId, compatibility);
    }

    return choice;
  }

  async createMatch(userId: string, targetUserId: string, compatibility: any) {
    // Create match logic
    const match = await this.matchRepository.save(newMatch);

    // Track match created for both users
    await Promise.all([
      this.analyticsService.trackMatching(userId, {
        action: 'match_created',
        matchId: match.id,
        compatibilityScore: compatibility.score,
      }),
      this.analyticsService.trackMatching(targetUserId, {
        action: 'match_created',
        matchId: match.id,
        compatibilityScore: compatibility.score,
      }),
    ]);

    return match;
  }

  async handleMatchExpiry(matchId: string) {
    // Get match details
    const match = await this.matchRepository.findOne(matchId);

    // Track match expiry
    await Promise.all([
      this.analyticsService.trackMatching(match.userId, {
        action: 'match_expired',
        matchId: match.id,
        metadata: {
          duration: this.calculateDuration(match),
          messagesSent: match.messagesCount,
        },
      }),
      this.analyticsService.trackMatching(match.targetUserId, {
        action: 'match_expired',
        matchId: match.id,
        metadata: {
          duration: this.calculateDuration(match),
          messagesSent: match.messagesCount,
        },
      }),
    ]);

    // Delete match
    await this.matchRepository.delete(matchId);
  }
}
```

---

## Chat Module Integration

Track messaging and conversation events.

### chat.service.ts

```typescript
import { Injectable } from '@nestjs/common';
import { AnalyticsService } from '../analytics';

@Injectable()
export class ChatService {
  constructor(
    // ... other dependencies
    private readonly analyticsService: AnalyticsService,
  ) {}

  async createConversation(matchId: string, userId: string, targetUserId: string) {
    // Create conversation logic
    const conversation = await this.conversationRepository.save({
      matchId,
      participants: [userId, targetUserId],
    });

    // Track conversation started
    await Promise.all([
      this.analyticsService.trackChat(userId, {
        action: 'conversation_started',
        conversationId: conversation.id,
      }),
      this.analyticsService.trackChat(targetUserId, {
        action: 'conversation_started',
        conversationId: conversation.id,
      }),
    ]);

    return conversation;
  }

  async sendMessage(userId: string, conversationId: string, message: string) {
    // Send message logic
    const msg = await this.messageRepository.save({
      conversationId,
      senderId: userId,
      content: message,
    });

    // Track message sent
    await this.analyticsService.trackChat(userId, {
      action: 'message_sent',
      conversationId,
      metadata: {
        messageLength: message.length,
        messageNumber: await this.getMessageCount(conversationId),
      },
    });

    return msg;
  }

  async handleConversationExpiry(conversationId: string) {
    // Get conversation details
    const conversation = await this.conversationRepository.findOne(conversationId);
    const messagesCount = await this.getMessageCount(conversationId);

    // Track conversation expired for both participants
    await Promise.all(
      conversation.participants.map((userId) =>
        this.analyticsService.trackChat(userId, {
          action: 'conversation_expired',
          conversationId,
          metadata: {
            messagesSent: messagesCount,
            duration: this.calculateDuration(conversation),
          },
        }),
      ),
    );

    // Archive conversation
    await this.conversationRepository.update(conversationId, {
      archived: true,
    });
  }
}
```

---

## Subscriptions Module Integration

Track subscription lifecycle events.

### subscriptions.service.ts

```typescript
import { Injectable } from '@nestjs/common';
import { AnalyticsService } from '../analytics';

@Injectable()
export class SubscriptionsService {
  constructor(
    // ... other dependencies
    private readonly analyticsService: AnalyticsService,
  ) {}

  async createSubscription(userId: string, plan: string, paymentDetails: any) {
    // Create subscription logic
    const subscription = await this.subscriptionRepository.save({
      userId,
      plan,
      ...paymentDetails,
    });

    // Track subscription started
    await this.analyticsService.trackSubscription(userId, {
      action: 'subscription_started',
      plan,
      price: paymentDetails.amount,
      currency: paymentDetails.currency,
      metadata: {
        paymentMethod: paymentDetails.method,
        billingCycle: subscription.billingCycle,
      },
    });

    return subscription;
  }

  async renewSubscription(subscriptionId: string) {
    // Renew subscription logic
    const subscription = await this.subscriptionRepository.findOne(subscriptionId);
    await this.subscriptionRepository.update(subscriptionId, {
      renewedAt: new Date(),
    });

    // Track subscription renewed
    await this.analyticsService.trackSubscription(subscription.userId, {
      action: 'subscription_renewed',
      plan: subscription.plan,
      price: subscription.amount,
      currency: subscription.currency,
    });

    return subscription;
  }

  async cancelSubscription(userId: string, subscriptionId: string, reason?: string) {
    // Cancel subscription logic
    const subscription = await this.subscriptionRepository.findOne(subscriptionId);
    await this.subscriptionRepository.update(subscriptionId, {
      cancelledAt: new Date(),
      status: 'cancelled',
    });

    // Track subscription cancelled
    await this.analyticsService.trackSubscription(userId, {
      action: 'subscription_cancelled',
      plan: subscription.plan,
      metadata: {
        reason,
        subscriptionDuration: this.calculateDuration(subscription),
      },
    });

    return { success: true };
  }

  async upgradeSubscription(userId: string, subscriptionId: string, newPlan: string) {
    // Upgrade subscription logic
    const subscription = await this.subscriptionRepository.findOne(subscriptionId);
    await this.subscriptionRepository.update(subscriptionId, {
      plan: newPlan,
    });

    // Track subscription upgraded
    await this.analyticsService.trackSubscription(userId, {
      action: 'subscription_upgraded',
      plan: newPlan,
      metadata: {
        previousPlan: subscription.plan,
      },
    });

    return subscription;
  }
}
```

---

## GDPR Module Integration

Integrate analytics opt-out with GDPR consent management.

### gdpr.service.ts

```typescript
import { Injectable } from '@nestjs/common';
import { AnalyticsService } from '../analytics';

@Injectable()
export class GdprService {
  constructor(
    // ... other dependencies
    private readonly analyticsService: AnalyticsService,
  ) {}

  async recordConsent(userId: string, consentData: any) {
    // Save consent logic
    const consent = await this.consentRepository.save({
      userId,
      ...consentData,
    });

    // If user opted out of analytics, opt them out in Mixpanel
    if (!consentData.analytics) {
      await this.analyticsService.optOut(userId);
    }

    return consent;
  }

  async revokeConsent(userId: string) {
    // Revoke consent logic
    await this.consentRepository.update(
      { userId, isActive: true },
      { isActive: false, revokedAt: new Date() },
    );

    // Opt user out of analytics
    await this.analyticsService.optOut(userId);

    return { success: true };
  }

  async deleteUserAccount(userId: string) {
    // Delete user data from all tables
    await this.deleteUserFromDatabase(userId);

    // Delete all analytics data
    await this.analyticsService.deleteUserData(userId);

    // Continue with other cleanup...
    return { success: true };
  }
}
```

### gdpr.module.ts

```typescript
import { Module } from '@nestjs/common';
import { GdprService } from './gdpr.service';
import { GdprController } from './gdpr.controller';
import { AnalyticsModule } from '../analytics';

@Module({
  imports: [
    // ... other imports
    AnalyticsModule,
  ],
  controllers: [GdprController],
  providers: [GdprService],
  exports: [GdprService],
})
export class GdprModule {}
```

---

## General Best Practices

### 1. Import the AnalyticsModule

Always import `AnalyticsModule` in your feature module:

```typescript
@Module({
  imports: [AnalyticsModule],
  // ...
})
export class YourFeatureModule {}
```

### 2. Inject the AnalyticsService

Inject the service in your constructors:

```typescript
constructor(
  private readonly analyticsService: AnalyticsService,
) {}
```

### 3. Track Events Asynchronously

All tracking calls are async, but you don't need to await them if they're not critical:

```typescript
// Fire and forget
this.analyticsService.trackEvent({ ... });

// Or await if you want to ensure tracking completes
await this.analyticsService.trackEvent({ ... });
```

### 4. Handle Errors Gracefully

Analytics should never break your main flow:

```typescript
try {
  await this.analyticsService.trackEvent({ ... });
} catch (error) {
  // Log but don't throw
  this.logger.error('Analytics tracking failed', error);
}
```

### 5. Add Meaningful Context

Include relevant metadata to understand user behavior:

```typescript
await this.analyticsService.trackMatching(userId, {
  action: 'match_created',
  matchId: match.id,
  compatibilityScore: 85,
  metadata: {
    timeToMatch: 1200, // seconds since registration
    userTier: 'premium',
    profileCompleteness: 0.95,
  },
});
```

### 6. Respect User Privacy

Never track PII or sensitive information:

```typescript
// ❌ DON'T DO THIS
await this.analyticsService.trackEvent({
  name: 'message_sent',
  properties: {
    messageContent: message.text, // DON'T track message content
    email: user.email, // DON'T track email
  },
});

// ✅ DO THIS INSTEAD
await this.analyticsService.trackEvent({
  name: 'message_sent',
  properties: {
    messageLength: message.text.length,
    hasEmojis: this.containsEmojis(message.text),
  },
});
```

---

## Testing with Analytics

When writing tests, mock the AnalyticsService:

```typescript
const mockAnalyticsService = {
  trackEvent: jest.fn(),
  trackOnboarding: jest.fn(),
  trackMatching: jest.fn(),
  trackChat: jest.fn(),
  trackSubscription: jest.fn(),
  identifyUser: jest.fn(),
};

beforeEach(async () => {
  const module: TestingModule = await Test.createTestingModule({
    providers: [
      YourService,
      {
        provide: AnalyticsService,
        useValue: mockAnalyticsService,
      },
    ],
  }).compile();
});

it('should track event when action is performed', async () => {
  await service.performAction(userId);
  
  expect(mockAnalyticsService.trackEvent).toHaveBeenCalledWith({
    name: 'action_performed',
    userId,
    properties: expect.any(Object),
  });
});
```

---

## Troubleshooting Integration Issues

### Events Not Being Tracked

1. Verify `AnalyticsModule` is imported in your feature module
2. Check that `AnalyticsService` is properly injected
3. Ensure user has analytics consent enabled
4. Check application logs for error messages

### Module Dependency Issues

If you get circular dependency errors:

```typescript
// Use forwardRef if needed
@Module({
  imports: [
    forwardRef(() => AnalyticsModule),
  ],
})
```

### Type Errors

Import types from the analytics module:

```typescript
import { 
  AnalyticsService,
  OnboardingEvent,
  MatchingEvent,
  ChatEvent,
  SubscriptionEvent,
} from '../analytics';
```

---

For more information, see the [Analytics Module README](./README.md).
