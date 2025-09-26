enum FeedbackType {
  bug,
  feature,
  general
}

class FeedbackMetadata {
  final String? page;
  final String? userAgent;
  final String? appVersion;

  FeedbackMetadata({
    this.page,
    this.userAgent,
    this.appVersion,
  });

  factory FeedbackMetadata.fromJson(Map<String, dynamic> json) {
    return FeedbackMetadata(
      page: json['page'] as String?,
      userAgent: json['userAgent'] as String?,
      appVersion: json['appVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (page != null) 'page': page,
      if (userAgent != null) 'userAgent': userAgent,
      if (appVersion != null) 'appVersion': appVersion,
    };
  }
}

class Feedback {
  final String? id;
  final FeedbackType type;
  final String subject;
  final String message;
  final int? rating; // 1-5 stars, optional
  final FeedbackMetadata? metadata;
  final DateTime? createdAt;

  Feedback({
    this.id,
    required this.type,
    required this.subject,
    required this.message,
    this.rating,
    this.metadata,
    this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] as String?,
      type: _parseFeedbackType(json['type'] as String),
      subject: json['subject'] as String,
      message: json['message'] as String,
      rating: json['rating'] as int?,
      metadata: json['metadata'] != null 
          ? FeedbackMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': _feedbackTypeToString(type),
      'subject': subject,
      'message': message,
      if (rating != null) 'rating': rating,
      if (metadata != null) 'metadata': metadata!.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  static FeedbackType _parseFeedbackType(String type) {
    switch (type.toLowerCase()) {
      case 'bug':
        return FeedbackType.bug;
      case 'feature':
        return FeedbackType.feature;
      case 'general':
        return FeedbackType.general;
      default:
        return FeedbackType.general;
    }
  }

  static String _feedbackTypeToString(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'bug';
      case FeedbackType.feature:
        return 'feature';
      case FeedbackType.general:
        return 'general';
    }
  }

  // Helper method to get display text for feedback type
  String get typeDisplayText {
    switch (type) {
      case FeedbackType.bug:
        return 'Signaler un bug';
      case FeedbackType.feature:
        return 'Suggérer une fonctionnalité';
      case FeedbackType.general:
        return 'Commentaire général';
    }
  }

  // Helper method to get icon for feedback type
  String get typeIcon {
    switch (type) {
      case FeedbackType.bug:
        return '🐛';
      case FeedbackType.feature:
        return '💡';
      case FeedbackType.general:
        return '💬';
    }
  }
}