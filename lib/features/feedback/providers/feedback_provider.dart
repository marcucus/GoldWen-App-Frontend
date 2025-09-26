import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/feedback.dart';

class FeedbackProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isSubmitted = false;
  String? _error;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isSubmitted => _isSubmitted;
  String? get error => _error;
  String? get successMessage => _successMessage;

  void clearState() {
    _isLoading = false;
    _isSubmitted = false;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> submitFeedback({
    required FeedbackType type,
    required String subject,
    required String message,
    int? rating,
    String? currentPage,
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Auto-collect metadata
      final metadata = _generateMetadata(currentPage);

      // Submit feedback using API service
      final response = await ApiService.submitFeedback(
        type: _feedbackTypeToString(type),
        subject: subject,
        message: message,
        rating: rating,
        metadata: metadata,
      );

      _isLoading = false;
      _isSubmitted = true;
      _successMessage = 'Votre feedback a été envoyé avec succès. Merci pour votre contribution !';
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  Map<String, dynamic> _generateMetadata(String? currentPage) {
    final metadata = <String, dynamic>{};

    // Add current page if provided
    if (currentPage != null) {
      metadata['page'] = currentPage;
    }

    // Add platform information as user agent
    String userAgent;
    if (kIsWeb) {
      userAgent = 'GoldWen Web App';
    } else if (Platform.isAndroid) {
      userAgent = 'GoldWen Android App';
    } else if (Platform.isIOS) {
      userAgent = 'GoldWen iOS App';
    } else {
      userAgent = 'GoldWen Mobile App';
    }
    metadata['userAgent'] = userAgent;

    // Add app version - this could be retrieved from package_info_plus in a real app
    metadata['appVersion'] = '1.0.0+1';

    return metadata;
  }

  String _feedbackTypeToString(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'bug';
      case FeedbackType.feature:
        return 'feature';
      case FeedbackType.general:
        return 'general';
    }
  }

  // Helper method to get feedback type options for UI
  List<FeedbackTypeOption> getFeedbackTypeOptions() {
    return [
      FeedbackTypeOption(
        type: FeedbackType.bug,
        title: 'Signaler un bug',
        subtitle: 'Rapporter un problème technique',
        icon: Icons.bug_report,
        color: Colors.red,
      ),
      FeedbackTypeOption(
        type: FeedbackType.feature,
        title: 'Suggérer une fonctionnalité',
        subtitle: 'Proposer une amélioration',
        icon: Icons.lightbulb_outline,
        color: Colors.amber,
      ),
      FeedbackTypeOption(
        type: FeedbackType.general,
        title: 'Commentaire général',
        subtitle: 'Partager votre opinion',
        icon: Icons.chat_outlined,
        color: Colors.blue,
      ),
    ];
  }
}

class FeedbackTypeOption {
  final FeedbackType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  FeedbackTypeOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}