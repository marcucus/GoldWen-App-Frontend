import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/admin_report.dart';

class ReportListItem extends StatelessWidget {
  final AdminReport report;
  final VoidCallback onTap;
  final Function(String action, String resolution) onActionTaken;

  const ReportListItem({
    super.key,
    required this.report,
    required this.onTap,
    required this.onActionTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Report Type Icon
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _getTypeColor(report.reportType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(report.reportType),
                      color: _getTypeColor(report.reportType),
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // Report Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTypeLabel(report.reportType),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report.reason,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Chip
                  _StatusChip(status: report.status),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Details Row
              Row(
                children: [
                  Icon(
                    Icons.person_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Utilisateur: ${report.reportedUserId.substring(0, 8)}...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatCreatedAt(report.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              
              // Description if available
              if (report.description != null && report.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              
              // Action Buttons for pending/in-progress reports
              if (report.isPending || report.isInProgress) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (report.isPending)
                      OutlinedButton.icon(
                        onPressed: () => _showQuickAction(context, 'take_action'),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Prendre en charge'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGold,
                          side: const BorderSide(color: AppColors.primaryGold),
                        ),
                      ),
                    if (report.isPending) const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () => _showQuickAction(context, 'resolve'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Résoudre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Resolution info for resolved reports
              if (report.isResolved && report.resolution != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.successGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.successGreen,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Résolution: ${report.resolution}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.successGreen,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAction(BuildContext context, String action) {
    if (action == 'take_action') {
      onActionTaken('in_progress', 'Pris en charge par l\'administrateur');
    } else {
      _showResolveDialog(context);
    }
  }

  void _showResolveDialog(BuildContext context) {
    String? selectedAction;
    final resolutionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Résoudre le signalement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Action prise',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'warning_sent', child: Text('Avertissement envoyé')),
                DropdownMenuItem(value: 'content_removed', child: Text('Contenu supprimé')),
                DropdownMenuItem(value: 'user_suspended', child: Text('Utilisateur suspendu')),
                DropdownMenuItem(value: 'user_banned', child: Text('Utilisateur banni')),
                DropdownMenuItem(value: 'no_action', child: Text('Aucune action nécessaire')),
                DropdownMenuItem(value: 'false_report', child: Text('Faux signalement')),
              ],
              onChanged: (value) => selectedAction = value,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: resolutionController,
              decoration: const InputDecoration(
                labelText: 'Note de résolution',
                border: OutlineInputBorder(),
                hintText: 'Décrivez l\'action prise...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedAction != null && resolutionController.text.isNotEmpty) {
                Navigator.pop(context);
                onActionTaken(selectedAction!, resolutionController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Résoudre'),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'inappropriate_content':
        return Icons.warning;
      case 'fake_profile':
        return Icons.person_off;
      case 'harassment':
        return Icons.report_problem;
      case 'spam':
        return Icons.block;
      case 'other':
        return Icons.flag;
      default:
        return Icons.flag;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'inappropriate_content':
        return AppColors.errorRed;
      case 'fake_profile':
        return AppColors.warningAmber;
      case 'harassment':
        return Colors.purple;
      case 'spam':
        return AppColors.infoBlue;
      case 'other':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'inappropriate_content':
        return 'Contenu inapproprié';
      case 'fake_profile':
        return 'Faux profil';
      case 'harassment':
        return 'Harcèlement';
      case 'spam':
        return 'Spam';
      case 'other':
        return 'Autre';
      default:
        return type;
    }
  }

  String _formatCreatedAt(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        backgroundColor = AppColors.warningAmber.withOpacity(0.1);
        textColor = AppColors.warningAmber;
        label = 'En attente';
        icon = Icons.pending;
        break;
      case 'in_progress':
        backgroundColor = AppColors.infoBlue.withOpacity(0.1);
        textColor = AppColors.infoBlue;
        label = 'En cours';
        icon = Icons.work;
        break;
      case 'resolved':
        backgroundColor = AppColors.successGreen.withOpacity(0.1);
        textColor = AppColors.successGreen;
        label = 'Résolu';
        icon = Icons.check_circle;
        break;
      default:
        backgroundColor = AppColors.textTertiary.withOpacity(0.1);
        textColor = AppColors.textTertiary;
        label = 'Inconnu';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}