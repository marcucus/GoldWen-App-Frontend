# Analytics Module - Documentation

## Overview

The Analytics Module integrates Mixpanel analytics into the GoldWen backend to track key product events and user behavior. It is designed with GDPR compliance at its core, respecting user consent and providing opt-out capabilities.

## Features

- **Mixpanel Integration**: Full integration with Mixpanel for event tracking and user analytics
- **GDPR Compliant**: Automatic consent checking before tracking any user data
- **Event Tracking**: Pre-built methods for tracking key product events:
  - Onboarding events (registration, profile creation, questionnaire, photos)
  - Matching events (daily selection, profile chosen, matches created)
  - Chat events (conversations started, messages sent, conversations expired)
  - Subscription events (subscription lifecycle tracking)
- **API Tracking Middleware**: Automatic tracking of API requests and performance metrics
- **User Identification**: Track user properties and lifecycle
- **Opt-out Support**: Full GDPR compliance with opt-out and data deletion capabilities

## Architecture

### Components

#### 1. `AnalyticsService`
Main service for tracking events and managing user analytics.

**Key Methods:**
- `trackEvent(event)`: Generic event tracking
- `trackOnboarding(userId, event)`: Track onboarding flow events
- `trackMatching(userId, event)`: Track matching-related events
- `trackChat(userId, event)`: Track chat/messaging events
- `trackSubscription(userId, event)`: Track subscription lifecycle
- `identifyUser(userId, properties)`: Identify and enrich user profiles
- `optOut(userId)`: Opt user out of analytics (GDPR)
- `deleteUserData(userId)`: Delete all user analytics data (GDPR - Right to be Forgotten)

#### 2. `AnalyticsMiddleware`
Express middleware that automatically tracks API requests.

**Features:**
- Tracks successful API requests (status < 400)
- Captures request duration, method, path, status code
- Extracts authenticated user ID from requests
- Graceful error handling

#### 3. `AnalyticsModule`
NestJS module that encapsulates analytics functionality.

**Dependencies:**
- GdprModule (for consent management)

## Configuration

### Environment Variables

```bash
# Mixpanel Configuration
MIXPANEL_TOKEN=your_mixpanel_project_token
MIXPANEL_ENABLED=true  # Set to 'false' to disable analytics
```

### Configuration Structure

The module uses the following configuration structure:

```typescript
export interface AnalyticsConfig {
  mixpanel: {
    token: string;
    enabled: boolean;
  };
}
```

## Usage Examples

### Tracking Onboarding Events

```typescript
import { AnalyticsService } from './modules/analytics';

// In your registration controller/service
await this.analyticsService.trackOnboarding(userId, {
  step: 'registration',
  method: 'google',
  metadata: {
    referralSource: 'instagram',
  },
});

// Profile creation
await this.analyticsService.trackOnboarding(userId, {
  step: 'profile_creation',
});

// Questionnaire completion
await this.analyticsService.trackOnboarding(userId, {
  step: 'questionnaire',
  metadata: {
    questionsAnswered: 10,
  },
});

// Photos uploaded
await this.analyticsService.trackOnboarding(userId, {
  step: 'photos_upload',
  metadata: {
    photosCount: 5,
  },
});

// Onboarding completed
await this.analyticsService.trackOnboarding(userId, {
  step: 'completed',
});
```

### Tracking Matching Events

```typescript
// Daily selection viewed
await this.analyticsService.trackMatching(userId, {
  action: 'daily_selection_viewed',
  metadata: {
    profilesCount: 5,
  },
});

// Profile chosen
await this.analyticsService.trackMatching(userId, {
  action: 'profile_chosen',
  compatibilityScore: 87,
});

// Match created
await this.analyticsService.trackMatching(userId, {
  action: 'match_created',
  matchId: 'match-uuid',
  compatibilityScore: 87,
});
```

### Tracking Chat Events

```typescript
// Conversation started
await this.analyticsService.trackChat(userId, {
  action: 'conversation_started',
  conversationId: 'conversation-uuid',
});

// Message sent
await this.analyticsService.trackChat(userId, {
  action: 'message_sent',
  conversationId: 'conversation-uuid',
  metadata: {
    messageLength: 140,
  },
});

// Conversation expired
await this.analyticsService.trackChat(userId, {
  action: 'conversation_expired',
  conversationId: 'conversation-uuid',
  metadata: {
    messagesSent: 15,
    duration: 86400, // 24 hours in seconds
  },
});
```

### Tracking Subscription Events

```typescript
// Subscription started
await this.analyticsService.trackSubscription(userId, {
  action: 'subscription_started',
  plan: 'GoldWen Plus',
  price: 9.99,
  currency: 'USD',
});

// Subscription renewed
await this.analyticsService.trackSubscription(userId, {
  action: 'subscription_renewed',
  plan: 'GoldWen Plus',
  price: 9.99,
  currency: 'USD',
});

// Subscription cancelled
await this.analyticsService.trackSubscription(userId, {
  action: 'subscription_cancelled',
  plan: 'GoldWen Plus',
  metadata: {
    reason: 'too_expensive',
  },
});
```

### User Identification

```typescript
// Identify user with additional properties
await this.analyticsService.identifyUser(userId, {
  name: 'John Doe',
  email: 'john@example.com',
  age: 28,
  gender: 'male',
  city: 'Paris',
});
```

### Generic Event Tracking

```typescript
// Track custom events
await this.analyticsService.trackEvent({
  name: 'feature_used',
  userId: 'user-123',
  properties: {
    feature: 'icebreaker',
    variant: 'A',
  },
});
```

## GDPR Compliance

### Consent Management

