# Email Notification Management Feature

## Overview

This feature provides a complete UI for managing transactional email notifications in the GoldWen app. Users can view the history of all transactional emails sent to them, check their delivery status, and retry failed emails.

## Features

### 1. Email Types Supported
- **Welcome Email**: Sent when a user creates an account
- **Data Export Ready**: Sent when user data export is ready for download
- **Account Deleted**: Confirmation email when account is deleted
- **Subscription Confirmed**: Confirmation of subscription purchase or renewal
- **Password Reset**: Sent when user requests password reset
- **Other**: Generic transactional emails

### 2. Email Status Tracking
- **Pending**: Email is queued for sending
- **Sent**: Email has been sent to the mail server
- **Delivered**: Email successfully delivered to recipient
- **Failed**: Email sending failed
- **Bounced**: Email bounced back (invalid recipient, full mailbox, etc.)

### 3. User Interface Components

#### Email History Page
- **Location**: Settings > Historique des emails
- **Features**:
  - Tabbed interface (All, Failed, Pending)
  - Pull-to-refresh functionality
  - Infinite scroll for loading more emails
  - Email status badges with color coding
  - Detailed email information modal

#### Email Cards
Each email is displayed in a card showing:
- Email type icon
- Subject line
- Recipient email address
- Status badge
- Timestamp
- Error message (if failed)
- Retry button (if eligible)

#### Email Details Sheet
Tapping on an email shows a bottom sheet with:
- Full email details
- Complete timestamps (created, sent, delivered)
- Error details (if applicable)
- Formatted date/time display

### 4. Error Handling
- User-friendly error messages
- Retry functionality for failed emails
- Visual indicators for different error states
- Support contact information in error cases

## Implementation Details

### Models

#### `EmailNotification` (`lib/core/models/email_notification.dart`)
```dart
class EmailNotification {
  final String id;
  final EmailType type;
  final EmailStatus status;
  final String recipient;
  final String subject;
  final DateTime createdAt;
  final String? errorMessage;
  final bool canRetry;
  // ... additional fields
}
```

### Provider

#### `EmailNotificationProvider` (`lib/features/settings/providers/email_notification_provider.dart`)
Manages the state for email notifications:
- Loading email history
- Filtering by type and status
- Retry failed emails
- Pagination support
- Error handling

Key methods:
- `loadEmailHistory()`: Fetches email history from API
- `retryEmail(emailId)`: Retries sending a failed email
- `getEmailDetails(emailId)`: Gets detailed information about an email
- `refresh()`: Refreshes the email list

### API Endpoints

The following API endpoints are expected on the backend:

1. **GET** `/api/v1/users/me/email-history`
   - Query params: `page`, `limit`, `type`, `status`
   - Returns: List of email notifications

2. **GET** `/api/v1/users/me/email-history/:emailId`
   - Returns: Detailed email information

3. **POST** `/api/v1/users/me/email-history/:emailId/retry`
   - Retries sending a failed email
   - Returns: Updated email status

### Widgets

#### `EmailNotificationCard` (`lib/features/settings/widgets/email_notification_card.dart`)
Displays individual email in a list with:
- Type icon and name
- Status badge
- Subject and recipient
- Error message display
- Retry button

#### `EmailHistoryPage` (`lib/features/settings/pages/email_history_page.dart`)
Main page for email history with:
- TabBar for filtering
- List view with cards
- Pull-to-refresh
- Pagination
- Empty states

## Usage

### For Developers

1. **Add to app providers** (already done in `main.dart`):
```dart
ChangeNotifierProvider(
  create: (_) => EmailNotificationProvider(),
),
```

2. **Access in widgets**:
```dart
final emailProvider = context.read<EmailNotificationProvider>();
await emailProvider.loadEmailHistory();
```

3. **Navigate to email history**:
```dart
context.go('/email-history');
```

### For Users

1. Go to Settings (Profil & Paramètres)
2. Tap on "Historique des emails"
3. View email history in tabs:
   - All: All emails
   - Failed: Only failed emails
   - Pending: Emails being sent
4. Tap on any email to see full details
5. For failed emails, tap "Retry Sending" to resend

## Testing

### Unit Tests
- `test/email_notification_test.dart`: Tests for EmailNotification model
- `test/email_notification_provider_test.dart`: Tests for provider logic

### Widget Tests
- `test/email_history_page_test.dart`: UI component tests

Run tests with:
```bash
flutter test test/email_notification_test.dart
flutter test test/email_notification_provider_test.dart
flutter test test/email_history_page_test.dart
```

## Backend Requirements

The backend should implement the following:

1. **Email Tracking**: Store all transactional emails in database with:
   - Type, recipient, subject, status
   - Timestamps for created, sent, delivered
   - Error messages for failed emails
   - Retry capability flag

2. **Email Service Integration**: Use SendGrid/Mailgun webhooks to update email status:
   - Track delivery events
   - Track bounce events
   - Track failure events

3. **API Endpoints**: Implement the three endpoints listed above

4. **Error Handling**: Provide clear error messages for common failures:
   - SMTP connection errors
   - Invalid recipient
   - Rate limiting
   - Temporary failures (retryable)
   - Permanent failures (non-retryable)

## Design Patterns

### SOLID Principles
- **Single Responsibility**: Each class has one clear purpose
- **Open/Closed**: Models are open for extension via copyWith
- **Liskov Substitution**: EmailNotification can be used anywhere expecting the interface
- **Interface Segregation**: Provider exposes minimal necessary interface
- **Dependency Inversion**: Depends on abstractions (ApiService)

### State Management
- Uses Provider pattern for reactive state updates
- Separation of concerns: Provider for logic, Widgets for UI
- Error handling at provider level with user-friendly messages

### Code Quality
- Type-safe enums for email types and statuses
- Null-safety throughout
- Comprehensive error handling
- Consistent naming conventions
- Well-documented code

## Future Enhancements

Potential improvements for future versions:

1. **Email Filtering**:
   - Filter by date range
   - Search by subject or recipient
   - Advanced filters (multiple criteria)

2. **Email Actions**:
   - Resend email to different address
   - View email content/preview
   - Download email as PDF

3. **Notifications**:
   - Push notification when email fails
   - Notification settings for email alerts

4. **Analytics**:
   - Email delivery rate charts
   - Most common error types
   - Delivery time statistics

5. **Bulk Operations**:
   - Retry all failed emails
   - Delete old emails
   - Export email history

## Accessibility

The feature includes:
- High contrast mode support via AppTheme
- Screen reader friendly labels
- Semantic structure for navigation
- Proper focus management
- Touch target sizes (minimum 48x48)

## Performance

Optimizations implemented:
- Pagination to avoid loading all emails at once
- Lazy loading on scroll
- Efficient state updates with ChangeNotifier
- Minimal rebuilds with Consumer widgets
- Cached email list in provider

## Security Considerations

- Email addresses are displayed but not editable
- No sensitive email content is shown in UI
- API calls use authenticated endpoints
- Email IDs are opaque (no sequential IDs exposed)

## Support

For issues or questions about this feature:
1. Check existing GitHub issues
2. Create new issue with label `email-notifications`
3. Contact support through the app's feedback feature

## Related Documentation

- [Backend Email Service Documentation](../../main-api/BACKEND_ISSUES_READY.md#issue-backend-11-service-email-transactionnel)
- [API Routes Documentation](../../main-api/API_ROUTES_DOCUMENTATION.md)
- [GoldWen Specifications](../../specifications.md)
