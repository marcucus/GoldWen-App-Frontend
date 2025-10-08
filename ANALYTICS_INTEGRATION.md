# Analytics Integration - Mixpanel

This document describes the analytics implementation in the GoldWen app using Mixpanel.

## Overview

The analytics system tracks user events throughout the app to provide insights into user behavior, engagement, and conversion. It is fully GDPR-compliant with opt-in/opt-out functionality.

## Configuration

### Mixpanel Token Setup

The Mixpanel token should be configured as an environment variable:

```bash
# For development/testing
flutter run --dart-define=MIXPANEL_TOKEN=your_test_token_here

# For production builds
flutter build apk --dart-define=MIXPANEL_TOKEN=your_production_token_here
```

Alternatively, you can hardcode it in the app initialization service (not recommended for production):

```dart
// lib/core/services/app_initialization_service.dart
await AnalyticsService.initialize(token: 'your_mixpanel_token');
```

### GDPR Compliance

The analytics service is **opt-in by default**, meaning:
- Users must explicitly consent to analytics tracking via the GDPR consent modal
- Analytics are disabled until consent is given
- Users can withdraw consent at any time via privacy settings
- When consent is withdrawn, all analytics tracking stops immediately

The consent status is stored locally and synchronized with the backend.

## Tracked Events

### Onboarding Events

| Event Name | Description | Properties |
|------------|-------------|------------|
| `signup_started` | User initiated signup process | `method` (email/google/apple) |
| `signup_completed` | User completed signup | `method` (email/google/apple) |
| `personality_quiz_started` | User started personality quiz | - |
| `personality_quiz_completed` | User completed personality quiz | - |
| `profile_setup_started` | User started profile setup | - |
| `profile_completed` | User completed their profile | - |

### Matching Events

| Event Name | Description | Properties |
|------------|-------------|------------|
| `daily_selection_viewed` | User viewed daily selection | `profile_count` |
| `profile_viewed` | User viewed a specific profile | `profile_id` |
| `profile_chosen` | User liked a profile | `profile_id`, `compatibility_score` (optional) |
| `profile_passed` | User passed on a profile | `profile_id` |
| `match_created` | A mutual match was created | `match_id`, `other_user_id` |

### Chat Events

| Event Name | Description | Properties |
|------------|-------------|------------|
| `chat_accepted` | User accepted a chat request | `chat_id`, `match_id` |
| `chat_declined` | User declined a chat request | `match_id` |
| `first_message_sent` | User sent first message in a chat | `chat_id` |
| `message_sent` | User sent a message | `chat_id`, `message_length` (optional) |
| `chat_expired` | A chat conversation expired | `chat_id`, `message_count` |

### Subscription Events

| Event Name | Description | Properties |
|------------|-------------|------------|
| `subscription_page_viewed` | User viewed subscription page | - |
| `subscription_started` | User purchased a subscription | `tier`, `period` |
| `subscription_cancelled` | User cancelled their subscription | `tier` |
| `subscription_restored` | User restored their subscription | `tier` |

### App Lifecycle Events

| Event Name | Description | Properties |
|------------|-------------|------------|
| `app_opened` | User opened the app | - |
| `app_backgrounded` | User put app in background | - |

## Usage Examples

### Manual Event Tracking

```dart
import 'package:goldwen_app/core/services/analytics_service.dart';

// Track a custom event
await AnalyticsService.track('custom_event', properties: {
  'feature': 'advanced_filters',
  'action': 'filter_applied',
});

// Identify a user
await AnalyticsService.identify('user_123');

// Set user properties
await AnalyticsService.setUserProperties({
  'subscription_tier': 'plus',
  'profile_completeness': 100,
});
```

### Automatic Event Tracking

Most events are tracked automatically when users interact with the app:

```dart
// In AuthProvider - automatically tracked
await authProvider.registerWithEmail(...);  // Triggers signup_started and signup_completed

// In ProfileProvider - automatically tracked
await profileProvider.submitPersonalityAnswers();  // Triggers personality_quiz_completed

// In MatchingProvider - automatically tracked
await matchingProvider.selectProfile(profileId);  // Triggers profile_chosen and potentially match_created

// In ChatProvider - automatically tracked
await chatProvider.sendMessage(chatId, message);  // Triggers first_message_sent or message_sent

// In SubscriptionProvider - automatically tracked
await subscriptionProvider.loadSubscriptionPlans();  // Triggers subscription_page_viewed
await subscriptionProvider.purchaseSubscription(...);  // Triggers subscription_started
```

## User Properties

The following user properties are automatically set:

