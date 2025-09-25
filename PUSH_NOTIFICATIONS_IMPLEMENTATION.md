# Push Notifications Implementation - GoldWen App Frontend

## Overview

This document describes the complete push notifications implementation for the GoldWen dating app, covering daily selection notifications, event-based notifications (matches, messages, chat expiration), and comprehensive user settings management.

## Architecture

### Core Components

1. **NotificationManager** (`lib/core/services/notification_manager.dart`)
   - Centralized coordinator for all notification operations
   - Respects user settings and quiet hours
   - Manages both local and push notifications

2. **FirebaseMessagingService** (`lib/core/services/firebase_messaging_service.dart`)
   - Handles Firebase Cloud Messaging (FCM) integration
   - Manages device token registration/removal
   - Processes background and foreground push notifications

3. **LocalNotificationService** (`lib/core/services/local_notification_service.dart`)
   - Manages local scheduled notifications
   - Handles daily selection reminders at 12:00 PM
   - Shows different notification types with appropriate styling

4. **NotificationProvider** (`lib/features/notifications/providers/notification_provider.dart`)
   - Manages notification settings and preferences
   - Provides methods to check if notifications should be shown
   - Handles backend API calls for notifications

## Features Implemented

### 1. Daily Selection Notifications
- **Timing**: Automatically scheduled for 12:00 PM local time
- **Recurrence**: Daily recurring notifications
- **Content**: "Votre sélection GoldWen du jour est arrivée !" with customizable message
- **User Control**: Can be disabled in notification settings
- **Implementation**: Uses timezone-aware scheduling via `flutter_local_notifications`

### 2. Event-Based Notifications

#### New Match Notifications
- **Trigger**: When a mutual match is detected in `MatchingProvider`
- **Content**: "Nouveau match ! Félicitations ! Vous avez un match avec [Name]"
- **Navigation**: Taps navigate to matches page
- **Timing**: Instant delivery

#### New Message Notifications
- **Trigger**: When receiving messages via WebSocket in real-time
- **Content**: "[SenderName] vous a envoyé un message"
- **Navigation**: Taps navigate to chat (implementation can be enhanced for specific chats)
- **Smart Logic**: Only shows for messages from other users, not self

#### Chat Expiring Notifications
- **Trigger**: WebSocket events for chat expiration warnings
- **Content**: "Il vous reste [X]h pour discuter avec [Name]"
- **Timing**: Configurable hours before expiration
- **Purpose**: Encourages engagement before conversation expires

### 3. Notification Settings Management
- **Daily Selection**: Enable/disable daily profile selection reminders
- **New Matches**: Control match notifications
- **New Messages**: Control message notifications  
- **Chat Expiring**: Control expiration warnings
- **Push Enabled**: Master toggle for all push notifications
- **Email Enabled**: Email notification preferences
- **Sound/Vibration**: Notification style preferences
- **Quiet Hours**: Configure silent periods (default: 22:00 - 08:00)

### 4. Backend API Integration

#### Push Token Management
- **Registration**: `POST /users/me/push-tokens`
  ```json
  {
    "token": "string",
    "platform": "ios|android", 
    "appVersion": "string",
    "deviceId": "string"
  }
  ```
- **Removal**: `DELETE /users/me/push-tokens`
  ```json
  {
    "token": "string"
  }
  ```

#### Notification Settings
- **Update**: `PUT /notifications/settings`
  ```json
  {
    "dailySelection": boolean,
    "newMatch": boolean,
    "newMessage": boolean,
    "chatExpiring": boolean,
    "subscription": boolean
  }
  ```

#### Developer Testing Tools
- **Test Notifications**: `POST /notifications/test`
- **Daily Selection Trigger**: `POST /notifications/trigger-daily-selection`
- **Group Notifications**: `POST /notifications/send-group`

## Implementation Details

### Notification Flow

1. **Initialization**
   ```dart
   // App startup
   await NotificationManager().initialize(context);
   await NotificationManager().requestPermissions();
   ```

