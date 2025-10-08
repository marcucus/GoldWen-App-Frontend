import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/rate_limit_dialog.dart';

/// Utility class for handling API errors with rate limiting support
class ErrorHandler {
  /// Handles API exceptions and shows appropriate UI feedback
  /// Returns true if error was handled (e.g., rate limit dialog shown)
  /// Returns false if error should be handled by caller
  static Future<bool> handleApiError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    bool showDialog = true,
  }) async {
    if (error is! ApiException) {
      return false;
    }

    // Handle rate limit errors specially
    if (error.isRateLimitError && showDialog) {
      await RateLimitDialog.show(
        context,
        error,
        onRetry: onRetry,
      );
      return true;
    }

    return false;
  }

  /// Gets a user-friendly error message from an exception
  static String getErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.isRateLimitError && error.rateLimitInfo != null) {
        String message = error.message;
        message += '\n${error.rateLimitInfo!.getRetryMessage()}';
        return message;
      }
      return error.message;
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return 'Une erreur inattendue est survenue';
  }

  /// Shows a snackbar with the error message
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a warning snackbar for near-rate-limit situations
  static void showRateLimitWarning(
    BuildContext context,
    RateLimitInfo rateLimitInfo,
  ) {
    if (!rateLimitInfo.isNearLimit) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attention: Il vous reste ${rateLimitInfo.remaining} requête${rateLimitInfo.remaining! > 1 ? 's' : ''} sur ${rateLimitInfo.limit}.',
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
