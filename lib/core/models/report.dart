enum ReportType {
  inappropriateContent,
  harassment,
  fakeProfile,
  spam,
  other
}

enum ReportStatus {
  pending,
  reviewed,
  resolved,
  dismissed
}

class Report {
  final String id;
  final String targetUserId;
  final ReportType type;
  final String reason;
  final String? messageId;
  final String? chatId;
  final List<String>? evidence;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Report({
    required this.id,
    required this.targetUserId,
    required this.type,
    required this.reason,
    this.messageId,
    this.chatId,
    this.evidence,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      targetUserId: json['targetUserId'] as String,
      type: _parseReportType(json['type'] as String),
      reason: json['reason'] as String,
      messageId: json['messageId'] as String?,
      chatId: json['chatId'] as String?,
      evidence: (json['evidence'] as List<dynamic>?)?.cast<String>(),
      status: _parseReportStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetUserId': targetUserId,
      'type': _reportTypeToString(type),
      'reason': reason,
      'messageId': messageId,
      'chatId': chatId,
      'evidence': evidence,
      'status': _reportStatusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static ReportType _parseReportType(String type) {
    switch (type.toLowerCase()) {
      case 'inappropriate_content':
        return ReportType.inappropriateContent;
      case 'harassment':
        return ReportType.harassment;
      case 'fake_profile':
        return ReportType.fakeProfile;
      case 'spam':
        return ReportType.spam;
      case 'other':
        return ReportType.other;
      default:
        return ReportType.other;
    }
  }

  static ReportStatus _parseReportStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ReportStatus.pending;
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }

  static String _reportTypeToString(ReportType type) {
    switch (type) {
      case ReportType.inappropriateContent:
        return 'inappropriate_content';
      case ReportType.harassment:
        return 'harassment';
      case ReportType.fakeProfile:
        return 'fake_profile';
      case ReportType.spam:
        return 'spam';
      case ReportType.other:
        return 'other';
    }
  }

  static String _reportStatusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewed:
        return 'reviewed';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.dismissed:
        return 'dismissed';
    }
  }
}

class HistoryItem {
  final String date;
  final List<HistoryChoice> choices;

  HistoryItem({
    required this.date,
    required this.choices,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      date: json['date'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map((e) => HistoryChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }
}

class HistoryChoice {
  final String targetUserId;
  final dynamic targetUser; // Can be Profile object or just data
  final String choice; // 'like' or 'pass'
  final DateTime chosenAt;
  final bool isMatch;

  HistoryChoice({
    required this.targetUserId,
    required this.targetUser,
    required this.choice,
    required this.chosenAt,
    required this.isMatch,
  });

  factory HistoryChoice.fromJson(Map<String, dynamic> json) {
    return HistoryChoice(
      targetUserId: json['targetUserId'] as String,
      targetUser: json['targetUser'], // Keep as dynamic for now
      choice: json['choice'] as String,
      chosenAt: DateTime.parse(json['chosenAt'] as String),
      isMatch: json['isMatch'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetUserId': targetUserId,
      'targetUser': targetUser,
      'choice': choice,
      'chosenAt': chosenAt.toIso8601String(),
      'isMatch': isMatch,
    };
  }
}

class PaginatedHistory {
  final List<HistoryItem> data;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  PaginatedHistory({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory PaginatedHistory.fromJson(Map<String, dynamic> json) {
    return PaginatedHistory(
      data: (json['data'] as List<dynamic>)
          .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['pagination']['page'] as int,
      limit: json['pagination']['limit'] as int,
      total: json['pagination']['total'] as int,
      hasMore: json['pagination']['hasMore'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((h) => h.toJson()).toList(),
      'pagination': {
        'page': page,
        'limit': limit,
        'total': total,
        'hasMore': hasMore,
      },
    };
  }
}