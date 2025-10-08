# Push Notifications Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GOLDWEN APP FRONTEND                         │
│                     Push Notifications System                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                           EXTERNAL SYSTEMS                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────┐         ┌──────────────────────┐          │
│  │  Firebase Cloud      │         │   Backend API        │          │
│  │  Messaging (FCM)     │         │   (main-api)         │          │
│  │                      │         │                      │          │
│  │  - Push delivery     │         │  - Token storage     │          │
│  │  - Token validation  │◄────────┤  - Notification API  │          │
│  │  - Topic management  │         │  - Settings sync     │          │
│  └──────────┬───────────┘         └──────────┬───────────┘          │
│             │                                 │                      │
└─────────────┼─────────────────────────────────┼──────────────────────┘
              │                                 │
              │ Push Notifications              │ HTTP/WebSocket
              │                                 │
┌─────────────▼─────────────────────────────────▼──────────────────────┐
│                    MOBILE/WEB APPLICATION                             │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              INITIALIZATION LAYER                           │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                                                             │    │
│  │  AppInitializationService                                  │    │
│  │  ├── Initialize Firebase Core                             │    │
│  │  ├── Initialize Local Notifications                        │    │
│  │  └── Initialize Firebase Messaging                         │    │
│  │                                                             │    │
│  └───────────────────────┬─────────────────────────────────────┘    │
│                          │                                           │
│  ┌───────────────────────▼─────────────────────────────────────┐    │
│  │              SERVICE LAYER                                  │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                                                             │    │
│  │  ┌──────────────────────────────────────────────────────┐  │    │
│  │  │  FirebaseMessagingService                            │  │    │
│  │  ├──────────────────────────────────────────────────────┤  │    │
│  │  │  • Get device token                                  │  │    │
│  │  │  • Register token with backend                       │  │    │
│  │  │  • Handle foreground messages                        │  │    │
│  │  │  • Handle background messages                        │  │    │
│  │  │  • Handle notification opens                         │  │    │
│  │  │  • Listen for token refresh                          │  │    │
│  │  │  • Subscribe to topics                               │  │    │
│  │  └──────────────────────────────────────────────────────┘  │    │
│  │                          │                                  │    │
│  │  ┌──────────────────────▼──────────────────────────────┐  │    │
│  │  │  NotificationManager (Coordinator)                   │  │    │
│  │  ├──────────────────────────────────────────────────────┤  │    │
│  │  │  • Check user settings                               │  │    │
│  │  │  • Validate quiet hours                              │  │    │
│  │  │  • Choose notification service                       │  │    │
│  │  │  • Handle permissions                                │  │    │
│  │  └──────────────────┬───────────────┬───────────────────┘  │    │
│  │                     │               │                       │    │
│  │       ┌─────────────▼────────┐  ┌──▼──────────────────┐   │    │
│  │       │ LocalNotification    │  │ Navigation          │   │    │
│  │       │ Service              │  │ Service             │   │    │
│  │       ├──────────────────────┤  ├─────────────────────┤   │    │
│  │       │ • Daily scheduling   │  │ • Deep linking      │   │    │
│  │       │ • Instant notify     │  │ • Route navigation  │   │    │
│  │       │ • Timezone support   │  │ • Screen focus      │   │    │
│  │       │ • Channel mgmt       │  └─────────────────────┘   │    │
│  │       └──────────────────────┘                            │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│  ┌───────────────────────▼─────────────────────────────────────┐    │
│  │              STATE MANAGEMENT LAYER                         │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                                                             │    │
│  │  NotificationProvider (ChangeNotifier)                     │    │
│  │  ├─────────────────────────────────────────────────────┐  │    │
│  │  │  State:                                             │  │    │
│  │  │  • notifications: List<AppNotification>             │  │    │
│  │  │  • settings: NotificationSettings?                  │  │    │
│  │  │  • isLoading: bool                                  │  │    │
│  │  │  • error: String?                                   │  │    │
│  │  │  • unreadCount: int                                 │  │    │
│  │  ├─────────────────────────────────────────────────────┤  │    │
│  │  │  Methods:                                           │  │    │
│  │  │  • loadNotifications()                              │  │    │
│  │  │  • loadNotificationSettings()                       │  │    │
│  │  │  • markAsRead(id)                                   │  │    │
│  │  │  • markAllAsRead()                                  │  │    │
│  │  │  • deleteNotification(id)                           │  │    │
│  │  │  • updateNotificationSettings(settings)             │  │    │
│  │  │  • shouldShowNotification(type)                     │  │    │
│  │  └─────────────────────────────────────────────────────┘  │    │
│  │                                                             │    │
│  └───────────────────────┬─────────────────────────────────────┘    │
│                          │                                           │
│  ┌───────────────────────▼─────────────────────────────────────┐    │
│  │              USER INTERFACE LAYER                           │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                                                             │    │
│  │  NotificationsPage                                         │    │
│  │  ├─────────────────────────────────────────────────────┐  │    │
│  │  │  Tab 1: Unread Notifications                        │  │    │
│  │  │  • Display unread notifications                     │  │    │
│  │  │  • Swipe to dismiss                                 │  │    │
│  │  │  • Pull to refresh                                  │  │    │
│  │  │  • Tap to navigate                                  │  │    │
│  │  ├─────────────────────────────────────────────────────┤  │    │
│  │  │  Tab 2: All Notifications                           │  │    │
│  │  │  • Display all notifications                        │  │    │
│  │  │  • Pagination support                               │  │    │
│  │  │  • Mark all as read                                 │  │    │
│  │  ├─────────────────────────────────────────────────────┤  │    │
│  │  │  Tab 3: Settings                                    │  │    │
│  │  │  ┌───────────────────────────────────────────────┐ │  │    │
│  │  │  │ Notification Types:                          │ │  │    │
│  │  │  │  ☑ Daily Selection                           │ │  │    │
│  │  │  │  ☑ New Matches                               │ │  │    │
│  │  │  │  ☑ New Messages                              │ │  │    │
│  │  │  │  ☑ Chat Expiring                             │ │  │    │
│  │  │  ├───────────────────────────────────────────────┤ │  │    │
│  │  │  │ General Preferences:                         │ │  │    │
│  │  │  │  ☑ Push Enabled                              │ │  │    │
│  │  │  │  ☑ Email Enabled                             │ │  │    │
│  │  │  │  ☑ Sound                                     │ │  │    │
│  │  │  │  ☑ Vibration                                 │ │  │    │
│  │  │  ├───────────────────────────────────────────────┤ │  │    │
│  │  │  │ Quiet Hours:                                 │ │  │    │
│  │  │  │  Start: 22:00  |  End: 08:00                │ │  │    │
│  │  │  └───────────────────────────────────────────────┘ │  │    │
│  │  └─────────────────────────────────────────────────────┘  │    │
│  │                                                             │    │
│  │  NotificationTestPage (Debug Mode Only)                    │    │
│  │  ├─────────────────────────────────────────────────────┐  │    │
│  │  │  • Test Daily Selection                             │  │    │
│  │  │  • Test Match Notification                          │  │    │
│  │  │  • Test Message Notification                        │  │    │
│  │  │  • Test Chat Expiring                               │  │    │
│  │  │  • Schedule/Cancel Operations                       │  │    │
│  │  └─────────────────────────────────────────────────────┘  │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Notification Flow Diagrams

