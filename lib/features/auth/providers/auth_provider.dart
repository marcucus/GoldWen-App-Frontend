import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _userId;
  String? _email;
  String? _name;
  String? _token;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get email => _email;
  String? get name => _name;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );
      
      _handleAuthSuccess(response);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final response = await ApiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      _handleAuthSuccess(response);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      rethrow;
    }
    
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _status = AuthStatus.loading;
    notifyListeners();

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
      
      _handleAuthSuccess(response);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  Future<void> signInWithApple() async {
    _status = AuthStatus.loading;
    notifyListeners();

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
      
      _handleAuthSuccess(response);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  void _handleAuthSuccess(Map<String, dynamic> response) {
    final data = response['data'];
    final user = data['user'];
    
    _userId = user['id'];
    _email = user['email'];
    _name = '${user['firstName']} ${user['lastName'] ?? ''}';
    _token = data['token'];
    _status = AuthStatus.authenticated;
    
    // Set token for subsequent API calls
    ApiService.setToken(_token!);
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // TODO: Implement sign out logic with backend
      await Future.delayed(const Duration(seconds: 1));
      
      _userId = null;
      _email = null;
      _name = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      
      // Clear token from API service
      ApiService.setToken('');
    } catch (e) {
      // Handle error
    }
    
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // TODO: Check if user is already authenticated
      await Future.delayed(const Duration(seconds: 1));
      
      // For now, assume not authenticated
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }
}