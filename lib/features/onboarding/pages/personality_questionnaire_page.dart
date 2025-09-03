import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/pages/profile_setup_page.dart';

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
  bool _isLoading = true;
  String? _error;
  Map<String, String> _questionKeyToUuid = {};

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
  void initState() {
    super.initState();
    _loadPersonalityQuestions();
  }

  Future<void> _loadPersonalityQuestions() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.loadPersonalityQuestions();
      
      if (profileProvider.error != null) {
        setState(() {
          _error = profileProvider.error;
          _isLoading = false;
        });
        return;
      }

      // Create mapping between hardcoded question keys and backend UUIDs
      _createQuestionMapping(profileProvider.personalityQuestions);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des questions: $e';
        _isLoading = false;
      });
    }
  }

  void _createQuestionMapping(List<PersonalityQuestion> backendQuestions) {
    // Map hardcoded question keys to backend question UUIDs
    // First, try to match by category if available
    final categoryMapping = {
      'motivation': 'motivation',
      'free_time': 'free_time', 
      'conflict_style': 'conflict_style',
      'relationship_expectation': 'relationship_expectation',
      'communication_style': 'communication_style',
      'family_importance': 'family_importance',
      'stress_management': 'stress_management',
      'future_vision': 'future_vision',
      'humor_style': 'humor_style',
      'core_value': 'core_value',
    };

    // Sort backend questions by order to ensure consistent mapping
    final sortedBackendQuestions = List<PersonalityQuestion>.from(backendQuestions)
      ..sort((a, b) => a.order.compareTo(b.order));

    // If category mapping works, use it
    for (final backendQuestion in sortedBackendQuestions) {
      for (final entry in categoryMapping.entries) {
        if (backendQuestion.category == entry.value) {
          _questionKeyToUuid[entry.key] = backendQuestion.id;
          break;
        }
      }
    }

    // If category mapping didn't work (not enough matches), fall back to order-based mapping
    if (_questionKeyToUuid.length < _questions.length && sortedBackendQuestions.length >= _questions.length) {
      _questionKeyToUuid.clear();
      for (int i = 0; i < _questions.length && i < sortedBackendQuestions.length; i++) {
        final questionKey = _questions[i]['key'] as String;
        _questionKeyToUuid[questionKey] = sortedBackendQuestions[i].id;
      }
    }

    print('Question mapping created: $_questionKeyToUuid');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Questionnaire de personnalité'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Questionnaire de personnalité'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadPersonalityQuestions();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
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
      
      // Convert answers to API format using actual UUIDs
      final List<Map<String, dynamic>> apiAnswers = _answers.entries.map((entry) {
        final questionUuid = _questionKeyToUuid[entry.key];
        if (questionUuid == null) {
          throw Exception('Question UUID not found for key: ${entry.key}');
        }
        
        return {
          'questionId': questionUuid,
          'textAnswer': entry.value,
          'numericAnswer': null,
          'booleanAnswer': null,
          'multipleChoiceAnswer': null,
        };
      }).toList();

      // Submit to backend
      await ApiService.submitPersonalityAnswers(apiAnswers);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ProfileSetupPage(),
          ),
        );
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