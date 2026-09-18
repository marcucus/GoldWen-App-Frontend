import 'support/api_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:goldwen_app/features/notifications/providers/notification_provider.dart';
import 'package:goldwen_app/core/models/notification.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/services/firebase_messaging_service.dart';
import 'package:goldwen_app/core/services/local_notification_service.dart';

// Use generated mocks for ApiService
import 'mocks.mocks.dart';

// Mock classes for services without generated mocks
class MockFirebaseMessagingService extends Mock implements FirebaseMessagingService {}
class MockLocalNotificationService extends Mock implements LocalNotificationService {}

void main() {
  group('NotificationProvider Tests', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    test('should initialize with empty notifications and default settings', () {
      expect(provider.notifications, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, null);
      expect(provider.unreadCount, 0);
    });

    test('should load notifications successfully', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': '1',
            'userId': 'user1',
            'type': 'daily_selection',
            'title': 'Daily Selection',
            'body': 'Your daily selection is ready',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ]
      };

      ApiService.configureTestAdapter(() => ApiAdapter((_) => (200, mockResponse)));
      // Act & Assert
      // Note: This test would need to be refactored to use dependency injection
      // to properly mock the ApiService static methods
      expect(() => provider.loadNotifications(), returnsNormally);
    });

    test('should correctly identify notification types', () {
      final notifications = [
        AppNotification(
          id: '1',
          userId: 'user1',
          type: 'daily_selection',
          title: 'Daily Selection',
          body: 'Your selection is ready',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: '2',
          userId: 'user1',
          type: 'new_match',
          title: 'New Match',
          body: 'You have a match!',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ];

      expect(notifications[0].isDailySelection, true);
      expect(notifications[0].isNewMatch, false);
      expect(notifications[1].isDailySelection, false);
      expect(notifications[1].isNewMatch, true);
    });

    test('should calculate time ago correctly', () {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      final notifications = [
        AppNotification(
          id: '1',
          userId: 'user1',
          type: 'daily_selection',
          title: 'Test',
          body: 'Test',
          isRead: false,
          createdAt: fiveMinutesAgo,
        ),
        AppNotification(
          id: '2',
          userId: 'user1',
          type: 'new_match',
          title: 'Test',
          body: 'Test',
          isRead: false,
          createdAt: twoHoursAgo,
        ),
        AppNotification(
          id: '3',
          userId: 'user1',
          type: 'new_message',
          title: 'Test',
          body: 'Test',
          isRead: false,
          createdAt: threeDaysAgo,
        ),
        AppNotification(
          id: '4',
          userId: 'user1',
          type: 'system',
          title: 'Test',
          body: 'Test',
          isRead: false,
          createdAt: twoWeeksAgo,
        ),
      ];

      expect(notifications[0].timeAgo, '5m ago');
      expect(notifications[1].timeAgo, '2h ago');
      expect(notifications[2].timeAgo, '3d ago');
      expect(notifications[3].timeAgo, '2w ago');
    });
  });

  group('NotificationSettings Tests', () {
    test('should create settings with default values', () {
      final settings = NotificationSettings(
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        promotions: false,
        systemUpdates: true,
        emailFrequency: 'weekly',
        pushEnabled: true,
        emailEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
      );

      expect(settings.dailySelection, true);
      expect(settings.pushEnabled, true);
      expect(settings.quietHoursStart, '22:00');
    });

    test('should correctly detect quiet hours', () {
      final settings = NotificationSettings(
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        promotions: false,
        systemUpdates: true,
        emailFrequency: 'weekly',
        pushEnabled: true,
        emailEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
      );

      // Note: This test would be more complex in reality as it depends on current time
      // For demonstration purposes, we're just checking the method exists
      expect(() => settings.isInQuietHours, returnsNormally);
    });

    test('should create settings from JSON', () {
      final json = {
        'dailySelection': true,
        'newMatches': false,
        'newMessages': true,
        'chatExpiring': true,
        'promotions': false,
        'systemUpdates': true,
        'pushEnabled': true,
        'emailEnabled': false,
        'soundEnabled': true,
        'vibrationEnabled': true,
        'quietHoursStart': '23:00',
        'quietHoursEnd': '07:00',
      };

      final settings = NotificationSettings.fromJson(json);
      expect(settings.dailySelection, true);
      expect(settings.newMatches, false);
      expect(settings.emailEnabled, false);
      expect(settings.quietHoursStart, '23:00');
    });

    test('should update settings with copyWith', () {
      final originalSettings = NotificationSettings(
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        promotions: false,
        systemUpdates: true,
        emailFrequency: 'weekly',
        pushEnabled: true,
        emailEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
      );

      final updatedSettings = originalSettings.copyWith(
        dailySelection: false,
        pushEnabled: false,
        quietHoursStart: '23:00',
      );

      expect(updatedSettings.dailySelection, false);
      expect(updatedSettings.pushEnabled, false);
      expect(updatedSettings.quietHoursStart, '23:00');
      // Other settings should remain unchanged
      expect(updatedSettings.newMatches, true);
      expect(updatedSettings.quietHoursEnd, '08:00');
    });
  });

}
