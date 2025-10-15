import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_messaging_service.dart';
import 'local_notification_service.dart';
import 'analytics_service.dart';
import 'location_service.dart';

class AppInitializationService {
  static bool _initialized = false;
  static bool _firebaseAvailable = false;
  
  static bool get isInitialized => _initialized;
  static bool get isFirebaseAvailable => _firebaseAvailable;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Check if Firebase is properly initialized
      try {
        await Firebase.initializeApp();
        _firebaseAvailable = true;
        debugPrint('Firebase initialized successfully');
      } catch (e) {
        _firebaseAvailable = false;
        debugPrint('Firebase not available: $e');
      }
      
      // Initialize local notifications first (works without Firebase)
      final localNotificationService = LocalNotificationService();
      await localNotificationService.initialize();
      await localNotificationService.requestPermissions();
      debugPrint('Local notifications initialized successfully');
      
      // Request location permissions at app startup
      try {
        final hasLocationPermission = await LocationService.requestLocationAccess();
        if (hasLocationPermission) {
          debugPrint('Location permission granted');
        } else {
          debugPrint('Location permission denied or not available');
        }
      } catch (e) {
        debugPrint('Error requesting location permission: $e');
      }
      
      // Try to initialize Firebase messaging if available
      if (_firebaseAvailable) {
        try {
          final firebaseMessagingService = FirebaseMessagingService();
          await firebaseMessagingService.initialize();
          debugPrint('Firebase messaging initialized successfully');
        } catch (e) {
          debugPrint('Firebase messaging initialization failed: $e');
        }
      } else {
        debugPrint('Skipping Firebase messaging - Firebase not available');
      }
      
      // Initialize analytics service (Mixpanel)
      // Use environment variable or placeholder token
      const mixpanelToken = String.fromEnvironment(
        'MIXPANEL_TOKEN',
        defaultValue: 'YOUR_MIXPANEL_TOKEN_HERE',
      );
      
      if (mixpanelToken != 'YOUR_MIXPANEL_TOKEN_HERE') {
        try {
          await AnalyticsService.initialize(token: mixpanelToken);
          debugPrint('Analytics service initialized successfully');
        } catch (e) {
          debugPrint('Analytics initialization failed: $e');
        }
      } else {
        debugPrint('Skipping analytics - no token configured');
      }
      
      _initialized = true;
      debugPrint('App initialization completed (Firebase: $_firebaseAvailable)');
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      // Don't rethrow - app should still work with basic functionality
    }
  }
  
  static Future<void> scheduleTestNotifications() async {
    try {
      final localNotificationService = LocalNotificationService();
      await localNotificationService.scheduleDailySelectionNotification();
      debugPrint('Test notifications scheduled');
    } catch (e) {
      debugPrint('Error scheduling test notifications: $e');
    }
  }
  
  static String getInitializationStatus() {
    if (!_initialized) return 'Not initialized';
    
    return _firebaseAvailable 
        ? 'Fully initialized with Firebase' 
        : 'Initialized with local notifications only';
  }
}