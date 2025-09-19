import 'package:flutter/foundation.dart';
import 'firebase_messaging_service.dart';
import 'local_notification_service.dart';

class AppInitializationService {
  static bool _initialized = false;
  
  static bool get isInitialized => _initialized;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize local notifications first (works without Firebase)
      final localNotificationService = LocalNotificationService();
      await localNotificationService.initialize();
      await localNotificationService.requestPermissions();
      
      // Try to initialize Firebase messaging if available
      try {
        final firebaseMessagingService = FirebaseMessagingService();
        await firebaseMessagingService.initialize();
        debugPrint('Firebase messaging initialized successfully');
      } catch (e) {
        // Firebase not configured or not available
        debugPrint('Firebase messaging not available: $e');
        // Continue without Firebase - local notifications will still work
      }
      
      _initialized = true;
      debugPrint('App initialization completed');
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
}