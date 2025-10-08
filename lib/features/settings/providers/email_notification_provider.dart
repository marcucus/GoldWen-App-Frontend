import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/models.dart';

class EmailNotificationProvider with ChangeNotifier {
  List<EmailNotification> _emailHistory = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<EmailNotification> get emailHistory => _emailHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  List<EmailNotification> get pendingEmails {
    return _emailHistory
        .where((email) => email.isPending)
        .toList();
  }

  List<EmailNotification> get failedEmails {
    return _emailHistory
        .where((email) => email.hasError)
        .toList();
  }

  List<EmailNotification> get successfulEmails {
    return _emailHistory
        .where((email) => email.isSuccessful)
        .toList();
  }

  int get failedEmailCount => failedEmails.length;
  int get pendingEmailCount => pendingEmails.length;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadEmailHistory({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (page == 1) {
      _setLoading();
    }

    try {
      final response = await ApiService.getEmailHistory(
        page: page,
        limit: limit,
        type: type,
        status: status,
      );

      final emailData = response['data'] ?? response['emails'] ?? [];
      final newEmails = (emailData as List)
          .map((e) => EmailNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      if (page == 1 || refresh) {
        _emailHistory = newEmails;
      } else {
        _emailHistory.addAll(newEmails);
      }

      _currentPage = page;
      _hasMore = newEmails.length >= limit;
      _error = null;
    } catch (e) {
      _handleError(e, 'Failed to load email history');
    } finally {
      if (page == 1) {
        _setLoaded();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_hasMore && !_isLoading) {
      await loadEmailHistory(page: _currentPage + 1);
    }
  }

  Future<void> refresh() async {
    await loadEmailHistory(refresh: true);
  }

  Future<EmailNotification?> getEmailDetails(String emailId) async {
    try {
      final response = await ApiService.getEmailDetails(emailId);
      
      final emailData = response['data'] ?? response['email'];
      if (emailData != null) {
        final email = EmailNotification.fromJson(emailData as Map<String, dynamic>);
        
        // Update local cache
        final index = _emailHistory.indexWhere((e) => e.id == emailId);
        if (index != -1) {
          _emailHistory[index] = email;
          notifyListeners();
        }
        
        return email;
      }
      return null;
    } catch (e) {
      _handleError(e, 'Failed to load email details');
      return null;
    }
  }

  Future<bool> retryEmail(String emailId) async {
    try {
      final response = await ApiService.retryEmail(emailId);
      
      // Update the email status in local cache
      final emailData = response['data'] ?? response['email'];
      if (emailData != null) {
        final updatedEmail = EmailNotification.fromJson(emailData as Map<String, dynamic>);
        final index = _emailHistory.indexWhere((e) => e.id == emailId);
        if (index != -1) {
          _emailHistory[index] = updatedEmail;
          notifyListeners();
        }
      }
      
      return true;
    } catch (e) {
      _handleError(e, 'Failed to retry email');
      return false;
    }
  }

  void _setLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void _setLoaded() {
    _isLoading = false;
    notifyListeners();
  }

  void _handleError(dynamic error, String defaultMessage) {
    if (error is ApiException) {
      _error = error.message;
    } else {
      _error = defaultMessage;
    }
    _isLoading = false;
    notifyListeners();
  }
}
