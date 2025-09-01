class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? fcmToken;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.fcmToken,
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: (json['id'] is String ? json['id'] as String : json['id']?.toString()) ?? 
            (json['_id'] is String ? json['_id'] as String : json['_id']?.toString()) ?? '',
        email: (json['email'] is String ? json['email'] as String : json['email']?.toString()) ?? '',
        firstName: (json['firstName'] is String ? json['firstName'] as String : json['firstName']?.toString()) ?? 
                   (json['first_name'] is String ? json['first_name'] as String : json['first_name']?.toString()) ?? '',
        lastName: (json['lastName'] is String ? json['lastName'] as String : json['lastName']?.toString()) ?? 
                  (json['last_name'] is String ? json['last_name'] as String : json['last_name']?.toString()) ?? '',
        fcmToken: json['fcmToken'] is String ? json['fcmToken'] as String : json['fcmToken']?.toString(),
        notificationsEnabled: json['notificationsEnabled'] is bool ? json['notificationsEnabled'] as bool : 
                             (json['notificationsEnabled']?.toString().toLowerCase() == 'true') ? true : 
                             (json['notificationsEnabled'] == null) ? true : false,
        emailNotifications: json['emailNotifications'] is bool ? json['emailNotifications'] as bool : 
                           (json['emailNotifications']?.toString().toLowerCase() == 'true') ? true : 
                           (json['emailNotifications'] == null) ? true : false,
        pushNotifications: json['pushNotifications'] is bool ? json['pushNotifications'] as bool : 
                          (json['pushNotifications']?.toString().toLowerCase() == 'true') ? true : 
                          (json['pushNotifications'] == null) ? true : false,
        createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
        status: (json['status'] is String ? json['status'] as String : json['status']?.toString()) ?? 'active',
      );
    } catch (e) {
      print('Error parsing User from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }
    if (dateValue is String) {
      return DateTime.parse(dateValue);
    }
    if (dateValue is DateTime) {
      return dateValue;
    }
    // If it's a timestamp (int/double)
    if (dateValue is num) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue.toInt());
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fcmToken': fcmToken,
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? fcmToken,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}

class UserStats {
  final int totalMatches;
  final int totalMessages;
  final int profileViews;
  final int likesReceived;
  final int likesSent;
  final DateTime? lastActive;

  UserStats({
    required this.totalMatches,
    required this.totalMessages,
    required this.profileViews,
    required this.likesReceived,
    required this.likesSent,
    this.lastActive,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalMatches: json['totalMatches'] as int? ?? 0,
      totalMessages: json['totalMessages'] as int? ?? 0,
      profileViews: json['profileViews'] as int? ?? 0,
      likesReceived: json['likesReceived'] as int? ?? 0,
      likesSent: json['likesSent'] as int? ?? 0,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMatches': totalMatches,
      'totalMessages': totalMessages,
      'profileViews': profileViews,
      'likesReceived': likesReceived,
      'likesSent': likesSent,
      'lastActive': lastActive?.toIso8601String(),
    };
  }
}