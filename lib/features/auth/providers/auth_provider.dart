import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _errorMessage;
  
  late final AuthService _authService;
  
  AuthProvider() {
    final apiService = ApiService();
    _authService = AuthService(apiService);
    _initializeAuth();
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get userId => _user?.id;
  String? get email => _user?.email;
  String? get name => _user?.fullName;
  String? get firstName => _user?.firstName;
  String? get lastName => _user?.lastName;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  String? get errorMessage => _errorMessage;
  String? get token => _token;

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    
    if (savedToken != null) {
      _token = savedToken;
      // Verify token is still valid by making a test request
      await checkAuthStatus();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', user.toJson().toString());
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  void _setAuthenticatedState(String token, User user) {
    _token = token;
    _user = user;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void _setErrorState(String error) {
    _status = AuthStatus.unauthenticated;
    _errorMessage = error;
    notifyListeners();
  }

  /// Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      await _saveAuthData(response.token, response.user);
      _setAuthenticatedState(response.token, response.user);
      return true;
    } on ApiException catch (e) {
      _setErrorState(e.message);
      return false;
    } catch (e) {
      _setErrorState('Erreur inattendue lors de l\'inscription');
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      
      await _saveAuthData(response.token, response.user);
      _setAuthenticatedState(response.token, response.user);
      return true;
    } on ApiException catch (e) {
      _setErrorState(e.message);
      return false;
    } catch (e) {
      _setErrorState('Erreur inattendue lors de la connexion');
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual Google Sign In
      // This is a mock implementation for now
      await Future.delayed(const Duration(seconds: 2));
      
      final mockResponse = await _authService.socialLogin(
        socialId: 'google_user_123',
        provider: 'google',
        email: 'user@example.com',
        firstName: 'John',
        lastName: 'Doe',
      );
      
      await _saveAuthData(mockResponse.token, mockResponse.user);
      _setAuthenticatedState(mockResponse.token, mockResponse.user);
    } on ApiException catch (e) {
      _setErrorState(e.message);
    } catch (e) {
      _setErrorState('Erreur lors de la connexion Google');
    }
  }

  Future<void> signInWithApple() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual Apple Sign In
      // This is a mock implementation for now
      await Future.delayed(const Duration(seconds: 2));
      
      final mockResponse = await _authService.socialLogin(
        socialId: 'apple_user_123',
        provider: 'apple',
        email: 'user@privaterelay.appleid.com',
        firstName: 'Jane',
        lastName: 'Doe',
      );
      
      await _saveAuthData(mockResponse.token, mockResponse.user);
      _setAuthenticatedState(mockResponse.token, mockResponse.user);
    } on ApiException catch (e) {
      _setErrorState(e.message);
    } catch (e) {
      _setErrorState('Erreur lors de la connexion Apple');
    }
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.logout();
      await _clearAuthData();
      
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      // Even if logout fails on server, clear local data
      await _clearAuthData();
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    if (_token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // TODO: Implement token validation with backend
      // For now, simulate validation
      await Future.delayed(const Duration(seconds: 1));
      
      // If we have a token, assume authenticated for now
      // In real implementation, make a call to validate token
      if (_user == null) {
        // Token exists but no user data, clear everything
        await _clearAuthData();
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      await _clearAuthData();
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  /// Request password reset
  Future<bool> forgotPassword(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setErrorState(e.message);
      return false;
    } catch (e) {
      _setErrorState('Erreur lors de la demande de réinitialisation');
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}