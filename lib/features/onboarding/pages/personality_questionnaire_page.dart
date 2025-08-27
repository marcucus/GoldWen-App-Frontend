import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/questionnaire_provider.dart';
import '../services/questionnaire_service.dart';

class PersonalityQuestionnairePage extends StatefulWidget {
  const PersonalityQuestionnairePage({super.key});

  @override
  State<PersonalityQuestionnairePage> createState() => _PersonalityQuestionnairePageState();
}

class _PersonalityQuestionnairePageState extends State<PersonalityQuestionnairePage> {
  late QuestionnaireProvider questionnaireProvider;

  @override
  void initState() {
    super.initState();
    questionnaireProvider = QuestionnaireProvider();
    // Load questions when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      questionnaireProvider.loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: questionnaireProvider,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<QuestionnaireProvider>(
            builder: (context, provider, child) {
              if (provider.questions.isEmpty) return const Text('Questionnaire');
              return Text('Question ${provider.currentQuestionIndex + 1}/${provider.questions.length}');
            },
          ),
          leading: Consumer<QuestionnaireProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: provider.canGoPrevious ? provider.previousQuestion : () => context.go('/auth'),
              );
            },
          ),
          actions: [
            Consumer<QuestionnaireProvider>(
              builder: (context, provider, child) {
                if (provider.questions.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => _showProgressDialog(context),
                  child: Text('${(provider.progress * 100).round()}%'),
                );
              },
            ),
          ],
        ),
        body: Consumer<QuestionnaireProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.lg),
                    Text('Chargement du questionnaire...'),
                  ],
                ),
              );
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.errorRed,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Erreur',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        provider.errorMessage!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        onPressed: () {
                          provider.clearError();
                          provider.loadQuestions();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (provider.questions.isEmpty) {
              return const Center(
                child: Text('Aucune question disponible'),
              );
            }

            return Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: provider.progress,
                  backgroundColor: AppColors.dividerLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                ),
                
                Expanded(
                  child: PageView.builder(
                    controller: PageController(initialPage: provider.currentQuestionIndex),
                    onPageChanged: (index) => provider.goToQuestion(index),
                    itemCount: provider.questions.length,
                    itemBuilder: (context, index) => _buildQuestionPage(provider.questions[index], provider),
                  ),
                ),
                
                // Navigation buttons
                _buildNavigationButtons(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionPage(Question question, QuestionnaireProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final option = question.options[index];
                final isSelected = provider.answers[question.id] == option;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    onTap: () => provider.answerQuestion(question.id, option),
                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryGold.withOpacity(0.1) : AppColors.accentCream,
                        borderRadius: BorderRadius.circular(AppBorderRadius.large),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGold : AppColors.dividerLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primaryGold : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              option,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isSelected ? AppColors.primaryGold : AppColors.textDark,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(QuestionnaireProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          top: BorderSide(color: AppColors.dividerLight),
        ),
      ),
      child: Row(
        children: [
          if (provider.canGoPrevious)
            Expanded(
              child: OutlinedButton(
                onPressed: provider.previousQuestion,
                child: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.dividerLight),
                ),
              ),
            ),
          
          if (provider.canGoPrevious && provider.canGoNext)
            const SizedBox(width: AppSpacing.md),
          
          Expanded(
            child: ElevatedButton(
              onPressed: provider.isCurrentQuestionAnswered ? _handleNext : null,
              child: Text(
                provider.currentQuestionIndex == provider.questions.length - 1
                    ? 'Terminer'
                    : 'Suivant',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    final provider = questionnaireProvider;
    
    if (provider.currentQuestionIndex == provider.questions.length - 1) {
      // Last question, submit answers
      final success = await provider.submitAnswers();
      if (success && mounted) {
        // Save answers to profile provider
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        profileProvider.setPersonalityAnswers(provider.answers);
        
        // Navigate to profile setup
        context.go('/profile-setup');
      }
    } else {
      // Go to next question
      provider.nextQuestion();
    }
  }

  void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Progression'),
        content: Consumer<QuestionnaireProvider>(
          builder: (context, provider, child) {
            final answeredCount = provider.questions.where((q) => provider.isQuestionAnswered(q.id)).length;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$answeredCount / ${provider.questions.length} questions répondues'),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: provider.progress,
                  backgroundColor: AppColors.dividerLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    questionnaireProvider.dispose();
    super.dispose();
  }
}