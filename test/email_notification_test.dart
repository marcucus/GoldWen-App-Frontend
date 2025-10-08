import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/email_notification.dart';

void main() {
  group('EmailNotification Model', () {
    test('should create EmailNotification from JSON', () {
      final json = {
        'id': 'email-123',
        'userId': 'user-456',
        'type': 'welcome',
        'recipient': 'test@example.com',
        'subject': 'Welcome to GoldWen',
        'status': 'delivered',
        'createdAt': '2025-01-15T10:00:00Z',
        'sentAt': '2025-01-15T10:01:00Z',
        'deliveredAt': '2025-01-15T10:02:00Z',
        'canRetry': false,
      };

      final email = EmailNotification.fromJson(json);

      expect(email.id, 'email-123');
      expect(email.userId, 'user-456');
      expect(email.type, EmailType.welcome);
      expect(email.recipient, 'test@example.com');
      expect(email.subject, 'Welcome to GoldWen');
      expect(email.status, EmailStatus.delivered);
      expect(email.canRetry, false);
    });

    test('should handle different email types', () {
      final types = {
        'welcome': EmailType.welcome,
        'data_export': EmailType.dataExport,
        'dataexport': EmailType.dataExport,
        'account_deleted': EmailType.accountDeleted,
        'accountdeleted': EmailType.accountDeleted,
        'subscription_confirmed': EmailType.subscriptionConfirmed,
        'subscriptionconfirmed': EmailType.subscriptionConfirmed,
        'password_reset': EmailType.passwordReset,
        'passwordreset': EmailType.passwordReset,
        'unknown': EmailType.other,
      };

      types.forEach((typeString, expectedType) {
        final json = {
          'id': 'email-123',
          'userId': 'user-456',
          'type': typeString,
          'recipient': 'test@example.com',
          'subject': 'Test Subject',
          'status': 'pending',
          'createdAt': '2025-01-15T10:00:00Z',
        };

        final email = EmailNotification.fromJson(json);
        expect(email.type, expectedType);
      });
    });

    test('should handle different email statuses', () {
      final statuses = {
        'pending': EmailStatus.pending,
        'sent': EmailStatus.sent,
        'delivered': EmailStatus.delivered,
        'failed': EmailStatus.failed,
        'bounced': EmailStatus.bounced,
      };

      statuses.forEach((statusString, expectedStatus) {
        final json = {
          'id': 'email-123',
          'userId': 'user-456',
          'type': 'welcome',
          'recipient': 'test@example.com',
          'subject': 'Test Subject',
          'status': statusString,
          'createdAt': '2025-01-15T10:00:00Z',
        };

        final email = EmailNotification.fromJson(json);
        expect(email.status, expectedStatus);
      });
    });

    test('should convert EmailNotification to JSON', () {
      final email = EmailNotification(
        id: 'email-123',
        userId: 'user-456',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Welcome to GoldWen',
        status: EmailStatus.delivered,
        createdAt: DateTime.parse('2025-01-15T10:00:00Z'),
        sentAt: DateTime.parse('2025-01-15T10:01:00Z'),
      );

      final json = email.toJson();

      expect(json['id'], 'email-123');
      expect(json['userId'], 'user-456');
      expect(json['type'], 'welcome');
      expect(json['recipient'], 'test@example.com');
      expect(json['status'], 'delivered');
    });

    test('should correctly identify email with error', () {
      final failedEmail = EmailNotification(
        id: 'email-123',
        userId: 'user-456',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.failed,
        createdAt: DateTime.now(),
        errorMessage: 'SMTP connection failed',
      );

      expect(failedEmail.hasError, true);
      expect(failedEmail.isSuccessful, false);
      expect(failedEmail.isPending, false);

      final bouncedEmail = EmailNotification(
        id: 'email-124',
        userId: 'user-456',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.bounced,
        createdAt: DateTime.now(),
      );

      expect(bouncedEmail.hasError, true);
    });

    test('should correctly identify successful email', () {
      final email = EmailNotification(
        id: 'email-123',
        userId: 'user-456',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.delivered,
        createdAt: DateTime.now(),
      );

      expect(email.isSuccessful, true);
      expect(email.hasError, false);
      expect(email.isPending, false);
    });

    test('should correctly identify pending email', () {
      final pendingEmail = EmailNotification(
        id: 'email-123',
        userId: 'user-456',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(pendingEmail.isPending, true);
      expect(pendingEmail.hasError, false);
      expect(pendingEmail.isSuccessful, false);

      final sentEmail = EmailNotification(
        id: 'email-124',
        userId: 'user-456',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.sent,
        createdAt: DateTime.now(),
      );

      expect(sentEmail.isPending, true);
    });

    test('should provide correct type name', () {
      final typeNames = {
        EmailType.welcome: 'Welcome Email',
        EmailType.dataExport: 'Data Export Ready',
        EmailType.accountDeleted: 'Account Deleted',
        EmailType.subscriptionConfirmed: 'Subscription Confirmed',
        EmailType.passwordReset: 'Password Reset',
        EmailType.other: 'Other',
      };

      typeNames.forEach((type, expectedName) {
        final email = EmailNotification(
          id: 'email-123',
          userId: 'user-456',
          type: type,
          recipient: 'test@example.com',
          subject: 'Test',
          status: EmailStatus.pending,
          createdAt: DateTime.now(),
        );

        expect(email.typeName, expectedName);
      });
    });

    test('should provide correct status color', () {
      final email = EmailNotification(
        id: 'email-123',
        userId: 'user-456',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.delivered,
        createdAt: DateTime.now(),
      );

      expect(email.statusColor, Colors.green);
    });

    test('should provide correct status icon', () {
      final email = EmailNotification(
        id: 'email-123',
        userId: 'user-456',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.delivered,
        createdAt: DateTime.now(),
      );

      expect(email.statusIcon, Icons.check_circle);
    });

    test('should create copy with updated fields', () {
      final original = EmailNotification(
        id: 'email-123',
        userId: 'user-456',
        type: EmailType.welcome,
        recipient: 'test@example.com',
        subject: 'Test',
        status: EmailStatus.pending,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        status: EmailStatus.delivered,
        deliveredAt: DateTime.now(),
      );

      expect(updated.id, original.id);
      expect(updated.status, EmailStatus.delivered);
      expect(updated.deliveredAt, isNotNull);
      expect(original.status, EmailStatus.pending);
    });
  });
}
