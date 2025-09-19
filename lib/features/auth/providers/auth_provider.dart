import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
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
  String? get name => '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'.trim().isNotEmpty 
      ? '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'.trim() 
      : null;

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
      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Sign out any existing user first to ensure fresh sign-in
      await googleSignIn.signOut();
      
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        _setUnauthenticated();
        return;
      }

      // Get the auth details from the Google Sign In
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null) {
        throw Exception('Failed to obtain Google access token');
      }

      // Use the Google user information to authenticate with our backend
      final response = await ApiService.socialLogin(
        socialId: googleUser.id,
        provider: 'google',
        email: googleUser.email,
        firstName: googleUser.displayName?.split(' ').first ?? '',
        lastName: googleUser.displayName?.split(' ').skip(1).join(' '),
      );
      
      await _handleAuthSuccess(response);
    } catch (e) {
      print('Google Sign-In Error: $e');
      _handleAuthError(e);
    }
  }

  Future<void> signInWithApple() async {
    _setLoading();

    try {
      // Check if Apple Sign In is available on this device
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      // Trigger the Apple Sign In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Extract user information
      String? firstName;
      String? lastName;
      
      if (credential.givenName != null || credential.familyName != null) {
        firstName = credential.givenName;
        lastName = credential.familyName;
      }

      // Use the Apple credential to authenticate with our backend
      final response = await ApiService.socialLogin(
        socialId: credential.userIdentifier,
        provider: 'apple',
        email: credential.email ?? 'noemail@appleid.com', // Apple might not provide email
        firstName: firstName ?? '',
        lastName: lastName ?? '',
      );
      
      await _handleAuthSuccess(response);
    } catch (e) {
      print('Apple Sign-In Error: $e');
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
      
      // Update stored user data
      await _storeAuthData();
      
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
      
      // The backend returns: { "success": true, "message": "...", "data": { "user": {...}, "accessToken": "..." } }
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Response data is null');
      }
      print('Extracted data: $data');
      
      // Extract user data
      final userData = data['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('User data not found in response');
      }
      print('User data: $userData');
      
      // Extract token - backend returns it as 'accessToken'
      final token = data['accessToken'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Access token not found in response');
      }
      print('Token: ${token.substring(0, 10)}...');
      
      _user = User.fromJson(userData);
      _token = token;
      _status = AuthStatus.authenticated;
      _error = null;
      
      // Set token for subsequent API calls
      ApiService.setToken(_token!);
      
      // Store token and user data for session persistence
      await _storeAuthData();
      
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
      
      // Clear stored auth data
      await _clearAuthData();
    } catch (e) {
      // Even if logout fails, clear local state
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      ApiService.clearToken();
      await _clearAuthData();
    }
    
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _setLoading();

    try {
      // Check for stored authentication data
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      final storedUserData = prefs.getString('user_data');
      
      if (storedToken != null && storedUserData != null) {
        print('Found stored auth data, attempting to restore session...');
        
        // Set the token for API calls
        ApiService.setToken(storedToken);
        
        // Verify the token is still valid by getting current user
        try {
          final response = await ApiService.getCurrentUser();
          final userData = response['data'] ?? response;
          
          // Update with fresh user data from server
          _user = User.fromJson(userData);
          _token = storedToken;
          _status = AuthStatus.authenticated;
          _error = null;
          
          print('Session restored successfully for user: ${_user?.email}');
          notifyListeners();
          return;
        } catch (e) {
          print('Stored token is invalid, clearing auth data: $e');
          await _clearAuthData();
        }
      }
      
      // No valid stored data, user needs to authenticate
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      print('Error checking auth status: $e');
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

  Future<void> markProfileCompleted() async {
    try {
      await ApiService.updateUser({
        'isProfileCompleted': true,
        'isOnboardingCompleted': true,
      });
      await refreshUser();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Failed to mark profile as completed';
      notifyListeners();
    }
  }

  Future<void> markOnboardingCompleted() async {
    try {
      await ApiService.updateUser({
        'isOnboardingCompleted': true,
      });
      await refreshUser();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Failed to mark onboarding as completed';
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

  // Helper methods for persistent storage
  Future<void> _storeAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
      }
      if (_user != null) {
        await prefs.setString('user_data', jsonEncode(_user!.toJson()));
      }
    } catch (e) {
      print('Error storing auth data: $e');
    }
  }

  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }
}