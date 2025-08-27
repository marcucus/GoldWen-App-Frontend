import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  String? _name;
  int? _age;
  String? _bio;
  List<String> _photos = [];
  List<String> _prompts = [];
  Map<String, dynamic> _personalityAnswers = {};
  bool _isProfileComplete = false;

  String? get name => _name;
  int? get age => _age;
  String? get bio => _bio;
  List<String> get photos => _photos;
  List<String> get prompts => _prompts;
  Map<String, dynamic> get personalityAnswers => _personalityAnswers;
  bool get isProfileComplete => _isProfileComplete;

  void setBasicInfo(String name, int age, String bio) {
    _name = name;
    _age = age;
    _bio = bio;
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
    // TODO: Implement save profile to backend
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> loadProfile(String userId) async {
    // TODO: Implement load profile from backend
    await Future.delayed(const Duration(seconds: 1));
  }
}