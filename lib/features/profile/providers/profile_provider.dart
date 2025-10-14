import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/models/profile.dart';

class ProfileProvider with ChangeNotifier {
  String? _name;
  int? _age;
  DateTime? _birthDate;
  String? _bio;
  List<Photo> _photos = [];
  List<MediaFile> _mediaFiles = [];
  List<String> _prompts = [];
  Map<String, dynamic> _personalityAnswers = {};
  List<PersonalityQuestion> _personalityQuestions = [];
  List<Prompt> _availablePrompts = [];
  Map<String, String> _promptAnswers = {}; // prompt ID -> answer
  bool _isProfileComplete = false;
  bool _isLoading = false;
  String? _error;
  
  // New fields for complete profile
  String? _gender;
  List<String> _interestedInGenders = [];
  String? _location;
  double? _latitude;
  double? _longitude;
  int? _minAge;
  int? _maxAge;
  int? _maxDistance;
  String? _jobTitle;
  String? _company;
  String? _education;
  int? _height;
  List<String> _interests = [];
  List<String> _languages = [];
  ProfileCompletion? _profileCompletion;

  String? get name => _name;
  int? get age => _age;
  DateTime? get birthDate => _birthDate;
  String? get bio => _bio;
  List<Photo> get photos => _photos;
  List<MediaFile> get mediaFiles => _mediaFiles;
  List<String> get prompts => _prompts;
  Map<String, dynamic> get personalityAnswers => _personalityAnswers;
  List<PersonalityQuestion> get personalityQuestions => _personalityQuestions;
  List<Prompt> get availablePrompts => _availablePrompts;
  Map<String, String> get promptAnswers => _promptAnswers;
  bool get isProfileComplete => _isProfileComplete;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // New getters
  String? get gender => _gender;
  List<String> get interestedInGenders => _interestedInGenders;
  String? get location => _location;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  int? get minAge => _minAge;
  int? get maxAge => _maxAge;
  int? get maxDistance => _maxDistance;
  String? get jobTitle => _jobTitle;
  String? get company => _company;
  String? get education => _education;
  int? get height => _height;
  List<String> get interests => _interests;
  List<String> get languages => _languages;
  ProfileCompletion? get profileCompletion => _profileCompletion;

  void setBasicInfo(String name, int age, String bio, {DateTime? birthDate}) {
    _name = name;
    _age = age;
    _bio = bio;
    _birthDate = birthDate;
    _checkProfileCompletion();
    notifyListeners();
  }

  void addPhoto(Photo photo) {
    if (_photos.length < 6) {
      _photos.add(photo);
      _checkProfileCompletion();
      notifyListeners();
    }
  }

