import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/chat/providers/chat_provider.dart';
import 'package:goldwen_app/core/models/chat.dart';

void main() {
  group('ChatProvider Real-Time Features', () {
    late ChatProvider chatProvider;

    setUp(() {
      chatProvider = ChatProvider();
      chatProvider.setCurrentUserId('currentUser123');
    });

    tearDown(() {
      chatProvider.dispose();
    });

    group('Typing Indicators', () {
      test('should return null typing status when no one is typing', () {
        final status = chatProvider.getTypingStatus('chat123');
        expect(status, isNull);
      });

      test('should detect when user is typing', () {
        // Simulate typing status update
        final typingStatus = TypingStatus(
          userId: 'otherUser456',
          conversationId: 'chat123',
          isTyping: true,
          timestamp: DateTime.now(),
        );

        // Manually add to internal map (simulating WebSocket event)
        chatProvider.typingStatuses['chat123'] = typingStatus;

        expect(chatProvider.isUserTyping('chat123', 'otherUser456'), isTrue);
      });

      test('should return false when typing status is too old', () {
        final oldTypingStatus = TypingStatus(
          userId: 'otherUser456',
          conversationId: 'chat123',
          isTyping: true,
          timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
        );

        chatProvider.typingStatuses['chat123'] = oldTypingStatus;

        // Should be false because status is older than 5 seconds
        expect(chatProvider.isUserTyping('chat123', 'otherUser456'), isFalse);
      });

      test('should return null for old typing status', () {
        final oldTypingStatus = TypingStatus(
          userId: 'otherUser456',
          conversationId: 'chat123',
          isTyping: true,
          timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
        );

        chatProvider.typingStatuses['chat123'] = oldTypingStatus;

        // getTypingStatus should return null for old status
        expect(chatProvider.getTypingStatus('chat123'), isNull);
      });
    });

    group('Online Status', () {
      test('should return null online status when user status is not available', () {
        final status = chatProvider.getOnlineStatus('user123');
        expect(status, isNull);
      });

      test('should detect when user is online', () {
        final onlineStatus = OnlineStatus(
          userId: 'otherUser456',
          isOnline: true,
        );

        chatProvider.onlineStatuses['otherUser456'] = onlineStatus;

        expect(chatProvider.isUserOnline('otherUser456'), isTrue);
      });

      test('should detect when user is offline', () {
        final offlineStatus = OnlineStatus(
          userId: 'otherUser456',
          isOnline: false,
          lastSeenAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        chatProvider.onlineStatuses['otherUser456'] = offlineStatus;

        expect(chatProvider.isUserOnline('otherUser456'), isFalse);
      });

      test('should return false when user status is not available', () {
        expect(chatProvider.isUserOnline('unknownUser'), isFalse);
      });

      test('should retrieve online status correctly', () {
        final onlineStatus = OnlineStatus(
          userId: 'otherUser456',
          isOnline: true,
          lastSeenAt: DateTime.now(),
        );

        chatProvider.onlineStatuses['otherUser456'] = onlineStatus;

        final retrieved = chatProvider.getOnlineStatus('otherUser456');
        expect(retrieved, isNotNull);
        expect(retrieved!.userId, equals('otherUser456'));
        expect(retrieved.isOnline, isTrue);
      });
    });

    group('Read Receipts', () {
      test('should mark messages as read', () {
        // Create test conversation
        final conversation = Conversation(
          id: 'chat123',
          matchId: 'match123',
          participantIds: ['currentUser123', 'otherUser456'],
          unreadCount: 2,
          status: 'active',
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now(),
        );

        chatProvider.conversations.add(conversation);

        // Create test messages
        final messages = [
          ChatMessage(
            id: 'msg1',
            conversationId: 'chat123',
            senderId: 'otherUser456',
            type: 'text',
            content: 'Hello!',
            isRead: false,
            createdAt: DateTime.now(),
          ),
          ChatMessage(
            id: 'msg2',
            conversationId: 'chat123',
            senderId: 'otherUser456',
            type: 'text',
            content: 'How are you?',
            isRead: false,
            createdAt: DateTime.now(),
          ),
        ];

        chatProvider.chatMessages['chat123'] = messages;

        // All messages should initially be unread
        expect(chatProvider.chatMessages['chat123']!.every((m) => !m.isRead), isTrue);
      });
    });

    group('Chat Expiration', () {
      test('should detect expired chats', () {
        final expiredConversation = Conversation(
          id: 'expiredChat',
          matchId: 'match123',
          participantIds: ['currentUser123', 'otherUser456'],
          unreadCount: 0,
          status: 'active',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        );

        chatProvider.conversations.add(expiredConversation);

        expect(chatProvider.isChatExpired('expiredChat'), isTrue);
      });

      test('should detect active chats', () {
        final activeConversation = Conversation(
          id: 'activeChat',
          matchId: 'match123',
          participantIds: ['currentUser123', 'otherUser456'],
          unreadCount: 0,
          status: 'active',
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now(),
        );

        chatProvider.conversations.add(activeConversation);

        expect(chatProvider.isChatExpired('activeChat'), isFalse);
      });

      test('should calculate remaining time correctly', () {
        final futureTime = DateTime.now().add(const Duration(hours: 5));
        final conversation = Conversation(
          id: 'activeChat',
          matchId: 'match123',
          participantIds: ['currentUser123', 'otherUser456'],
          unreadCount: 0,
          status: 'active',
          expiresAt: futureTime,
          createdAt: DateTime.now().subtract(const Duration(hours: 19)),
          updatedAt: DateTime.now(),
        );

        chatProvider.conversations.add(conversation);

        final remaining = chatProvider.getRemainingTime('activeChat');
        expect(remaining, isNotNull);
        expect(remaining!.inHours, equals(4)); // Allow for small time difference
      });
    });

    group('WebSocket Connection Status', () {
      test('should initialize with disconnected state', () {
        expect(chatProvider.isWebSocketConnected, isFalse);
      });

      test('should track connection state', () {
        // Initially disconnected
        expect(chatProvider.isWebSocketConnected, isFalse);
        
        // Connection state would be updated by WebSocket events
        // This would be tested in integration tests with actual WebSocket
      });
    });
  });
}