### Flow 1: Daily Selection Notification (Scheduled)

```
┌──────────────┐
│ 12:00 PM     │
│ Local Time   │
└──────┬───────┘
       │
       ▼
┌──────────────────────────┐
│ LocalNotificationService │
│ Scheduled Notification   │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐     ┌─────────────────┐
│ NotificationManager      │────►│ Check Settings  │
│ Check if should show     │     │ • dailySelection│
└──────┬───────────────────┘     │ • quietHours    │
       │                         │ • pushEnabled   │
       │ ✓ Allowed              └─────────────────┘
       ▼
┌──────────────────────────┐
│ Show Notification        │
│ "Votre sélection du      │
│  jour est arrivée!"      │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ User Taps Notification   │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ NavigationService        │
│ Navigate to /discover    │
└──────────────────────────┘
```

### Flow 2: Match Notification (Real-time)

```
┌──────────────────────────┐
│ Backend API              │
│ Detects Mutual Match     │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Firebase Cloud Messaging │
│ Send Push Notification   │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐     ┌──────────────────┐
│ FirebaseMessaging        │────►│ Foreground?      │
│ Service                  │     │ • Yes: Show local│
│ Receives FCM message     │     │ • No: System UI  │
└──────┬───────────────────┘     └──────────────────┘
       │
       ▼
┌──────────────────────────┐
│ NotificationManager      │
│ showNewMatchNotification │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐     ┌─────────────────┐
│ Check Settings           │────►│ newMatches: ✓   │
│ shouldShowNotification   │     │ quietHours: OK  │
└──────┬───────────────────┘     └─────────────────┘
       │ ✓ Allowed
       ▼
┌──────────────────────────┐
│ Show Notification        │
│ "Nouveau match!"         │
│ "...avec Sophie"         │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ User Taps                │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Deep Link to /matches    │
└──────────────────────────┘
```

