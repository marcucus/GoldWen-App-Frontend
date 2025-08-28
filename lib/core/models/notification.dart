import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? imageUrl;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.imageUrl,
    this.actionUrl,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      actionUrl: json['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  bool get isDailySelection => type == 'daily_selection';
  bool get isNewMatch => type == 'new_match';
  bool get isNewMessage => type == 'new_message';
  bool get isChatExpiring => type == 'chat_expiring';
  bool get isSystem => type == 'system';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

class NotificationSettings {
  final bool dailySelection;
  final bool newMatches;
  final bool newMessages;
  final bool chatExpiring;
  final bool promotions;
  final bool systemUpdates;
  final String emailFrequency;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  NotificationSettings({
    required this.dailySelection,
    required this.newMatches,
    required this.newMessages,
    required this.chatExpiring,
    required this.promotions,
    required this.systemUpdates,
    required this.emailFrequency,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      dailySelection: json['dailySelection'] as bool? ?? true,
      newMatches: json['newMatches'] as bool? ?? true,
      newMessages: json['newMessages'] as bool? ?? true,
      chatExpiring: json['chatExpiring'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? false,
      systemUpdates: json['systemUpdates'] as bool? ?? true,
      emailFrequency: json['emailFrequency'] as String? ?? 'weekly',
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '08:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailySelection': dailySelection,
      'newMatches': newMatches,
      'newMessages': newMessages,
      'chatExpiring': chatExpiring,
      'promotions': promotions,
      'systemUpdates': systemUpdates,
      'emailFrequency': emailFrequency,
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  NotificationSettings copyWith({
    bool? dailySelection,
    bool? newMatches,
    bool? newMessages,
    bool? chatExpiring,
    bool? promotions,
    bool? systemUpdates,
    String? emailFrequency,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationSettings(
      dailySelection: dailySelection ?? this.dailySelection,
      newMatches: newMatches ?? this.newMatches,
      newMessages: newMessages ?? this.newMessages,
      chatExpiring: chatExpiring ?? this.chatExpiring,
      promotions: promotions ?? this.promotions,
      systemUpdates: systemUpdates ?? this.systemUpdates,
      emailFrequency: emailFrequency ?? this.emailFrequency,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  bool get isInQuietHours {
    final now = DateTime.now();
    final startTime = _parseTime(quietHoursStart);
    final endTime = _parseTime(quietHoursEnd);
    final currentTime = TimeOfDay.fromDateTime(now);

    if (startTime.hour > endTime.hour || 
        (startTime.hour == endTime.hour && startTime.minute > endTime.minute)) {
      // Quiet hours span midnight
      return _isTimeAfterOrEqual(currentTime, startTime) || 
             _isTimeBefore(currentTime, endTime);
    } else {
      // Quiet hours within same day
      return _isTimeAfterOrEqual(currentTime, startTime) && 
             _isTimeBefore(currentTime, endTime);
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  bool _isTimeAfterOrEqual(TimeOfDay time, TimeOfDay other) {
    return time.hour > other.hour || 
           (time.hour == other.hour && time.minute >= other.minute);
  }

  bool _isTimeBefore(TimeOfDay time, TimeOfDay other) {
    return time.hour < other.hour || 
           (time.hour == other.hour && time.minute < other.minute);
  }
}