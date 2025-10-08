# GoldWen Plus Subscription Setup Guide

This guide explains how to configure the GoldWen Plus subscription system that has been implemented.

## Overview

The subscription system supports:
- **Free users**: 1 profile selection per day
- **GoldWen Plus subscribers**: 3 profile selections per day
- Dynamic subscription plans loaded from API
- RevenueCat integration for payment processing
- Subscription management (cancel, restore, upgrade)

## Implementation Status

✅ **Completed:**
- Subscription page UI with responsive design and animations
- RevenueCat SDK integration for iOS and Android payments
- Subscription provider with state management
- Purchase flow with error handling and user cancellation support
- Subscription status indicators and banners
- Daily selection limit enforcement
- Settings integration for subscription management
- Unit and integration tests

⚠️ **Configuration Required:**
- RevenueCat API key needs to be set in production
- Backend API endpoints must be configured
- App Store Connect and Google Play Console products setup

## Configuration Required

### 1. RevenueCat Setup

1. **Update API Key**: In `lib/core/services/revenue_cat_service.dart`, replace `'your_revenue_cat_api_key_here'` with your actual RevenueCat API key.

2. **Configure Products**: Set up subscription products in RevenueCat dashboard:
   - `goldwen_plus_monthly` - Monthly subscription
   - `goldwen_plus_quarterly` - Quarterly subscription (marked as popular)
   - `goldwen_plus_semiannual` - Semi-annual subscription

3. **Product Configuration**: Update the product identifiers in RevenueCat service methods if needed.

### 2. Backend Integration

Ensure your backend API supports these endpoints:

```
GET /subscriptions/plans          # List available plans
GET /subscriptions/me             # Current user subscription
POST /subscriptions/purchase      # Handle subscription purchase
POST /subscriptions/verify-receipt # Verify RevenueCat receipts
PUT /subscriptions/cancel         # Cancel subscription
POST /subscriptions/restore       # Restore previous subscription
GET /subscriptions/usage          # Get subscription usage limits
GET /users/me                     # User profile with subscription status
```

### 3. User Model Updates

The User model now includes subscription fields:
- `hasActiveSubscription: bool?`
- `subscriptionPlan: String?`
- `subscriptionExpiresAt: DateTime?`

Ensure your backend returns these fields in the `/users/me` endpoint.

## Purchase Flow

The subscription purchase flow is fully integrated with RevenueCat:

1. **Plan Selection**: User selects a subscription plan on `/subscription` page
2. **RevenueCat Purchase**: The app initiates native payment via RevenueCat SDK
   - iOS: App Store payment sheet
   - Android: Google Play payment sheet
3. **User Cancellation**: If user cancels, the flow exits gracefully without showing errors
4. **Verification**: Successful purchases are verified with the backend
5. **Status Update**: Subscription status is updated and user is notified
6. **Success Dialog**: User sees confirmation and can start using premium features

### Error Handling

The purchase flow handles various scenarios:
- **User Cancellation**: Silent exit, no error shown
- **Network Errors**: User-friendly error message with retry option
- **Verification Failures**: Specific error about backend verification
- **Invalid Plans**: Error message about plan availability

## Features Implemented

### Subscription Page (`/subscription`)
- Dynamic plan loading from API
- RevenueCat payment integration
- Plan comparison with features
- Success/error handling

### Daily Matching Integration
- Selection limit enforcement (1 for free, 3 for premium)
- Upgrade prompts when limits reached
- Subscription status indicators
- Premium user benefits display

### Settings Integration
- Subscription management section
- Cancel/restore subscription options
- Subscription status display
- Upgrade promotions for free users

### UI Components
- `SubscriptionPromoBanner` - Non-intrusive upgrade prompts
- `SubscriptionLimitReachedDialog` - Upgrade dialog when limits reached
- `SubscriptionStatusIndicator` - Status display for premium users

## Usage Examples

### Initialize Subscription Provider
```dart
// In main app or user login
final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
await subscriptionProvider.initializeWithUser(userId);
await subscriptionProvider.loadSubscriptionPlans();
```

### Check Subscription Status
```dart
final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
if (subscriptionProvider.hasActiveSubscription) {
  // Premium user logic
} else {
  // Free user logic
}
```

### Enforce Daily Limits
```dart
final matchingProvider = Provider.of<MatchingProvider>(context);
if (!matchingProvider.canSelectMore) {
  // Show upgrade prompt or limit message
}
```

## Testing

Run the subscription integration tests:
```bash
flutter test test/subscription_integration_test.dart
```

## Notes

- The system is designed to work with or without RevenueCat (fallback to API-only)
- Subscription status is cached and automatically refreshed
- UI components are non-intrusive and follow the specifications
- All subscription features are backwards compatible with existing code

## RevenueCat Configuration Checklist

- [ ] Add RevenueCat API key
- [ ] Configure subscription products
- [ ] Set up webhooks for subscription events
- [ ] Test purchase flow on iOS and Android
- [ ] Verify receipt validation in backend
- [ ] Test subscription management (cancel/restore)

For more details, see the specifications.md file and API documentation.