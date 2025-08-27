import '../../../core/services/api_service.dart';

class ProfileService {
  final ApiService _apiService;

  ProfileService(this._apiService);

  /// Create user profile
  Future<Profile> createProfile({
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String bio,
    required List<String> photos,
    required List<String> prompts,
    required Map<String, dynamic> personalityAnswers,
  }) async {
    final response = await _apiService.post('/profiles', data: {
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'bio': bio,
      'photos': photos,
      'prompts': prompts,
      'personalityAnswers': personalityAnswers,
    });

    return Profile.fromJson(response.data);
  }

  /// Update user profile
  Future<Profile> updateProfile({
    required String profileId,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? bio,
    List<String>? photos,
    List<String>? prompts,
    Map<String, dynamic>? personalityAnswers,
  }) async {
    final data = <String, dynamic>{};
    
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (birthDate != null) data['birthDate'] = birthDate.toIso8601String();
    if (bio != null) data['bio'] = bio;
    if (photos != null) data['photos'] = photos;
    if (prompts != null) data['prompts'] = prompts;
    if (personalityAnswers != null) data['personalityAnswers'] = personalityAnswers;

    final response = await _apiService.put('/profiles/$profileId', data: data);

    return Profile.fromJson(response.data);
  }

  /// Get user profile
  Future<Profile> getProfile(String profileId) async {
    final response = await _apiService.get('/profiles/$profileId');
    return Profile.fromJson(response.data);
  }

  /// Get current user profile
  Future<Profile> getCurrentUserProfile() async {
    final response = await _apiService.get('/profiles/me');
    return Profile.fromJson(response.data);
  }

  /// Upload profile photo
  Future<String> uploadPhoto(String imagePath) async {
    // TODO: Implement actual image upload
    // This is a mock implementation
    await Future.delayed(const Duration(seconds: 2));
    return 'https://example.com/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  /// Delete profile photo
  Future<void> deletePhoto(String photoUrl) async {
    await _apiService.delete('/profiles/photos', data: {
      'photoUrl': photoUrl,
    });
  }

  /// Submit personality questionnaire
  Future<void> submitPersonalityAnswers({
    required Map<String, dynamic> answers,
  }) async {
    await _apiService.post('/profiles/personality', data: {
      'answers': answers,
    });
  }

  /// Get profile completion status
  Future<ProfileCompletion> getProfileCompletion() async {
    final response = await _apiService.get('/profiles/completion');
    return ProfileCompletion.fromJson(response.data);
  }
}

class Profile {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String bio;
  final List<String> photos;
  final List<String> prompts;
  final Map<String, dynamic> personalityAnswers;
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.bio,
    required this.photos,
    required this.prompts,
    required this.personalityAnswers,
    required this.isComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      bio: json['bio'] as String,
      photos: List<String>.from(json['photos'] as List),
      prompts: List<String>.from(json['prompts'] as List),
      personalityAnswers: Map<String, dynamic>.from(json['personalityAnswers'] as Map),
      isComplete: json['isComplete'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'bio': bio,
      'photos': photos,
      'prompts': prompts,
      'personalityAnswers': personalityAnswers,
      'isComplete': isComplete,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

class ProfileCompletion {
  final bool hasBasicInfo;
  final bool hasPhotos;
  final bool hasPrompts;
  final bool hasPersonalityAnswers;
  final bool isComplete;
  final double completionPercentage;

  ProfileCompletion({
    required this.hasBasicInfo,
    required this.hasPhotos,
    required this.hasPrompts,
    required this.hasPersonalityAnswers,
    required this.isComplete,
    required this.completionPercentage,
  });

  factory ProfileCompletion.fromJson(Map<String, dynamic> json) {
    return ProfileCompletion(
      hasBasicInfo: json['hasBasicInfo'] as bool,
      hasPhotos: json['hasPhotos'] as bool,
      hasPrompts: json['hasPrompts'] as bool,
      hasPersonalityAnswers: json['hasPersonalityAnswers'] as bool,
      isComplete: json['isComplete'] as bool,
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasBasicInfo': hasBasicInfo,
      'hasPhotos': hasPhotos,
      'hasPrompts': hasPrompts,
      'hasPersonalityAnswers': hasPersonalityAnswers,
      'isComplete': isComplete,
      'completionPercentage': completionPercentage,
    };
  }
}