import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';

class MatchReasonsWidget extends StatelessWidget {
  final List<MatchReason> matchReasons;

  const MatchReasonsWidget({
    super.key,
    required this.matchReasons,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: matchReasons.map((reason) => _buildReasonCard(context, reason)).toList(),
    );
  }

  Widget _buildReasonCard(BuildContext context, MatchReason reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getCategoryColor(reason.category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor(reason.category).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCategoryColor(reason.category),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(reason.category),
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCategoryLabel(reason.category),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(reason.category),
                        textBaseline: TextBaseline.alphabetic,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark,
                      ),
                ),
              ],
            ),
          ),
          
          // Impact indicator
          _buildImpactIndicator(context, reason.impact),
        ],
      ),
    );
  }

  Widget _buildImpactIndicator(BuildContext context, double impact) {
    final isPositive = impact >= 0;
    final color = isPositive ? AppColors.successGreen : AppColors.errorRed;
    final percentage = (impact.abs() * 100).round();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isPositive ? '+' : ''}$percentage%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personality':
      case 'personnalité':
        return AppColors.infoBlue;
      case 'interests':
      case 'intérêts':
        return AppColors.primaryGold;
      case 'values':
      case 'valeurs':
        return const Color(0xFF9C27B0); // Purple
      case 'lifestyle':
      case 'mode de vie':
        return AppColors.successGreen;
      case 'communication':
        return const Color(0xFFFF5722); // Deep Orange
      case 'activity':
      case 'activité':
        return const Color(0xFFFF9800); // Orange
      case 'reciprocity':
      case 'réciprocité':
        return const Color(0xFFE91E63); // Pink
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'personality':
      case 'personnalité':
        return Icons.psychology;
      case 'interests':
      case 'intérêts':
        return Icons.interests;
      case 'values':
      case 'valeurs':
        return Icons.favorite;
      case 'lifestyle':
      case 'mode de vie':
        return Icons.location_city;
      case 'communication':
        return Icons.chat_bubble;
      case 'activity':
      case 'activité':
        return Icons.flash_on;
      case 'reciprocity':
      case 'réciprocité':
        return Icons.sync;
      default:
        return Icons.info;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'personality':
        return 'Personnalité';
      case 'interests':
        return 'Intérêts';
      case 'values':
        return 'Valeurs';
      case 'lifestyle':
        return 'Mode de vie';
      case 'communication':
        return 'Communication';
      case 'activity':
        return 'Activité';
      case 'reciprocity':
        return 'Réciprocité';
      default:
        return category;
    }
  }
}
