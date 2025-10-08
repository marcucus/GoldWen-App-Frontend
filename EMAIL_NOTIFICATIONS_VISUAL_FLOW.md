# Email Notification Feature - Visual Flow

## User Journey

```
┌─────────────────────────────────────────────────────────────┐
│                      Settings Page                          │
│  (Profil & Paramètres)                                      │
│                                                              │
│  ┌────────────────────────────────────────┐                 │
│  │ 👤 Profile Header                      │                 │
│  │    Name, Age, Bio, Stats               │                 │
│  └────────────────────────────────────────┘                 │
│                                                              │
│  ┌─ Paramètres ──────────────────────────┐                 │
│  │                                        │                 │
│  │  🔔 Notifications                      │                 │
│  │                                        │                 │
│  │  ✉️  Historique des emails   [NEW]   ─┼─────────┐       │
│  │     Consulter vos emails               │         │       │
│  │     transactionnels                    │         │       │
│  │                                        │         │       │
│  │  📍 Localisation                       │         │       │
│  │                                        │         │       │
│  │  🔒 Sécurité                           │         │       │
│  │                                        │         │       │
│  └────────────────────────────────────────┘         │       │
└─────────────────────────────────────────────────────┼───────┘
                                                      │
                                                      │ Navigate
                                                      │ to
                                                      │ /email-history
                                                      ▼
┌─────────────────────────────────────────────────────────────┐
│                   Email History Page                         │
│                                                              │
│  ← Back        Email History                                │
│                                                              │
│  ┌───────┬────────┬─────────┐                               │
│  │  All  │ Failed │ Pending │ ◄─── Tabs                     │
│  └───────┴────────┴─────────┘                               │
│                                                              │
│  ┌────────────────────────────────────────┐                 │
│  │ 👋 Welcome Email           ✓ Delivered │                 │
│  │ Welcome to GoldWen                     │                 │
│  │ ✉️  user@example.com      2h ago       │                 │
│  └────────────────────────────────────────┘                 │
│                                                              │
│  ┌────────────────────────────────────────┐                 │
│  │ 📥 Data Export Ready       ⏳ Pending   │                 │
│  │ Your data export is ready              │                 │
│  │ ✉️  user@example.com      5m ago       │                 │
│  └────────────────────────────────────────┘                 │
│                                                              │
│  ┌────────────────────────────────────────┐                 │
│  │ 🔐 Password Reset          ❌ Failed    │ ◄─ With error  │
│  │ Reset your password                    │                 │
│  │ ✉️  user@example.com      1d ago       │                 │
│  │ ┌────────────────────────────────────┐ │                 │
│  │ │ ⚠️  SMTP connection failed         │ │                 │
│  │ └────────────────────────────────────┘ │                 │
│  │ [ 🔄 Retry Sending ]                   │ ◄─ Action btn   │
│  └────────────────────────────────────────┘                 │
│                                                              │
│                ⬇️ Pull to refresh                            │
│                ⬇️ Scroll for more                            │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ Tap email card
                        │
                        ▼
            ┌──────────────────────────┐
            │  Email Detail Sheet      │
            │                          │
            │  👋 Welcome Email        │
            │     ✓ Delivered          │
            │                          │
            │  Subject: Welcome...     │
            │  Recipient: user@...     │
            │  Created: 15/01 10:00    │
            │  Sent: 15/01 10:01       │
            │  Delivered: 15/01 10:02  │
            │                          │
            └──────────────────────────┘
```

## Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Application                            │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │              MultiProvider (main.dart)             │     │
│  │                                                     │     │
│  │  • AuthProvider                                    │     │
│  │  • ProfileProvider                                 │     │
│  │  • NotificationProvider                            │     │
│  │  • EmailNotificationProvider    ◄───── NEW        │     │
│  │  • ...other providers                              │     │
│  └────────────────────────────────────────────────────┘     │
│                         │                                    │
│                         │ provides                           │
│                         ▼                                    │
│  ┌────────────────────────────────────────────────────┐     │
│  │           App Router (app_router.dart)             │     │
│  │                                                     │     │
│  │  Routes:                                           │     │
│  │    /settings      → SettingsPage                  │     │
│  │    /email-history → EmailHistoryPage  ◄─── NEW   │     │
│  │    /notifications → NotificationsPage             │     │
│  │    ...                                            │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

```
┌──────────────────┐
│   User Action    │
│  (View emails)   │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   EmailNotificationProvider         │
│                                     │
│   • loadEmailHistory()              │
│   • retryEmail()                    │
│   • getEmailDetails()               │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│      ApiService                     │
│                                     │
│   GET  /users/me/email-history     │
│   GET  /users/me/email-history/:id │
│   POST /users/me/email-history/:id/retry │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│      Backend API                    │
│   (Not part of this PR)             │
│                                     │
│   • Email tracking database         │
│   • SendGrid/Mailgun integration    │
│   • Webhook handlers                │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   Response Data                     │
│   EmailNotification models          │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   UI Update                         │
│                                     │
│   • EmailHistoryPage                │
│   • EmailNotificationCard           │
│   • EmailStatusSummary              │
└─────────────────────────────────────┘
```