  void addPhotoFromUrl(String photoUrl) {
    if (_photos.length < 6) {
      // Create a temporary Photo object for compatibility
      final photo = Photo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: photoUrl,
        order: _photos.length + 1,
        isPrimary: _photos.isEmpty,
        createdAt: DateTime.now(),
      );
      _photos.add(photo);
      _checkProfileCompletion();
      notifyListeners();
    }
  }

  void updatePhotos(List<Photo> photos) {
    _photos = List.from(photos);
    _checkProfileCompletion();
    notifyListeners();
  }

  void updateMediaFiles(List<MediaFile> mediaFiles) {
    _mediaFiles = List.from(mediaFiles);
    _checkProfileCompletion();
    notifyListeners();
  }

  void addMediaFile(MediaFile mediaFile) {
    _mediaFiles.add(mediaFile);
    _checkProfileCompletion();
    notifyListeners();
  }

  void removeMediaFile(String mediaId) {
    _mediaFiles.removeWhere((m) => m.id == mediaId);
    _checkProfileCompletion();
    notifyListeners();
  }

  void removePhoto(int index) {
    if (index < _photos.length) {
      _photos.removeAt(index);
      // Update order for remaining photos
      for (int i = 0; i < _photos.length; i++) {
        _photos[i] = Photo(
          id: _photos[i].id,
          url: _photos[i].url,
          order: i + 1,
          isPrimary: _photos[i].isPrimary,
          createdAt: _photos[i].createdAt,
        );
      }
      _checkProfileCompletion();
      notifyListeners();
    }
  }

  void reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex >= _photos.length || newIndex > _photos.length) return;
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final Photo photo = _photos.removeAt(oldIndex);
    _photos.insert(newIndex, photo);
    
    // Update order for all photos
    for (int i = 0; i < _photos.length; i++) {
      _photos[i] = Photo(
        id: _photos[i].id,
        url: _photos[i].url,
        order: i + 1,
        isPrimary: _photos[i].isPrimary,
        createdAt: _photos[i].createdAt,
      );
    }
    
    notifyListeners();
  }

  void setPrimaryPhoto(String photoId) {
    _photos = _photos.map((photo) => Photo(
      id: photo.id,
      url: photo.url,
      order: photo.order,
      isPrimary: photo.id == photoId,
      createdAt: photo.createdAt,
    )).toList();
    notifyListeners();
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

  void setPromptAnswer(String promptId, String answer) {
    _promptAnswers[promptId] = answer;
    _checkProfileCompletion();
    notifyListeners();
  }

  void removePromptAnswer(String promptId) {
    _promptAnswers.remove(promptId);
    _checkProfileCompletion();
    notifyListeners();
  }

  void clearPromptAnswers() {
    _promptAnswers.clear();
    notifyListeners();
  }

  // New setter methods
  void setGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void setGenderPreferences(List<String> genders) {
    _interestedInGenders = genders;
    notifyListeners();
  }

  void setLocation({required String location, double? latitude, double? longitude}) {
    _location = location;
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }

  void setAgePreferences({required int minAge, required int maxAge}) {
    _minAge = minAge;
    _maxAge = maxAge;
    notifyListeners();
  }

  void setDistancePreference({required int maxDistance}) {
    _maxDistance = maxDistance;
    notifyListeners();
  }

  void setJobTitle(String jobTitle) {
    _jobTitle = jobTitle;
    notifyListeners();
  }

  void setCompany(String company) {
    _company = company;
    notifyListeners();
  }

  void setEducation(String education) {
    _education = education;
    notifyListeners();
  }

  void setHeight(int height) {
    _height = height;
    notifyListeners();
  }

  void setInterests(List<String> interests) {
    _interests = interests;
    notifyListeners();
  }

  void setLanguages(List<String> languages) {
    _languages = languages;
    notifyListeners();
  }

  Future<void> loadPersonalityQuestions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final questionsData = await ApiService.getPersonalityQuestions();
      
      if (questionsData.isEmpty) {
        _error = 'Aucune question de personnalité disponible';
        print('WARNING: API returned empty personality questions list');
      } else {
        _personalityQuestions = questionsData
            .map((questionJson) => PersonalityQuestion.fromJson(questionJson))
            .toList();
        print('Successfully loaded ${_personalityQuestions.length} personality questions');
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to load personality questions: $e';
      print('Error loading personality questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPrompts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final promptsData = await ApiService.getPrompts();
      _availablePrompts = promptsData
          .map((promptJson) => Prompt.fromJson(promptJson))
          .toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load prompts: $e';
      print('Error loading prompts: $e');
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

      print('ProfileProvider: Submitting ${answersData.length} personality answers');
      print('ProfileProvider: Answers data: $answersData');
      
      await ApiService.submitPersonalityAnswers(answersData);
      _error = null;
      print('ProfileProvider: Personality answers submitted successfully');
      
      // Track personality quiz completion
      await AnalyticsService.trackPersonalityQuizCompleted();
      
      // Refresh profile data after successful submission
      await loadProfile();
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
    // Local validation - but backend completion status is authoritative
    // This is used for UI guidance only, not for actual validation
    _isProfileComplete = _name != null &&
        _age != null &&
        _bio != null &&
        _photos.length >= 3 &&
        _promptAnswers.length >= 3 &&
        _personalityAnswers.isNotEmpty &&
        _gender != null &&
        _interestedInGenders.isNotEmpty &&
        _location != null &&
        _minAge != null &&
        _maxAge != null;
    
    // Note: Backend completion status (_profileCompletion) is the authoritative source
    // and should always be used for actual validation checks
  }

  Future<void> saveProfile() async {
    try {
      final profileData = <String, dynamic>{
        if (_name != null) 'pseudo': _name,
        if (_birthDate != null)
          'birthDate': _birthDate!.toIso8601String().split('T')[0],
        if (_bio != null) 'bio': _bio,
        if (_gender != null) 'gender': _gender,
        if (_interestedInGenders.isNotEmpty) 'interestedInGenders': _interestedInGenders,
        if (_location != null) 'location': _location,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        if (_minAge != null) 'minAge': _minAge,
        if (_maxAge != null) 'maxAge': _maxAge,
        if (_maxDistance != null) 'maxDistance': _maxDistance,
        if (_jobTitle != null) 'jobTitle': _jobTitle,
        if (_company != null) 'company': _company,
        if (_education != null) 'education': _education,
        if (_height != null) 'height': _height,
        if (_interests.isNotEmpty) 'interests': _interests,
        if (_languages.isNotEmpty) 'languages': _languages,
      };

      print('Saving profile data: $profileData');
      await ApiService.updateProfile(profileData);
      print('Profile saved successfully');
      
      // Refresh profile data and completion status after successful save
      await loadProfile();
    } catch (e) {
      print('Error in saveProfile: $e');
      // Handle error - could throw to let UI handle it
      rethrow;
    }
  }

  Future<void> submitPromptAnswers() async {
    try {
      print('DEBUG: Current _promptAnswers state: $_promptAnswers');
      print('DEBUG: _promptAnswers.entries: ${_promptAnswers.entries.toList()}');
      
      final promptAnswers = _promptAnswers.entries.map((entry) {
        return {
          'promptId': entry.key, // Use real prompt ID
          'answer': entry.value,
        };
      }).toList();

      print('Submitting ${promptAnswers.length} prompt answers');
      print('Prompt answers data: $promptAnswers');

      if (promptAnswers.isEmpty) {
        throw Exception('No prompt answers to submit. Please fill in the prompts first.');
      }

      await ApiService.submitPromptAnswers(promptAnswers);
      print('Prompt answers submitted successfully');
      
      // Refresh profile data and completion status after successful submission
      await loadProfile();
    } catch (e) {
      print('Error in submitPromptAnswers: $e');
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
      _name = profileData['pseudo'] ?? 
          (profileData['firstName'] != null && profileData['lastName'] != null
              ? '${profileData['firstName']} ${profileData['lastName']}'
              : profileData['name']);
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

      // Load photos from profile data
      if (profileData['photos'] != null && profileData['photos'] is List) {
        try {
          _photos = (profileData['photos'] as List)
              .map((photoData) => Photo.fromJson(photoData))
              .toList();
        } catch (e) {
          debugPrint('Error parsing photos: $e');
          // Fallback to string URLs if Photo parsing fails
          _photos = (profileData['photos'] as List)
              .map((photoUrl) => Photo(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    url: photoUrl.toString(),
                    order: 1,
                    isPrimary: false,
                    createdAt: DateTime.now(),
                  ))
              .toList();
        }
      } else {
        _photos.clear();
      }

      // Load media files from profile data
      if (profileData['mediaFiles'] != null && profileData['mediaFiles'] is List) {
        try {
          _mediaFiles = (profileData['mediaFiles'] as List)
              .map((mediaData) => MediaFile.fromJson(mediaData))
              .toList();
        } catch (e) {
          debugPrint('Error parsing media files: $e');
          _mediaFiles.clear();
        }
      } else {
        _mediaFiles.clear();
      }
      
      _prompts = List<String>.from(profileData['prompts'] ?? []);
      _personalityAnswers =
          Map<String, dynamic>.from(profileData['personalityAnswers'] ?? {});

      _checkProfileCompletion();
      
      // Also load the detailed completion status from backend
      await loadProfileCompletion();
    } catch (e) {
      // If API call fails, keep default empty state
      _name = null;
      _age = null;
      _bio = null;
      _birthDate = null;
      _photos.clear();
      _mediaFiles.clear();
      _prompts.clear();
      _personalityAnswers.clear();
      _isProfileComplete = false;
      _profileCompletion = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfileCompletion() async {
    try {
      final response = await ApiService.getProfileCompletion();
      final completionData = response['data'] ?? response;
      
      // Debug: Print the backend response for profile completion
      print('Profile completion raw response: $completionData');
      print('Requirements section: ${completionData['requirements']}');
      print('Minimum prompts section: ${completionData['requirements']?['minimumPrompts']}');
      
      // Map backend response to frontend model
      final mappedData = {
        'isCompleted': completionData['isComplete'] ?? false,
        'hasPhotos': completionData['requirements']?['minimumPhotos']?['satisfied'] ?? false,
        'hasPrompts': completionData['requirements']?['minimumPrompts']?['satisfied'] ?? false,
        'hasPersonalityAnswers': completionData['requirements']?['personalityQuestionnaire']?['satisfied'] ?? false,
        'hasRequiredProfileFields': completionData['requirements']?['basicInfo']?['satisfied'] ?? false,
        'missingSteps': completionData['missingSteps'] ?? [],
      };
      
      print('Mapped completion data: $mappedData');
      
      _profileCompletion = ProfileCompletion.fromJson(mappedData);
      _isProfileComplete = _profileCompletion!.isCompleted;
      
      notifyListeners();
    } catch (e) {
      print('Error loading profile completion: $e');
      _profileCompletion = null;
    }
  }

  Future<void> validateAndActivateProfile() async {
    try {
      // First check if profile is complete using backend validation
      await loadProfileCompletion();
      
      if (_profileCompletion?.isCompleted ?? false) {
        // Profile is complete, update status to mark as validated
        await ApiService.updateProfileStatus(completed: true);
        await loadProfileCompletion(); // Reload to get updated status
        
        // Track profile completion
        // Note: We need userId from auth - this assumes it's available via API
        await AnalyticsService.trackProfileCompleted('current_user');
      } else {
        throw Exception('Profile is not complete. Missing steps: ${_profileCompletion?.missingSteps.join(', ') ?? 'Unknown'}');
      }
    } catch (e) {
      print('Error validating profile: $e');
      rethrow;
    }
  }

  /// Get the next incomplete step that the user should complete
  /// Returns null if profile is complete
  String? getNextIncompleteStep() {
    final completion = _profileCompletion;
    if (completion == null) return null;
    if (completion.isCompleted) return null;
    
    // Check in order: basic info, photos, prompts, personality
    if (!completion.hasRequiredProfileFields) {
      return 'basic_info';
    } else if (!completion.hasPhotos) {
      return 'photos';
    } else if (!completion.hasPrompts) {
      return 'prompts';
    } else if (!completion.hasPersonalityAnswers) {
      return 'personality';
    }
    
    return null;
  }

  /// Check if the profile is truly complete based on backend validation
  /// This is the authoritative method for checking completion
  bool get isProfileTrulyComplete {
    return _profileCompletion?.isCompleted ?? false;
  }

  // Test helper method - only used in tests
  void setTestCompletion(ProfileCompletion? completion) {
    _profileCompletion = completion;
    if (completion != null) {
      _isProfileComplete = completion.isCompleted;
    }
    notifyListeners();
  }
}
