import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class PersonalityQuestionnairePage extends StatefulWidget {
  const PersonalityQuestionnairePage({super.key});

  @override
  State<PersonalityQuestionnairePage> createState() => _PersonalityQuestionnairePageState();
}

class _PersonalityQuestionnairePageState extends State<PersonalityQuestionnairePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<String, dynamic> _answers = {};
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Qu\'est-ce qui vous motive le plus dans la vie ?',
      'options': [
        'L\'épanouissement personnel',
        'Les relations humaines',
        'La réussite professionnelle',
        'L\'aventure et la découverte'
      ],
      'key': 'motivation'
    },
    {
      'question': 'Comment préférez-vous passer votre temps libre ?',
      'options': [
        'Lire un bon livre',
        'Sortir avec des amis',
        'Faire du sport',
        'Découvrir de nouveaux endroits'
      ],
      'key': 'free_time'
    },
    {
      'question': 'Quelle est votre approche face aux conflits ?',
      'options': [
        'J\'évite autant que possible',
        'Je préfère discuter calmement',
        'Je fais face directement',
        'J\'essaie de trouver un compromis'
      ],
      'key': 'conflict_style'
    },
    {
      'question': 'Qu\'attendez-vous d\'une relation amoureuse ?',
      'options': [
        'Complicité et soutien mutuel',
        'Passion et romance',
        'Stabilité et sécurité',
        'Croissance et évolution commune'
      ],
      'key': 'relationship_expectation'
    },
    {
      'question': 'Comment décririez-vous votre style de communication ?',
      'options': [
        'Direct et honnête',
        'Empathique et à l\'écoute',
        'Drôle et léger',
        'Réfléchi et posé'
      ],
      'key': 'communication_style'
    },
    {
      'question': 'Quelle importance accordez-vous à la famille ?',
      'options': [
        'C\'est ma priorité absolue',
        'Très importante mais pas unique',
        'Importante mais j\'ai d\'autres priorités',
        'Je privilégie mon indépendance'
      ],
      'key': 'family_importance'
    },
    {
      'question': 'Comment gérez-vous le stress ?',
      'options': [
        'Méditation ou relaxation',
        'Sport ou activité physique',
        'Discussion avec des proches',
        'Isolement pour réfléchir'
      ],
      'key': 'stress_management'
    },
    {
      'question': 'Quelle est votre vision de l\'avenir ?',
      'options': [
        'Optimiste et confiante',
        'Réaliste mais positive',
        'Prudente et préparée',
        'Spontanée et ouverte'
      ],
      'key': 'future_vision'
    },
    {
      'question': 'Qu\'est-ce qui vous fait le plus rire ?',
      'options': [
        'L\'humour intelligent',
        'Les situations absurdes',
        'L\'autodérision',
        'L\'humour subtil'
      ],
      'key': 'humor_style'
    },
    {
      'question': 'Quelle valeur est la plus importante pour vous ?',
      'options': [
        'L\'authenticité',
        'La bienveillance',
        'L\'ambition',
        'La liberté'
      ],
      'key': 'core_value'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentPage + 1}/${_questions.length}'),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousQuestion,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / _questions.length,
            backgroundColor: AppColors.dividerLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionPage(_questions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(Map<String, dynamic> questionData) {
    final questionKey = questionData['key'];
    final selectedAnswer = _answers[questionKey];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // Question
          Text(
            questionData['question'],
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Options
          Expanded(
            child: ListView.builder(
              itemCount: questionData['options'].length,
              itemBuilder: (context, index) {
                final option = questionData['options'][index];
                final isSelected = selectedAnswer == option;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Card(
                    elevation: isSelected ? 4 : 1,
                    color: isSelected ? AppColors.primaryGold.withOpacity(0.1) : null,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      title: Text(
                        option,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isSelected ? AppColors.primaryGold : null,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: AppColors.primaryGold,
                            )
                          : const Icon(
                              Icons.radio_button_unchecked,
                              color: AppColors.textSecondary,
                            ),
                      onTap: () => _selectAnswer(questionKey, option),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Navigation buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: TextButton(
                    onPressed: _previousQuestion,
                    child: const Text('Précédent'),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: (selectedAnswer != null && !_isSubmitting) ? _nextQuestion : null,
                  child: _isSubmitting && _currentPage == _questions.length - 1
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_currentPage == _questions.length - 1 ? 'Terminer' : 'Suivant'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _selectAnswer(String questionKey, String answer) {
    setState(() {
      _answers[questionKey] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishQuestionnaire();
    }
  }

  void _previousQuestion() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishQuestionnaire() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.setPersonalityAnswers(_answers);
      
      // Convert answers to API format
      final List<Map<String, dynamic>> apiAnswers = _answers.entries.map((entry) {
        return {
          'questionId': entry.key, // In real app, this would be the UUID from backend
          'textAnswer': entry.value,
          'numericAnswer': null,
          'booleanAnswer': null,
          'multipleChoiceAnswer': null,
        };
      }).toList();

      // Submit to backend
      await ApiService.submitPersonalityAnswers(apiAnswers);
      
      if (mounted) {
        context.go('/profile-setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}