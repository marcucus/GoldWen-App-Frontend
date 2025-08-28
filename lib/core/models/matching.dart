import 'profile.dart';

class Match {
  final String id;
  final String userId1;
  final String userId2;
  final String status;
  final double compatibilityScore;
  final String? chatId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Profile? otherProfile;

  Match({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.compatibilityScore,
    this.chatId,
    required this.createdAt,
    this.expiresAt,
    this.otherProfile,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      status: json['status'] as String,
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      chatId: json['chatId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      otherProfile: json['otherProfile'] != null
          ? Profile.fromJson(json['otherProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'status': status,
      'compatibilityScore': compatibilityScore,
      'chatId': chatId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'otherProfile': otherProfile?.toJson(),
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

class DailySelection {
  final List<Profile> profiles;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final int remainingLikes;
  final bool hasUsedSuperLike;

  DailySelection({
    required this.profiles,
    required this.generatedAt,
    required this.expiresAt,
    required this.remainingLikes,
    required this.hasUsedSuperLike,
  });

  factory DailySelection.fromJson(Map<String, dynamic> json) {
    return DailySelection(
      profiles: (json['profiles'] as List<dynamic>)
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      remainingLikes: json['remainingLikes'] as int,
      hasUsedSuperLike: json['hasUsedSuperLike'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'remainingLikes': remainingLikes,
      'hasUsedSuperLike': hasUsedSuperLike,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CompatibilityResult {
  final double score;
  final Map<String, double> categoryScores;
  final List<String> commonInterests;
  final List<String> personalityMatches;
  final String explanation;

  CompatibilityResult({
    required this.score,
    required this.categoryScores,
    required this.commonInterests,
    required this.personalityMatches,
    required this.explanation,
  });

  factory CompatibilityResult.fromJson(Map<String, dynamic> json) {
    return CompatibilityResult(
      score: (json['score'] as num).toDouble(),
      categoryScores: Map<String, double>.from(
        (json['categoryScores'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      commonInterests: (json['commonInterests'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      personalityMatches: (json['personalityMatches'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'categoryScores': categoryScores,
      'commonInterests': commonInterests,
      'personalityMatches': personalityMatches,
      'explanation': explanation,
    };
  }
}