The Analytics Module automatically checks user consent before tracking any event. It integrates with the GDPR module to verify that users have opted in to analytics tracking.

**Consent Flow:**
1. User consent is checked via `GdprService.getCurrentConsent(userId)`
2. Only users with `analytics: true` in their consent will have events tracked
3. If no consent record exists, the module defaults to **opt-out** (GDPR compliant)
4. On consent check errors, the module defaults to **opt-out** for safety

### Opt-out

```typescript
// User opts out of analytics
await this.analyticsService.optOut(userId);
```

### Right to be Forgotten

```typescript
// Delete all analytics data for a user
await this.analyticsService.deleteUserData(userId);
```

This method should be called as part of the account deletion flow to ensure full GDPR compliance.

## Integration with Existing Modules

### In Controllers

```typescript
import { Injectable } from '@nestjs/common';
import { AnalyticsService } from '../analytics';

@Injectable()
export class MatchingService {
  constructor(private readonly analyticsService: AnalyticsService) {}

  async createMatch(userId: string, targetUserId: string) {
    // Business logic...
    const match = await this.matchRepository.save(newMatch);

    // Track the event
    await this.analyticsService.trackMatching(userId, {
      action: 'match_created',
      matchId: match.id,
      compatibilityScore: match.compatibilityScore,
    });

    return match;
  }
}
```

### In the Account Deletion Flow

```typescript
import { Injectable } from '@nestjs/common';
import { AnalyticsService } from '../analytics';

@Injectable()
export class GdprService {
  constructor(private readonly analyticsService: AnalyticsService) {}

  async deleteUserAccount(userId: string) {
    // Delete user data from database...

    // Delete analytics data
    await this.analyticsService.deleteUserData(userId);

    // Continue with other deletions...
  }
}
```

## Monitoring and Debugging

### Logging

The Analytics Module uses NestJS Logger for all logging:

```typescript
this.logger.log('Event tracked: onboarding_registration', { userId });
this.logger.debug('User opted out of analytics', { userId });
this.logger.error('Failed to track event', error.stack);
```

### Disabling Analytics

To disable analytics (e.g., in development or testing):

```bash
# In .env
MIXPANEL_ENABLED=false
```

Or simply don't set the `MIXPANEL_TOKEN` environment variable.

## Mixpanel Dashboard Setup

### Key Dashboards to Create

1. **Onboarding Funnel**
   - Registration → Profile Creation → Questionnaire → Photos Upload → Completed
   - Track drop-off rates at each step

2. **Matching Performance**
   - Daily selection views
   - Profile chosen rate
   - Match creation rate
   - Time to first match

3. **Chat Engagement**
   - Conversations started
   - Messages per conversation
   - Conversation completion rate (before expiry)

4. **Subscription Metrics**
   - Free to paid conversion rate
   - Subscription renewal rate
   - Churn rate and reasons

5. **User Retention**
   - Daily Active Users (DAU)
   - Weekly Active Users (WAU)
   - Monthly Active Users (MAU)
   - Retention cohorts

## Testing

The module includes comprehensive unit tests:

```bash
# Run analytics tests
npm test -- analytics.service.spec.ts
npm test -- analytics.middleware.spec.ts
```

### Test Coverage

- ✅ Service initialization with/without Mixpanel token
- ✅ GDPR consent checking
- ✅ Event tracking with consent
- ✅ Event tracking without consent
- ✅ Onboarding event tracking
- ✅ Matching event tracking
- ✅ Chat event tracking
- ✅ Subscription event tracking
- ✅ User identification
- ✅ Opt-out functionality
- ✅ Data deletion
- ✅ Middleware request tracking
- ✅ Error handling

## Security Considerations

1. **PII Protection**: Be careful not to track Personally Identifiable Information (PII) in event properties
2. **Token Security**: Keep `MIXPANEL_TOKEN` secure and never commit it to version control
3. **Consent First**: Always check consent before tracking user events
4. **Error Handling**: All tracking errors are logged but don't interrupt the main application flow

## Best Practices

1. **Track Intent, Not Actions**: Focus on user intent and outcomes rather than technical actions
2. **Consistent Naming**: Use consistent event naming conventions (e.g., `module_action`)
3. **Meaningful Properties**: Include context that helps understand user behavior
4. **Don't Over-Track**: Track meaningful events that inform product decisions
5. **Async Tracking**: All tracking is asynchronous and non-blocking
6. **Graceful Degradation**: The app continues to work even if analytics fails

## Troubleshooting

### Events Not Appearing in Mixpanel

1. Check `MIXPANEL_ENABLED=true` in environment
2. Verify `MIXPANEL_TOKEN` is set correctly
3. Check user has `analytics: true` consent
4. Look for error logs in application logs
5. Verify Mixpanel token is valid in Mixpanel dashboard

### Consent Issues

If events are not being tracked due to consent:
1. Verify user has a consent record in the database
2. Check that `analytics` field is set to `true`
3. Review GDPR module integration

### Performance Impact

Analytics tracking is designed to be non-blocking:
- All Mixpanel calls are fire-and-forget
- Errors don't propagate to the main application
- Minimal overhead on request processing

## Future Enhancements

Potential future improvements:

- [ ] Batch event tracking for better performance
- [ ] A/B testing integration
- [ ] Funnel analysis helpers
- [ ] Automatic user property enrichment
- [ ] Analytics event validation
- [ ] Multi-provider support (Amplitude, Segment)
- [ ] Real-time analytics dashboard
- [ ] Automated anomaly detection

## Support

For issues or questions about the Analytics Module:
1. Check the logs for error messages
2. Review Mixpanel documentation: https://developer.mixpanel.com/
3. Contact the backend team