- `signup_method`: Email, Google, or Apple
- `signup_date`: When the user signed up
- `profile_completed_at`: When profile was completed
- `profile_status`: Complete or incomplete
- `subscription_tier`: Current subscription tier
- `subscription_period`: Subscription billing period
- `subscription_started_at`: When subscription started
- `subscription_status`: Active, cancelled, etc.

## GDPR Opt-Out Implementation

### Consent Management

Users can manage their analytics consent in two places:

1. **Initial Consent Modal**: Shows on first app launch
2. **Privacy Settings**: Under Settings > Privacy > Analytics

```dart
// Update analytics consent
await gdprService.updatePrivacySettings(
  analytics: true,  // Enable analytics
  marketing: false,
  functionalCookies: true,
);
```

### Opt-Out Flow

When a user opts out:
1. GDPR service updates local consent status
2. Analytics service is notified via `updateConsent(false)`
3. Mixpanel's `optOutTracking()` is called
4. No further events are tracked until user opts back in

### Opt-In Flow

When a user opts in:
1. GDPR service updates local consent status
2. Analytics service is notified via `updateConsent(true)`
3. Mixpanel's `optInTracking()` is called
4. Event tracking resumes

## Testing

### Unit Tests

Run the analytics service tests:

```bash
flutter test test/analytics_service_test.dart
```

### Manual Testing

To verify analytics are working:

1. **Setup Mixpanel**: Create a free Mixpanel account at [mixpanel.com](https://mixpanel.com)
2. **Get Token**: Copy your project token from Mixpanel settings
3. **Configure App**: Add token to environment or code
4. **Run App**: Launch the app with the token configured
5. **Verify Dashboard**: Check Mixpanel dashboard for incoming events

### Testing GDPR Opt-Out

1. Launch app and deny analytics consent
2. Perform various actions (signup, profile completion, etc.)
3. Check Mixpanel dashboard - no events should appear
4. Enable analytics in Privacy Settings
5. Perform actions again - events should now appear in dashboard

## Dashboard & Monitoring

### Recommended Mixpanel Dashboards

Create the following dashboards in Mixpanel:

1. **Onboarding Funnel**
   - signup_started → signup_completed → personality_quiz_completed → profile_completed

2. **Matching Engagement**
   - daily_selection_viewed → profile_chosen → match_created → chat_accepted

3. **Chat Activity**
   - chat_accepted → first_message_sent → message_sent (count)

4. **Subscription Conversion**
   - subscription_page_viewed → subscription_started

5. **User Retention**
   - Daily/Weekly/Monthly active users
   - Cohort analysis by signup date

### Key Metrics to Monitor

- **Signup Conversion**: signup_started → signup_completed
- **Profile Completion Rate**: signup_completed → profile_completed
- **Daily Matching Engagement**: % of users viewing daily selection
- **Match Rate**: profile_chosen → match_created
- **Chat Activation**: match_created → chat_accepted
- **First Message Rate**: chat_accepted → first_message_sent
- **Subscription Conversion**: subscription_page_viewed → subscription_started

## Troubleshooting

### Events Not Appearing in Dashboard

1. Verify Mixpanel token is correct
2. Check that analytics consent is enabled
3. Check debug logs for initialization errors
4. Verify internet connectivity
5. Wait a few minutes - Mixpanel may have a delay

### Analytics Disabled After Consent

1. Check SharedPreferences for `gdpr_analytics_consent` value
2. Verify `updateConsent()` was called after consent change
3. Check for any errors in the console logs

### Test Events in Production Dashboard

Use Mixpanel's test mode or create separate projects for development/staging/production to avoid polluting production data.

## Security & Privacy

### Data Anonymization

- User IDs are anonymized on the Mixpanel side
- Personal information (email, name, etc.) is NOT sent to Mixpanel
- Only behavioral events and anonymous user properties are tracked

### Data Retention

- Follow Mixpanel's data retention policies
- Configure data retention in Mixpanel settings
- Respect user's data deletion requests

### Compliance

This implementation complies with:
- ✅ GDPR (European Union)
- ✅ CCPA (California)
- ✅ Apple App Store privacy requirements
- ✅ Google Play Store privacy requirements

## Next Steps

1. **Configure Mixpanel Project**: Create account and get token
2. **Set Up Dashboards**: Create recommended dashboards
3. **Define KPIs**: Set target metrics for each funnel
4. **Monitor Regularly**: Review analytics weekly
5. **Iterate**: Use insights to improve user experience

## Support

For questions or issues:
- Mixpanel Documentation: [docs.mixpanel.com](https://docs.mixpanel.com)
- Flutter Plugin: [pub.dev/packages/mixpanel_flutter](https://pub.dev/packages/mixpanel_flutter)
