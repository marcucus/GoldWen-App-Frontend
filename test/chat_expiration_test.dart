import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/chat/providers/chat_provider.dart';
import 'package:goldwen_app/core/models/chat.dart';

void main() {
  group('ChatProvider Expiration', () {
    late ChatProvider chatProvider;

    setUp(() {
      chatProvider = ChatProvider();
    });

    test('isChatExpired returns true for expired chats', () {
      // Create a mock expired conversation
      final expiredConversation = Conversation(
        id: 'test-chat-id',
        matchId: 'test-match-id',
        participantIds: ['user1', 'user2'],
        unreadCount: 0,
        status: 'active',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)), // 1 hour ago
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      // Add conversation to provider (simulating loaded data)
      chatProvider.conversations.add(expiredConversation);

      expect(chatProvider.isChatExpired('test-chat-id'), isTrue);
    });

    test('isChatExpired returns false for active chats', () {
      // Create a mock active conversation
      final activeConversation = Conversation(
        id: 'test-chat-id',
        matchId: 'test-match-id',
        participantIds: ['user1', 'user2'],
        unreadCount: 0,
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(hours: 12)), // 12 hours from now
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
      );

      // Add conversation to provider (simulating loaded data)
      chatProvider.conversations.add(activeConversation);

      expect(chatProvider.isChatExpired('test-chat-id'), isFalse);
    });

    test('getRemainingTime returns correct duration for active chat', () {
      final futureTime = DateTime.now().add(const Duration(hours: 2, minutes: 30));
      final activeConversation = Conversation(
        id: 'test-chat-id',
        matchId: 'test-match-id',
        participantIds: ['user1', 'user2'],
        unreadCount: 0,
        status: 'active',
        expiresAt: futureTime,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
      );

      chatProvider.conversations.add(activeConversation);

      final remainingTime = chatProvider.getRemainingTime('test-chat-id');
      
      expect(remainingTime, isNotNull);
      expect(remainingTime!.inHours, equals(2));
      // Allow some tolerance for test execution time
      expect(remainingTime.inMinutes, greaterThanOrEqualTo(149)); // ~2h 29m
      expect(remainingTime.inMinutes, lessThanOrEqualTo(151)); // ~2h 31m
    });

    test('getRemainingTime returns null for chat without expiration', () {
      final neverExpiresConversation = Conversation(
        id: 'test-chat-id',
        matchId: 'test-match-id',
        participantIds: ['user1', 'user2'],
        unreadCount: 0,
        status: 'active',
        expiresAt: null, // No expiration
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
      );

      chatProvider.conversations.add(neverExpiresConversation);

      final remainingTime = chatProvider.getRemainingTime('test-chat-id');
      expect(remainingTime, isNull);
    });

    test('clearExpiredChats adds system message for expired conversations', () {
      // Create expired conversation
      final expiredConversation = Conversation(
        id: 'expired-chat',
        matchId: 'test-match-id',
        participantIds: ['user1', 'user2'],
        unreadCount: 0,
        status: 'active',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      chatProvider.conversations.add(expiredConversation);

      // Call clearExpiredChats
      chatProvider.clearExpiredChats();

      // Check if system message was added
      final messages = chatProvider.getChatMessages('expired-chat');
      expect(messages.length, equals(1));
      expect(messages.first.type, equals('system'));
      expect(messages.first.content, equals('Cette conversation a expiré'));
      expect(messages.first.senderId, equals('system'));
    });
  });
}