2. **Settings-Aware Notifications**
   ```dart
   // Check settings before showing
   if (notificationProvider.shouldShowNotification('new_match')) {
     await NotificationManager().showNewMatchNotification(context, userName);
   }
   ```

3. **Daily Scheduling**
   ```dart
   // Schedule daily selection reminders
   await NotificationManager().scheduleDailySelectionNotifications(context);
   ```

### WebSocket Integration
- Real-time message notifications via WebSocket events
- Automatic notification filtering based on message sender
- Support for chat expiration events
- Centralized through `WebSocketService`

### User Experience Features
- **Smart Filtering**: Respects quiet hours and user preferences
- **Navigation**: Notifications navigate to relevant app sections
- **Testing Interface**: Comprehensive test page for developers
- **Settings UI**: User-friendly notification preferences panel
- **Immediate Feedback**: Real-time settings changes

## Security & Privacy

- **Token Security**: Device tokens are properly managed and cleaned up
- **User Control**: Complete user control over notification types
- **Data Minimization**: Only necessary data is sent with notifications
- **Settings Persistence**: User preferences are stored securely
- **No Vulnerabilities**: Passed CodeQL security analysis

## Testing

### Automated Tests
- **Provider Tests**: `test/notification_system_test.dart`
  - Notification loading and filtering
  - Settings management and updates
  - Time calculation utilities
  - Provider state management

### Manual Testing Tools
- **Test Page**: `lib/features/notifications/pages/notification_test_page.dart`
  - Test all notification types
  - Schedule/cancel operations
  - Backend API integration testing
  - Quick test buttons for each notification type

### Test Scenarios
1. **Daily Selection Flow**: Schedule → Show → Navigate → Settings Check
2. **Match Notification Flow**: Match Event → Notification → Navigation
3. **Message Notification Flow**: WebSocket → Filter → Show → Navigate
4. **Settings Changes**: Update → Backend Sync → Local Update → Schedule Changes
5. **Quiet Hours**: Time Check → Respect Settings → Show/Hide Logic

## Configuration

### Required Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-fetch</string>
    <string>background-processing</string>
</array>
```

### Firebase Setup
- FCM configured in `firebase_config.dart`
- Background message handler in `main.dart`
- Platform-specific push notification setup

## Future Enhancements

1. **Rich Notifications**: Support for images and actions
2. **Smart Scheduling**: Machine learning for optimal timing
3. **Advanced Filtering**: Location-based and context-aware filtering
4. **Analytics Integration**: Track notification engagement
5. **A/B Testing**: Test different notification content and timing
6. **Localization**: Multi-language notification support

## Dependencies

- `firebase_messaging: ^16.0.0` - Push notifications
- `flutter_local_notifications: ^19.4.1` - Local scheduling
- `timezone: ^0.10.1` - Timezone-aware scheduling
- `provider: ^6.1.1` - State management
- Standard Flutter dependencies

## API Compliance

The implementation follows the backend API specifications documented in `API_ROUTES_DOCUMENTATION.md`:
- ✅ GET /notifications (with pagination and filtering)
- ✅ PUT /notifications/:id/read
- ✅ PUT /notifications/read-all
- ✅ DELETE /notifications/:id
- ✅ PUT /notifications/settings
- ✅ POST /notifications/test
- ✅ POST /notifications/trigger-daily-selection
- ✅ POST /notifications/send-group
- ✅ POST /users/me/push-tokens
- ✅ DELETE /users/me/push-tokens

## Conclusion

This implementation provides a complete, user-friendly, and maintainable push notification system that meets all requirements specified in the issue. It supports both daily quotidian notifications and event-driven notifications while giving users full control over their notification experience.

The modular architecture allows for easy extension and maintenance, while the comprehensive testing ensures reliability. The integration with existing GoldWen app features (matching, chat, settings) provides a seamless user experience that encourages meaningful connections through timely, relevant notifications.