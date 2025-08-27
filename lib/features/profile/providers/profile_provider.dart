import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  String? _name;
  DateTime? _birthDate;
  String? _bio;
  List<String> _photos = [];
  List<String> _prompts = [];
  Map<String, dynamic> _personalityAnswers = {};
  bool _isProfileComplete = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  late final ProfileService _profileService;
  Profile? _currentProfile;

  ProfileProvider() {
    final apiService = ApiService();
    _profileService = ProfileService(apiService);
  }

  String? get name => _name;
  DateTime? get birthDate => _birthDate;
  int? get age => _birthDate != null ? _calculateAge(_birthDate!) : null;
  String? get bio => _bio;
  List<String> get photos => _photos;
  List<String> get prompts => _prompts;
  Map<String, dynamic> get personalityAnswers => _personalityAnswers;
  bool get isProfileComplete => _isProfileComplete;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Profile? get currentProfile => _currentProfile;

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

  Future<void> addPhoto(String photoPath) async {
    if (_photos.length >= 6) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Upload photo to backend
      final photoUrl = await _profileService.uploadPhoto(photoPath);
      _photos.add(photoUrl);
      _checkProfileCompletion();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'upload de la photo';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removePhoto(int index) async {
    if (index >= _photos.length) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final photoUrl = _photos[index];
      await _profileService.deletePhoto(photoUrl);
      _photos.removeAt(index);
      _checkProfileCompletion();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression de la photo';
    } finally {
      _isLoading = false;
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

  /// Save complete profile to backend
  Future<bool> saveProfile() async {
    if (!_isProfileComplete) {
      _errorMessage = 'Profil incomplet';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _profileService.createProfile(
        firstName: _name!.split(' ').first,
        lastName: _name!.split(' ').length > 1 ? _name!.split(' ').skip(1).join(' ') : '',
        birthDate: _birthDate!,
        bio: _bio!,
        photos: _photos,
        prompts: _prompts,
        personalityAnswers: _personalityAnswers,
      );
      
      _currentProfile = profile;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde du profil';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load profile from backend
  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _profileService.getCurrentUserProfile();
      
      _currentProfile = profile;
      _name = profile.fullName;
      _birthDate = profile.birthDate;
      _bio = profile.bio;
      _photos = List.from(profile.photos);
      _prompts = List.from(profile.prompts);
      _personalityAnswers = Map.from(profile.personalityAnswers);
      _checkProfileCompletion();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement du profil';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update existing profile
  Future<bool> updateProfile() async {
    if (_currentProfile == null) {
      return await saveProfile();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _profileService.updateProfile(
        profileId: _currentProfile!.id,
        firstName: _name?.split(' ').first,
        lastName: _name?.split(' ').length != null && _name!.split(' ').length > 1 
            ? _name!.split(' ').skip(1).join(' ') 
            : '',
        birthDate: _birthDate,
        bio: _bio,
        photos: _photos,
        prompts: _prompts,
        personalityAnswers: _personalityAnswers,
      );
      
      _currentProfile = updatedProfile;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du profil';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get profile completion status
  Future<void> checkProfileCompletion() async {
    try {
      final completion = await _profileService.getProfileCompletion();
      // Update local state based on server response if needed
    } catch (e) {
      // Handle error silently or log it
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearProfile() {
    _name = null;
    _birthDate = null;
    _bio = null;
    _photos.clear();
    _prompts.clear();
    _personalityAnswers.clear();
    _isProfileComplete = false;
    _currentProfile = null;
    _errorMessage = null;
    notifyListeners();
  }
}