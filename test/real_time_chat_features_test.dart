import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/chat.dart';

void main() {
  group('OnlineStatus Model', () {
    test('should create OnlineStatus from JSON correctly', () {
      final json = {
        'userId': 'user123',
        'isOnline': true,
        'lastSeenAt': '2025-01-15T14:30:00Z',
      };

      final status = OnlineStatus.fromJson(json);

      expect(status.userId, equals('user123'));
      expect(status.isOnline, isTrue);
      expect(status.lastSeenAt, isNotNull);
    });

    test('should handle null lastSeenAt', () {
      final json = {
        'userId': 'user123',
        'isOnline': false,
      };

      final status = OnlineStatus.fromJson(json);

      expect(status.userId, equals('user123'));
      expect(status.isOnline, isFalse);
      expect(status.lastSeenAt, isNull);
    });

    test('should return "En ligne" for online users', () {
      final status = OnlineStatus(
        userId: 'user123',
        isOnline: true,
      );

      expect(status.getLastSeenText(), equals('En ligne'));
    });

    test('should return "Hors ligne" for offline users without lastSeenAt', () {
      final status = OnlineStatus(
        userId: 'user123',
        isOnline: false,
      );

      expect(status.getLastSeenText(), equals('Hors ligne'));
    });

    test('should return "Vu à l\'instant" for very recent activity', () {
      final status = OnlineStatus(
        userId: 'user123',
        isOnline: false,
        lastSeenAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      expect(status.getLastSeenText(), equals('Vu à l\'instant'));
    });

    test('should return minutes for recent activity', () {
      final status = OnlineStatus(
        userId: 'user123',
        isOnline: false,
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      expect(status.getLastSeenText(), equals('Vu il y a 15 min'));
    });

    test('should return hours for activity within 24 hours', () {
      final status = OnlineStatus(
        userId: 'user123',
        isOnline: false,
        lastSeenAt: DateTime.now().subtract(const Duration(hours: 5)),
      );

      expect(status.getLastSeenText(), equals('Vu il y a 5h'));
    });

    test('should return days for activity within a week', () {
      final status = OnlineStatus(
        userId: 'user123',
        isOnline: false,
        lastSeenAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(status.getLastSeenText(), equals('Vu il y a 3j'));
    });

    test('should return "Hors ligne" for very old activity', () {
      final status = OnlineStatus(
        userId: 'user123',
        isOnline: false,
        lastSeenAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(status.getLastSeenText(), equals('Hors ligne'));
    });

    test('should serialize to JSON correctly', () {
      final status = OnlineStatus(
        userId: 'user123',
        isOnline: true,
        lastSeenAt: DateTime.parse('2025-01-15T14:30:00Z'),
      );

      final json = status.toJson();

      expect(json['userId'], equals('user123'));
      expect(json['isOnline'], isTrue);
      expect(json['lastSeenAt'], equals('2025-01-15T14:30:00.000Z'));
    });
  });

  group('TypingStatus Model', () {
    test('should create TypingStatus from JSON correctly', () {
      final json = {
        'userId': 'user123',
        'conversationId': 'conv456',
        'isTyping': true,
        'timestamp': '2025-01-15T14:30:00Z',
      };

      final status = TypingStatus.fromJson(json);

      expect(status.userId, equals('user123'));
      expect(status.conversationId, equals('conv456'));
      expect(status.isTyping, isTrue);
      expect(status.timestamp, isNotNull);
    });

    test('should handle missing isTyping field', () {
      final json = {
        'userId': 'user123',
        'conversationId': 'conv456',
        'timestamp': '2025-01-15T14:30:00Z',
      };

      final status = TypingStatus.fromJson(json);

      expect(status.isTyping, isFalse);
    });

    test('should handle missing timestamp field', () {
      final json = {
        'userId': 'user123',
        'conversationId': 'conv456',
        'isTyping': true,
      };

      final status = TypingStatus.fromJson(json);

      expect(status.timestamp, isNotNull);
      // Should use current time when timestamp is missing
      final now = DateTime.now();
      expect(status.timestamp.difference(now).inSeconds.abs(), lessThan(2));
    });

    test('should determine if status is recent (within 5 seconds)', () {
      final recentStatus = TypingStatus(
        userId: 'user123',
        conversationId: 'conv456',
        isTyping: true,
        timestamp: DateTime.now().subtract(const Duration(seconds: 3)),
      );

      expect(recentStatus.isRecent, isTrue);
    });

    test('should determine if status is not recent (older than 5 seconds)', () {
      final oldStatus = TypingStatus(
        userId: 'user123',
        conversationId: 'conv456',
        isTyping: true,
        timestamp: DateTime.now().subtract(const Duration(seconds: 6)),
      );

      expect(oldStatus.isRecent, isFalse);
    });

    test('should serialize to JSON correctly', () {
      final status = TypingStatus(
        userId: 'user123',
        conversationId: 'conv456',
        isTyping: true,
        timestamp: DateTime.parse('2025-01-15T14:30:00Z'),
      );

      final json = status.toJson();

      expect(json['userId'], equals('user123'));
      expect(json['conversationId'], equals('conv456'));
      expect(json['isTyping'], isTrue);
      expect(json['timestamp'], equals('2025-01-15T14:30:00.000Z'));
    });
  });

  group('ChatMessage Read Receipts', () {
    test('should create message with read status', () {
      final message = ChatMessage(
        id: 'msg123',
        conversationId: 'conv456',
        senderId: 'user123',
        type: 'text',
        content: 'Hello!',
        isRead: true,
        createdAt: DateTime.now(),
        readAt: DateTime.now(),
      );

      expect(message.isRead, isTrue);
      expect(message.readAt, isNotNull);
    });

    test('should create unread message', () {
      final message = ChatMessage(
        id: 'msg123',
        conversationId: 'conv456',
        senderId: 'user123',
        type: 'text',
        content: 'Hello!',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(message.isRead, isFalse);
      expect(message.readAt, isNull);
    });

    test('should update message to read status using copyWith', () {
      final unreadMessage = ChatMessage(
        id: 'msg123',
        conversationId: 'conv456',
        senderId: 'user123',
        type: 'text',
        content: 'Hello!',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final readMessage = unreadMessage.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );

      expect(unreadMessage.isRead, isFalse);
      expect(readMessage.isRead, isTrue);
      expect(readMessage.readAt, isNotNull);
    });
  });
}
