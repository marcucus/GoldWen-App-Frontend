# Backend Integration Documentation

This document outlines the comprehensive backend integration implemented for the GoldWen dating app.

## Overview

The backend integration provides full API coverage for all features documented in `API_ROUTES.md`, including:

- Complete REST API integration
- Real-time chat via WebSocket
- External matching service integration
- Comprehensive error handling
- Type-safe data models

## Architecture

### Services Layer

#### 1. ApiService (`lib/core/services/api_service.dart`)
Main REST API service that handles all HTTP requests to the backend.

**Features:**
- Token management
- Comprehensive error handling
- All API endpoints from API_ROUTES.md
- Request/response logging support

**Endpoints covered:**
- Authentication (login, register, social login, password reset)
- User management (profile, settings, stats)
- Profile management (photos, personality, prompts)
- Matching system (daily selection, compatibility)
- Chat and messaging
- Subscriptions and payments
- Notifications
- Admin functions

#### 2. MatchingServiceApi (`lib/core/services/api_service.dart`)
Separate service for the external Python matching service.

**Features:**
- External API key authentication
- Compatibility calculations
- Daily selection generation
- Batch processing

#### 3. WebSocketService (`lib/core/services/websocket_service.dart`)
Real-time communication service for chat functionality.

**Features:**
- Real-time messaging
- Typing indicators
- Read receipts
- Connection management
- Automatic reconnection

### Models Layer

#### Data Models (`lib/core/models/`)
Type-safe data models for all API responses.

- **User Models**: User, UserStats
- **Profile Models**: Profile, Photo, PersonalityAnswer, PromptAnswer, PersonalityQuestion, Prompt
- **Matching Models**: Match, DailySelection, CompatibilityResult
- **Chat Models**: Conversation, ChatMessage, TypingStatus
- **Subscription Models**: Subscription, SubscriptionPlan, SubscriptionUsage
- **Notification Models**: AppNotification, NotificationSettings

### Providers Layer

#### 1. AuthProvider (`lib/features/auth/providers/auth_provider.dart`)
Manages user authentication and account operations.

**Features:**
- Email/password authentication
- Social login (Google, Apple)
- Password reset/change
- Account management
- Token persistence

#### 2. MatchingProvider (`lib/features/matching/providers/matching_provider.dart`)
Handles matching and daily selection functionality.

**Features:**
- Daily profile selection
- Match management
- Compatibility calculations
- Subscription usage tracking

#### 3. ChatProvider (`lib/features/chat/providers/chat_provider.dart`)
Manages chat conversations and messaging.

**Features:**
- Real-time messaging via WebSocket
- Message history
- Typing indicators
- Chat expiration
- Unread message tracking

#### 4. SubscriptionProvider (`lib/features/subscription/providers/subscription_provider.dart`)
Handles subscription and payment management.

**Features:**
- Subscription plans
- Purchase processing
- Receipt verification
- Usage tracking
- Feature access control

#### 5. NotificationProvider (`lib/features/notifications/providers/notification_provider.dart`)
Manages push notifications and settings.

**Features:**
- Notification history
- Settings management
- Real-time updates
- Badge counting

## Configuration

### AppConfig (`lib/core/config/app_config.dart`)
Centralized configuration management.

**Settings:**
- API endpoints
- Timeouts
- Feature flags
- Environment detection

## Error Handling

### ApiException
Comprehensive error handling with specific error types:

- Authentication errors (401)
- Validation errors (400, 422)
- Not found errors (404)
- Server errors (500+)
- Network errors

### Error Recovery
- Automatic token refresh
- Retry logic for network failures
- Graceful degradation for non-critical features

## Usage Examples

### Authentication
```dart
// Login
await authProvider.signInWithEmail(
  email: 'user@example.com',
  password: 'password',
);

// Register
await authProvider.registerWithEmail(
  email: 'user@example.com',
  password: 'password',
  firstName: 'John',
  lastName: 'Doe',
);

// Social login
await authProvider.signInWithGoogle();
```

### Matching
```dart
// Load daily selection
await matchingProvider.loadDailySelection();

// Select a profile
final success = await matchingProvider.selectProfile('profile_id');

// Get compatibility score
final compatibility = await matchingProvider.getCompatibility('profile_id');
```

### Chat
```dart
// Initialize WebSocket
await chatProvider.initializeWebSocket(token);

// Load conversations
await chatProvider.loadConversations();

// Send message
await chatProvider.sendMessage('chat_id', 'Hello!');

// Start typing indicator
chatProvider.startTyping('chat_id');
```

### Subscriptions
```dart
// Load plans
await subscriptionProvider.loadSubscriptionPlans();

// Purchase subscription
final success = await subscriptionProvider.purchaseSubscription(
  planId: 'goldwen_plus',
  platform: 'ios',
  receiptData: receiptData,
);
```

### Notifications
```dart
// Load notifications
await notificationProvider.loadNotifications();

// Mark as read
await notificationProvider.markAsRead('notification_id');

// Update settings
await notificationProvider.updateNotificationSettings(newSettings);
```

## Testing

### Test Coverage (`test/api_service_test.dart`)
Comprehensive test suite covering:

- API service functionality
- Model serialization/deserialization
- Error handling
- Provider integration
- WebSocket connectivity

### Running Tests
```bash
flutter test
```

## Security Considerations

1. **Token Management**: Secure JWT token storage and automatic refresh
2. **API Key Protection**: External service API keys are configurable
3. **Input Validation**: Client-side validation with server-side verification
4. **Error Information**: Sensitive information is not exposed in error messages

## Performance Optimizations

1. **Lazy Loading**: Data is loaded on-demand
2. **Caching**: Appropriate caching for static data
3. **Pagination**: Large datasets use pagination
4. **WebSocket Optimization**: Efficient real-time communication

## Monitoring and Logging

1. **Error Tracking**: All errors are caught and can be sent to crash reporting
2. **Network Logging**: API requests/responses can be logged for debugging
3. **Performance Metrics**: Response times and success rates can be tracked

## Future Enhancements

1. **Offline Support**: Cache data for offline functionality
2. **Push Notifications**: Firebase Cloud Messaging integration
3. **Advanced Caching**: Redis-like caching strategies
4. **Analytics**: User behavior tracking and analytics

## Development Guidelines

### Adding New API Endpoints

1. Add the endpoint method to `ApiService`
2. Create/update model classes as needed
3. Update the relevant provider
4. Add tests
5. Update documentation

### Error Handling Best Practices

1. Always use try-catch blocks
2. Provide user-friendly error messages
3. Log technical details for debugging
4. Implement appropriate fallbacks

### Code Organization

- Keep services focused and single-purpose
- Use consistent naming conventions
- Document complex business logic
- Maintain separation of concerns

## Support

For questions or issues related to the backend integration:

1. Check the API documentation in `API_ROUTES.md`
2. Review the error logs
3. Test with the provided test suite
4. Refer to this documentation for usage examples