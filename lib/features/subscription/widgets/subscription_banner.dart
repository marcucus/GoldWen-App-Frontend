import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';

class SubscriptionPromoBanner extends StatelessWidget {
  final String? message;
  final bool compact;
  final VoidCallback? onTap;
  
  const SubscriptionPromoBanner({
    super.key,
    this.message,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultMessage = compact 
      ? 'Passez à GoldWen Plus pour 3 choix/jour'
      : 'Passez à GoldWen Plus pour choisir jusqu\'à 3 profils par jour';
    
    return FadeInAnimation(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGold.withOpacity(0.1),
                  AppColors.primaryGoldLight.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: onTap ?? () => context.go('/subscription'),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              child: Padding(
                padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.small),
                      ),
                      child: Icon(
                        Icons.star,
                        color: AppColors.primaryGold,
                        size: compact ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message ?? defaultMessage,
                            style: (compact 
                              ? Theme.of(context).textTheme.bodyMedium 
                              : Theme.of(context).textTheme.bodyLarge)?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Plus de matches, plus de possibilités !',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primaryGold,
                      size: compact ? 16 : 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SubscriptionLimitReachedDialog extends StatelessWidget {
  final int currentSelections;
  final int maxSelections;
  final DateTime? resetTime;
  
  const SubscriptionLimitReachedDialog({
    super.key,
    required this.currentSelections,
    required this.maxSelections,
    this.resetTime,
  });

  String _formatResetTime(DateTime resetTime) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);
    
    if (difference.isNegative) return 'bientôt';
    
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (hours > 0) {
        return 'dans ${hours}h${minutes > 0 ? minutes.toString().padLeft(2, '0') : ''}';
      } else {
        return 'dans ${minutes}min';
      }
    }
    
    // Format as "demain à HH:MM"
    final hour = resetTime.hour;
    final minute = resetTime.minute;
    return 'demain à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final resetTimeText = resetTime != null ? _formatResetTime(resetTime!) : null;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
            ),
            child: Icon(
              Icons.star,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Text('Limite atteinte')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous avez utilisé $currentSelections/$maxSelections sélections aujourd\'hui.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (resetTimeText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Nouvelle sélection $resetTimeText',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGold.withOpacity(0.1),
                  AppColors.primaryGold.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.primaryGold, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Avec GoldWen Plus:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('• 3 sélections par jour au lieu d\'1'),
                const Text('• Chat illimité avec vos matches'),
                const Text('• Voir qui vous a sélectionné'),
                const Text('• Profil prioritaire'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Plus tard'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/subscription');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGold,
            foregroundColor: Colors.white,
          ),
          child: const Text('Passer à Plus'),
        ),
      ],
    );
  }
}

class SubscriptionStatusIndicator extends StatelessWidget {
  final bool hasActiveSubscription;
  final int? daysUntilExpiry;
  final bool compact;
  
  const SubscriptionStatusIndicator({
    super.key,
    required this.hasActiveSubscription,
    this.daysUntilExpiry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasActiveSubscription) return const SizedBox.shrink();
    
    final isExpiringSoon = daysUntilExpiry != null && daysUntilExpiry! <= 7;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpiringSoon 
            ? [
                AppColors.warningOrange.withOpacity(0.1),
                AppColors.warningOrange.withOpacity(0.05),
              ]
            : [
                AppColors.primaryGold.withOpacity(0.1),
                AppColors.primaryGold.withOpacity(0.05),
              ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(
          color: isExpiringSoon 
            ? AppColors.warningOrange.withOpacity(0.3)
            : AppColors.primaryGold.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpiringSoon ? Icons.warning : Icons.star,
            color: isExpiringSoon ? AppColors.warningOrange : AppColors.primaryGold,
            size: compact ? 16 : 20,
          ),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
          Flexible(
            child: Text(
              isExpiringSoon 
                ? 'Plus expire dans $daysUntilExpiry jour${daysUntilExpiry! > 1 ? 's' : ''}'
                : 'GoldWen Plus actif',
              style: (compact 
                ? Theme.of(context).textTheme.bodySmall 
                : Theme.of(context).textTheme.bodyMedium)?.copyWith(
                color: isExpiringSoon ? AppColors.warningOrange : AppColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}