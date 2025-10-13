# Chat Expiration - Quick Reference Guide

## For Developers

### Key Files
```
lib/features/chat/
├── providers/chat_provider.dart          # Core logic, notifications
├── pages/
│   ├── chat_page.dart                    # Chat UI with expiration
│   ├── chat_list_page.dart              # Active chats list
│   └── archived_chats_page.dart         # Archived chats (NEW)
└── widgets/
    └── chat_countdown_timer.dart        # Timer display widget

test/
└── chat_expiration_test.dart            # Unit tests

lib/core/
├── routes/app_router.dart               # Route configuration
└── services/
    └── local_notification_service.dart  # Notification handling
```

### Quick API Reference

#### Check if Chat is Expired
```dart
final chatProvider = Provider.of<ChatProvider>(context);
final isExpired = chatProvider.isChatExpired(chatId);
```

#### Get Remaining Time
```dart
final remainingTime = chatProvider.getRemainingTime(chatId);
if (remainingTime != null) {
  print('${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m remaining');
}
```

#### Get Active Conversations
```dart
final activeChats = chatProvider.activeConversations;
```

#### Get Archived Conversations
```dart
final archivedChats = chatProvider.archivedConversations;
```

#### Navigate to Archived Chats
```dart
context.push('/archived-chats');
```

#### Open Archived Chat (Read-Only)
```dart
context.push('/chat/$chatId?archived=true');
```

### Notification Flow

1. **Chat Loaded** → `_scheduleExpirationNotification()` called
2. **Timer Set** → Waits until 2h before expiration
3. **Notification Shown** → User sees warning
4. **Chat Expires** → Timer cancelled, chat archived

### UI States

#### Active Chat
- Green/gold timer indicator
- Input enabled
- Send button active
- No warning banner

#### Expiring Soon (< 2h)
- Red/orange timer indicator
- Notification sent (once)
- Input still enabled
- Countdown visible

#### Expired Chat
- Red timer (full)
- Input disabled
- "Cette conversation a expiré" message
- Chat moved to archived

#### Archived Chat View
- Archive banner at top
- "Lecture seule" indicator
- Messages visible
- No input field

### Testing Tips

#### Test Expiration Quickly
```dart
// Create conversation expiring in 5 seconds for testing
final testConversation = Conversation(
  id: 'test-chat',
  matchId: 'test-match',
  participantIds: ['user1', 'user2'],
  unreadCount: 0,
  status: 'active',
  expiresAt: DateTime.now().add(Duration(seconds: 5)),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

#### Test Notification
```dart
// Manually trigger notification
_notificationService.showChatExpiringNotification(
  partnerName: 'Test User',
  hoursLeft: 2,
);
```

### Common Gotchas

❌ **Don't** schedule notifications for already expired chats
✅ **Do** check expiration status before scheduling

❌ **Don't** forget to cancel timers on dispose
✅ **Do** clean up timers in ChatProvider.dispose()

❌ **Don't** allow sending messages in archived mode
✅ **Do** check both `isArchived` and `isExpired` flags

❌ **Don't** show typing indicators for archived chats
✅ **Do** conditionally render based on archive status

### Performance Tips

1. **Schedule Once**: Only schedule notification when chat is first loaded
2. **Cancel Early**: Cancel timers as soon as chat expires
3. **Filter Smart**: Use getters for active/archived to avoid filtering multiple times
4. **Lazy Load**: Load archived chats only when user navigates to page

### Debugging

#### Check Active Timers
```dart
print('Active timers: ${chatProvider._expirationCheckTimers.length}');
```

#### Verify Notification Scheduled
```dart
final pending = await LocalNotificationService().getPendingNotifications();
print('Pending notifications: ${pending.length}');
```

#### Monitor Expiration
```dart
chatProvider.addListener(() {
  final remaining = chatProvider.getRemainingTime(chatId);
  print('Remaining: ${remaining?.inSeconds}s');
});
```

### Troubleshooting

**Problem**: Notification not showing
- Check notification permissions
- Verify timer was scheduled
- Check system notification settings

**Problem**: Chat not moving to archived
- Verify expiresAt is set correctly
- Check if clearExpiredChats() is called
- Ensure getters are being used

**Problem**: Timer not updating
- Check _countdownTimer is running
- Verify setState() is called
- Ensure Timer.periodic interval is correct

**Problem**: Input still enabled when expired
- Check isExpired flag
- Verify conditional rendering
- Test with mock expired conversation

## For Product/QA

### Feature Checklist

- [ ] Timer visible in all active chats
- [ ] Notification received 2h before expiration
- [ ] Input disabled when expired
- [ ] "Cette conversation a expiré" message shown
- [ ] Chat moves to archived automatically
- [ ] Archived chats accessible from list
- [ ] Archived chats are read-only
- [ ] Archive badge shows on chat list
- [ ] Empty state shows when no archives

### Test Scenarios

**Scenario 1: Happy Path**
1. Open fresh chat (23h remaining)
2. Wait for 2h notification (in production)
3. Continue chatting until expiration
4. Verify chat becomes read-only
5. Check chat appears in archives

**Scenario 2: Edge Cases**
1. Open chat with 1h remaining → No notification
2. Open expired chat → Immediately read-only
3. Background app → Notification still fires
4. Restart app → Timers reschedule correctly

**Scenario 3: UI/UX**
1. Timer updates smoothly (1s intervals)
2. Colors change appropriately (green → red)
3. Archive button has correct badge count
4. Archived chat cards have visual distinction
5. Read-only banner is clear and visible

### Expected Behavior

| Remaining Time | Timer Color | Notification | Input Status |
|---------------|-------------|--------------|--------------|
| > 2h          | Gold        | Not sent     | Enabled      |
| 2h - 0h       | Orange/Red  | Sent once    | Enabled      |
| 0h (expired)  | Red (full)  | None         | Disabled     |

### Acceptance Criteria (from specs)

✅ Le timer 24h est visible en permanence dans le chat
✅ Impossible d'envoyer des messages après expiration
✅ Message système clair : "Cette conversation a expiré"
✅ Notification 2h avant expiration
✅ Les chats expirés sont automatiquement archivés
✅ Possibilité de consulter les chats archivés (lecture seule)

## Quick Links

- [Full Documentation](./CHAT_EXPIRATION_IMPLEMENTATION.md)
- [Specifications](./specifications.md)
- [API Routes](./API_ROUTES_DOCUMENTATION.md)
- [Frontend Tasks](./TACHES_FRONTEND.md)
- [Backend Tasks](./TACHES_BACKEND.md)
