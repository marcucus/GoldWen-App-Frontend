# Clean Code Without Debug Logs

Once you've verified that the fix works correctly, you can remove the debugging logs by applying these changes:

## 1. Clean splash_page.dart

```dart
// Remove debug logs from _checkAuthStatus method
if (authProvider.isAuthenticated && authProvider.user != null) {
  await authProvider.refreshUser(); 
  final user = authProvider.user!;

  bool hasLocationPermission = await LocationService.checkLocationPermission();
  
  if (!hasLocationPermission) {
    if (mounted) {
      context.go('/welcome');
    }
    return;
  }

  if (user.isOnboardingCompleted == true && user.isProfileCompleted == true) {
    LocationService().initialize();
    if (mounted) {
      context.go('/home');
    }
    return;
  } else if (user.isOnboardingCompleted == true) {
    if (mounted) {
      context.go('/profile-setup');
    }
    return;
  } else {
    if (mounted) {
      context.go('/questionnaire');
    }
    return;
  }
}
```

## 2. Clean auth_provider.dart

```dart
Future<void> refreshUser() async {
  if (!isAuthenticated) return;

  try {
    final response = await ApiService.getCurrentUser();
    final userData = response['data'] ?? response;
    _user = User.fromJson(userData);
    
    await _storeAuthData();
    notifyListeners();
  } catch (e) {
    if (e is ApiException && e.isAuthError) {
      await signOut();
    }
  }
}
```

## 3. Clean user.dart

```dart
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
    );
  } catch (e) {
    print('Error parsing User from JSON: $e');
    print('JSON data: $json');
    rethrow;
  }
}
```

To apply these clean versions, use the `str_replace_editor` tool to replace the current implementations with these clean versions that remove all the debug print statements.