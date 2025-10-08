/// Moderation status for content (messages, photos, bio)
enum ModerationStatus {
  approved,
  pending,
  blocked,
}

/// Moderation flag category
class ModerationFlag {
  final String name;
  final double confidence;
  final String? parentName;

  ModerationFlag({
    required this.name,
    required this.confidence,
    this.parentName,
  });

  factory ModerationFlag.fromJson(Map<String, dynamic> json) {
    return ModerationFlag(
      name: json['name'] as String? ?? json['Name'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 
                  (json['Confidence'] as num?)?.toDouble() ?? 
                  0.0,
      parentName: json['parentName'] as String? ?? json['ParentName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
      if (parentName != null) 'parentName': parentName,
    };
  }
}

/// Moderation result for a specific resource
class ModerationResult {
  final ModerationStatus status;
  final List<ModerationFlag> flags;
  final DateTime? moderatedAt;
  final String? moderator; // 'ai' or admin ID

  ModerationResult({
    required this.status,
    this.flags = const [],
    this.moderatedAt,
    this.moderator,
  });

  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    return ModerationResult(
      status: _parseModerationStatus(json['status'] as String),
      flags: (json['flags'] as List<dynamic>?)
              ?.map((e) => e is String 
                  ? ModerationFlag(name: e, confidence: 100.0)
                  : ModerationFlag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      moderatedAt: json['moderatedAt'] != null
          ? DateTime.parse(json['moderatedAt'] as String)
          : null,
      moderator: json['moderator'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': _moderationStatusToString(status),
      'flags': flags.map((f) => f.toJson()).toList(),
      if (moderatedAt != null) 'moderatedAt': moderatedAt!.toIso8601String(),
      if (moderator != null) 'moderator': moderator,
    };
  }

  static ModerationStatus _parseModerationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return ModerationStatus.approved;
      case 'pending':
        return ModerationStatus.pending;
      case 'blocked':
        return ModerationStatus.blocked;
      default:
        return ModerationStatus.pending;
    }
  }

  static String _moderationStatusToString(ModerationStatus status) {
    switch (status) {
      case ModerationStatus.approved:
        return 'approved';
      case ModerationStatus.pending:
        return 'pending';
      case ModerationStatus.blocked:
        return 'blocked';
    }
  }

  bool get isBlocked => status == ModerationStatus.blocked;
  bool get isPending => status == ModerationStatus.pending;
  bool get isApproved => status == ModerationStatus.approved;
  bool get hasFlags => flags.isNotEmpty;
}

/// Moderation history item
class ModerationHistoryItem {
  final String id;
  final String resourceType; // 'message', 'photo', 'bio'
  final String resourceId;
  final ModerationResult result;
  final DateTime createdAt;

  ModerationHistoryItem({
    required this.id,
    required this.resourceType,
    required this.resourceId,
    required this.result,
    required this.createdAt,
  });

  factory ModerationHistoryItem.fromJson(Map<String, dynamic> json) {
    return ModerationHistoryItem(
      id: json['id'] as String,
      resourceType: json['resourceType'] as String,
      resourceId: json['resourceId'] as String,
      result: ModerationResult.fromJson(json['result'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'result': result.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
