import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goldwen_app/core/services/gdpr_service.dart';
import 'package:goldwen_app/core/models/gdpr_consent.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('GdprService', () {
    late GdprService gdprService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      gdprService = GdprService();
      mockPrefs = MockSharedPreferences();
      SharedPreferences.setMockInitialValues({});
    });

    group('checkConsentStatus', () {
      test('should return false when no consent is stored', () async {
        SharedPreferences.setMockInitialValues({});
        
        final result = await gdprService.checkConsentStatus();
        
        expect(result, false);
        expect(gdprService.hasValidConsent, false);
      });

      test('should return true when valid consent is stored', () async {
        final consentDate = DateTime.now().toIso8601String();
        SharedPreferences.setMockInitialValues({
          'gdpr_consent_given': true,
          'gdpr_consent_date': consentDate,
          'gdpr_marketing_consent': false,
          'gdpr_analytics_consent': true,
        });

        final result = await gdprService.checkConsentStatus();

        expect(result, true);
        expect(gdprService.hasValidConsent, true);
        expect(gdprService.currentConsent, isNotNull);
        expect(gdprService.currentConsent!.dataProcessing, true);
        expect(gdprService.currentConsent!.marketing, false);
        expect(gdprService.currentConsent!.analytics, true);
      });
    });

    group('isConsentStillValid', () {
      test('should return false when no consent exists', () {
        final result = gdprService.isConsentStillValid();
        expect(result, false);
      });

      test('should return true for recent consent', () {
        // gdprService.currentConsent = GdprConsent(
          dataProcessing: true,
          consentedAt: DateTime.now().subtract(const Duration(days: 30)),
        );

        final result = gdprService.isConsentStillValid();
        expect(result, true);
      });

      test('should return false for old consent (over 1 year)', () {
        // gdprService.currentConsent = GdprConsent(
          dataProcessing: true,
          consentedAt: DateTime.now().subtract(const Duration(days: 370)),
        );

        final result = gdprService.isConsentStillValid();
        expect(result, false);
      });
    });

    group('needsConsentRenewal', () {
      test('should return true when no consent exists', () {
        final result = gdprService.needsConsentRenewal();
        expect(result, true);
      });

      test('should return false for recent consent', () {
        // gdprService.currentConsent = GdprConsent(
          dataProcessing: true,
          consentedAt: DateTime.now().subtract(const Duration(days: 30)),
        );

        final result = gdprService.needsConsentRenewal();
        expect(result, false);
      });

      test('should return true for consent older than 10 months', () {
        // gdprService.currentConsent = GdprConsent(
          dataProcessing: true,
          consentedAt: DateTime.now().subtract(const Duration(days: 305)),
        );

        final result = gdprService.needsConsentRenewal();
        expect(result, true);
      });
    });

    group('clearLocalConsentData', () {
      test('should clear all local consent data', () async {
        // Set initial data
        // gdprService.currentConsent = GdprConsent(
          dataProcessing: true,
          consentedAt: DateTime.now(),
        );
        
        await gdprService.clearLocalConsentData();

        expect(gdprService.currentConsent, isNull);
        expect(gdprService.currentPrivacySettings, isNull);
        expect(gdprService.currentPrivacyPolicy, isNull);
      });
    });
  });

  group('GdprConsent model', () {
    test('should create from JSON correctly', () {
      final json = {
        'dataProcessing': true,
        'marketing': false,
        'analytics': true,
        'consentedAt': '2024-01-01T12:00:00Z',
        'consentVersion': '1.0',
      };

      final consent = GdprConsent.fromJson(json);

      expect(consent.dataProcessing, true);
      expect(consent.marketing, false);
      expect(consent.analytics, true);
      expect(consent.consentedAt, DateTime.parse('2024-01-01T12:00:00Z'));
      expect(consent.consentVersion, '1.0');
    });

    test('should convert to JSON correctly', () {
      final consent = GdprConsent(
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: DateTime.parse('2024-01-01T12:00:00Z'),
        consentVersion: '1.0',
      );

      final json = consent.toJson();

      expect(json['dataProcessing'], true);
      expect(json['marketing'], false);
      expect(json['analytics'], true);
      expect(json['consentedAt'], '2024-01-01T12:00:00.000Z');
      expect(json['consentVersion'], '1.0');
    });

    test('should handle optional fields correctly', () {
      final consent = GdprConsent(
        dataProcessing: true,
        consentedAt: DateTime.now(),
      );

      final json = consent.toJson();

      expect(json['dataProcessing'], true);
      expect(json.containsKey('marketing'), false);
      expect(json.containsKey('analytics'), false);
      expect(json.containsKey('consentVersion'), false);
    });
  });

  group('PrivacySettings model', () {
    test('should create from JSON correctly', () {
      final json = {
        'analytics': true,
        'marketing': false,
        'functionalCookies': true,
        'dataRetention': 365,
      };

      final settings = PrivacySettings.fromJson(json);

      expect(settings.analytics, true);
      expect(settings.marketing, false);
      expect(settings.functionalCookies, true);
      expect(settings.dataRetention, 365);
    });

    test('should use default values when fields are missing', () {
      final json = <String, dynamic>{};

      final settings = PrivacySettings.fromJson(json);

      expect(settings.analytics, true);
      expect(settings.marketing, false);
      expect(settings.functionalCookies, true);
      expect(settings.dataRetention, isNull);
    });

    test('should convert to JSON correctly', () {
      final settings = PrivacySettings(
        analytics: false,
        marketing: true,
        functionalCookies: true,
        dataRetention: 730,
      );

      final json = settings.toJson();

      expect(json['analytics'], false);
      expect(json['marketing'], true);
      expect(json['functionalCookies'], true);
      expect(json['dataRetention'], 730);
    });
  });

  group('PrivacyPolicy model', () {
    test('should create from JSON correctly', () {
      final json = {
        'content': 'Privacy policy content',
        'version': '2.0',
        'lastUpdated': '2024-01-01T12:00:00Z',
      };

      final policy = PrivacyPolicy.fromJson(json);

      expect(policy.content, 'Privacy policy content');
      expect(policy.version, '2.0');
      expect(policy.lastUpdated, DateTime.parse('2024-01-01T12:00:00Z'));
    });

    test('should use default values when fields are missing', () {
      final json = <String, dynamic>{};

      final policy = PrivacyPolicy.fromJson(json);

      expect(policy.content, '');
      expect(policy.version, '1.0');
      expect(policy.lastUpdated, isA<DateTime>());
    });
  });
}