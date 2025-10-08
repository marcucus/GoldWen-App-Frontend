import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/gdpr_consent.dart';

void main() {
  group('DataExportRequest', () {
    test('should create from JSON correctly', () {
      final json = {
        'requestId': 'test-123',
        'status': 'processing',
        'requestedAt': '2025-01-15T10:00:00Z',
        'estimatedTime': '24 heures',
      };

      final request = DataExportRequest.fromJson(json);

      expect(request.requestId, 'test-123');
      expect(request.status, 'processing');
      expect(request.estimatedTime, '24 heures');
      expect(request.isProcessing, true);
      expect(request.isReady, false);
      expect(request.isFailed, false);
    });

    test('should detect ready status correctly', () {
      final request = DataExportRequest(
        requestId: 'test-123',
        status: 'ready',
        requestedAt: DateTime.now(),
        downloadUrl: 'https://example.com/download',
      );

      expect(request.isReady, true);
      expect(request.isProcessing, false);
      expect(request.downloadUrl, isNotNull);
    });

    test('should detect failed status correctly', () {
      final request = DataExportRequest(
        requestId: 'test-123',
        status: 'failed',
        requestedAt: DateTime.now(),
      );

      expect(request.isFailed, true);
      expect(request.isReady, false);
      expect(request.isProcessing, false);
    });

    test('should detect expired status correctly', () {
      final expiredDate = DateTime.now().subtract(const Duration(days: 1));
      final request = DataExportRequest(
        requestId: 'test-123',
        status: 'ready',
        requestedAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: expiredDate,
      );

      expect(request.isExpired, true);
    });

    test('should serialize to JSON correctly', () {
      final request = DataExportRequest(
        requestId: 'test-123',
        status: 'ready',
        requestedAt: DateTime.parse('2025-01-15T10:00:00Z'),
        expiresAt: DateTime.parse('2025-01-20T10:00:00Z'),
        downloadUrl: 'https://example.com/download',
        estimatedTime: '24 heures',
      );

      final json = request.toJson();

      expect(json['requestId'], 'test-123');
      expect(json['status'], 'ready');
      expect(json['downloadUrl'], 'https://example.com/download');
      expect(json['estimatedTime'], '24 heures');
    });
  });

  group('AccountDeletionStatus', () {
    test('should create from JSON correctly', () {
      final json = {
        'status': 'scheduled_deletion',
        'deletionDate': '2025-02-15T10:00:00Z',
        'message': 'Votre compte sera supprimé dans 30 jours',
        'canCancel': true,
      };

      final status = AccountDeletionStatus.fromJson(json);

      expect(status.status, 'scheduled_deletion');
      expect(status.deletionDate, isNotNull);
      expect(status.message, 'Votre compte sera supprimé dans 30 jours');
      expect(status.canCancel, true);
      expect(status.isScheduledForDeletion, true);
      expect(status.isActive, false);
    });

    test('should detect active status correctly', () {
      final status = AccountDeletionStatus(status: 'active');

      expect(status.isActive, true);
      expect(status.isScheduledForDeletion, false);
      expect(status.isDeleted, false);
    });

    test('should calculate days until deletion correctly', () {
      final futureDate = DateTime.now().add(const Duration(days: 15));
      final status = AccountDeletionStatus(
        status: 'scheduled_deletion',
        deletionDate: futureDate,
        canCancel: true,
      );

      expect(status.daysUntilDeletion, 15);
    });

    test('should handle null deletion date', () {
      final status = AccountDeletionStatus(status: 'active');

      expect(status.daysUntilDeletion, isNull);
    });

    test('should serialize to JSON correctly', () {
      final status = AccountDeletionStatus(
        status: 'scheduled_deletion',
        deletionDate: DateTime.parse('2025-02-15T10:00:00Z'),
        message: 'Test message',
        canCancel: true,
      );

      final json = status.toJson();

      expect(json['status'], 'scheduled_deletion');
      expect(json['deletionDate'], isNotNull);
      expect(json['message'], 'Test message');
      expect(json['canCancel'], true);
    });

    test('should handle deleted status correctly', () {
      final status = AccountDeletionStatus(status: 'deleted');

      expect(status.isDeleted, true);
      expect(status.isActive, false);
      expect(status.isScheduledForDeletion, false);
    });
  });

  group('GdprConsent', () {
    test('should maintain backward compatibility', () {
      final consent = GdprConsent(
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: DateTime.now(),
      );

      expect(consent.dataProcessing, true);
      expect(consent.marketing, false);
      expect(consent.analytics, true);
      expect(consent.consentedAt, isNotNull);
    });

    test('should handle optional fields', () {
      final consent = GdprConsent(
        dataProcessing: true,
        consentedAt: DateTime.now(),
        consentVersion: '1.2',
      );

      expect(consent.marketing, isNull);
      expect(consent.analytics, isNull);
      expect(consent.consentVersion, '1.2');
    });

    test('should copy with modifications', () {
      final original = GdprConsent(
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: DateTime.now(),
      );

      final modified = original.copyWith(marketing: true);

      expect(modified.dataProcessing, true);
      expect(modified.marketing, true);
      expect(modified.analytics, true);
    });
  });

  group('PrivacySettings', () {
    test('should create with required fields', () {
      final settings = PrivacySettings(
        analytics: true,
        marketing: false,
        functionalCookies: true,
      );

      expect(settings.analytics, true);
      expect(settings.marketing, false);
      expect(settings.functionalCookies, true);
      expect(settings.dataRetention, isNull);
    });

    test('should handle optional data retention', () {
      final settings = PrivacySettings(
        analytics: true,
        marketing: false,
        functionalCookies: true,
        dataRetention: 365,
      );

      expect(settings.dataRetention, 365);
    });

    test('should serialize to JSON correctly', () {
      final settings = PrivacySettings(
        analytics: true,
        marketing: false,
        functionalCookies: true,
        dataRetention: 180,
      );

      final json = settings.toJson();

      expect(json['analytics'], true);
      expect(json['marketing'], false);
      expect(json['functionalCookies'], true);
      expect(json['dataRetention'], 180);
    });

    test('should copy with modifications', () {
      final original = PrivacySettings(
        analytics: true,
        marketing: false,
        functionalCookies: true,
      );

      final modified = original.copyWith(marketing: true, dataRetention: 365);

      expect(modified.analytics, true);
      expect(modified.marketing, true);
      expect(modified.functionalCookies, true);
      expect(modified.dataRetention, 365);
    });
  });

  group('PrivacyPolicy', () {
    test('should maintain existing functionality', () {
      final policy = PrivacyPolicy(
        content: 'Test policy content',
        version: '1.1',
        lastUpdated: DateTime.now(),
      );

      expect(policy.content, 'Test policy content');
      expect(policy.version, '1.1');
      expect(policy.lastUpdated, isNotNull);
    });

    test('should create from JSON with defaults', () {
      final json = {
        'content': 'Test content',
      };

      final policy = PrivacyPolicy.fromJson(json);

      expect(policy.content, 'Test content');
      expect(policy.version, '1.0'); // Default
      expect(policy.lastUpdated, isNotNull);
    });
  });
}
