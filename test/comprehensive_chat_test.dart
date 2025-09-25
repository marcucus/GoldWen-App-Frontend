import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goldwen_app/features/chat/providers/chat_provider.dart';
import 'package:goldwen_app/core/models/chat.dart';
import 'package:goldwen_app/core/models/user.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/services/websocket_service.dart';

class MockApiService extends Mock {}
class MockWebSocketService extends Mock {}

@GenerateMocks([MockApiService, MockWebSocketService])
void main() {
  group('Chat System Tests', () {
    late ChatProvider chatProvider;
    late MockApiService mockApiService;
    late MockWebSocketService mockWebSocketService;

    setUp(() {
      mockApiService = MockApiService();
      mockWebSocketService = MockWebSocketService();
      chatProvider = ChatProvider();
    });

    test('should initialize with default values', () {
      expect(chatProvider.conversations, isEmpty);
      expect(chatProvider.currentConversation, isNull);
      expect(chatProvider.messages, isEmpty);
      expect(chatProvider.isLoading, isFalse);
      expect(chatProvider.error, isNull);
      expect(chatProvider.isConnected, isFalse);
      expect(chatProvider.typingUsers, isEmpty);
    });

    test('should create and manage conversations', () {
      final otherUser = User(
        id: 'other-user-id',
        email: 'other@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final conversation = Conversation(
        id: 'conversation-id',
        matchId: 'match-id',
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        otherUser: otherUser,
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      chatProvider.addConversation(conversation);

      expect(chatProvider.conversations.length, equals(1));
      expect(chatProvider.conversations[0].id, equals('conversation-id'));
      expect(chatProvider.conversations[0].otherUser.firstName, equals('Jane'));
    });

    test('should handle 24-hour expiration correctly', () {
      final now = DateTime.now();
      final expiryTime = now.add(const Duration(hours: 24));

      final conversation = Conversation(
        id: 'conversation-id',
        matchId: 'match-id',
        status: 'active',
        expiresAt: expiryTime,
        otherUser: User(
          id: 'other-user-id',
          email: 'other@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        lastMessage: null,
        unreadCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      chatProvider.addConversation(conversation);

      // Test time remaining calculation
      final timeRemaining = chatProvider.getTimeRemaining(conversation.id);
      expect(timeRemaining, isNotNull);
      expect(timeRemaining!.inHours, equals(23)); // Approximately 23 hours remaining

      // Test expiry status
      expect(chatProvider.isConversationExpired(conversation.id), isFalse);

      // Test expired conversation
      final expiredConversation = conversation.copyWith(
        expiresAt: now.subtract(const Duration(minutes: 1)),
        status: 'expired',
      );

      chatProvider.updateConversation(expiredConversation);
      expect(chatProvider.isConversationExpired(conversation.id), isTrue);
    });

    test('should send and receive messages', () {
      final conversation = Conversation(
        id: 'conversation-id',
        matchId: 'match-id',
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        otherUser: User(
          id: 'other-user-id',
          email: 'other@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      chatProvider.setCurrentConversation(conversation);

      final message1 = ChatMessage(
        id: 'message-1',
        chatId: 'conversation-id',
        senderId: 'current-user-id',
        content: 'Hello there!',
        status: 'sent',
        createdAt: DateTime.now(),
      );

      final message2 = ChatMessage(
        id: 'message-2',
        chatId: 'conversation-id',
        senderId: 'other-user-id',
        content: 'Hi! How are you?',
        status: 'delivered',
        createdAt: DateTime.now().add(const Duration(minutes: 1)),
      );

      chatProvider.addMessage(message1);
      chatProvider.addMessage(message2);

      expect(chatProvider.messages.length, equals(2));
      expect(chatProvider.messages[0].content, equals('Hello there!'));
      expect(chatProvider.messages[1].content, equals('Hi! How are you?'));

      // Test message ordering (should be chronological)
      expect(chatProvider.messages[0].createdAt.isBefore(chatProvider.messages[1].createdAt), isTrue);
    });

    test('should handle message status updates', () {
      final message = ChatMessage(
        id: 'message-id',
        chatId: 'conversation-id',
        senderId: 'current-user-id',
        content: 'Test message',
        status: 'sending',
        createdAt: DateTime.now(),
      );

      chatProvider.setCurrentConversation(Conversation(
        id: 'conversation-id',
        matchId: 'match-id',
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        otherUser: User(
          id: 'other-user-id',
          email: 'other@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      chatProvider.addMessage(message);
      expect(chatProvider.messages[0].status, equals('sending'));

      // Update message status
      final updatedMessage = message.copyWith(status: 'sent');
      chatProvider.updateMessageStatus(message.id, 'sent');

      expect(chatProvider.messages[0].status, equals('sent'));
    });

    test('should handle typing indicators', () {
      expect(chatProvider.typingUsers, isEmpty);
      expect(chatProvider.isUserTyping('other-user-id'), isFalse);

      // User starts typing
      chatProvider.setUserTyping('other-user-id', true);
      expect(chatProvider.typingUsers.contains('other-user-id'), isTrue);
      expect(chatProvider.isUserTyping('other-user-id'), isTrue);

      // User stops typing
      chatProvider.setUserTyping('other-user-id', false);
      expect(chatProvider.typingUsers.contains('other-user-id'), isFalse);
      expect(chatProvider.isUserTyping('other-user-id'), isFalse);
    });

    test('should track unread messages correctly', () {
      final conversation = Conversation(
        id: 'conversation-id',
        matchId: 'match-id',
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        otherUser: User(
          id: 'other-user-id',
          email: 'other@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        lastMessage: null,
        unreadCount: 3, // 3 unread messages
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      chatProvider.addConversation(conversation);

      expect(chatProvider.getTotalUnreadCount(), equals(3));
      expect(chatProvider.hasUnreadMessages, isTrue);

      // Mark messages as read
      final updatedConversation = conversation.copyWith(unreadCount: 0);
      chatProvider.updateConversation(updatedConversation);

      expect(chatProvider.getTotalUnreadCount(), equals(0));
      expect(chatProvider.hasUnreadMessages, isFalse);
    });

    test('should handle conversation sorting by last activity', () {
      final now = DateTime.now();
      
      final conversation1 = Conversation(
        id: 'conversation-1',
        matchId: 'match-1',
        status: 'active',
        expiresAt: now.add(const Duration(hours: 24)),
        otherUser: User(
          id: 'user-1',
          email: 'user1@example.com',
          firstName: 'Alice',
          lastName: 'Smith',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: now,
          updatedAt: now,
        ),
        lastMessage: ChatMessage(
          id: 'msg-1',
          chatId: 'conversation-1',
          senderId: 'user-1',
          content: 'First message',
          status: 'delivered',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        unreadCount: 0,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      );

      final conversation2 = Conversation(
        id: 'conversation-2',
        matchId: 'match-2',
        status: 'active',
        expiresAt: now.add(const Duration(hours: 24)),
        otherUser: User(
          id: 'user-2',
          email: 'user2@example.com',
          firstName: 'Bob',
          lastName: 'Johnson',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: now,
          updatedAt: now,
        ),
        lastMessage: ChatMessage(
          id: 'msg-2',
          chatId: 'conversation-2',
          senderId: 'user-2',
          content: 'Recent message',
          status: 'delivered',
          createdAt: now.subtract(const Duration(minutes: 30)),
        ),
        unreadCount: 1,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      );

      chatProvider.setConversations([conversation1, conversation2]);

      final sortedConversations = chatProvider.sortedConversations;

      // Most recent conversation should be first
      expect(sortedConversations[0].id, equals('conversation-2'));
      expect(sortedConversations[1].id, equals('conversation-1'));
    });

    test('should prevent sending messages to expired chats', () {
      final expiredConversation = Conversation(
        id: 'expired-conversation',
        matchId: 'match-id',
        status: 'expired',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        otherUser: User(
          id: 'other-user-id',
          email: 'other@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now().subtract(const Duration(hours: 25)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      chatProvider.setCurrentConversation(expiredConversation);

      expect(chatProvider.canSendMessages, isFalse);
      expect(() => chatProvider.sendMessage('This should fail'), 
          throwsA(isA<Exception>()));
    });

    test('should handle connection status correctly', () {
      expect(chatProvider.isConnected, isFalse);

      chatProvider.setConnectionStatus(true);
      expect(chatProvider.isConnected, isTrue);

      chatProvider.setConnectionStatus(false);
      expect(chatProvider.isConnected, isFalse);
    });

    test('should filter active conversations', () {
      final activeConversation = Conversation(
        id: 'active-conversation',
        matchId: 'match-1',
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        otherUser: User(
          id: 'user-1',
          email: 'user1@example.com',
          firstName: 'Alice',
          lastName: 'Smith',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final expiredConversation = Conversation(
        id: 'expired-conversation',
        matchId: 'match-2',
        status: 'expired',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        otherUser: User(
          id: 'user-2',
          email: 'user2@example.com',
          firstName: 'Bob',
          lastName: 'Johnson',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      chatProvider.setConversations([activeConversation, expiredConversation]);

      expect(chatProvider.conversations.length, equals(2));
      expect(chatProvider.activeConversations.length, equals(1));
      expect(chatProvider.activeConversations[0].status, equals('active'));
      expect(chatProvider.expiredConversations.length, equals(1));
      expect(chatProvider.expiredConversations[0].status, equals('expired'));
    });
  });

  group('Chat Models Tests', () {
    test('ChatMessage should handle different content types', () {
      final textMessage = ChatMessage(
        id: 'text-message',
        chatId: 'chat-id',
        senderId: 'sender-id',
        content: 'Hello world!',
        status: 'sent',
        createdAt: DateTime.now(),
      );

      expect(textMessage.content, equals('Hello world!'));
      expect(textMessage.isTextMessage, isTrue);
      expect(textMessage.hasContent, isTrue);

      // Test message with media (future feature)
      final mediaMessage = ChatMessage(
        id: 'media-message',
        chatId: 'chat-id',
        senderId: 'sender-id',
        content: '',
        status: 'sent',
        mediaUrl: 'https://example.com/image.jpg',
        mediaType: 'image',
        createdAt: DateTime.now(),
      );

      expect(mediaMessage.hasMediaContent, isTrue);
      expect(mediaMessage.isImageMessage, isTrue);
      expect(mediaMessage.hasContent, isTrue); // Still has content (media)
    });

    test('Conversation should calculate time remaining correctly', () {
      final now = DateTime.now();
      final expiresIn2Hours = now.add(const Duration(hours: 2));
      
      final conversation = Conversation(
        id: 'conversation-id',
        matchId: 'match-id',
        status: 'active',
        expiresAt: expiresIn2Hours,
        otherUser: User(
          id: 'other-user-id',
          email: 'other@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        lastMessage: null,
        unreadCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      final timeRemaining = conversation.timeRemaining;
      expect(timeRemaining.inHours, equals(1)); // Approximately 2 hours - processing time
      expect(conversation.isExpired, isFalse);
      expect(conversation.isExpiringSoon, isFalse); // Not within 1 hour

      // Test expiring soon (within 1 hour)
      final expiringSoonConversation = conversation.copyWith(
        expiresAt: now.add(const Duration(minutes: 30)),
      );
      expect(expiringSoonConversation.isExpiringSoon, isTrue);
    });

    test('TypingStatus should handle user typing states', () {
      final typingStatus = TypingStatus(
        userId: 'user-id',
        conversationId: 'conversation-id',
        isTyping: true,
        timestamp: DateTime.now(),
      );

      expect(typingStatus.isTyping, isTrue);
      expect(typingStatus.userId, equals('user-id'));

      // Test expiry (typing indicators should expire after a few seconds)
      final oldTypingStatus = TypingStatus(
        userId: 'user-id',
        conversationId: 'conversation-id',
        isTyping: true,
        timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
      );

      expect(oldTypingStatus.isExpired, isTrue);
    });
  });

  group('Chat Integration Tests', () {
    test('should handle complete chat flow', () {
      final chatProvider = ChatProvider();
      
      // Create conversation
      final conversation = Conversation(
        id: 'conversation-id',
        matchId: 'match-id',
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        otherUser: User(
          id: 'other-user-id',
          email: 'other@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
          status: 'active',
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      chatProvider.addConversation(conversation);
      chatProvider.setCurrentConversation(conversation);

      // Send messages back and forth
      final messages = [
        ChatMessage(
          id: 'msg-1',
          chatId: 'conversation-id',
          senderId: 'current-user-id',
          content: 'Hello! Nice to match with you.',
          status: 'sent',
          createdAt: DateTime.now(),
        ),
        ChatMessage(
          id: 'msg-2',
          chatId: 'conversation-id',
          senderId: 'other-user-id',
          content: 'Hi there! Thanks for the match.',
          status: 'delivered',
          createdAt: DateTime.now().add(const Duration(minutes: 2)),
        ),
        ChatMessage(
          id: 'msg-3',
          chatId: 'conversation-id',
          senderId: 'current-user-id',
          content: 'What do you like to do for fun?',
          status: 'sent',
          createdAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
      ];

      messages.forEach(chatProvider.addMessage);

      expect(chatProvider.messages.length, equals(3));
      expect(chatProvider.currentConversation?.id, equals('conversation-id'));
      expect(chatProvider.canSendMessages, isTrue);

      // Test conversation updates with last message
      final lastMessage = messages.last;
      final updatedConversation = conversation.copyWith(
        lastMessage: lastMessage,
        updatedAt: lastMessage.createdAt,
      );

      chatProvider.updateConversation(updatedConversation);

      expect(chatProvider.conversations[0].lastMessage?.content, equals('What do you like to do for fun?'));
    });
  });
});