import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/user.dart';
import '../models/admin_report.dart';
import '../models/admin_analytics.dart';

class AdminProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  // Analytics
  AdminAnalytics? _analytics;
  
  // Users Management
  List<User> _users = [];
  int _currentUsersPage = 1;
  bool _hasMoreUsers = true;
  String? _usersSearchQuery;
  String? _usersStatusFilter;
  
  // Reports Management
  List<AdminReport> _reports = [];
  int _currentReportsPage = 1;
  bool _hasMoreReports = true;
  String? _reportsStatusFilter;
  String? _reportsTypeFilter;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  AdminAnalytics? get analytics => _analytics;
  List<User> get users => _users;
  List<AdminReport> get reports => _reports;
  bool get hasMoreUsers => _hasMoreUsers;
  bool get hasMoreReports => _hasMoreReports;

  // Analytics Methods
  Future<void> loadAnalytics() async {
    try {
      _setLoading(true);
      final response = await ApiService.getAdminAnalytics();
      _analytics = AdminAnalytics.fromJson(response);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Users Management Methods
  Future<void> loadUsers({
    bool refresh = false,
    String? search,
    String? status,
  }) async {
    try {
      if (refresh) {
        _currentUsersPage = 1;
        _users.clear();
        _hasMoreUsers = true;
      }

      _usersSearchQuery = search;
      _usersStatusFilter = status;
      _setLoading(true);

      final response = await ApiService.getAdminUsers(
        page: _currentUsersPage,
        limit: 20,
        search: search,
        status: status,
      );

      final usersList = (response['users'] as List)
          .map((json) => User.fromJson(json))
          .toList();

      if (refresh) {
        _users = usersList;
      } else {
        _users.addAll(usersList);
      }

      _hasMoreUsers = usersList.length == 20;
      _currentUsersPage++;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> getUserDetails(String userId) async {
    try {
      _setLoading(true);
      final response = await ApiService.getAdminUserDetails(userId);
      return User.fromJson(response['user']);
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserStatus(String userId, String status) async {
    try {
      _setLoading(true);
      await ApiService.updateUserStatus(userId, status);
      
      // Update local user status
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        // Update user status in local list if User model supports it
        // This would depend on the User model implementation
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reports Management Methods
  Future<void> loadReports({
    bool refresh = false,
    String? status,
    String? type,
  }) async {
    try {
      if (refresh) {
        _currentReportsPage = 1;
        _reports.clear();
        _hasMoreReports = true;
      }

      _reportsStatusFilter = status;
      _reportsTypeFilter = type;
      _setLoading(true);

      final response = await ApiService.getAdminReports(
        page: _currentReportsPage,
        limit: 20,
        status: status,
        type: type,
      );

      final reportsList = (response['reports'] as List)
          .map((json) => AdminReport.fromJson(json))
          .toList();

      if (refresh) {
        _reports = reportsList;
      } else {
        _reports.addAll(reportsList);
      }

      _hasMoreReports = reportsList.length == 20;
      _currentReportsPage++;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateReportStatus(String reportId, String status, String resolution) async {
    try {
      _setLoading(true);
      await ApiService.updateReportStatus(reportId, status, resolution);
      
      // Update local report status
      final reportIndex = _reports.indexWhere((report) => report.id == reportId);
      if (reportIndex != -1) {
        _reports[reportIndex] = AdminReport.fromJson({
          ..._reports[reportIndex].toJson(),
          'status': status,
          'resolution': resolution,
          'resolvedAt': DateTime.now().toIso8601String(),
        });
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Notification Methods
  Future<bool> broadcastNotification(String title, String body, String type) async {
    try {
      _setLoading(true);
      await ApiService.broadcastNotification(
        title: title,
        body: body,
        type: type,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}