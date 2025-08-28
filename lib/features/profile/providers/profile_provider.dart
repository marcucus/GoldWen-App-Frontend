import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  String? _name;
  int? _age;
  DateTime? _birthDate;
  String? _bio;
  List<String> _photos = [];
  List<String> _prompts = [];
  Map<String, dynamic> _personalityAnswers = {};
  bool _isProfileComplete = false;

  String? get name => _name;
  int? get age => _age;
  DateTime? get birthDate => _birthDate;
  String? get bio => _bio;
  List<String> get photos => _photos;
  List<String> get prompts => _prompts;
  Map<String, dynamic> get personalityAnswers => _personalityAnswers;
  bool get isProfileComplete => _isProfileComplete;

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
        if (_birthDate != null) 'birthDate': _birthDate!.toIso8601String().split('T')[0],
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
          'promptId': 'prompt_${entry.key + 1}', // In real app, use actual prompt IDs
          'answer': entry.value,
          'order': entry.key + 1,
        };
      }).toList();
      
      await ApiService.submitPromptAnswers(promptAnswers);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadProfile(String userId) async {
    // TODO: Implement load profile from backend
    await Future.delayed(const Duration(seconds: 1));
  }
}