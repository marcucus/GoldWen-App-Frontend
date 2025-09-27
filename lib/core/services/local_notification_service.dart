import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'navigation_service.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static const int _dailySelectionNotificationId = 1;

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    bool? androidGranted;
    bool? iosGranted;

    if (androidPlugin != null) {
      androidGranted = await androidPlugin.requestNotificationsPermission();
    }

    if (iosPlugin != null) {
      iosGranted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return androidGranted == true || iosGranted == true;
  }

  Future<void> scheduleDailySelectionNotification() async {
    await _notifications.cancel(_dailySelectionNotificationId);

    const androidDetails = AndroidNotificationDetails(
      'daily_selection',
      'Daily Selection',
      channelDescription: 'Daily profile selection notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for 12:00 PM today, or tomorrow if it's already past 12:00 PM
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 12, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      _dailySelectionNotificationId,
      'Votre sélection GoldWen du jour est arrivée !',
      'Découvrez vos nouveaux profils compatibles',
      scheduledTZ,
      notificationDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
      payload: 'daily_selection',
    );
  }

  Future<void> cancelDailySelectionNotification() async {
    await _notifications.cancel(_dailySelectionNotificationId);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant',
      'Instant Notifications',
      channelDescription: 'Instant notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showMatchNotification({
    required String matchedUserName,
  }) async {
    await showInstantNotification(
      title: 'Nouveau match !',
      body: 'Félicitations ! Vous avez un match avec $matchedUserName',
      payload: 'new_match',
      id: 2,
    );
  }

  Future<void> showNewMessageNotification({
    required String senderName,
  }) async {
    await showInstantNotification(
      title: 'Nouveau message',
      body: '$senderName vous a envoyé un message',
      payload: 'new_message',
      id: 3,
    );
  }

  Future<void> showChatExpiringNotification({
    required String partnerName,
    required int hoursLeft,
  }) async {
    await showInstantNotification(
      title: 'Conversation expire bientôt !',
      body: 'Il vous reste ${hoursLeft}h pour discuter avec $partnerName',
      payload: 'chat_expiring',
      id: 4,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    
    if (payload == null) return;

    // Handle different notification types
    switch (payload) {
      case 'daily_selection':
        // Navigate to daily matches page
        // This would typically use a navigation service or global navigator
        _handleDailySelectionTap();
        break;
      case 'new_match':
        // Navigate to matches page
        _handleNewMatchTap();
        break;
      case 'new_message':
        // Navigate to chat
        _handleNewMessageTap();
        break;
      case 'chat_expiring':
        // Navigate to chat
        _handleChatExpiringTap();
        break;
    }
  }

  void _handleDailySelectionTap() {
    NavigationService.navigateToDiscoverTab();
    print('Daily selection notification tapped - navigating to discover');
  }

  void _handleNewMatchTap() {
    NavigationService.navigateToMatches();
    print('New match notification tapped - navigating to matches');
  }

  void _handleNewMessageTap() {
    NavigationService.navigateToNotifications(); // Could be improved to go to specific chat
    print('New message notification tapped - navigating to notifications');  
  }

  void _handleChatExpiringTap() {
    NavigationService.navigateToNotifications(); // Could be improved to go to specific chat
    print('Chat expiring notification tapped - navigating to notifications');
  }

  // Method to show immediate notifications (for foreground FCM messages)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? type,
    String? imageUrl,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload ?? type,
    );
  }

  // Method to show notification with custom sound for different types
  Future<void> showTypedNotification({
    required String type,
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    late AndroidNotificationDetails androidDetails;
    late DarwinNotificationDetails iosDetails;
    late int notificationId;

    switch (type) {
      case 'daily_selection':
        notificationId = 1;
        androidDetails = const AndroidNotificationDetails(
          'daily_selection',
          'Daily Selection',
          channelDescription: 'Daily profile selection notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        break;
        
      case 'new_match':
        notificationId = 2;
        androidDetails = const AndroidNotificationDetails(
          'matches',
          'New Matches',
          channelDescription: 'New match notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        break;
        
      case 'new_message':
        notificationId = 3;
        androidDetails = const AndroidNotificationDetails(
          'messages',
          'New Messages',
          channelDescription: 'New message notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        break;
        
      case 'chat_expiring':
        notificationId = 4;
        androidDetails = const AndroidNotificationDetails(
          'chat_expiring',
          'Chat Expiring',
          channelDescription: 'Chat expiration notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        break;
        
      default:
        notificationId = 999;
        androidDetails = const AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
    }

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload ?? type,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}