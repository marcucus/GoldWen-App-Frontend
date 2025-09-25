import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'local_notification_service.dart';
import 'api_service.dart';
import 'navigation_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  
  String? _deviceToken;
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  String? get deviceToken => _deviceToken;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize local notifications first
      await _localNotificationService.initialize();

      // Request permissions for iOS
      await requestPermissions();

      // Get the device token
      await _getDeviceToken();

      // Set up message handlers
      _setupMessageHandlers();

      // Listen for token refresh
      _listenForTokenRefresh();

      _initialized = true;
      print('Firebase Messaging Service initialized successfully');
    } catch (e) {
      print('Error initializing Firebase Messaging Service: $e');
      rethrow;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      // Request FCM permissions
      final NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Also request local notification permissions
      final bool localPermission = await _localNotificationService.requestPermissions();

      final bool fcmPermissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      print('FCM Permission status: ${settings.authorizationStatus}');
      print('Local notification permission: $localPermission');

      return fcmPermissionGranted && localPermission;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<String?> _getDeviceToken() async {
    try {
      _deviceToken = await _firebaseMessaging.getToken();
      print('FCM Device Token: ${_deviceToken?.substring(0, 20)}...');
      
      if (_deviceToken != null) {
        await _registerDeviceWithBackend(_deviceToken!);
      }
      
      return _deviceToken;
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }

  Future<void> _registerDeviceWithBackend(String token) async {
    try {
      // Determine platform
      final platform = Platform.isIOS ? 'ios' : 'android';
      
      // Register device token with backend using the correct API endpoint
      await ApiService.registerPushToken(
        token: token,
        platform: platform,
        appVersion: '1.0.0', // This should come from package info
      );
      print('Device token registered with backend successfully');
    } catch (e) {
      print('Error registering device token with backend: $e');
      // Don't rethrow - this is not critical for initialization
    }
  }

  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle messages when app is opened from terminated state
    _handleInitialMessage();
  }

  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');
    
    // Handle navigation based on notification type
    _handleNotificationNavigation(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _localNotificationService.showNotification(
        id: message.hashCode,
        title: notification.title ?? 'GoldWen',
        body: notification.body ?? '',
        payload: jsonEncode(data),
        type: data['type'] ?? 'general',
      );
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'daily_selection':
        NavigationService.navigateToDiscoverTab();
        break;
      case 'new_match':
        final matchedUserId = data['matchedUserId'];
        if (matchedUserId != null) {
          NavigationService.navigateToMatches();
        }
        break;
      case 'new_message':
        final conversationId = data['conversationId'];
        if (conversationId != null) {
          NavigationService.navigateToChat(conversationId);
        }
        break;
      case 'chat_expiring':
        final conversationId = data['conversationId'];
        if (conversationId != null) {
          NavigationService.navigateToChat(conversationId);
        }
        break;
      default:
        NavigationService.navigateToNotifications();
    }
  }

  void _listenForTokenRefresh() {
    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((String token) {
      _deviceToken = token;
      print('FCM Token refreshed: ${token.substring(0, 20)}...');
      _registerDeviceWithBackend(token);
    });
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      // Remove token from backend first
      if (_deviceToken != null) {
        await ApiService.removePushToken(token: _deviceToken!);
      }
      
      // Then delete from Firebase
      await _firebaseMessaging.deleteToken();
      _deviceToken = null;
      print('FCM token deleted');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  
  // Handle background notification data processing here if needed
  // Note: UI operations cannot be performed in background handler
}