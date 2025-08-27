import '../../../core/services/api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  /// Register new user with email and password
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _apiService.post('/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });

    return AuthResponse.fromJson(response.data);
  }

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final authResponse = AuthResponse.fromJson(response.data);
    
    // Set token for future requests
    _apiService.setAuthToken(authResponse.token);
    
    return authResponse;
  }

  /// Social login (Google/Apple)
  Future<AuthResponse> socialLogin({
    required String socialId,
    required String provider,
    required String email,
    required String firstName,
    String? lastName,
  }) async {
    final response = await _apiService.post('/auth/social-login', data: {
      'socialId': socialId,
      'provider': provider,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
    });

    final authResponse = AuthResponse.fromJson(response.data);
    
    // Set token for future requests
    _apiService.setAuthToken(authResponse.token);
    
    return authResponse;
  }

  /// Logout user
  Future<void> logout() async {
    await _apiService.post('/auth/logout');
    _apiService.setAuthToken(null);
  }

  /// Request password reset
  Future<void> forgotPassword(String email) async {
    await _apiService.post('/auth/forgot-password', data: {
      'email': email,
    });
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiService.post('/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  /// Change password (authenticated user)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiService.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Verify email with token
  Future<void> verifyEmail(String token) async {
    await _apiService.post('/auth/verify-email', data: {
      'token': token,
    });
  }

  /// Refresh token
  Future<AuthResponse> refreshToken() async {
    final response = await _apiService.post('/auth/refresh');
    
    final authResponse = AuthResponse.fromJson(response.data);
    _apiService.setAuthToken(authResponse.token);
    
    return authResponse;
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}

class User {
  final String id;
  final String email;
  final String firstName;
  final String? lastName;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get fullName {
    if (lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName;
  }
}