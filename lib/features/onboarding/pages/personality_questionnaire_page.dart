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
  List<PersonalityQuestion> _questions = [];

  // Hardcoded fallback questions in case API fails
  final List<Map<String, dynamic>> _fallbackQuestions = [
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

      // Use dynamic questions from API
      final backendQuestions = profileProvider.personalityQuestions;
      if (backendQuestions.isEmpty) {
        throw Exception('Aucune question de personnalité trouvée sur le serveur');
      }

      // Sort questions by order
      final sortedQuestions = List<PersonalityQuestion>.from(backendQuestions)
        ..sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        _questions = sortedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading personality questions: $e');
      setState(() {
        _error = 'Erreur lors du chargement des questions: $e';
        _isLoading = false;
      });
    }
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

  Widget _buildQuestionPage(PersonalityQuestion question) {
    final selectedAnswer = _answers[question.id];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // Question
          Text(
            question.question,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Options - render based on question type
          Expanded(
            child: _buildQuestionOptions(question, selectedAnswer),
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

  Widget _buildQuestionOptions(PersonalityQuestion question, dynamic selectedAnswer) {
    if (question.type == 'multiple_choice' && question.options.isNotEmpty) {
      return ListView.builder(
        itemCount: question.options.length,
        itemBuilder: (context, index) {
          final option = question.options[index];
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
                onTap: () => _selectAnswer(question.id, option),
              ),
            ),
          );
        },
      );
    } else if (question.type == 'scale') {
      // Handle scale questions (e.g., 1-5 rating)
      return Column(
        children: [
          Text(
            'Évaluez de 1 à 5',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final value = index + 1;
              final isSelected = selectedAnswer == value;
              
              return GestureDetector(
                onTap: () => _selectAnswer(question.id, value),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primaryGold : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      value.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    } else if (question.type == 'boolean') {
      // Handle yes/no questions
      return Column(
        children: [
          _buildBooleanOption(question.id, true, 'Oui', selectedAnswer),
          const SizedBox(height: AppSpacing.md),
          _buildBooleanOption(question.id, false, 'Non', selectedAnswer),
        ],
      );
    } else {
      // Fallback for text input or unknown types
      return TextField(
        decoration: const InputDecoration(
          hintText: 'Tapez votre réponse...',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => _selectAnswer(question.id, value),
        controller: TextEditingController(text: selectedAnswer?.toString()),
      );
    }
  }

  Widget _buildBooleanOption(String questionId, bool value, String label, dynamic selectedAnswer) {
    final isSelected = selectedAnswer == value;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppColors.primaryGold.withOpacity(0.1) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        title: Text(
          label,
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
        onTap: () => _selectAnswer(questionId, value),
      ),
    );
  }

  void _selectAnswer(String questionId, dynamic answer) {
    setState(() {
      _answers[questionId] = answer;
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Verify we have all answers
      if (_answers.length < _questions.length) {
        throw Exception('Veuillez répondre à toutes les questions');
      }
      
      // Convert answers to API format using actual question IDs
      final List<Map<String, dynamic>> apiAnswers = _answers.entries.map((entry) {
        final questionId = entry.key;
        final answerValue = entry.value;
        
        // Find the question to determine correct answer format
        final question = _questions.firstWhere(
          (q) => q.id == questionId, 
          orElse: () => throw Exception('Question not found: $questionId')
        );
        
        Map<String, dynamic> answerData = {
          'questionId': questionId,
        };
        
        // Set the appropriate answer field based on question type
        if (question.type == 'multiple_choice') {
          answerData['textAnswer'] = answerValue.toString();
        } else if (question.type == 'scale') {
          answerData['numericAnswer'] = answerValue is int ? answerValue : int.tryParse(answerValue.toString()) ?? 0;
        } else if (question.type == 'boolean') {
          answerData['booleanAnswer'] = answerValue is bool ? answerValue : answerValue.toString().toLowerCase() == 'true';
        } else {
          answerData['textAnswer'] = answerValue.toString();
        }
        
        return answerData;
      }).toList();

      print('Submitting ${apiAnswers.length} personality answers');
      print('API Answers format: $apiAnswers');

      // Submit to backend and refresh user to get updated status
      await ApiService.submitPersonalityAnswers(apiAnswers);
      await authProvider.refreshUser();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ProfileSetupPage(),
          ),
        );
      }
    } catch (e) {
      print('Error submitting personality answers: $e');
      if (mounted) {
        String errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
        
        // Provide more specific error messages
        if (e.toString().contains('not found')) {
          errorMessage = 'Erreur de configuration des questions. Veuillez redémarrer l\'application.';
        } else if (e.toString().contains('Validation failed')) {
          errorMessage = 'Erreur de validation des réponses. Veuillez vérifier vos réponses.';
        }
        
        setState(() {
          _error = errorMessage;
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}