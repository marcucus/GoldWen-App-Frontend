import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'local_notification_service.dart';
import 'firebase_messaging_service.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../models/notification.dart';

/// Centralized notification manager that coordinates between local notifications,
/// Firebase messaging, and user settings
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final LocalNotificationService _localNotificationService = LocalNotificationService();
  final FirebaseMessagingService _firebaseMessagingService = FirebaseMessagingService();
  bool _initialized = false;

  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;

    try {
      // Initialize Firebase Messaging
      await _firebaseMessagingService.initialize();
      
      // Initialize Local Notifications
      await _localNotificationService.initialize();
      
      // Load notification settings
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.loadNotificationSettings();
      
      _initialized = true;
      print('NotificationManager initialized successfully');
    } catch (e) {
      print('Error initializing NotificationManager: $e');
      rethrow;
    }
  }

  /// Show a notification if settings permit
  Future<void> showNotificationIfAllowed({
    required BuildContext context,
    required String type,
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    // Check if notification should be shown based on settings
    if (!notificationProvider.shouldShowNotification(type)) {
      print('Notification blocked by settings: $type');
      return;
    }

    // Get notification style preferences
    final style = notificationProvider.getNotificationStyle();
    
    try {
      await _localNotificationService.showTypedNotification(
        type: type,
        title: title,
        body: body,
        payload: payload,
      );
      print('Notification shown: $type - $title');
    } catch (e) {
      print('Failed to show notification: $e');
    }
  }

  /// Show a daily selection notification
  Future<void> showDailySelectionNotification(BuildContext context) async {
    await showNotificationIfAllowed(
      context: context,
      type: 'daily_selection',
      title: 'Votre sélection GoldWen du jour est arrivée !',
      body: 'Découvrez vos nouveaux profils compatibles',
      payload: 'daily_selection',
    );
  }

  /// Show a new match notification
  Future<void> showNewMatchNotification(BuildContext context, String matchedUserName) async {
    await showNotificationIfAllowed(
      context: context,
      type: 'new_match',
      title: 'Nouveau match !',
      body: 'Félicitations ! Vous avez un match avec $matchedUserName',
      payload: 'new_match',
      data: {'matchedUserName': matchedUserName},
    );
  }

  /// Show a new message notification
  Future<void> showNewMessageNotification(BuildContext context, String senderName) async {
    await showNotificationIfAllowed(
      context: context,
      type: 'new_message',
      title: 'Nouveau message',
      body: '$senderName vous a envoyé un message',
      payload: 'new_message',
      data: {'senderName': senderName},
    );
  }

  /// Show a chat expiring notification
  Future<void> showChatExpiringNotification(
    BuildContext context, 
    String partnerName, 
    int hoursLeft
  ) async {
    await showNotificationIfAllowed(
      context: context,
      type: 'chat_expiring',
      title: 'Votre conversation expire bientôt !',
      body: 'Il vous reste ${hoursLeft}h pour discuter avec $partnerName',
      payload: 'chat_expiring',
      data: {'partnerName': partnerName, 'hoursLeft': hoursLeft},
    );
  }

  /// Schedule daily selection notifications
  Future<void> scheduleDailySelectionNotifications(BuildContext context) async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    if (notificationProvider.shouldShowNotification('daily_selection')) {
      try {
        await _localNotificationService.scheduleDailySelectionNotification();
        print('Daily selection notifications scheduled');
      } catch (e) {
        print('Failed to schedule daily selection notifications: $e');
      }
    } else {
      print('Daily selection notifications disabled by user settings');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotificationService.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Failed to cancel notifications: $e');
    }
  }

  /// Handle notification settings changes
  Future<void> onNotificationSettingsChanged(
    BuildContext context,
    NotificationSettings newSettings,
  ) async {
    // If daily selection notifications are disabled, cancel them
    if (!newSettings.dailySelection) {
      await _localNotificationService.cancelDailySelectionNotification();
    } else {
      // If they're enabled, schedule them
      await scheduleDailySelectionNotifications(context);
    }

    // Handle push token registration/removal based on pushEnabled setting
    if (newSettings.pushEnabled && _firebaseMessagingService.deviceToken != null) {
      // Ensure token is registered with backend
      try {
        await _firebaseMessagingService.initialize(); // This will re-register if needed
      } catch (e) {
        print('Failed to re-register push token: $e');
      }
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      final firebasePermission = await _firebaseMessagingService.requestPermissions();
      final localPermission = await _localNotificationService.requestPermissions();
      
      return firebasePermission && localPermission;
    } catch (e) {
      print('Failed to request notification permissions: $e');
      return false;
    }
  }

  /// Get current notification permission status
  bool get isInitialized => _initialized;
  String? get deviceToken => _firebaseMessagingService.deviceToken;
  
  /// Cleanup resources
  void dispose() {
    _firebaseMessagingService.dispose();
  }
}