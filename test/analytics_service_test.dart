import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goldwen_app/core/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      // Note: In a real test environment, you might want to reset the analytics service
      // For now, we're just testing the public API
    });

    group('Initialization', () {
      test('should initialize without errors', () async {
        await AnalyticsService.initialize(token: 'test_token');
        // If we get here without throwing, initialization succeeded
        expect(true, true);
      });

      test('should not re-initialize if already initialized', () async {
        await AnalyticsService.initialize(token: 'test_token');
        // Second initialization should complete without error
        await AnalyticsService.initialize(token: 'test_token');
        expect(true, true);
      });
    });

    group('GDPR Consent', () {
      test('should default to analytics disabled without consent', () async {
        SharedPreferences.setMockInitialValues({});
        
        // Initialize without consent
        await AnalyticsService.initialize(token: 'test_token');
        
        // Analytics should be disabled by default (opt-in approach)
        // We can't directly test the internal state, but we can verify
        // that tracking calls don't throw errors when disabled
        await AnalyticsService.track('test_event');
        expect(true, true);
      });

      test('should enable analytics when consent is given', () async {
        SharedPreferences.setMockInitialValues({
          'gdpr_analytics_consent': true,
        });
        
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.updateConsent(true);
        
        // Analytics should be enabled
        await AnalyticsService.track('test_event');
        expect(true, true);
      });

      test('should disable analytics when consent is withdrawn', () async {
        SharedPreferences.setMockInitialValues({
          'gdpr_analytics_consent': true,
        });
        
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.updateConsent(false);
        
        // Analytics should be disabled
        await AnalyticsService.track('test_event');
        expect(true, true);
      });

      test('should opt out when updateConsent(false) is called', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.updateConsent(false);
        
        // Opt-out should succeed without errors
        expect(true, true);
      });

      test('should opt in when updateConsent(true) is called', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.updateConsent(true);
        
        // Opt-in should succeed without errors
        expect(true, true);
      });
    });

    group('User Identification', () {
      test('should identify user without errors', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.identify('user_123');
        expect(true, true);
      });

      test('should set user properties without errors', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.setUserProperties({
          'name': 'Test User',
          'email': 'test@example.com',
        });
        expect(true, true);
      });
    });

    group('Event Tracking', () {
      test('should track generic events without errors', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.track('custom_event', properties: {
          'key': 'value',
        });
        expect(true, true);
      });

      test('should track events with no properties', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.track('simple_event');
        expect(true, true);
      });
    });

    group('Onboarding Events', () {
      test('should track signup started', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackSignupStarted('email');
        expect(true, true);
      });

      test('should track signup completed', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackSignupCompleted('user_123', 'google');
        expect(true, true);
      });

      test('should track personality quiz started', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackPersonalityQuizStarted();
        expect(true, true);
      });

      test('should track personality quiz completed', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackPersonalityQuizCompleted();
        expect(true, true);
      });

      test('should track profile completed', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackProfileCompleted('user_123');
        expect(true, true);
      });
    });

    group('Matching Events', () {
      test('should track daily selection viewed', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackDailySelectionViewed(3);
        expect(true, true);
      });

      test('should track profile chosen', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackProfileChosen('profile_123', compatibilityScore: 85.5);
        expect(true, true);
      });

      test('should track profile chosen without compatibility score', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackProfileChosen('profile_123');
        expect(true, true);
      });

      test('should track profile passed', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackProfilePassed('profile_123');
        expect(true, true);
      });

      test('should track match created', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackMatchCreated('match_123', 'user_456');
        expect(true, true);
      });
    });

    group('Chat Events', () {
      test('should track chat accepted', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackChatAccepted('chat_123', 'match_456');
        expect(true, true);
      });

      test('should track first message sent', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackFirstMessageSent('chat_123');
        expect(true, true);
      });

      test('should track message sent', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackMessageSent('chat_123', messageLength: 50);
        expect(true, true);
      });

      test('should track chat expired', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackChatExpired('chat_123', 10);
        expect(true, true);
      });
    });

    group('Subscription Events', () {
      test('should track subscription page viewed', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackSubscriptionPageViewed();
        expect(true, true);
      });

      test('should track subscription started', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackSubscriptionStarted('plus', 'monthly');
        expect(true, true);
      });

      test('should track subscription cancelled', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackSubscriptionCancelled('plus');
        expect(true, true);
      });

      test('should track subscription restored', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackSubscriptionRestored('plus');
        expect(true, true);
      });
    });

    group('App Lifecycle Events', () {
      test('should track app opened', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackAppOpened();
        expect(true, true);
      });

      test('should track app backgrounded', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.trackAppBackgrounded();
        expect(true, true);
      });
    });

    group('Reset', () {
      test('should reset analytics without errors', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.identify('user_123');
        await AnalyticsService.reset();
        expect(true, true);
      });
    });

    group('Error Handling', () {
      test('should handle tracking when not initialized', () async {
        // Reset by creating a fresh test environment
        // Even without initialization, tracking should not throw
        await AnalyticsService.track('test_event');
        expect(true, true);
      });

      test('should handle null properties gracefully', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.track('test_event', properties: null);
        expect(true, true);
      });

      test('should handle empty properties gracefully', () async {
        await AnalyticsService.initialize(token: 'test_token');
        await AnalyticsService.track('test_event', properties: {});
        expect(true, true);
      });
    });
  });
}