## State Management

```
EmailNotificationProvider
│
├─ State Variables:
│  ├─ _emailHistory: List<EmailNotification>
│  ├─ _isLoading: bool
│  ├─ _error: String?
│  ├─ _currentPage: int
│  └─ _hasMore: bool
│
├─ Computed Getters:
│  ├─ emailHistory (all emails)
│  ├─ pendingEmails (filtered)
│  ├─ failedEmails (filtered)
│  ├─ successfulEmails (filtered)
│  ├─ failedEmailCount
│  └─ pendingEmailCount
│
└─ Actions:
   ├─ loadEmailHistory() → fetches from API
   ├─ loadMore() → pagination
   ├─ refresh() → pull to refresh
   ├─ retryEmail(id) → retry failed email
   └─ getEmailDetails(id) → fetch single email
```

## Email Status State Machine

```
    ┌─────────┐
    │ PENDING │
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │  SENT   │
    └────┬────┘
         │
         ├───────────┐
         │           │
         ▼           ▼
    ┌──────────┐  ┌─────────┐
    │DELIVERED │  │ FAILED  │
    └──────────┘  └────┬────┘
                       │
                       │ canRetry?
                       │
                       ├─ Yes ─► Back to PENDING (retry)
                       │
                       └─ No ──► BOUNCED (permanent)
```

## File Structure

```
lib/
├── core/
│   ├── models/
│   │   ├── email_notification.dart    ◄─── NEW (EmailNotification model)
│   │   └── models.dart                     (updated: export email model)
│   ├── services/
│   │   └── api_service.dart                (updated: +3 endpoints)
│   └── routes/
│       └── app_router.dart                 (updated: +1 route)
│
├── features/
│   └── settings/
│       ├── pages/
│       │   ├── email_history_page.dart  ◄─── NEW (main email history UI)
│       │   └── settings_page.dart           (updated: +menu item)
│       ├── providers/
│       │   └── email_notification_provider.dart  ◄─── NEW (state mgmt)
│       └── widgets/
│           ├── email_notification_card.dart      ◄─── NEW (email card)
│           └── email_status_summary.dart         ◄─── NEW (status widget)
│
└── main.dart                                     (updated: register provider)

test/
├── email_notification_test.dart          ◄─── NEW (model tests)
├── email_notification_provider_test.dart ◄─── NEW (provider tests)
└── email_history_page_test.dart          ◄─── NEW (widget tests)

docs/
├── EMAIL_NOTIFICATIONS_FEATURE.md              ◄─── NEW (feature guide)
└── IMPLEMENTATION_SUMMARY_EMAIL_NOTIFICATIONS.md ◄─── NEW (impl summary)
```

## Integration Points

### 1. Settings Page Menu
```dart
// settings_page.dart
_buildSettingItem(
  context,
  'Historique des emails',      // New menu item
  'Consulter vos emails transactionnels',
  Icons.email,
  () => context.go('/email-history'),  // Navigation
),
```

### 2. App Providers
```dart
// main.dart
ChangeNotifierProvider(
  create: (_) => EmailNotificationProvider(),  // New provider
),
```

### 3. Routes
```dart
// app_router.dart
GoRoute(
  path: '/email-history',           // New route
  name: 'email-history',
  builder: (context, state) => const EmailHistoryPage(),
),
```

### 4. API Service
```dart
// api_service.dart
static Future<Map<String, dynamic>> getEmailHistory({...}) {...}
static Future<Map<String, dynamic>> getEmailDetails(String emailId) {...}
static Future<Map<String, dynamic>> retryEmail(String emailId) {...}
```

## Key Features Implemented

✅ **Email History Display**
   - Tabbed interface (All/Failed/Pending)
   - Paginated list view
   - Status badges
   - Time stamps
   - Empty states

✅ **Error Handling**
   - Visual error indicators
   - Error messages
   - Retry functionality
   - User-friendly feedback

✅ **State Management**
   - Provider pattern
   - Reactive updates
   - Efficient filtering
   - Pagination support

✅ **Testing**
   - Unit tests (models)
   - Provider tests (logic)
   - Widget tests (UI)

✅ **Documentation**
   - Feature guide
   - API specifications
   - Usage examples
   - Implementation details

## Performance Considerations

- **Pagination**: Loads 20 emails per page (configurable)
- **Lazy Loading**: Infinite scroll triggers at 90% scroll
- **State Optimization**: Only rebuilds affected widgets
- **Caching**: Provider caches loaded emails
- **Pull-to-refresh**: Resets pagination and refreshes data

## Accessibility

- **Color Contrast**: Status colors meet WCAG AA standards
- **Touch Targets**: All interactive elements ≥ 48x48dp
- **Screen Readers**: Semantic labels on all widgets
- **Text Scaling**: Respects system font size settings
- **Focus Management**: Proper tab order for keyboard navigation
