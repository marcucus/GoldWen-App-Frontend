import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/chat.dart';

/// Widget that displays online/offline status with a colored dot and text
class OnlineStatusIndicator extends StatelessWidget {
  final OnlineStatus? status;
  final bool showText;
  final bool compact;
  
  const OnlineStatusIndicator({
    super.key,
    this.status,
    this.showText = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    final isOnline = status!.isOnline;
    final statusText = status!.getLastSeenText();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 6 : 8,
          height: compact ? 6 : 8,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : AppColors.textTertiary,
            shape: BoxShape.circle,
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        if (showText) ...[
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isOnline ? Colors.green : AppColors.textSecondary,
                  fontSize: compact ? 10 : 12,
                ),
          ),
        ],
      ],
    );
  }
}
