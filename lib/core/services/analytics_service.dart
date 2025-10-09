import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Analytics service for tracking user events using Mixpanel
/// Respects GDPR opt-out preferences
class AnalyticsService {
  static Mixpanel? _mixpanel;
  static bool _isInitialized = false;
  static bool _analyticsEnabled = true;

  /// Initialize Mixpanel SDK
  static Future<void> initialize({required String token}) async {
    if (_isInitialized) return;

    try {
      _mixpanel = await Mixpanel.init(
        token,
        trackAutomaticEvents: false, // Manual tracking for GDPR compliance
      );
      _isInitialized = true;

      // Check GDPR consent
      await _loadAnalyticsConsent();

      debugPrint('Analytics service initialized');
    } catch (e) {
      debugPrint('Failed to initialize analytics: $e');
    }
  }

  /// Load analytics consent from local storage
  static Future<void> _loadAnalyticsConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsConsent = prefs.getBool('gdpr_analytics_consent');
      
      // If no explicit consent is given, default to disabled (opt-in approach)
      _analyticsEnabled = analyticsConsent ?? false;

      if (!_analyticsEnabled) {
        await optOut();
      }
    } catch (e) {
      debugPrint('Error loading analytics consent: $e');
      _analyticsEnabled = false;
    }
  }

  /// Update analytics consent status
  static Future<void> updateConsent(bool enabled) async {
    _analyticsEnabled = enabled;
    
    if (!enabled) {
      await optOut();
    } else {
      await optIn();
    }
  }

  /// Opt out of analytics tracking (GDPR compliance)
  static Future<void> optOut() async {
    if (_mixpanel == null) return;
    
    try {
      _mixpanel!.optOutTracking();
      debugPrint('Analytics tracking opted out');
    } catch (e) {
      debugPrint('Error opting out of analytics: $e');
    }
  }

  /// Opt in to analytics tracking
  static Future<void> optIn() async {
    if (_mixpanel == null) return;
    
    try {
      _mixpanel!.optInTracking();
      debugPrint('Analytics tracking opted in');
    } catch (e) {
      debugPrint('Error opting in to analytics: $e');
    }
  }

  /// Identify a user
  static Future<void> identify(String userId) async {
    if (!_isInitialized || !_analyticsEnabled || _mixpanel == null) return;

    try {
      await _mixpanel!.identify(userId);
    } catch (e) {
      debugPrint('Error identifying user: $e');
    }
  }

  /// Set user properties
  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_isInitialized || !_analyticsEnabled || _mixpanel == null) return;

    try {
      final people = _mixpanel!.getPeople();
      await people.set(properties);
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }

  /// Track a generic event
  static Future<void> track(String eventName, {Map<String, dynamic>? properties}) async {
    if (!_isInitialized || !_analyticsEnabled || _mixpanel == null) return;

    try {
      final eventProps = {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
        ...?properties,
      };

      await _mixpanel!.track(eventName, properties: eventProps);
      debugPrint('Analytics event tracked: $eventName');
    } catch (e) {
      debugPrint('Error tracking event $eventName: $e');
    }
  }

  // ========== ONBOARDING EVENTS ==========

  /// Track signup started
  static Future<void> trackSignupStarted(String method) async {
    await track('signup_started', properties: {'method': method});
  }

  /// Track signup completed
  static Future<void> trackSignupCompleted(String userId, String method) async {
    await identify(userId);
    await track('signup_completed', properties: {'method': method});
    await setUserProperties({
      'signup_method': method,
      'signup_date': DateTime.now().toIso8601String(),
    });
  }

  /// Track personality quiz started
  static Future<void> trackPersonalityQuizStarted() async {
    await track('personality_quiz_started');
  }

  /// Track personality quiz completed
  static Future<void> trackPersonalityQuizCompleted() async {
    await track('personality_quiz_completed');
    await setUserProperties({
      'personality_quiz_completed_at': DateTime.now().toIso8601String(),
    });
  }

  /// Track profile setup started
  static Future<void> trackProfileSetupStarted() async {
    await track('profile_setup_started');
  }

  /// Track profile completed
  static Future<void> trackProfileCompleted(String userId) async {
    await identify(userId);
    await track('profile_completed');
    await setUserProperties({
      'profile_completed_at': DateTime.now().toIso8601String(),
      'profile_status': 'complete',
    });
  }

  // ========== MATCHING EVENTS ==========

  /// Track daily selection viewed
  static Future<void> trackDailySelectionViewed(int profileCount) async {
    await track('daily_selection_viewed', properties: {
      'profile_count': profileCount,
    });
  }

  /// Track profile viewed in daily selection
  static Future<void> trackProfileViewed(String profileId) async {
    await track('profile_viewed', properties: {
      'profile_id': profileId,
    });
  }

  /// Track profile chosen (liked)
  static Future<void> trackProfileChosen(String profileId, {double? compatibilityScore}) async {
    await track('profile_chosen', properties: {
      'profile_id': profileId,
      if (compatibilityScore != null) 'compatibility_score': compatibilityScore,
    });
  }

  /// Track profile passed (disliked)
  static Future<void> trackProfilePassed(String profileId) async {
    await track('profile_passed', properties: {
      'profile_id': profileId,
    });
  }

  /// Track match created
  static Future<void> trackMatchCreated(String matchId, String otherUserId) async {
    await track('match_created', properties: {
      'match_id': matchId,
      'other_user_id': otherUserId,
    });
  }

  // ========== CHAT EVENTS ==========

  /// Track chat accepted
  static Future<void> trackChatAccepted(String chatId, String matchId) async {
    await track('chat_accepted', properties: {
      'chat_id': chatId,
      'match_id': matchId,
    });
  }

  /// Track chat declined
  static Future<void> trackChatDeclined(String matchId) async {
    await track('chat_declined', properties: {
      'match_id': matchId,
    });
  }

  /// Track first message sent
  static Future<void> trackFirstMessageSent(String chatId) async {
    await track('first_message_sent', properties: {
      'chat_id': chatId,
    });
  }

  /// Track message sent (any message)
  static Future<void> trackMessageSent(String chatId, {int? messageLength}) async {
    await track('message_sent', properties: {
      'chat_id': chatId,
      if (messageLength != null) 'message_length': messageLength,
    });
  }

  /// Track chat expired
  static Future<void> trackChatExpired(String chatId, int messageCount) async {
    await track('chat_expired', properties: {
      'chat_id': chatId,
      'message_count': messageCount,
    });
  }

  // ========== SUBSCRIPTION EVENTS ==========

  /// Track subscription page viewed
  static Future<void> trackSubscriptionPageViewed() async {
    await track('subscription_page_viewed');
  }

  /// Track subscription started
  static Future<void> trackSubscriptionStarted(String tier, String period) async {
    await track('subscription_started', properties: {
      'tier': tier,
      'period': period,
    });
    await setUserProperties({
      'subscription_tier': tier,
      'subscription_period': period,
      'subscription_started_at': DateTime.now().toIso8601String(),
    });
  }

  /// Track subscription cancelled
  static Future<void> trackSubscriptionCancelled(String tier) async {
    await track('subscription_cancelled', properties: {
      'tier': tier,
    });
    await setUserProperties({
      'subscription_status': 'cancelled',
      'subscription_cancelled_at': DateTime.now().toIso8601String(),
    });
  }

  /// Track subscription restored
  static Future<void> trackSubscriptionRestored(String tier) async {
    await track('subscription_restored', properties: {
      'tier': tier,
    });
  }

  // ========== APP LIFECYCLE EVENTS ==========

  /// Track app opened
  static Future<void> trackAppOpened() async {
    await track('app_opened');
  }

  /// Track app backgrounded
  static Future<void> trackAppBackgrounded() async {
    await track('app_backgrounded');
  }

  // ========== RESET ==========

  /// Reset analytics (for logout/account deletion)
  static Future<void> reset() async {
    if (_mixpanel == null) return;

    try {
      await _mixpanel!.reset();
      debugPrint('Analytics reset');
    } catch (e) {
      debugPrint('Error resetting analytics: $e');
    }
  }
}
