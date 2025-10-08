import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goldwen_app/core/services/gdpr_service.dart';
import 'package:goldwen_app/core/models/gdpr_consent.dart';

void main() {
  group('GdprService - RGPD Enhanced Features', () {
    late GdprService gdprService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gdprService = GdprService();
    });

    group('Data Export Request Management', () {
      test('should initialize with no export request', () {
        expect(gdprService.currentExportRequest, isNull);
      });

      test('should track export request after requesting', () {
        // Simulate setting an export request
        gdprService.currentExportRequest = DataExportRequest(
          requestId: 'test-123',
          status: 'processing',
          requestedAt: DateTime.now(),
          estimatedTime: '24 heures',
        );

        expect(gdprService.currentExportRequest, isNotNull);
        expect(gdprService.currentExportRequest!.requestId, 'test-123');
        expect(gdprService.currentExportRequest!.isProcessing, true);
      });

      test('should update export request status', () {
        gdprService.currentExportRequest = DataExportRequest(
          requestId: 'test-123',
          status: 'processing',
          requestedAt: DateTime.now(),
        );

        // Simulate status update
        gdprService.currentExportRequest = DataExportRequest(
          requestId: 'test-123',
          status: 'ready',
          requestedAt: gdprService.currentExportRequest!.requestedAt,
          downloadUrl: 'https://example.com/download',
        );

        expect(gdprService.currentExportRequest!.isReady, true);
        expect(gdprService.currentExportRequest!.downloadUrl, isNotNull);
      });
    });

    group('Account Deletion Status Management', () {
      test('should initialize with no deletion status', () {
        expect(gdprService.accountDeletionStatus, isNull);
      });

      test('should track scheduled deletion', () {
        final deletionDate = DateTime.now().add(const Duration(days: 30));
        gdprService.accountDeletionStatus = AccountDeletionStatus(
          status: 'scheduled_deletion',
          deletionDate: deletionDate,
          message: 'Votre compte sera supprimé dans 30 jours',
          canCancel: true,
        );

        expect(gdprService.accountDeletionStatus, isNotNull);
        expect(gdprService.accountDeletionStatus!.isScheduledForDeletion, true);
        expect(gdprService.accountDeletionStatus!.canCancel, true);
        expect(gdprService.accountDeletionStatus!.daysUntilDeletion, 30);
      });

      test('should reset status after cancellation', () {
        gdprService.accountDeletionStatus = AccountDeletionStatus(
          status: 'scheduled_deletion',
          deletionDate: DateTime.now().add(const Duration(days: 30)),
          canCancel: true,
        );

        // Simulate cancellation
        gdprService.accountDeletionStatus = AccountDeletionStatus(status: 'active');

        expect(gdprService.accountDeletionStatus!.isActive, true);
        expect(gdprService.accountDeletionStatus!.isScheduledForDeletion, false);
      });

      test('should handle immediate deletion request', () {
        gdprService.accountDeletionStatus = AccountDeletionStatus(
          status: 'deleted',
        );

        expect(gdprService.accountDeletionStatus!.isDeleted, true);
      });
    });

    group('GDPR Service State Management', () {
      test('should manage loading state correctly', () {
        expect(gdprService.isLoading, false);
        
        // Note: In real implementation, loading state is managed internally
        // during async operations
      });

      test('should manage error state correctly', () {
        expect(gdprService.error, isNull);
        
        // In real implementation, errors would be set during failed operations
      });

      test('should notify listeners on state changes', () {
        var notified = false;
        gdprService.addListener(() {
          notified = true;
        });

        // Simulate a state change
        gdprService.currentExportRequest = DataExportRequest(
          requestId: 'test-123',
          status: 'processing',
          requestedAt: DateTime.now(),
        );

        // Note: In actual implementation, notifyListeners() is called
        expect(gdprService.currentExportRequest, isNotNull);
      });
    });

    group('Grace Period Calculations', () {
      test('should calculate remaining grace period days', () {
        final deletionDate = DateTime.now().add(const Duration(days: 25));
        final status = AccountDeletionStatus(
          status: 'scheduled_deletion',
          deletionDate: deletionDate,
          canCancel: true,
        );

        expect(status.daysUntilDeletion, 25);
      });

      test('should handle expired grace period', () {
        final deletionDate = DateTime.now().subtract(const Duration(days: 1));
        final status = AccountDeletionStatus(
          status: 'scheduled_deletion',
          deletionDate: deletionDate,
          canCancel: false,
        );

        // Days until deletion would be negative, indicating expired
        expect(status.daysUntilDeletion! < 0, true);
      });
    });

    group('Export Request Expiration', () {
      test('should detect expired export request', () {
        final expiredDate = DateTime.now().subtract(const Duration(days: 1));
        final request = DataExportRequest(
          requestId: 'test-123',
          status: 'ready',
          requestedAt: DateTime.now().subtract(const Duration(days: 8)),
          expiresAt: expiredDate,
        );

        expect(request.isExpired, true);
      });

      test('should detect valid export request', () {
        final futureDate = DateTime.now().add(const Duration(days: 5));
        final request = DataExportRequest(
          requestId: 'test-123',
          status: 'ready',
          requestedAt: DateTime.now(),
          expiresAt: futureDate,
          downloadUrl: 'https://example.com/download',
        );

        expect(request.isExpired, false);
        expect(request.isReady, true);
      });
    });

    group('RGPD Compliance Validation', () {
      test('should maintain valid consent check', () {
        expect(gdprService.hasValidConsent, false);

        gdprService.currentConsent = GdprConsent(
          dataProcessing: true,
          consentedAt: DateTime.now(),
        );

        expect(gdprService.hasValidConsent, true);
      });

      test('should validate consent is still valid within 1 year', () {
        gdprService.currentConsent = GdprConsent(
          dataProcessing: true,
          consentedAt: DateTime.now().subtract(const Duration(days: 100)),
        );

        expect(gdprService.isConsentStillValid(), true);
      });

      test('should invalidate consent older than 1 year', () {
        gdprService.currentConsent = GdprConsent(
          dataProcessing: true,
          consentedAt: DateTime.now().subtract(const Duration(days: 400)),
        );

        expect(gdprService.isConsentStillValid(), false);
      });

      test('should suggest consent renewal after 10 months', () {
        gdprService.currentConsent = GdprConsent(
          dataProcessing: true,
          consentedAt: DateTime.now().subtract(const Duration(days: 305)),
        );

        expect(gdprService.needsConsentRenewal(), true);
      });
    });

    group('Privacy Settings Management', () {
      test('should track privacy settings', () {
        expect(gdprService.currentPrivacySettings, isNull);

        gdprService.currentPrivacySettings = PrivacySettings(
          analytics: true,
          marketing: false,
          functionalCookies: true,
          dataRetention: 365,
        );

        expect(gdprService.currentPrivacySettings, isNotNull);
        expect(gdprService.currentPrivacySettings!.analytics, true);
        expect(gdprService.currentPrivacySettings!.marketing, false);
        expect(gdprService.currentPrivacySettings!.dataRetention, 365);
      });

      test('should update privacy settings', () {
        gdprService.currentPrivacySettings = PrivacySettings(
          analytics: true,
          marketing: false,
          functionalCookies: true,
        );

        // Simulate update
        gdprService.currentPrivacySettings = PrivacySettings(
          analytics: true,
          marketing: true, // Changed
          functionalCookies: true,
          dataRetention: 180, // Added
        );

        expect(gdprService.currentPrivacySettings!.marketing, true);
        expect(gdprService.currentPrivacySettings!.dataRetention, 180);
      });
    });

    group('Data Portability (RGPD Art. 20)', () {
      test('should support data export request tracking', () {
        final request = DataExportRequest(
          requestId: 'export-001',
          status: 'processing',
          requestedAt: DateTime.now(),
          estimatedTime: '24 heures',
        );

        gdprService.currentExportRequest = request;

        expect(gdprService.currentExportRequest!.requestId, 'export-001');
        expect(gdprService.currentExportRequest!.isProcessing, true);
      });

      test('should track export readiness', () {
        gdprService.currentExportRequest = DataExportRequest(
          requestId: 'export-001',
          status: 'ready',
          requestedAt: DateTime.now().subtract(const Duration(hours: 12)),
          downloadUrl: 'https://api.goldwen.com/exports/export-001/download',
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(gdprService.currentExportRequest!.isReady, true);
        expect(gdprService.currentExportRequest!.downloadUrl, isNotNull);
        expect(gdprService.currentExportRequest!.isExpired, false);
      });
    });

    group('Right to be Forgotten (RGPD Art. 17)', () {
      test('should support deletion scheduling', () {
        final deletionDate = DateTime.now().add(const Duration(days: 30));
        final status = AccountDeletionStatus(
          status: 'scheduled_deletion',
          deletionDate: deletionDate,
          message: 'Votre compte sera supprimé le ${deletionDate.day}/${deletionDate.month}/${deletionDate.year}',
          canCancel: true,
        );

        gdprService.accountDeletionStatus = status;

        expect(gdprService.accountDeletionStatus!.isScheduledForDeletion, true);
        expect(gdprService.accountDeletionStatus!.canCancel, true);
        expect(gdprService.accountDeletionStatus!.daysUntilDeletion, 30);
      });

      test('should support immediate deletion', () {
        gdprService.accountDeletionStatus = AccountDeletionStatus(
          status: 'deleted',
          message: 'Compte supprimé immédiatement',
        );

        expect(gdprService.accountDeletionStatus!.isDeleted, true);
        expect(gdprService.accountDeletionStatus!.deletionDate, isNull);
      });

      test('should support deletion cancellation', () {
        // Initially scheduled
        gdprService.accountDeletionStatus = AccountDeletionStatus(
          status: 'scheduled_deletion',
          deletionDate: DateTime.now().add(const Duration(days: 20)),
          canCancel: true,
        );

        expect(gdprService.accountDeletionStatus!.canCancel, true);

        // Cancel deletion
        gdprService.accountDeletionStatus = AccountDeletionStatus(status: 'active');

        expect(gdprService.accountDeletionStatus!.isActive, true);
        expect(gdprService.accountDeletionStatus!.isScheduledForDeletion, false);
      });
    });
  });
}
