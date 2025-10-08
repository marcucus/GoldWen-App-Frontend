import 'moderation.dart';

class Profile {
  final String id;
  final String userId;
  final String? pseudo;
  final DateTime? birthDate;
  final String? gender;
  final List<String> interestedInGenders;
  final String? bio;
  final ModerationResult? bioModerationResult;
  final String? jobTitle;
  final String? company;
  final String? education;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int maxDistance;
  final int minAge;
  final int maxAge;
  final List<String> interests;
  final List<String> languages;
  final int? height;
  final List<Photo> photos;
  final List<PersonalityAnswer> personalityAnswers;
  final List<PromptAnswer> promptAnswers;
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.userId,
    this.pseudo,
    this.birthDate,
    this.gender,
    this.interestedInGenders = const [],
    this.bio,
    this.bioModerationResult,
    this.jobTitle,
    this.company,
    this.education,
    this.location,
    this.latitude,
    this.longitude,
    this.maxDistance = 50,
    this.minAge = 18,
    this.maxAge = 99,
    this.interests = const [],
    this.languages = const [],
    this.height,
    this.photos = const [],
    this.personalityAnswers = const [],
    this.promptAnswers = const [],
    required this.isComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  // Add missing getters that are expected by components
  String? get firstName => pseudo?.split(' ').first;
  String? get lastName => pseudo!.split(' ').length > 1
      ? pseudo?.split(' ').skip(1).join(' ')
      : null;

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      pseudo: json['pseudo'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      gender: json['gender'] as String?,
      interestedInGenders: (json['interestedInGenders'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bio: json['bio'] as String?,
      bioModerationResult: json['bioModerationResult'] != null
          ? ModerationResult.fromJson(json['bioModerationResult'] as Map<String, dynamic>)
          : null,
      jobTitle: json['jobTitle'] as String?,
      company: json['company'] as String?,
      education: json['education'] as String?,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      maxDistance: json['maxDistance'] as int? ?? 50,
      minAge: json['minAge'] as int? ?? 18,
      maxAge: json['maxAge'] as int? ?? 99,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      height: json['height'] as int?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      personalityAnswers: (json['personalityAnswers'] as List<dynamic>?)
              ?.map(
                  (e) => PersonalityAnswer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      promptAnswers: (json['promptAnswers'] as List<dynamic>?)
              ?.map((e) => PromptAnswer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isComplete: json['isComplete'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'pseudo': pseudo,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'interestedInGenders': interestedInGenders,
      'bio': bio,
      'bioModerationResult': bioModerationResult?.toJson(),
      'jobTitle': jobTitle,
      'company': company,
      'education': education,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'maxDistance': maxDistance,
      'minAge': minAge,
      'maxAge': maxAge,
      'interests': interests,
      'languages': languages,
      'height': height,
      'photos': photos.map((p) => p.toJson()).toList(),
      'personalityAnswers': personalityAnswers.map((a) => a.toJson()).toList(),
      'promptAnswers': promptAnswers.map((a) => a.toJson()).toList(),
      'isComplete': isComplete,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Photo {
  final String id;
  final String url;
  final int order;
  final bool isPrimary;
  final DateTime createdAt;
  final ModerationResult? moderationResult;

  Photo({
    required this.id,
    required this.url,
    required this.order,
    required this.isPrimary,
    required this.createdAt,
    this.moderationResult,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      url: json['url'] as String,
      order: json['order'] as int,
      isPrimary: json['isPrimary'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      moderationResult: json['moderationResult'] != null
          ? ModerationResult.fromJson(json['moderationResult'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'order': order,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
      'moderationResult': moderationResult?.toJson(),
    };
  }
}

class PersonalityAnswer {
  final String id;
  final String questionId;
  final String? textAnswer;
  final int? numericAnswer;
  final bool? booleanAnswer;
  final List<String>? multipleChoiceAnswer;
  final DateTime createdAt;

  PersonalityAnswer({
    required this.id,
    required this.questionId,
    this.textAnswer,
    this.numericAnswer,
    this.booleanAnswer,
    this.multipleChoiceAnswer,
    required this.createdAt,
  });

  factory PersonalityAnswer.fromJson(Map<String, dynamic> json) {
    return PersonalityAnswer(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      textAnswer: json['textAnswer'] as String?,
      numericAnswer: json['numericAnswer'] as int?,
      booleanAnswer: json['booleanAnswer'] as bool?,
      multipleChoiceAnswer: (json['multipleChoiceAnswer'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'textAnswer': textAnswer,
      'numericAnswer': numericAnswer,
      'booleanAnswer': booleanAnswer,
      'multipleChoiceAnswer': multipleChoiceAnswer,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PromptAnswer {
  final String id;
  final String promptId;
  final String answer;
  final int order;
  final DateTime createdAt;

  PromptAnswer({
    required this.id,
    required this.promptId,
    required this.answer,
    required this.order,
    required this.createdAt,
  });

  factory PromptAnswer.fromJson(Map<String, dynamic> json) {
    return PromptAnswer(
      id: json['id'] as String,
      promptId: json['promptId'] as String,
      answer: json['answer'] as String,
      order: json['order'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promptId': promptId,
      'answer': answer,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PersonalityQuestion {
  final String id;
  final String question;
  final String type;
  final List<String>? options;
  final int? minValue;
  final int? maxValue;
  final bool isRequired;
  final int order;
  final bool isActive;
  final String category;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalityQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    this.minValue,
    this.maxValue,
    required this.isRequired,
    required this.order,
    required this.isActive,
    required this.category,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalityQuestion.fromJson(Map<String, dynamic> json) {
    return PersonalityQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      type: json['type'] as String,
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      minValue: json['minValue'] as int?,
      maxValue: json['maxValue'] as int?,
      isRequired: json['isRequired'] as bool? ?? true,
      order: json['order'] as int,
      isActive: json['isActive'] as bool? ?? true,
      category: json['category'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'minValue': minValue,
      'maxValue': maxValue,
      'isRequired': isRequired,
      'order': order,
      'isActive': isActive,
      'category': category,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Prompt {
  final String id;
  final String text;
  final String category;
  final bool active;

  Prompt({
    required this.id,
    required this.text,
    required this.category,
    required this.active,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String,
      active: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'active': active,
    };
  }
}

class ProfileCompletion {
  final bool isCompleted;
  final bool hasPhotos;
  final bool hasPrompts;
  final bool hasPersonalityAnswers;
  final bool hasRequiredProfileFields;
  final List<String> missingSteps;

  ProfileCompletion({
    required this.isCompleted,
    required this.hasPhotos,
    required this.hasPrompts,
    required this.hasPersonalityAnswers,
    required this.hasRequiredProfileFields,
    required this.missingSteps,
  });

  factory ProfileCompletion.fromJson(Map<String, dynamic> json) {
    return ProfileCompletion(
      isCompleted: json['isCompleted'] as bool? ?? false,
      hasPhotos: json['hasPhotos'] as bool? ?? false,
      hasPrompts: json['hasPrompts'] as bool? ?? false,
      hasPersonalityAnswers: json['hasPersonalityAnswers'] as bool? ?? false,
      hasRequiredProfileFields: json['hasRequiredProfileFields'] as bool? ?? false,
      missingSteps: (json['missingSteps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCompleted': isCompleted,
      'hasPhotos': hasPhotos,
      'hasPrompts': hasPrompts,
      'hasPersonalityAnswers': hasPersonalityAnswers,
      'hasRequiredProfileFields': hasRequiredProfileFields,
      'missingSteps': missingSteps,
    };
  }
}
