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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État du profil:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatusRow(context, 'Photos (minimum 3)', completion.hasPhotos),
        _buildStatusRow(context, 'Prompts (3 réponses)', completion.hasPrompts),
        _buildStatusRow(context, 'Questionnaire personnalité', completion.hasPersonalityAnswers),
        _buildStatusRow(context, 'Informations de base', completion.hasRequiredProfileFields),
      ],
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
      ],
    );
  }
}