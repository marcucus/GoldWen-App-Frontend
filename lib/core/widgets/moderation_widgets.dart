import 'package:flutter/material.dart';
import '../../models/moderation.dart';
import '../../theme/app_theme.dart';

/// A badge widget to display moderation status
class ModerationStatusBadge extends StatelessWidget {
  final ModerationResult moderationResult;
  final bool showLabel;
  final bool compact;

  const ModerationStatusBadge({
    super.key,
    required this.moderationResult,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (moderationResult.isApproved && !moderationResult.hasFlags) {
      // Don't show badge for approved content with no flags
      return const SizedBox.shrink();
    }

    final color = _getStatusColor();
    final icon = _getStatusIcon();
    final label = _getStatusLabel();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1),
        ),
        child: Icon(
          icon,
          size: 12,
          color: color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (moderationResult.status) {
      case ModerationStatus.approved:
        return AppColors.successGreen;
      case ModerationStatus.pending:
        return AppColors.warningAmber;
      case ModerationStatus.blocked:
        return AppColors.errorRed;
    }
  }

  IconData _getStatusIcon() {
    switch (moderationResult.status) {
      case ModerationStatus.approved:
        return Icons.check_circle;
      case ModerationStatus.pending:
        return Icons.hourglass_empty;
      case ModerationStatus.blocked:
        return Icons.block;
    }
  }

  String _getStatusLabel() {
    switch (moderationResult.status) {
      case ModerationStatus.approved:
        return 'Approuvé';
      case ModerationStatus.pending:
        return 'En attente';
      case ModerationStatus.blocked:
        return 'Bloqué';
    }
  }
}

/// A widget to display moderation flags/categories
class ModerationFlagsWidget extends StatelessWidget {
  final List<ModerationFlag> flags;
  final bool showConfidence;

  const ModerationFlagsWidget({
    super.key,
    required this.flags,
    this.showConfidence = false,
  });

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: flags.map((flag) => _buildFlagChip(flag, context)).toList(),
    );
  }

  Widget _buildFlagChip(ModerationFlag flag, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: AppColors.errorRed,
          ),
          const SizedBox(width: 4),
          Text(
            _formatFlagName(flag.name),
            style: TextStyle(
              color: AppColors.errorRed,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showConfidence) ...[
            const SizedBox(width: 4),
            Text(
              '(${flag.confidence.toStringAsFixed(0)}%)',
              style: TextStyle(
                color: AppColors.errorRed.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatFlagName(String name) {
    // Convert snake_case or camelCase to readable format
    return name
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
            : '')
        .join(' ');
  }
}

/// A widget to display blocked content message
class ModerationBlockedContent extends StatelessWidget {
  final ModerationResult moderationResult;
  final String resourceType;
  final VoidCallback? onAppeal;

  const ModerationBlockedContent({
    super.key,
    required this.moderationResult,
    required this.resourceType,
    this.onAppeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.block,
                color: AppColors.errorRed,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getBlockedMessage(),
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (moderationResult.hasFlags) ...[
            const SizedBox(height: 12),
            Text(
              'Raisons:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ModerationFlagsWidget(flags: moderationResult.flags),
          ],
          if (onAppeal != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAppeal,
                icon: const Icon(Icons.feedback, size: 16),
                label: const Text('Faire appel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGold,
                  side: const BorderSide(color: AppColors.primaryGold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getBlockedMessage() {
    switch (resourceType) {
      case 'message':
        return 'Ce message a été bloqué par notre système de modération automatique.';
      case 'photo':
        return 'Cette photo a été bloquée par notre système de modération automatique.';
      case 'bio':
        return 'Cette biographie a été bloquée par notre système de modération automatique.';
      default:
        return 'Ce contenu a été bloqué par notre système de modération automatique.';
    }
  }
}
