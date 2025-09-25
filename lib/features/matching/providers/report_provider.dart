import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/models.dart';

class ReportProvider with ChangeNotifier {
  List<Report> _myReports = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMoreReports = true;

  List<Report> get myReports => _myReports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreReports => _hasMoreReports;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> submitReport({
    required String targetUserId,
    required ReportType type,
    required String reason,
    String? messageId,
    String? chatId,
    List<String>? evidence,
  }) async {
    _setLoading(true);

    try {
      final response = await ApiService.submitReport(
        targetUserId: targetUserId,
        type: type,
        reason: reason,
        messageId: messageId,
        chatId: chatId,
        evidence: evidence,
      );

      // If successful, the report was submitted
      _error = null;
      
      // Optionally, refresh the user's reports list
      await loadMyReports(refresh: true);
      
    } catch (e) {
      _error = e.toString();
      rethrow; // Re-throw so the UI can handle it
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyReports({
    int page = 1,
    int limit = 20,
    ReportStatus? status,
    bool refresh = false,
  }) async {
    if (refresh) {
      _myReports.clear();
      _hasMoreReports = true;
    }

    _setLoading(true);

    try {
      final response = await ApiService.getMyReports(
        page: page,
        limit: limit,
        status: status,
      );

      final reportsData = response['data'] as List<dynamic>;
      final newReports = reportsData
          .map((data) => Report.fromJson(data as Map<String, dynamic>))
          .toList();

      if (refresh || page == 1) {
        _myReports = newReports;
      } else {
        _myReports.addAll(newReports);
      }

      // Check if there are more reports to load
      final pagination = response['pagination'] as Map<String, dynamic>?;
      _hasMoreReports = pagination?['hasMore'] as bool? ?? false;
      
      _error = null;
    } catch (e) {
      _handleError(e, 'Failed to load reports');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _handleError(dynamic error, String fallbackMessage) {
    _error = error.toString();
    notifyListeners();
    print('ReportProvider Error: $error');
  }
}