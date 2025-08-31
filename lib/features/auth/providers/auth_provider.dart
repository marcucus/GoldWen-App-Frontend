import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  String? get userId => _user?.id;
  String? get email => _user?.email;
  String? get name => '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'.trim();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );
      
      await _handleAuthSuccess(response);
    } catch (e) {
      _handleAuthError(e);
      rethrow; // Ensure exceptions propagate to the UI
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _setLoading();

    try {
      final response = await ApiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      await _handleAuthSuccess(response);
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading();

    try {
      // TODO: Implement Google Sign In with Firebase Auth
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // For now, use mock data - in real implementation, get data from Google Auth
      final response = await ApiService.socialLogin(
        socialId: 'google_user_123',
        provider: 'google',
        email: 'user@example.com',
        firstName: 'John',
        lastName: 'Doe',
      );
      
      await _handleAuthSuccess(response);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> signInWithApple() async {
    _setLoading();

    try {
      // TODO: Implement Apple Sign In
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // For now, use mock data - in real implementation, get data from Apple Auth
      final response = await ApiService.socialLogin(
        socialId: 'apple_user_123',
        provider: 'apple',
        email: 'user@privaterelay.appleid.com',
        firstName: 'Jane',
        lastName: 'Doe',
      );
      
      await _handleAuthSuccess(response);
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    _setLoading();

    try {
      await ApiService.forgotPassword(email);
      _status = AuthStatus.unauthenticated;
      _error = null;
      notifyListeners();
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    _setLoading();

    try {
      await ApiService.resetPassword(token, newPassword);
      _status = AuthStatus.unauthenticated;
      _error = null;
      notifyListeners();
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    _setLoading();

    try {
      await ApiService.changePassword(currentPassword, newPassword);
      _error = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> verifyEmail(String token) async {
    _setLoading();

    try {
      await ApiService.verifyEmail(token);
      // Refresh user data
      await refreshUser();
    } catch (e) {
      _handleAuthError(e);
    }
  }

  Future<void> refreshUser() async {
    if (!isAuthenticated) return;

    try {
      final response = await ApiService.getCurrentUser();
      final userData = response['data'] ?? response;
      _user = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      // If refresh fails, user might need to re-authenticate
      if (e is ApiException && e.isAuthError) {
        await signOut();
      }
    }
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic> response) async {
    try {
      // Debug: Print the full response to understand its structure
      print('Auth response received: $response');
      
      // Try multiple levels of data nesting
      Map<String, dynamic> data;
      if (response['data'] != null) {
        data = response['data'] as Map<String, dynamic>;
      } else if (response['result'] != null) {
        data = response['result'] as Map<String, dynamic>;
      } else {
        data = response;
      }
      print('Extracted data: $data');
      
      // Try different possible structures for user data
      Map<String, dynamic>? userData;
      if (data['user'] != null) {
        if (data['user'] is Map<String, dynamic>) {
          userData = data['user'] as Map<String, dynamic>;
          print('Found user data in user field');
        } else {
          print('Warning: user field exists but is not a Map<String, dynamic>: ${data['user'].runtimeType}');
        }
      } else if (data['profile'] != null) {
        if (data['profile'] is Map<String, dynamic>) {
          userData = data['profile'] as Map<String, dynamic>;
          print('Found user data in profile field');
        } else {
          print('Warning: profile field exists but is not a Map<String, dynamic>: ${data['profile'].runtimeType}');
        }
      } else if (data.containsKey('id') && data.containsKey('email')) {
        // User data might be directly in the response
        userData = data;
        print('Found user data directly in response');
      } else {
        print('Available keys in data: ${data.keys.toList()}');
        throw Exception('User data not found in response. Available keys: ${data.keys.toList()}');
      }
      print('User data: $userData');
      
      // Try different possible token field names
      String? token;
      final possibleTokenFields = [
        'token', 'accessToken', 'access_token', 'authToken', 'auth_token',
        'jwt', 'jwtToken', 'jwt_token', 'bearerToken', 'bearer_token'
      ];
      
      // Check in data first, then in response root
      for (final field in possibleTokenFields) {
        // Safely extract token - check type before casting
        final dataToken = data[field] is String ? data[field] as String : null;
        final responseToken = response[field] is String ? response[field] as String : null;
        token = dataToken ?? responseToken;
        if (token != null && token.isNotEmpty) {
          print('Found token in field: $field');
          break;
        }
      }
      
      print('Token: $token');
      
      
      if (userData == null) {
        print('Available keys in data: ${data.keys.toList()}');
        throw Exception('User data not found or invalid in response. Available keys: ${data.keys.toList()}');
      }
      
      if (token == null || token.isEmpty) {
        print('Available keys in data: ${data.keys.toList()}');
        print('Available keys in response: ${response.keys.toList()}');
        throw Exception('Token not found in response. Checked fields: $possibleTokenFields');
      }
      
      _user = User.fromJson(userData!);
      _token = token;
      _status = AuthStatus.authenticated;
      _error = null;
      
      // Set token for subsequent API calls
      ApiService.setToken(_token!);
      
      print('Authentication successful, status: $_status, isAuthenticated: $isAuthenticated');
      print('User: ${_user?.email}, Token: ${_token?.substring(0, 10)}...');
      notifyListeners();
    } catch (e) {
      print('Error in _handleAuthSuccess: $e');
      print('Stack trace: ${StackTrace.current}');
      _handleAuthError(e);
    }
  }

  void _handleAuthError(dynamic error) {
    _status = AuthStatus.unauthenticated;
    
    if (error is ApiException) {
      _error = error.message;
    } else {
      _error = 'An unexpected error occurred';
    }
    
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    _setLoading();

    try {
      // Call backend logout endpoint if token exists
      if (_token != null) {
        try {
          await ApiService.logout();
        } catch (e) {
          // If logout API call fails, still proceed with local cleanup
          print('Logout API call failed: $e');
        }
      }
      
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      
      // Clear token from API service
      ApiService.clearToken();
    } catch (e) {
      // Even if logout fails, clear local state
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      ApiService.clearToken();
    }
    
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _setLoading();

    try {
      // TODO: Check if user has a valid stored token
      await Future.delayed(const Duration(seconds: 1));
      
      // For now, assume not authenticated
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      await ApiService.updateUserSettings(settings);
      await refreshUser();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Failed to update settings';
      notifyListeners();
    }
  }

  Future<void> deactivateAccount() async {
    try {
      await ApiService.deactivateAccount();
      await signOut();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Failed to deactivate account';
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    try {
      await ApiService.deleteAccount();
      await signOut();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Failed to delete account';
      notifyListeners();
    }
  }
}