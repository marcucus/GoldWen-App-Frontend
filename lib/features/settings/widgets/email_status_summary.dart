import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/email_notification_provider.dart';
import 'package:provider/provider.dart';

/// Widget that displays a summary of email notification status
/// Shows counts of failed and pending emails with color-coded badges
class EmailStatusSummary extends StatelessWidget {
  final VoidCallback? onTap;

  const EmailStatusSummary({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EmailNotificationProvider>(
      builder: (context, provider, _) {
        final failedCount = provider.failedEmailCount;
        final pendingCount = provider.pendingEmailCount;

        // Don't show if no failed or pending emails
        if (failedCount == 0 && pendingCount == 0) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: failedCount > 0 
                    ? Colors.red.shade200
                    : Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email,
                  color: failedCount > 0 ? Colors.red : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (failedCount > 0) ...[
                            _buildBadge(
                              context,
                              '$failedCount Failed',
                              Colors.red,
                            ),
                            if (pendingCount > 0)
                              const SizedBox(width: AppSpacing.sm),
                          ],
                          if (pendingCount > 0)
                            _buildBadge(
                              context,
                              '$pendingCount Pending',
                              Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
