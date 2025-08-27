import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  String? _name;
  DateTime? _birthDate;
  String? _bio;
  List<String> _photos = [];
  List<String> _prompts = [];
  Map<String, dynamic> _personalityAnswers = {};
  bool _isProfileComplete = false;

  String? get name => _name;
  DateTime? get birthDate => _birthDate;
  int? get age => _birthDate != null ? _calculateAge(_birthDate!) : null;
  String? get bio => _bio;
  List<String> get photos => _photos;
  List<String> get prompts => _prompts;
  Map<String, dynamic> get personalityAnswers => _personalityAnswers;
  bool get isProfileComplete => _isProfileComplete;

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void setBasicInfo(String name, DateTime birthDate, String bio) {
    _name = name;
    _birthDate = birthDate;
    _bio = bio;
    _checkProfileCompletion();
    notifyListeners();
  }

  void setBirthDate(DateTime birthDate) {
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
        _birthDate != null &&
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