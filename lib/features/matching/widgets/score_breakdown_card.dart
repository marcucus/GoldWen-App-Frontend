import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';

class ScoreBreakdownCard extends StatelessWidget {
  final ScoreBreakdown breakdown;

  const ScoreBreakdownCard({
    super.key,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails du score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
          ),
          const SizedBox(height: 16),
          
          // Base scores
          _buildScoreRow(
            context,
            'Personnalité',
            breakdown.personalityScore,
            Icons.psychology,
            AppColors.infoBlue,
          ),
          const SizedBox(height: 12),
          _buildScoreRow(
            context,
            'Préférences',
            breakdown.preferencesScore,
            Icons.favorite,
            AppColors.primaryGold,
          ),
          
          const Divider(height: 24),
          
          // Bonus/Malus section
          Text(
            'Bonus',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          
          _buildBonusRow(
            context,
            'Activité',
            breakdown.activityBonus,
            Icons.flash_on,
          ),
          const SizedBox(height: 8),
          _buildBonusRow(
            context,
            'Taux de réponse',
            breakdown.responseRateBonus,
            Icons.message,
          ),
          const SizedBox(height: 8),
          _buildBonusRow(
            context,
            'Réciprocité',
            breakdown.reciprocityBonus,
            Icons.favorite_border,
          ),
          
          const Divider(height: 24),
          
          // Summary
          _buildSummaryRow(
            context,
            'Score de base',
            breakdown.baseScore,
            false,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            'Total bonus',
            breakdown.totalBonuses,
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(
    BuildContext context,
    String label,
    double score,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              _buildProgressBar(score, color),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${score.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildBonusRow(
    BuildContext context,
    String label,
    double value,
    IconData icon,
  ) {
    final isPositive = value >= 0;
    final color = isPositive ? AppColors.successGreen : AppColors.errorRed;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${value.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double value,
    bool highlight,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                  color: highlight ? AppColors.primaryGold : AppColors.textDark,
                ),
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.primaryGold : AppColors.textDark,
              ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double value, Color color) {
    // Normalize to 0-100 range (assuming max score per category is around 60)
    final percentage = (value / 60).clamp(0.0, 1.0);
    
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
