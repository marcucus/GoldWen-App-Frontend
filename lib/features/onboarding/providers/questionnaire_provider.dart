import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../services/questionnaire_service.dart';

class QuestionnaireProvider with ChangeNotifier {
  List<Question> _questions = [];
  Map<String, dynamic> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  QuestionnaireResult? _result;
  bool _isCompleted = false;

  late final QuestionnaireService _questionnaireService;

  QuestionnaireProvider() {
    final apiService = ApiService();
    _questionnaireService = QuestionnaireService(apiService);
    _loadMockQuestions(); // Load mock questions for now
  }

  List<Question> get questions => _questions;
  Map<String, dynamic> get answers => _answers;
  int get currentQuestionIndex => _currentQuestionIndex;
  Question? get currentQuestion => 
      _currentQuestionIndex < _questions.length ? _questions[_currentQuestionIndex] : null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  QuestionnaireResult? get result => _result;
  bool get isCompleted => _isCompleted;
  double get progress => _questions.isEmpty ? 0 : _currentQuestionIndex / _questions.length;
  bool get canGoNext => _currentQuestionIndex < _questions.length - 1;
  bool get canGoPrevious => _currentQuestionIndex > 0;

  void _loadMockQuestions() {
    // Load mock questions for development
    _questions = [
      Question(
        id: '1',
        text: 'Qu\'est-ce qui vous motive le plus dans la vie ?',
        type: QuestionType.singleChoice,
        options: [
          'L\'épanouissement personnel',
          'Les relations humaines',
          'La réussite professionnelle',
          'L\'aventure et la découverte'
        ],
        required: true,
        order: 1,
      ),
      Question(
        id: '2',
        text: 'Comment préférez-vous passer votre temps libre ?',
        type: QuestionType.singleChoice,
        options: [
          'Lire un bon livre',
          'Sortir avec des amis',
          'Faire du sport',
          'Découvrir de nouveaux endroits'
        ],
        required: true,
        order: 2,
      ),
      Question(
        id: '3',
        text: 'Quelle est votre approche face aux conflits ?',
        type: QuestionType.singleChoice,
        options: [
          'J\'évite autant que possible',
          'Je préfère discuter calmement',
          'Je fais face directement',
          'J\'essaie de trouver un compromis'
        ],
        required: true,
        order: 3,
      ),
      Question(
        id: '4',
        text: 'Dans une relation, qu\'est-ce qui est le plus important pour vous ?',
        type: QuestionType.singleChoice,
        options: [
          'La communication',
          'La confiance',
          'La passion',
          'La complicité'
        ],
        required: true,
        order: 4,
      ),
      Question(
        id: '5',
        text: 'Comment gérez-vous le stress ?',
        type: QuestionType.singleChoice,
        options: [
          'Je médite ou fais du yoga',
          'Je fais du sport',
          'Je parle à mes proches',
          'Je me plonge dans le travail'
        ],
        required: true,
        order: 5,
      ),
      Question(
        id: '6',
        text: 'Quel type d\'environnement vous inspire le plus ?',
        type: QuestionType.singleChoice,
        options: [
          'La nature et les grands espaces',
          'Les villes animées',
          'Les lieux culturels',
          'Les endroits calmes et intimes'
        ],
        required: true,
        order: 6,
      ),
      Question(
        id: '7',
        text: 'Votre façon de prendre des décisions importantes ?',
        type: QuestionType.singleChoice,
        options: [
          'J\'écoute mon intuition',
          'J\'analyse tous les aspects',
          'Je demande conseil',
          'Je fais confiance à l\'expérience'
        ],
        required: true,
        order: 7,
      ),
      Question(
        id: '8',
        text: 'Qu\'est-ce qui vous rend le plus heureux(se) ?',
        type: QuestionType.singleChoice,
        options: [
          'Atteindre mes objectifs',
          'Passer du temps avec mes proches',
          'Découvrir de nouvelles choses',
          'Aider les autres'
        ],
        required: true,
        order: 8,
      ),
      Question(
        id: '9',
        text: 'Votre rapport à l\'argent ?',
        type: QuestionType.singleChoice,
        options: [
          'C\'est un moyen de réaliser mes rêves',
          'La sécurité avant tout',
          'J\'aime profiter de la vie',
          'C\'est un outil pour aider les autres'
        ],
        required: true,
        order: 9,
      ),
      Question(
        id: '10',
        text: 'Dans 10 ans, vous vous voyez comment ?',
        type: QuestionType.singleChoice,
        options: [
          'Épanoui(e) dans ma vie personnelle',
          'Ayant réussi professionnellement',
          'Voyageant à travers le monde',
          'Entouré(e) de ma famille'
        ],
        required: true,
        order: 10,
      ),
    ];
    notifyListeners();
  }

  Future<void> loadQuestions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _questions = await _questionnaireService.getQuestions();
      _questions.sort((a, b) => a.order.compareTo(b.order));
    } on ApiException catch (e) {
      _errorMessage = e.message;
      // Fallback to mock questions if API fails
      _loadMockQuestions();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des questions';
      _loadMockQuestions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void answerQuestion(String questionId, dynamic answer) {
    _answers[questionId] = answer;
    notifyListeners();
  }

  void nextQuestion() {
    if (canGoNext) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (canGoPrevious) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  bool isQuestionAnswered(String questionId) {
    return _answers.containsKey(questionId) && _answers[questionId] != null;
  }

  bool get isCurrentQuestionAnswered {
    if (currentQuestion == null) return false;
    return isQuestionAnswered(currentQuestion!.id);
  }

  bool get areAllRequiredQuestionsAnswered {
    for (final question in _questions) {
      if (question.required && !isQuestionAnswered(question.id)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> submitAnswers() async {
    if (!areAllRequiredQuestionsAnswered) {
      _errorMessage = 'Veuillez répondre à toutes les questions obligatoires';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _questionnaireService.submitAnswers(answers: _answers);
      _isCompleted = true;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erreur lors de la soumission des réponses';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadResults() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _questionnaireService.getResults();
      _isCompleted = true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des résultats';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _answers.clear();
    _currentQuestionIndex = 0;
    _result = null;
    _isCompleted = false;
    _errorMessage = null;
    notifyListeners();
  }
}