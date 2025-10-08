import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

/// Dialog widget for displaying rate limit errors with countdown timer
class RateLimitDialog extends StatefulWidget {
  final ApiException exception;
  final VoidCallback? onRetry;

  const RateLimitDialog({
    super.key,
    required this.exception,
    this.onRetry,
  });

  @override
  State<RateLimitDialog> createState() => _RateLimitDialogState();

  /// Shows the rate limit dialog
  static Future<void> show(
    BuildContext context,
    ApiException exception, {
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RateLimitDialog(
        exception: exception,
        onRetry: onRetry,
      ),
    );
  }
}

class _RateLimitDialogState extends State<RateLimitDialog> {
  Timer? _countdownTimer;
  int? _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
  }

  void _initializeCountdown() {
    final rateLimitInfo = widget.exception.rateLimitInfo;
    if (rateLimitInfo == null) return;

    if (rateLimitInfo.retryAfterSeconds != null) {
      _remainingSeconds = rateLimitInfo.retryAfterSeconds;
    } else if (rateLimitInfo.resetTime != null) {
      final now = DateTime.now();
      final diff = rateLimitInfo.resetTime!.difference(now);
      if (!diff.isNegative) {
        _remainingSeconds = diff.inSeconds;
      }
    }

    if (_remainingSeconds != null && _remainingSeconds! > 0) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds != null && _remainingSeconds! > 0) {
          _remainingSeconds = _remainingSeconds! - 1;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _getTitle() {
    if (widget.exception.code == 'BRUTE_FORCE_DETECTED' ||
        (widget.exception.message.toLowerCase().contains('login') &&
            widget.exception.message.toLowerCase().contains('tentative'))) {
      return 'Trop de tentatives de connexion';
    }
    return 'Limite de requêtes atteinte';
  }

  String _getMessage() {
    final rateLimitInfo = widget.exception.rateLimitInfo;
    
    // Check for brute force login attempts
    if (widget.exception.code == 'BRUTE_FORCE_DETECTED' ||
        (widget.exception.message.toLowerCase().contains('login') &&
            widget.exception.message.toLowerCase().contains('tentative'))) {
      return 'Pour votre sécurité, votre compte a été temporairement bloqué après plusieurs tentatives de connexion échouées.\n\n${rateLimitInfo?.getRetryMessage() ?? 'Veuillez réessayer dans quelques minutes.'}';
    }

    // General rate limit message
    String message = widget.exception.message;
    if (rateLimitInfo != null) {
      if (rateLimitInfo.limit != null && rateLimitInfo.remaining != null) {
        message += '\n\nVous avez dépassé la limite de ${rateLimitInfo.limit} requêtes.';
      }
      message += '\n\n${rateLimitInfo.getRetryMessage()}';
    }
    
    return message;
  }

  String _getCountdownText() {
    if (_remainingSeconds == null || _remainingSeconds! <= 0) {
      return 'Vous pouvez réessayer maintenant';
    }

    final minutes = _remainingSeconds! ~/ 60;
    final seconds = _remainingSeconds! % 60;

    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '$seconds seconde${seconds > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final canRetry = _remainingSeconds == null || _remainingSeconds! <= 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      title: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: AppColors.primaryGold,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _getTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getMessage(),
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          if (!canRetry) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _getCountdownText(),
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (canRetry && widget.onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRetry?.call();
            },
            child: const Text('Réessayer'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            canRetry ? 'Fermer' : 'Compris',
            style: TextStyle(
              color: canRetry ? AppColors.textSecondary : AppColors.primaryGold,
              fontWeight: canRetry ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget to display a warning when approaching rate limits
class RateLimitWarningBanner extends StatelessWidget {
  final RateLimitInfo rateLimitInfo;
  final VoidCallback? onDismiss;

  const RateLimitWarningBanner({
    super.key,
    required this.rateLimitInfo,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!rateLimitInfo.isNearLimit) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attention',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Il vous reste ${rateLimitInfo.remaining} requête${rateLimitInfo.remaining! > 1 ? 's' : ''} sur ${rateLimitInfo.limit}.',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.orange.shade700,
                size: 20,
              ),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
