class AdminReport {
  final String id;
  final String reportedUserId;
  final String? reporterUserId;
  final String reportType;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolution;
  final Map<String, dynamic>? metadata;

  AdminReport({
    required this.id,
    required this.reportedUserId,
    this.reporterUserId,
    required this.reportType,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolution,
    this.metadata,
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    return AdminReport(
      id: json['id'] ?? '',
      reportedUserId: json['reportedUserId'] ?? '',
      reporterUserId: json['reporterUserId'],
      reportType: json['reportType'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolution: json['resolution'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportedUserId': reportedUserId,
      'reporterUserId': reporterUserId,
      'reportType': reportType,
      'reason': reason,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolution': resolution,
      'metadata': metadata,
    };
  }

  bool get isPending => status == 'pending';
  bool get isResolved => status == 'resolved';
  bool get isInProgress => status == 'in_progress';
}