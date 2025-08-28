import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/models.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  NotificationSettings? _settings;
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  NotificationSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  List<AppNotification> get unreadNotifications {
    return _notifications.where((notification) => !notification.isRead).toList();
  }

  List<AppNotification> get readNotifications {
    return _notifications.where((notification) => notification.isRead).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadNotifications({
    int page = 1,
    int limit = 50,
    String? type,
    bool? read,
  }) async {
    if (page == 1) _setLoading();

    try {
      final response = await ApiService.getNotifications(
        page: page,
        limit: limit,
        type: type,
        read: read,
      );
      
      final notificationsData = response['data'] ?? response['notifications'] ?? [];
      final newNotifications = (notificationsData as List)
          .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
          .toList();

      if (page == 1) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }
      
      _updateUnreadCount();
      _error = null;
    } catch (e) {
      _handleError(e, 'Failed to load notifications');
    } finally {
      if (page == 1) _setLoaded();
    }
  }

  Future<void> loadNotificationSettings() async {
    try {
      // Note: This endpoint might be part of user settings
      // For now, we'll assume default settings
      _settings = NotificationSettings(
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        promotions: false,
        systemUpdates: true,
        emailFrequency: 'weekly',
        pushEnabled: true,
        emailEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
      );
      
      notifyListeners();
    } catch (e) {
      _handleError(e, 'Failed to load notification settings');
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await ApiService.markNotificationAsRead(notificationId);
      
      // Update local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _updateUnreadCount();
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _handleError(e, 'Failed to mark notification as read');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    _setLoading();

    try {
      await ApiService.markAllNotificationsAsRead();
      
      // Update all local notifications
      _notifications = _notifications.map((notification) {
        if (!notification.isRead) {
          return notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return notification;
      }).toList();
      
      _updateUnreadCount();
      _error = null;
      _setLoaded();
      return true;
    } catch (e) {
      _handleError(e, 'Failed to mark all notifications as read');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await ApiService.deleteNotification(notificationId);
      
      // Remove from local list
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
      notifyListeners();
      
      return true;
    } catch (e) {
      _handleError(e, 'Failed to delete notification');
      return false;
    }
  }

  Future<bool> updateNotificationSettings(NotificationSettings newSettings) async {
    _setLoading();

    try {
      await ApiService.updateNotificationSettings(newSettings.toJson());
      
      _settings = newSettings;
      _error = null;
      _setLoaded();
      return true;
    } catch (e) {
      _handleError(e, 'Failed to update notification settings');
      return false;
    }
  }

  Future<bool> sendTestNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await ApiService.sendTestNotification(
        title: title,
        body: body,
        type: type,
      );
      
      // Optionally reload notifications to see the test notification
      await loadNotifications();
      
      return true;
    } catch (e) {
      _handleError(e, 'Failed to send test notification');
      return false;
    }
  }

  // Filter methods
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  List<AppNotification> get dailySelectionNotifications {
    return getNotificationsByType('daily_selection');
  }

  List<AppNotification> get matchNotifications {
    return getNotificationsByType('new_match');
  }

  List<AppNotification> get messageNotifications {
    return getNotificationsByType('new_message');
  }

  List<AppNotification> get systemNotifications {
    return getNotificationsByType('system');
  }

  // Utility methods for notification badges
  bool get hasUnreadDailySelection {
    return unreadNotifications.any((n) => n.isDailySelection);
  }

  bool get hasUnreadMatches {
    return unreadNotifications.any((n) => n.isNewMatch);
  }

  bool get hasUnreadMessages {
    return unreadNotifications.any((n) => n.isNewMessage);
  }

  int get unreadMatchesCount {
    return unreadNotifications.where((n) => n.isNewMatch).length;
  }

  int get unreadMessagesCount {
    return unreadNotifications.where((n) => n.isNewMessage).length;
  }

  // Settings convenience methods
  Future<void> toggleDailySelectionNotifications() async {
    if (_settings != null) {
      final newSettings = _settings!.copyWith(
        dailySelection: !_settings!.dailySelection,
      );
      await updateNotificationSettings(newSettings);
    }
  }

  Future<void> toggleNewMatchNotifications() async {
    if (_settings != null) {
      final newSettings = _settings!.copyWith(
        newMatches: !_settings!.newMatches,
      );
      await updateNotificationSettings(newSettings);
    }
  }

  Future<void> toggleNewMessageNotifications() async {
    if (_settings != null) {
      final newSettings = _settings!.copyWith(
        newMessages: !_settings!.newMessages,
      );
      await updateNotificationSettings(newSettings);
    }
  }

  Future<void> togglePushNotifications() async {
    if (_settings != null) {
      final newSettings = _settings!.copyWith(
        pushEnabled: !_settings!.pushEnabled,
      );
      await updateNotificationSettings(newSettings);
    }
  }

  Future<void> toggleEmailNotifications() async {
    if (_settings != null) {
      final newSettings = _settings!.copyWith(
        emailEnabled: !_settings!.emailEnabled,
      );
      await updateNotificationSettings(newSettings);
    }
  }

  void _updateUnreadCount() {
    _unreadCount = unreadNotifications.length;
  }

  // Utility methods
  void _setLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _setLoaded() {
    _isLoading = false;
    notifyListeners();
  }

  void _handleError(dynamic error, String fallbackMessage) {
    _isLoading = false;
    
    if (error is ApiException) {
      _error = error.message;
    } else {
      _error = fallbackMessage;
    }
    
    notifyListeners();
  }
}

// Extension to add copyWith method to AppNotification
extension AppNotificationExtension on AppNotification {
  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? imageUrl,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}