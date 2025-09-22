class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? fcmToken;
  final bool? notificationsEnabled;
  final bool? emailNotifications;
  final bool? pushNotifications;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;
  final bool? isOnboardingCompleted;
  final bool? isProfileCompleted;
  final bool? hasActiveSubscription;
  final String? subscriptionPlan;
  final DateTime? subscriptionExpiresAt;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.fcmToken,
    this.notificationsEnabled,
    this.emailNotifications,
    this.pushNotifications,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.isOnboardingCompleted,
    this.isProfileCompleted,
    this.hasActiveSubscription,
    this.subscriptionPlan,
    this.subscriptionExpiresAt,
  });

  // Computed property for display name
  String? get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName;
    } else if (lastName != null) {
      return lastName;
    }
    return null;
  }

  // Add missing getters that are expected by admin and user list components
  int? get age => null; // Age should come from profile, not user
  String? get bio => null; // Bio should come from profile, not user  
  DateTime? get lastActive => updatedAt; // Use updatedAt as lastActive
  String? get profilePicture => photoUrl; // Alias for photoUrl

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: (json['id'] is String ? json['id'] as String : json['id']?.toString()) ?? 
            (json['_id'] is String ? json['_id'] as String : json['_id']?.toString()) ?? '',
        email: (json['email'] is String ? json['email'] as String : json['email']?.toString()) ?? '',
        firstName: json['firstName'] is String ? json['firstName'] as String : 
                   json['first_name'] is String ? json['first_name'] as String : 
                   json['firstName']?.toString(),
        lastName: json['lastName'] is String ? json['lastName'] as String : 
                  json['last_name'] is String ? json['last_name'] as String :
                  json['lastName']?.toString(),
        photoUrl: json['photoUrl'] is String ? json['photoUrl'] as String : 
                  json['photo_url'] is String ? json['photo_url'] as String : 
                  json['avatar'] is String ? json['avatar'] as String :
                  json['photoUrl']?.toString(),
        fcmToken: json['fcmToken'] is String ? json['fcmToken'] as String : json['fcmToken']?.toString(),
        notificationsEnabled: json['notificationsEnabled'] is bool ? json['notificationsEnabled'] as bool : 
                             (json['notificationsEnabled']?.toString().toLowerCase() == 'true') ? true : 
                             json['notificationsEnabled'] == null ? null : false,
        emailNotifications: json['emailNotifications'] is bool ? json['emailNotifications'] as bool : 
                           (json['emailNotifications']?.toString().toLowerCase() == 'true') ? true : 
                           json['emailNotifications'] == null ? null : false,
        pushNotifications: json['pushNotifications'] is bool ? json['pushNotifications'] as bool : 
                          (json['pushNotifications']?.toString().toLowerCase() == 'true') ? true : 
                          json['pushNotifications'] == null ? null : false,
        createdAt: json['createdAt'] != null || json['created_at'] != null 
                  ? _parseDateTime(json['createdAt'] ?? json['created_at']) 
                  : null,
        updatedAt: json['updatedAt'] != null || json['updated_at'] != null 
                  ? _parseDateTime(json['updatedAt'] ?? json['updated_at']) 
                  : null,
        status: json['status'] is String ? json['status'] as String : json['status']?.toString(),
        isOnboardingCompleted: json['isOnboardingCompleted'] is bool ? json['isOnboardingCompleted'] as bool :
                              (json['isOnboardingCompleted']?.toString().toLowerCase() == 'true') ? true :
                              json['isOnboardingCompleted'] == null ? null : false,
        isProfileCompleted: json['isProfileCompleted'] is bool ? json['isProfileCompleted'] as bool :
                           (json['isProfileCompleted']?.toString().toLowerCase() == 'true') ? true :
                           json['isProfileCompleted'] == null ? null : false,
        hasActiveSubscription: json['hasActiveSubscription'] is bool ? json['hasActiveSubscription'] as bool :
                              (json['hasActiveSubscription']?.toString().toLowerCase() == 'true') ? true :
                              json['hasActiveSubscription'] == null ? null : false,
        subscriptionPlan: json['subscriptionPlan'] is String ? json['subscriptionPlan'] as String : json['subscriptionPlan']?.toString(),
        subscriptionExpiresAt: json['subscriptionExpiresAt'] != null 
                  ? _parseDateTime(json['subscriptionExpiresAt']) 
                  : null,
      );
    } catch (e) {
      print('Error parsing User from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return null;
    }
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('Error parsing date: $dateValue');
        return null;
      }
    }
    if (dateValue is DateTime) {
      return dateValue;
    }
    // If it's a timestamp (int/double)
    if (dateValue is num) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue.toInt());
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (notificationsEnabled != null) 'notificationsEnabled': notificationsEnabled,
      if (emailNotifications != null) 'emailNotifications': emailNotifications,
      if (pushNotifications != null) 'pushNotifications': pushNotifications,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (status != null) 'status': status,
      if (isOnboardingCompleted != null) 'isOnboardingCompleted': isOnboardingCompleted,
      if (isProfileCompleted != null) 'isProfileCompleted': isProfileCompleted,
      if (hasActiveSubscription != null) 'hasActiveSubscription': hasActiveSubscription,
      if (subscriptionPlan != null) 'subscriptionPlan': subscriptionPlan,
      if (subscriptionExpiresAt != null) 'subscriptionExpiresAt': subscriptionExpiresAt!.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? fcmToken,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    bool? isOnboardingCompleted,
    bool? isProfileCompleted,
    bool? hasActiveSubscription,
    String? subscriptionPlan,
    DateTime? subscriptionExpiresAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
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