# Quick Start Guide - Analytics Integration

This guide will help you get analytics up and running in 5 minutes.

## Step 1: Get Mixpanel Token

1. Go to [mixpanel.com](https://mixpanel.com) and create a free account
2. Create a new project called "GoldWen App"
3. Navigate to Settings > Project Settings
4. Copy your **Project Token** (e.g., `abc123def456...`)

## Step 2: Configure the App

### Option A: Environment Variable (Recommended)

```bash
# Run the app with your token
flutter run --dart-define=MIXPANEL_TOKEN=your_token_here
```

### Option B: Configuration File

```bash
# 1. Copy the template
cp .env.analytics.template .env.analytics

# 2. Edit .env.analytics and add your token
nano .env.analytics  # or use your favorite editor

# 3. Run the app
flutter run --dart-define-from-file=.env.analytics
```

### Option C: Hardcode (Development Only)

Edit `lib/core/services/app_initialization_service.dart`:

```dart
// Replace this line:
const mixpanelToken = String.fromEnvironment(
  'MIXPANEL_TOKEN',
  defaultValue: 'YOUR_MIXPANEL_TOKEN_HERE',
);

// With your actual token:
const mixpanelToken = 'your_actual_token_here';
```

## Step 3: Enable Analytics in App

1. Launch the app
2. When the GDPR consent modal appears, **enable analytics consent**
3. Complete the onboarding process

## Step 4: Verify Events in Mixpanel

1. Go to your Mixpanel dashboard
2. Click on "Events" in the left sidebar
3. You should see events appearing within a few seconds:
   - `signup_started`
   - `signup_completed`
   - `personality_quiz_completed`
   - `profile_completed`
   - etc.

## Step 5: Create Your First Dashboard

In Mixpanel:

1. Click "Boards" > "Create Board"
2. Name it "User Onboarding"
3. Add a Funnel report:
   - Step 1: `signup_started`
   - Step 2: `signup_completed`
   - Step 3: `personality_quiz_completed`
   - Step 4: `profile_completed`
4. Save the funnel

## Testing GDPR Opt-Out

### Test Opt-Out:

1. Go to Settings > Privacy
2. Disable "Analytics Tracking"
3. Perform actions (view profiles, send messages, etc.)
4. Check Mixpanel - no new events should appear

### Test Opt-In:

1. Go to Settings > Privacy
2. Enable "Analytics Tracking"
3. Perform actions again
4. Check Mixpanel - events should now appear

## Common Issues

### "No events appearing in Mixpanel"

**Solutions:**
1. Verify token is correct
2. Check console logs for initialization errors
3. Ensure analytics consent is enabled
4. Wait 1-2 minutes - Mixpanel has a slight delay
5. Check internet connection

### "Events appearing even after opt-out"

**Solutions:**
1. Restart the app after changing consent
2. Check SharedPreferences (`gdpr_analytics_consent` should be `false`)
3. Verify `AnalyticsService.updateConsent(false)` was called

### "Token not found error"

**Solutions:**
1. If using `--dart-define`, ensure no spaces around `=`
2. Verify token is set in environment or hardcoded
3. Check that `app_initialization_service.dart` has correct token source

## Example Events to Track Manually

You can also track custom events:

```dart
import 'package:goldwen_app/core/services/analytics_service.dart';

// Track a custom action
await AnalyticsService.track('custom_feature_used', properties: {
  'feature_name': 'advanced_search',
  'filters_applied': 3,
});

// Track user engagement
await AnalyticsService.track('profile_viewed_duration', properties: {
  'profile_id': 'abc123',
  'duration_seconds': 45,
});
```

## Next Steps

1. ✅ Verify events are flowing to Mixpanel
2. ✅ Test GDPR opt-out functionality
3. 📊 Create dashboards for key metrics
4. 📈 Set up funnels for conversion tracking
5. 🔔 Configure alerts for important events
6. 🎯 Define KPIs and targets

## Support Resources

- **Mixpanel Docs**: [docs.mixpanel.com](https://docs.mixpanel.com)
- **Flutter Plugin**: [pub.dev/packages/mixpanel_flutter](https://pub.dev/packages/mixpanel_flutter)
- **Full Documentation**: See [ANALYTICS_INTEGRATION.md](ANALYTICS_INTEGRATION.md)

---

**Ready to scale?** Once basic analytics are working, explore advanced features like:
- Cohort analysis
- A/B testing
- User segmentation
- Retention reports
- Revenue analytics
