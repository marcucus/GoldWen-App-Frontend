import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/profile.dart';
import '../providers/profile_provider.dart';

class ProfileCompletionWidget extends StatelessWidget {
  final bool showProgress;
  final VoidCallback? onMissingStepTap;

  const ProfileCompletionWidget({
    super.key,
    this.showProgress = true,
    this.onMissingStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final completion = profileProvider.profileCompletion;
        if (completion == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      completion.isCompleted
                          ? Icons.check_circle
                          : Icons.warning,
                      color: completion.isCompleted
                          ? AppColors.successGreen
                          : AppColors.warningAmber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        completion.isCompleted
                            ? 'Profil complet et validé'
                            : 'Profil incomplet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: completion.isCompleted
                              ? AppColors.successGreen
                              : AppColors.warningAmber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (showProgress) ...[
                  _buildProgressIndicator(context, completion),
                  const SizedBox(height: 16),
                ],
                
                _buildCompletionStatus(context, completion),
                
                if (!completion.isCompleted && completion.missingSteps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildMissingSteps(context, completion),
                ],
                
                if (!completion.isCompleted && onMissingStepTap != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onMissingStepTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Compléter le profil'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ProfileCompletion completion) {
    final completedSteps = [
      completion.hasPhotos,
      completion.hasPrompts,
      completion.hasPersonalityAnswers,
      completion.hasRequiredProfileFields,
    ];
    final completedCount = completedSteps.where((step) => step).length;
    final totalSteps = completedSteps.length;
    final progress = completedCount / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.backgroundGrey,
          valueColor: AlwaysStoppedAnimation<Color>(
            completion.isCompleted 
                ? AppColors.successGreen 
                : AppColors.primaryGold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionStatus(BuildContext context, ProfileCompletion completion) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final photoCount = profileProvider.photos.length;
    final promptCount = profileProvider.prompts.where((p) => p.isNotEmpty).length;
    final questionnaireCount = profileProvider.personalityAnswers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Force du profil:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildStrengthRow(context, 'Photos', photoCount, 6, completion.hasPhotos),
        _buildStrengthRow(context, 'Prompts', promptCount, 3, completion.hasPrompts),
        _buildStrengthRow(context, 'Questionnaire', questionnaireCount, 10, completion.hasPersonalityAnswers),
        _buildStatusRow(context, 'Informations de base', completion.hasRequiredProfileFields),
      ],
    );
  }

  Widget _buildStrengthRow(
    BuildContext context,
    String label,
    int current,
    int max,
    bool completed,
  ) {
    final clamped = current.clamp(0, max);
    final fraction = clamped / max;
    final color = completed ? AppColors.successGreen : AppColors.primaryGold;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    completed ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: completed ? AppColors.successGreen : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: completed ? AppColors.textDark : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              Text(
                '$clamped / $max',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: AppColors.backgroundGrey,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: completed ? AppColors.successGreen : AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: completed ? AppColors.textDark : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingSteps(BuildContext context, ProfileCompletion completion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étapes manquantes:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.warningAmber,
          ),
        ),
        const SizedBox(height: 8),
        ...completion.missingSteps.map((step) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Icon(
                Icons.arrow_right,
                size: 16,
                color: AppColors.warningAmber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warningAmber,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningAmber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.warningAmber.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.warningAmber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Votre profil ne sera pas visible tant que toutes les étapes ne sont pas complétées.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}