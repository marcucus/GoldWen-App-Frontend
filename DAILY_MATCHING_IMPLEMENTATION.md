# Daily Matching Ritual Implementation

This document describes the implementation of the daily matching ritual feature according to the specifications in `specifications.md`.

## Overview

The daily matching ritual is the core feature of GoldWen that implements the "slow dating" approach by providing users with a limited number of high-quality profile matches each day.

## Features Implemented

### 1. Daily Profile Selection Display
- **Location**: `lib/features/matching/pages/daily_matches_page.dart`
- **API Integration**: Uses `GET /matching/daily-selection` endpoint
- **UI**: Clean card-based interface displaying 3-5 profiles per day
- **States**: Loading, error, empty, profile display, and selection complete states

### 2. Profile Selection with Subscription Limits
- **Free Users**: 1 profile selection per day
- **Premium Users**: Up to 3 profile selections per day (GoldWen Plus)
- **API Integration**: Uses `POST /matching/choose/:profileId` endpoint
- **Confirmation Dialog**: Shows remaining selections and confirmation before final choice

### 3. Smart UI Updates
- **Profile Hiding**: Selected profiles are automatically hidden from the list
- **Selection Counter**: Real-time display of remaining selections
- **Completion State**: Special UI when all selections are used
- **Subscription Prompts**: Encourages upgrade when limits are reached

### 4. Daily Notification System
- **Schedule**: Automatic notification at 12:00 PM daily (local time)
- **Message**: "Votre sélection GoldWen du jour est arrivée !"
- **Implementation**: `LocalNotificationService` with timezone-aware scheduling
- **Match Notifications**: Instant notifications when profile selection results in a match

## Technical Architecture

### Core Components

1. **MatchingProvider** (`lib/features/matching/providers/matching_provider.dart`)
   - State management for daily selections
   - API integration for profile loading and selection
   - Subscription usage tracking
   - Notification scheduling

2. **DailyMatchesPage** (`lib/features/matching/pages/daily_matches_page.dart`)
   - Main UI for daily matching ritual
   - Profile card display
   - Selection confirmation dialogs
   - State-based UI rendering

3. **LocalNotificationService** (`lib/core/services/local_notification_service.dart`)
   - Daily notification scheduling at noon
   - Match and message notifications
   - Permission handling
   - Cross-platform notification support

### Data Flow

1. **App Initialization**
   - Notification service is initialized
   - Daily notification is scheduled for 12:00 PM
   - Permissions are requested

2. **Daily Selection Loading**
   - User opens the daily matches page
   - `MatchingProvider.loadDailySelection()` is called
   - API fetches 3-5 profiles based on compatibility
   - Subscription usage limits are loaded

3. **Profile Selection**
   - User taps "Choisir" on a profile
   - Confirmation dialog shows remaining selections
   - `MatchingProvider.selectProfile()` is called
   - API processes the selection and checks for mutual match
   - If match occurs, instant notification is shown
   - UI updates to hide selected profile

4. **Selection Complete**
   - When all selections are used, special completion UI is shown
   - Users are encouraged to upgrade for more selections
   - Next day's notification is automatically scheduled

## API Integration

### Endpoints Used

1. **GET /matching/daily-selection**
   - Fetches daily profile selection
   - Returns 3-5 profiles with compatibility scores
   - Includes user's remaining selection count

2. **POST /matching/choose/:profileId**
   - Registers user's profile selection
   - Returns match status if mutual interest exists
   - Updates user's daily selection usage

3. **GET /subscriptions/usage** (via ApiService)
   - Fetches subscription limits and usage
   - Determines daily selection limits (1 for free, 3 for premium)

## Notification Implementation

### Daily Notifications
- **Timing**: 12:00 PM local time daily
- **Content**: "Votre sélection GoldWen du jour est arrivée !"
- **Action**: Opens daily matches page when tapped
- **Scheduling**: Uses `flutter_local_notifications` with timezone support

### Match Notifications
- **Trigger**: Immediate when profile selection results in mutual match
- **Content**: "Nouveau match ! Félicitations ! Vous avez un match avec [Name]"
- **Action**: Opens matches/chat page

## Compliance with Specifications

### Module 4.2: Le Rituel Quotidien et le Matching

✅ **Daily 12:00 PM Notification**: Implemented with `LocalNotificationService`

✅ **Limited Profile Display**: 3-5 profiles displayed in card format

✅ **Single Selection for Free Users**: Enforced through subscription checking

✅ **Selection Confirmation and UI Updates**: Confirmation dialog + profile hiding

✅ **Persistent Selection Until Midnight**: Selections remain until next day's refresh

### Module 4.4: Monétisation (GoldWen Plus)

✅ **Subscription Limit Display**: Clear indication of remaining selections

✅ **Premium User Benefits**: Up to 3 selections for GoldWen Plus subscribers

✅ **Upgrade Prompts**: Non-intrusive banners promoting GoldWen Plus

## Testing

### Unit Tests
- `test/matching_provider_test.dart`: Provider state management
- `test/daily_matches_page_test.dart`: Widget rendering and interactions
- `test/daily_matching_workflow_test.dart`: End-to-end workflow validation

### Test Coverage
- Initial state verification
- Loading and error states
- Profile selection logic
- Subscription limit enforcement
- Notification scheduling
- UI state transitions

## Future Enhancements

1. **Advanced Filtering**: Allow premium users to filter daily selections
2. **Profile Analytics**: Track selection patterns and improve recommendations
3. **Customizable Notification Time**: Allow users to choose notification timing
4. **Weekend Specials**: Special selection bonuses for premium users
5. **Social Features**: Share anonymized compatibility insights

## Dependencies Added

- `timezone: ^0.9.4`: For timezone-aware notification scheduling
- Uses existing: `flutter_local_notifications: ^19.4.1`

## Configuration Notes

### Android
- Requires notification permissions in `android/app/src/main/AndroidManifest.xml`
- Uses `@mipmap/ic_launcher` for notification icon

### iOS
- Requires notification permissions through `DarwinInitializationSettings`
- Handles permission requests automatically

## Troubleshooting

### Common Issues

1. **Notifications Not Working**
   - Check permissions are granted
   - Verify timezone initialization
   - Ensure device allows scheduled notifications

2. **Profile Selection Fails**
   - Verify API connectivity
   - Check subscription usage limits
   - Ensure profile ID is valid

3. **UI Not Updating**
   - Check `MatchingProvider` is properly provided in widget tree
   - Verify `notifyListeners()` is called after state changes
   - Ensure proper Consumer widgets are used

### Debug Information

Enable debug logging by setting:
```dart
// In LocalNotificationService
print('Failed to schedule daily notifications: $e');
```

## Performance Considerations

- Profile images are cached using `cached_network_image`
- API calls are debounced to prevent excessive requests
- Notifications are scheduled efficiently without battery drain
- UI animations are optimized for smooth performance

---

This implementation fully satisfies the requirements specified in `specifications.md` for the daily matching ritual, providing a premium user experience that encourages meaningful connections through the "slow dating" approach.