import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/animated_pressable.dart';

class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: onDismiss != null ? (_) => onDismiss!() : null,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        color: AppColors.errorRed,
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: AnimatedPressable(
        onPressed: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? AppColors.cardBackground 
                : AppColors.primaryGold.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border
                  : AppColors.primaryGold.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: notification.isRead 
                                      ? FontWeight.normal 
                                      : FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryGold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      notification.timeAgo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'daily_selection':
        iconData = Icons.favorite;
        iconColor = AppColors.primaryGold;
        break;
      case 'new_match':
        iconData = Icons.favorite_rounded;
        iconColor = AppColors.successGreen;
        break;
      case 'new_message':
        iconData = Icons.message;
        iconColor = AppColors.primaryGold;
        break;
      case 'chat_expiring':
        iconData = Icons.schedule;
        iconColor = AppColors.warningOrange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.textMuted;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withOpacity(0.1),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }
}