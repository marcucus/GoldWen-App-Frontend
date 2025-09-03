import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/profile.dart';

class ProfileProvider with ChangeNotifier {
  String? _name;
  int? _age;
  DateTime? _birthDate;
  String? _bio;
  List<String> _photos = [];
  List<String> _prompts = [];
  Map<String, dynamic> _personalityAnswers = {};
  List<PersonalityQuestion> _personalityQuestions = [];
  bool _isProfileComplete = false;
  bool _isLoading = false;
  String? _error;

  String? get name => _name;
  int? get age => _age;
  DateTime? get birthDate => _birthDate;
  String? get bio => _bio;
  List<String> get photos => _photos;
  List<String> get prompts => _prompts;
  Map<String, dynamic> get personalityAnswers => _personalityAnswers;
  List<PersonalityQuestion> get personalityQuestions => _personalityQuestions;
  bool get isProfileComplete => _isProfileComplete;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setBasicInfo(String name, int age, String bio, {DateTime? birthDate}) {
    _name = name;
    _age = age;
    _bio = bio;
    _birthDate = birthDate;
    _checkProfileCompletion();
    notifyListeners();
  }

  void addPhoto(String photoUrl) {
    if (_photos.length < 6) {
      _photos.add(photoUrl);
      _checkProfileCompletion();
      notifyListeners();
    }
  }

  void removePhoto(int index) {
    if (index < _photos.length) {
      _photos.removeAt(index);
      _checkProfileCompletion();
      notifyListeners();
    }
  }

  void addPrompt(String prompt) {
    if (_prompts.length < 3) {
      _prompts.add(prompt);
      _checkProfileCompletion();
      notifyListeners();
    }
  }

  void updatePrompt(int index, String prompt) {
    if (index < _prompts.length) {
      _prompts[index] = prompt;
      notifyListeners();
    }
  }

  void setPersonalityAnswers(Map<String, dynamic> answers) {
    _personalityAnswers = answers;
    _checkProfileCompletion();
    notifyListeners();
  }

  void setPersonalityAnswer(String questionId, dynamic answer) {
    _personalityAnswers[questionId] = answer;
    _checkProfileCompletion();
    notifyListeners();
  }

  Future<void> loadPersonalityQuestions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final questionsData = await ApiService.getPersonalityQuestions();
      _personalityQuestions = questionsData
          .map((questionJson) => PersonalityQuestion.fromJson(questionJson))
          .toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load personality questions: $e';
      print('Error loading personality questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitPersonalityAnswers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final answersData = _personalityAnswers.entries.map((entry) {
        final questionId = entry.key;
        final answer = entry.value;

        // Find the question to determine the type
        final question = _personalityQuestions.firstWhere(
          (q) => q.id == questionId,
          orElse: () => throw Exception('Question not found: $questionId'),
        );

        // Format answer according to question type
        Map<String, dynamic> answerData = {
          'questionId': questionId,
        };

        if (question.type == 'multiple_choice') {
          answerData['textAnswer'] = answer.toString();
        } else if (question.type == 'scale') {
          answerData['numericAnswer'] =
              answer is int ? answer : int.tryParse(answer.toString()) ?? 0;
        } else if (question.type == 'boolean') {
          answerData['booleanAnswer'] = answer is bool
              ? answer
              : answer.toString().toLowerCase() == 'true';
        } else {
          answerData['textAnswer'] = answer.toString();
        }

        return answerData;
      }).toList();

      await ApiService.submitPersonalityAnswers(answersData);
      _error = null;
    } catch (e) {
      _error = 'Failed to submit personality answers: $e';
      print('Error submitting personality answers: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _checkProfileCompletion() {
    _isProfileComplete = _name != null &&
        _age != null &&
        _bio != null &&
        _photos.length >= 3 &&
        _prompts.length >= 3 &&
        _personalityAnswers.isNotEmpty;
  }

  Future<void> saveProfile() async {
    try {
      final profileData = <String, dynamic>{
        if (_birthDate != null)
          'birthDate': _birthDate!.toIso8601String().split('T')[0],
        if (_bio != null) 'bio': _bio,
        // Add other profile fields as needed
      };

      await ApiService.updateProfile(profileData);
    } catch (e) {
      // Handle error - could throw to let UI handle it
      rethrow;
    }
  }

  Future<void> submitPromptAnswers() async {
    try {
      final promptAnswers = _prompts.asMap().entries.map((entry) {
        return {
          'promptId':
              'prompt_${entry.key + 1}', // In real app, use actual prompt IDs
          'answer': entry.value,
          'order': entry.key + 1,
        };
      }).toList();

      await ApiService.submitPromptAnswers(promptAnswers);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadProfile([String? userId]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getProfile();
      final profileData = response['data'] ?? response;

      // Update profile data from response
      _name =
          profileData['firstName'] != null && profileData['lastName'] != null
              ? '${profileData['firstName']} ${profileData['lastName']}'
              : profileData['name'];
      _bio = profileData['bio'];
      _birthDate = profileData['birthDate'] != null
          ? DateTime.parse(profileData['birthDate'])
          : null;

      // Calculate age from birthDate
      if (_birthDate != null) {
        final now = DateTime.now();
        _age = now.year - _birthDate!.year;
        if (now.month < _birthDate!.month ||
            (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
          _age = _age! - 1;
        }
      }

      // Load photos and prompts
      _photos = List<String>.from(profileData['photos'] ?? []);
      _prompts = List<String>.from(profileData['prompts'] ?? []);
      _personalityAnswers =
          Map<String, dynamic>.from(profileData['personalityAnswers'] ?? {});

      _checkProfileCompletion();
    } catch (e) {
      // If API call fails, keep default empty state
      _name = null;
      _age = null;
      _bio = null;
      _birthDate = null;
      _photos.clear();
      _prompts.clear();
      _personalityAnswers.clear();
      _isProfileComplete = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
