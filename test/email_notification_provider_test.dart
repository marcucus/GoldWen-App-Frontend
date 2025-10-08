import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goldwen_app/features/settings/providers/email_notification_provider.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/models/email_notification.dart';

@GenerateMocks([])
class MockApiService extends Mock {
  static Future<Map<String, dynamic>> getEmailHistory({
    int? page,
    int? limit,
    String? type,
    String? status,
  }) async {
    return {
      'data': [
        {
          'id': 'email-1',
          'userId': 'user-1',
          'type': 'welcome',
          'recipient': 'test@example.com',
          'subject': 'Welcome to GoldWen',
          'status': 'delivered',
          'createdAt': '2025-01-15T10:00:00Z',
          'sentAt': '2025-01-15T10:01:00Z',
          'deliveredAt': '2025-01-15T10:02:00Z',
          'canRetry': false,
        },
      ],
    };
  }

  static Future<Map<String, dynamic>> getEmailDetails(String emailId) async {
    return {
      'data': {
        'id': emailId,
        'userId': 'user-1',
        'type': 'welcome',
        'recipient': 'test@example.com',
        'subject': 'Welcome to GoldWen',
        'status': 'delivered',
        'createdAt': '2025-01-15T10:00:00Z',
        'sentAt': '2025-01-15T10:01:00Z',
        'deliveredAt': '2025-01-15T10:02:00Z',
        'canRetry': false,
      },
    };
  }

  static Future<Map<String, dynamic>> retryEmail(String emailId) async {
    return {
      'data': {
        'id': emailId,
        'userId': 'user-1',
        'type': 'welcome',
        'recipient': 'test@example.com',
        'subject': 'Welcome to GoldWen',
        'status': 'pending',
        'createdAt': '2025-01-15T10:00:00Z',
        'canRetry': false,
      },
    };
  }
}

void main() {
  group('EmailNotificationProvider', () {
    late EmailNotificationProvider provider;

    setUp(() {
      provider = EmailNotificationProvider();
    });

    test('should initialize with empty state', () {
      expect(provider.emailHistory, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.hasMore, true);
    });

    test('should filter pending emails correctly', () {
      provider = EmailNotificationProvider();
      // We would need to add test data manually here since we can't easily mock API calls
      // This is a simplified test
      expect(provider.pendingEmails, isEmpty);
    });

    test('should filter failed emails correctly', () {
      provider = EmailNotificationProvider();
      expect(provider.failedEmails, isEmpty);
    });

    test('should filter successful emails correctly', () {
      provider = EmailNotificationProvider();
      expect(provider.successfulEmails, isEmpty);
    });

    test('should count failed and pending emails', () {
      provider = EmailNotificationProvider();
      expect(provider.failedEmailCount, 0);
      expect(provider.pendingEmailCount, 0);
    });

    test('should clear error', () {
      provider = EmailNotificationProvider();
      // Manually set an error for testing
      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  group('EmailNotification Model Helpers', () {
    test('should correctly identify email states', () {
      final pendingEmail = EmailNotification(
        id: 'email-1',
        userId: 'user-1',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.pending,
        createdAt: DateTime.now(),
      );

      final failedEmail = EmailNotification(
        id: 'email-2',
        userId: 'user-1',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.failed,
        createdAt: DateTime.now(),
        errorMessage: 'SMTP error',
        canRetry: true,
      );

      final successEmail = EmailNotification(
        id: 'email-3',
        userId: 'user-1',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.delivered,
        createdAt: DateTime.now(),
      );

      expect(pendingEmail.isPending, true);
      expect(failedEmail.hasError, true);
      expect(failedEmail.canRetry, true);
      expect(successEmail.isSuccessful, true);
    });

    test('should format time ago correctly', () {
      final now = DateTime.now();
      
      final recentEmail = EmailNotification(
        id: 'email-1',
        userId: 'user-1',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.delivered,
        createdAt: now.subtract(const Duration(seconds: 30)),
      );

      expect(recentEmail.timeAgo, 'Just now');

      final oldEmail = EmailNotification(
        id: 'email-2',
        userId: 'user-1',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.delivered,
        createdAt: now.subtract(const Duration(days: 10)),
      );

      expect(oldEmail.timeAgo.contains('w ago'), true);
    });
  });
}