### Flow 3: Message Notification (WebSocket)

```
┌──────────────────────────┐
│ Other User Sends Message │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ WebSocket Service        │
│ Receives message event   │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐     ┌──────────────────┐
│ ChatProvider             │────►│ Filter Self      │
│ Handle new message       │     │ Messages         │
└──────┬───────────────────┘     └──────────────────┘
       │ Not from self
       ▼
┌──────────────────────────┐
│ NotificationManager      │
│ showNewMessageNotif      │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐     ┌─────────────────┐
│ Check Settings           │────►│ newMessages: ✓  │
└──────┬───────────────────┘     └─────────────────┘
       │ ✓ Allowed
       ▼
┌──────────────────────────┐
│ Show Notification        │
│ "Nouveau message"        │
│ "Marc vous a envoyé..."  │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Deep Link to Chat        │
│ /chat/:conversationId    │
└──────────────────────────┘
```

### Flow 4: Settings Update

```
┌──────────────────────────┐
│ User Opens Settings      │
│ (Notifications Page)     │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ NotificationProvider     │
│ loadNotificationSettings │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Backend API              │
│ GET /notifications/      │
│     settings             │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Display Current Settings │
│ • All toggles            │
│ • Quiet hours            │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ User Toggles Setting     │
│ (e.g., Daily Selection)  │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ NotificationProvider     │
│ updateNotificationSettings│
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Backend API              │
│ PUT /notifications/      │
│     settings             │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ NotificationManager      │
│ onSettingsChanged        │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐     ┌──────────────────┐
│ If dailySelection OFF    │────►│ Cancel Scheduled │
│ If dailySelection ON     │────►│ Schedule New     │
└──────────────────────────┘     └──────────────────┘
```

## Data Models

### AppNotification Model

```dart
class AppNotification {
  final String id;              // Unique notification ID
  final String userId;          // User who receives notification
  final String type;            // Type: daily_selection, new_match, etc.
  final String title;           // Notification title
  final String body;            // Notification body
  final Map<String, dynamic>? data;  // Additional data
  final bool isRead;            // Read status
  final DateTime createdAt;     // Creation timestamp
  final DateTime? readAt;       // When marked as read
  final String? imageUrl;       // Optional image
  final String? actionUrl;      // Deep link URL

  // Computed properties
  bool get isDailySelection => type == 'daily_selection';
  bool get isNewMatch => type == 'new_match';
  bool get isNewMessage => type == 'new_message';
  bool get isChatExpiring => type == 'chat_expiring';
  
  String get timeAgo;  // "5m ago", "2h ago", etc.
}
```

### NotificationSettings Model

```dart
class NotificationSettings {
  // Notification type toggles
  final bool dailySelection;    // Daily profile selection
  final bool newMatches;        // Match notifications
  final bool newMessages;       // Message notifications
  final bool chatExpiring;      // Chat expiration warnings
  final bool promotions;        // Promotional notifications
  final bool systemUpdates;     // System updates
  
  // General preferences
  final bool pushEnabled;       // Master push toggle
  final bool emailEnabled;      // Email notifications
  final bool soundEnabled;      // Sound with notifications
  final bool vibrationEnabled;  // Vibration
  
  // Quiet hours
  final String quietHoursStart; // e.g., "22:00"
  final String quietHoursEnd;   // e.g., "08:00"
  
  final String emailFrequency;  // 'daily', 'weekly', 'never'
  
  // Computed property
  bool get isInQuietHours;      // Check if currently in quiet hours
}
```

