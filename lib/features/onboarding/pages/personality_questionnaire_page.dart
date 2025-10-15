import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'gender_selection_page.dart';

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
        print('WARNING: No personality questions found on server');
        setState(() {
          _error = 'Aucune question de personnalité trouvée sur le serveur. Veuillez contacter le support.';
          _isLoading = false;
        });
        return;
      }

      // Sort questions by order
      final sortedQuestions = List<PersonalityQuestion>.from(backendQuestions)
        ..sort((a, b) => a.order.compareTo(b.order));

      print('Loaded ${sortedQuestions.length} personality questions successfully');
      
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

    // Add check for empty questions list
    if (_questions.isEmpty) {
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
                Icons.quiz_outlined,
                size: 64,
                color: Colors.orange[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune question disponible',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les questions du questionnaire n\'ont pas pu être chargées.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
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
      resizeToAvoidBottomInset: true,
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
              physics: const NeverScrollableScrollPhysics(), // Disable horizontal swiping
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

    return SingleChildScrollView(
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
          _buildQuestionOptions(question, selectedAnswer),
          
          const SizedBox(height: AppSpacing.xl),
          
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
    if (question.type == 'multiple_choice') {
      final options = question.options;
      if (options == null || options.isEmpty) {
        return const Center(
          child: Text('Aucune option disponible pour cette question'),
        );
      }
      
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        itemBuilder: (context, index) {
          if (index >= options.length) return Container();
          
          final option = options[index];
          final isSelected = selectedAnswer == option;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Card(
              elevation: isSelected ? 4 : 1,
              color: isSelected ? AppColors.primaryGold.withOpacity(0.1) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryGold : Colors.transparent,
                  width: 2,
                ),
              ),
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
      // Handle scale questions - use minValue and maxValue from question
      final minValue = question.minValue ?? 1;
      final maxValue = question.maxValue ?? 5;
      final scaleRange = maxValue - minValue + 1;
      
      return Column(
        children: [
          Text(
            'Évaluez de $minValue à $maxValue',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(scaleRange, (index) {
              final value = minValue + index;
              final isSelected = selectedAnswer == value;
              
              return GestureDetector(
                onTap: () => _selectAnswer(question.id, value),
                child: Container(
                  width: scaleRange <= 5 ? 50 : 40,
                  height: scaleRange <= 5 ? 50 : 40,
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
                        fontSize: scaleRange <= 5 ? 18 : 14,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        side: BorderSide(
          color: isSelected ? AppColors.primaryGold : Colors.transparent,
          width: 2,
        ),
      ),
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
        // Navigate to gender selection to start the full onboarding flow
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const GenderSelectionPage(),
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