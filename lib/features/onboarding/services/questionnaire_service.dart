import '../../../core/services/api_service.dart';

class QuestionnaireService {
  final ApiService _apiService;

  QuestionnaireService(this._apiService);

  /// Get personality questionnaire questions
  Future<List<Question>> getQuestions() async {
    final response = await _apiService.get('/questionnaire/questions');
    
    final questions = (response.data['questions'] as List)
        .map((json) => Question.fromJson(json))
        .toList();
    
    return questions;
  }

  /// Submit questionnaire answers
  Future<QuestionnaireResult> submitAnswers({
    required Map<String, dynamic> answers,
  }) async {
    final response = await _apiService.post('/questionnaire/submit', data: {
      'answers': answers,
    });

    return QuestionnaireResult.fromJson(response.data);
  }

  /// Get questionnaire results
  Future<QuestionnaireResult> getResults() async {
    final response = await _apiService.get('/questionnaire/results');
    return QuestionnaireResult.fromJson(response.data);
  }

  /// Update questionnaire answers
  Future<QuestionnaireResult> updateAnswers({
    required Map<String, dynamic> answers,
  }) async {
    final response = await _apiService.put('/questionnaire/answers', data: {
      'answers': answers,
    });

    return QuestionnaireResult.fromJson(response.data);
  }
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<String> options;
  final bool required;
  final int order;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    required this.required,
    required this.order,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(json['options'] as List? ?? []),
      required: json['required'] as bool? ?? true,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      'options': options,
      'required': required,
      'order': order,
    };
  }
}

class QuestionnaireResult {
  final String id;
  final String userId;
  final Map<String, dynamic> answers;
  final PersonalityProfile personalityProfile;
  final DateTime completedAt;

  QuestionnaireResult({
    required this.id,
    required this.userId,
    required this.answers,
    required this.personalityProfile,
    required this.completedAt,
  });

  factory QuestionnaireResult.fromJson(Map<String, dynamic> json) {
    return QuestionnaireResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      answers: Map<String, dynamic>.from(json['answers'] as Map),
      personalityProfile: PersonalityProfile.fromJson(json['personalityProfile'] as Map<String, dynamic>),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'answers': answers,
      'personalityProfile': personalityProfile.toJson(),
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

class PersonalityProfile {
  final Map<String, double> traits;
  final List<String> values;
  final String summary;

  PersonalityProfile({
    required this.traits,
    required this.values,
    required this.summary,
  });

  factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
    return PersonalityProfile(
      traits: Map<String, double>.from(json['traits'] as Map),
      values: List<String>.from(json['values'] as List),
      summary: json['summary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'traits': traits,
      'values': values,
      'summary': summary,
    };
  }
}

enum QuestionType {
  multipleChoice,
  singleChoice,
  scale,
  text,
  boolean,
}