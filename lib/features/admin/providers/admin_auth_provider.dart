import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../models/admin_user.dart';

enum AdminAuthStatus { initial, loading, authenticated, unauthenticated, error }

class AdminAuthProvider extends ChangeNotifier {
  AdminAuthStatus _status = AdminAuthStatus.initial;
  AdminUser? _currentAdmin;
  String? _error;
  String? _token;

  AdminAuthStatus get status => _status;
  AdminUser? get currentAdmin => _currentAdmin;
  String? get error => _error;
  bool get isAuthenticated => _status == AdminAuthStatus.authenticated && _currentAdmin != null;

  Future<void> login(String email, String password) async {
    try {
      _status = AdminAuthStatus.loading;
      _error = null;
      notifyListeners();

      final response = await ApiService.adminLogin(
        email: email,
        password: password,
      );

      if (response['admin'] != null) {
        _currentAdmin = AdminUser.fromJson(response['admin']);
        _token = response['token']; // If token is provided
        _status = AdminAuthStatus.authenticated;
      } else {
        _status = AdminAuthStatus.unauthenticated;
        _error = response['message'] ?? 'Authentication failed';
      }
    } catch (e) {
      _status = AdminAuthStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _status = AdminAuthStatus.unauthenticated;
    _currentAdmin = null;
    _token = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}