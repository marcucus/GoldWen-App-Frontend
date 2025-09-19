class AdminAnalytics {
  final int activeUsers;
  final int newRegistrations;
  final int dailyMatches;
  final int messagesSent;
  final double subscriptionRate;
  final int totalUsers;
  final int pendingReports;
  final int resolvedReports;
  final Map<String, dynamic>? additionalStats;

  AdminAnalytics({
    required this.activeUsers,
    required this.newRegistrations,
    required this.dailyMatches,
    required this.messagesSent,
    required this.subscriptionRate,
    required this.totalUsers,
    required this.pendingReports,
    required this.resolvedReports,
    this.additionalStats,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      activeUsers: json['activeUsers'] ?? 0,
      newRegistrations: json['newRegistrations'] ?? 0,
      dailyMatches: json['dailyMatches'] ?? 0,
      messagesSent: json['messagesSent'] ?? 0,
      subscriptionRate: (json['subscriptionRate'] ?? 0.0).toDouble(),
      totalUsers: json['totalUsers'] ?? 0,
      pendingReports: json['pendingReports'] ?? 0,
      resolvedReports: json['resolvedReports'] ?? 0,
      additionalStats: json['additionalStats'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeUsers': activeUsers,
      'newRegistrations': newRegistrations,
      'dailyMatches': dailyMatches,
      'messagesSent': messagesSent,
      'subscriptionRate': subscriptionRate,
      'totalUsers': totalUsers,
      'pendingReports': pendingReports,
      'resolvedReports': resolvedReports,
      'additionalStats': additionalStats,
    };
  }
}