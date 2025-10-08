# Real-Time Chat Component - Implementation Documentation

## Overview

This implementation adds comprehensive real-time chat features to the GoldWen app, including:
- **Typing Indicators**: Shows when the other user is typing with a 3-second timeout
- **Read Receipts**: Visual checkmarks indicating message delivery and read status
- **Online/Offline Status**: Green dot for online users with "last seen" timestamps
- **WebSocket Integration**: Real-time event handling via socket.io
- **REST Fallback**: HTTP endpoints for marking messages as read when WebSocket is unavailable

## Architecture

### Models (`lib/core/models/chat.dart`)

#### TypingStatus
```dart
class TypingStatus {
  final String userId;
  final String conversationId;
  final bool isTyping;
  final DateTime timestamp;
  
  bool get isRecent; // Returns true if within 5 seconds
}
```

#### OnlineStatus
```dart
class OnlineStatus {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeenAt;
  
  String getLastSeenText(); // "En ligne", "Vu il y a X min", etc.
}
```

### Services

#### WebSocketService (`lib/core/services/websocket_service.dart`)
Handles all real-time communication:
- `messageStream`: New message events
- `typingStream`: Typing indicator events
- `readReceiptStream`: Read receipt events
- `onlineStatusStream`: Online/offline status events
- `connectionStream`: WebSocket connection status

#### ApiService (`lib/core/services/api_service.dart`)
REST fallback endpoint:
- `markMessagesAsRead(String chatId)`: HTTP PUT to mark messages as read

### Provider (`lib/features/chat/providers/chat_provider.dart`)

#### Typing Indicator Methods
```dart
void startTyping(String chatId);  // Triggers typing event with 3s auto-timeout
void stopTyping(String chatId);   // Explicitly stops typing indicator
```

#### Online Status Methods
```dart
OnlineStatus? getOnlineStatus(String userId);
bool isUserOnline(String userId);
```

#### Read Receipt Methods
```dart
Future<void> markMessagesAsRead(String chatId);
```

### UI Components

#### TypingIndicator Widget (`lib/features/chat/widgets/typing_indicator.dart`)
Displays animated dots with user name: "Sophie écrit..."
- Animated three-dot indicator
- Customizable appearance
- Automatically scales for different screen sizes

#### OnlineStatusIndicator Widget (`lib/features/chat/widgets/online_status_indicator.dart`)
Shows online status with colored dot and text:
- Green pulsing dot for online users
- Gray dot for offline users
- Smart "last seen" text formatting
- Compact mode option

## WebSocket Events

### Outgoing Events (Frontend → Backend)

#### Start Typing
```json
{
  "type": "typing",
  "chatId": "conv123"
}
```

#### Stop Typing
```json
{
  "type": "stopped_typing",
  "chatId": "conv123"
}
```

#### Mark as Read
```json
{
  "type": "mark_read",
  "chatId": "conv123",
  "messageId": "msg456"
}
```

### Incoming Events (Backend → Frontend)

#### User Typing
```json
{
  "type": "user_typing",
  "conversationId": "conv123",
  "userId": "user456",
  "isTyping": true,
  "timestamp": "2025-01-15T14:30:00Z"
}
```

#### User Online
```json
{
  "type": "user_online",
  "userId": "user456",
  "isOnline": true,
  "lastSeenAt": "2025-01-15T14:30:00Z"
}
```

#### Message Read
```json
{
  "type": "message_read",
  "chatId": "conv123",
  "messageId": "msg456",
  "readAt": "2025-01-15T14:30:00Z"
}
```

## Usage Examples

### Initialize Chat with Real-Time Features

```dart
// In your chat page initState or provider initialization
final chatProvider = Provider.of<ChatProvider>(context, listen: false);
await chatProvider.initializeWebSocket(authToken);
```

### Display Typing Indicator

```dart
Consumer<ChatProvider>(
  builder: (context, chatProvider, child) {
    final otherUserId = getOtherUserId();
    
    if (chatProvider.isUserTyping(chatId, otherUserId)) {
      return TypingIndicator(
        userName: otherUser.firstName,
      );
    }
    return const SizedBox.shrink();
  },
)
```

### Display Online Status

```dart
Consumer<ChatProvider>(
  builder: (context, chatProvider, child) {
    final onlineStatus = chatProvider.getOnlineStatus(otherUserId);
    
    return OnlineStatusIndicator(
      status: onlineStatus,
      showText: true,
      compact: false,
    );
  },
)
```

### Trigger Typing Events

```dart
TextField(
  onChanged: (text) {
    if (text.isNotEmpty) {
      chatProvider.startTyping(chatId);
    } else {
      chatProvider.stopTyping(chatId);
    }
  },
)
```

### Display Read Receipts

```dart
// In message bubble widget
Row(
  children: [
    Text(timestamp),
    if (isFromCurrentUser) ...[
      SizedBox(width: 4),
      Icon(
        message.isRead ? Icons.done_all : Icons.done,
        size: 14,
        color: message.isRead ? Colors.lightBlue : Colors.grey,
      ),
    ],
  ],
)
```

## Testing

### Unit Tests
- `test/real_time_chat_features_test.dart`: Tests for OnlineStatus and TypingStatus models
- `test/chat_provider_realtime_test.dart`: Tests for ChatProvider real-time methods

### Widget Tests
- `test/real_time_chat_widgets_test.dart`: Tests for UI components

### Integration Tests
Run all tests:
```bash
flutter test test/real_time_chat_features_test.dart
flutter test test/chat_provider_realtime_test.dart
flutter test test/real_time_chat_widgets_test.dart
```

## Performance Considerations

1. **Typing Timeout**: Automatic 3-second timeout prevents unnecessary WebSocket traffic
2. **Recent Status Check**: TypingStatus.isRecent ensures old typing indicators don't display
3. **Stream Controllers**: Broadcast streams allow multiple listeners without duplication
4. **Lazy Loading**: Online status only fetched for visible conversations

## Mobile Responsiveness

All components are designed to be responsive:
- Compact mode for small screens
- Touch-friendly hit targets
- Adaptive text sizing
- Efficient animations (60 FPS)

## Accessibility

- Semantic labels for screen readers
- Sufficient color contrast ratios
- Keyboard navigation support
- ARIA-compatible status updates

## Backend Compatibility

Works with the backend implementation described in:
- `main-api/BACKEND_ISSUES_READY.md` (Issue #7)
- `FRONTEND_BACKEND_PROCESSES.md`

Backend events expected:
- `start_typing` / `stop_typing`
- `mark_read`
- `user_online` / `user_offline`
- `user_typing` / `user_stopped_typing`
- `message_read`

## Troubleshooting

### Typing indicator not showing
1. Check WebSocket connection status: `chatProvider.isWebSocketConnected`
2. Verify typing events are being sent/received
3. Ensure TypingStatus timestamp is recent (< 5 seconds)

### Read receipts not updating
1. Try REST fallback: `chatProvider.markMessagesAsRead(chatId)`
2. Check WebSocket `message_read` events in browser console
3. Verify message IDs match between frontend and backend

### Online status not updating
1. Ensure WebSocket connection is established
2. Check `user_online` / `user_offline` events
3. Verify userId mapping is correct

## Future Enhancements

Potential improvements for v2:
- Voice message indicators
- File transfer progress
- Reaction animations
- Group chat typing indicators (multiple users)
- Presence heartbeat optimization
