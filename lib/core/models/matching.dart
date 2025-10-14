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
  final bool hasUnreadMessages;

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
    this.hasUnreadMessages = false,
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
      hasUnreadMessages: json['hasUnreadMessages'] as bool? ?? false,
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
      'hasUnreadMessages': hasUnreadMessages,
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
  final int choicesRemaining;
  final int choicesMade;
  final int maxChoices;
  final DateTime? refreshTime;

  DailySelection({
    required this.profiles,
    required this.generatedAt,
    required this.expiresAt,
    required this.remainingLikes,
    required this.hasUsedSuperLike,
    required this.choicesRemaining,
    required this.choicesMade,
    required this.maxChoices,
    this.refreshTime,
  });

  factory DailySelection.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>?;
    final profiles = json['profiles'] as List<dynamic>? ?? [];
    
    // Handle case where backend sends selection data directly without metadata wrapper  
    final choicesRemaining = metadata?['choicesRemaining'] as int? ?? 
                            json['choicesRemaining'] as int? ?? 1;
    final choicesMade = metadata?['choicesMade'] as int? ?? 
                       json['choicesMade'] as int? ?? 0;
    final maxChoices = metadata?['maxChoices'] as int? ?? 
                      json['maxChoices'] as int? ?? 1;
    
    return DailySelection(
      profiles: profiles
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String? ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expiresAt'] as String? ?? DateTime.now().add(Duration(hours: 24)).toIso8601String()),
      remainingLikes: json['remainingLikes'] as int? ?? 0,
      hasUsedSuperLike: json['hasUsedSuperLike'] as bool? ?? false,
      choicesRemaining: choicesRemaining,
      choicesMade: choicesMade,
      maxChoices: maxChoices,
      refreshTime: (metadata?['refreshTime'] ?? json['refreshTime']) != null 
          ? DateTime.parse((metadata?['refreshTime'] ?? json['refreshTime']) as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'remainingLikes': remainingLikes,
      'hasUsedSuperLike': hasUsedSuperLike,
      'metadata': {
        'choicesRemaining': choicesRemaining,
        'choicesMade': choicesMade,
        'maxChoices': maxChoices,
        'refreshTime': refreshTime?.toIso8601String(),
      },
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canSelectMore => choicesRemaining > 0;
  bool get isSelectionComplete => choicesMade >= maxChoices;
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

class WhoLikedMeItem {
  final String userId;
  final Profile user;
  final DateTime likedAt;

  WhoLikedMeItem({
    required this.userId,
    required this.user,
    required this.likedAt,
  });

  factory WhoLikedMeItem.fromJson(Map<String, dynamic> json) {
    return WhoLikedMeItem(
      userId: json['userId'] as String,
      user: Profile.fromJson(json['user'] as Map<String, dynamic>),
      likedAt: DateTime.parse(json['likedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'user': user.toJson(),
      'likedAt': likedAt.toIso8601String(),
    };
  }
}

class ScoreBreakdown {
  final double personalityScore;
  final double preferencesScore;
  final double activityBonus;
  final double responseRateBonus;
  final double reciprocityBonus;

  ScoreBreakdown({
    required this.personalityScore,
    required this.preferencesScore,
    required this.activityBonus,
    required this.responseRateBonus,
    required this.reciprocityBonus,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      personalityScore: (json['personalityScore'] as num).toDouble(),
      preferencesScore: (json['preferencesScore'] as num).toDouble(),
      activityBonus: (json['activityBonus'] as num).toDouble(),
      responseRateBonus: (json['responseRateBonus'] as num).toDouble(),
      reciprocityBonus: (json['reciprocityBonus'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personalityScore': personalityScore,
      'preferencesScore': preferencesScore,
      'activityBonus': activityBonus,
      'responseRateBonus': responseRateBonus,
      'reciprocityBonus': reciprocityBonus,
    };
  }

  double get baseScore => personalityScore + preferencesScore;
  double get totalBonuses => activityBonus + responseRateBonus + reciprocityBonus;
}

class MatchReason {
  final String category;
  final String description;
  final double impact;

  MatchReason({
    required this.category,
    required this.description,
    required this.impact,
  });

  factory MatchReason.fromJson(Map<String, dynamic> json) {
    return MatchReason(
      category: json['category'] as String,
      description: json['description'] as String,
      impact: (json['impact'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'impact': impact,
    };
  }
}

class CompatibilityScoreV2 {
  final String userId;
  final double score;
  final ScoreBreakdown breakdown;
  final List<MatchReason> matchReasons;

  CompatibilityScoreV2({
    required this.userId,
    required this.score,
    required this.breakdown,
    required this.matchReasons,
  });

  factory CompatibilityScoreV2.fromJson(Map<String, dynamic> json) {
    return CompatibilityScoreV2(
      userId: json['userId'] as String,
      score: (json['score'] as num).toDouble(),
      breakdown: ScoreBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
      matchReasons: (json['matchReasons'] as List<dynamic>?)
          ?.map((e) => MatchReason.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'score': score,
      'breakdown': breakdown.toJson(),
      'matchReasons': matchReasons.map((r) => r.toJson()).toList(),
    };
  }
}