## Platform-Specific Details

### Android Architecture

```
┌─────────────────────────────────────────┐
│ AndroidManifest.xml                     │
├─────────────────────────────────────────┤
│ Permissions:                            │
│ • INTERNET                              │
│ • RECEIVE_BOOT_COMPLETED               │
│ • VIBRATE                               │
│ • WAKE_LOCK                             │
│ • POST_NOTIFICATIONS                    │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ google-services.json                    │
├─────────────────────────────────────────┤
│ • Project configuration                 │
│ • API keys                              │
│ • Client IDs                            │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ Notification Channels                   │
├─────────────────────────────────────────┤
│ • daily_selection (High priority)       │
│ • matches (High priority)               │
│ • messages (High priority)              │
│ • general (Default priority)            │
└─────────────────────────────────────────┘
```

### iOS Architecture

```
┌─────────────────────────────────────────┐
│ Info.plist                              │
├─────────────────────────────────────────┤
│ UIBackgroundModes:                      │
│ • fetch                                 │
│ • remote-notification                   │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ GoogleService-Info.plist                │
├─────────────────────────────────────────┤
│ • Project configuration                 │
│ • API keys                              │
│ • Bundle ID                             │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ Xcode Capabilities                      │
├─────────────────────────────────────────┤
│ • Push Notifications                    │
│ • Background Modes                      │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ APNs Certificate (in Firebase)          │
├─────────────────────────────────────────┤
│ • .p8 authentication key                │
│ • Key ID                                │
│ • Team ID                               │
└─────────────────────────────────────────┘
```

### Web Architecture

```
┌─────────────────────────────────────────┐
│ index.html                              │
├─────────────────────────────────────────┤
│ Firebase SDK Scripts:                   │
│ • firebase-app-compat.js                │
│ • firebase-messaging-compat.js          │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ firebase-messaging-sw.js                │
├─────────────────────────────────────────┤
│ • Service worker registration           │
│ • Background message handler            │
│ • Notification click handler            │
│ • Deep linking logic                    │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ VAPID Key (in Firebase Console)         │
├─────────────────────────────────────────┤
│ • Web push certificate                  │
│ • Browser subscription                  │
└─────────────────────────────────────────┘
```

## API Endpoints Integration

```
┌───────────────────────────────────────────────────────┐
│              BACKEND API ENDPOINTS                    │
├───────────────────────────────────────────────────────┤
│                                                       │
│  Token Management:                                    │
│  POST   /users/me/push-tokens                        │
│  DELETE /users/me/push-tokens                        │
│                                                       │
│  Notifications:                                       │
│  GET    /notifications                               │
│  PUT    /notifications/:id/read                      │
│  PUT    /notifications/read-all                      │
│  DELETE /notifications/:id                           │
│                                                       │
│  Settings:                                            │
│  GET    /notifications/settings                      │
│  PUT    /notifications/settings                      │
│                                                       │
│  Testing (Developer Only):                            │
│  POST   /notifications/test                          │
│  POST   /notifications/trigger-daily-selection       │
│  POST   /notifications/send-group                    │
│                                                       │
└───────────────────────────────────────────────────────┘
```

## Security Flow

```
┌──────────────────────────┐
│ App Launch               │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Request Permissions      │
│ (iOS/Android/Web)        │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Get FCM Token            │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐     ┌─────────────────────┐
│ Register with Backend    │────►│ Encrypted Storage   │
│ POST /users/me/          │     │ • Token stored      │
│      push-tokens         │     │ • User associated   │
└──────┬───────────────────┘     └─────────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Token Refresh Listener   │
│ (Automatic)              │
└──────┬───────────────────┘
       │
       │ On Token Refresh
       ▼
┌──────────────────────────┐
│ Update Backend           │
│ (New token registered)   │
└──────┬───────────────────┘
       │
       │ On Logout
       ▼
┌──────────────────────────┐
│ Delete Token             │
│ DELETE /users/me/        │
│        push-tokens       │
└──────────────────────────┘
```

---

**Note**: This diagram represents the complete push notifications architecture for the GoldWen app. All components are implemented and ready for testing.
