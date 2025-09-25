class GdprConsent {
  final bool dataProcessing;
  final bool? marketing;
  final bool? analytics;
  final DateTime consentedAt;
  final String? consentVersion;

  GdprConsent({
    required this.dataProcessing,
    this.marketing,
    this.analytics,
    required this.consentedAt,
    this.consentVersion,
  });

  factory GdprConsent.fromJson(Map<String, dynamic> json) {
    return GdprConsent(
      dataProcessing: json['dataProcessing'] as bool? ?? false,
      marketing: json['marketing'] as bool?,
      analytics: json['analytics'] as bool?,
      consentedAt: json['consentedAt'] != null 
          ? DateTime.parse(json['consentedAt'] as String)
          : DateTime.now(),
      consentVersion: json['consentVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataProcessing': dataProcessing,
      if (marketing != null) 'marketing': marketing,
      if (analytics != null) 'analytics': analytics,
      'consentedAt': consentedAt.toIso8601String(),
      if (consentVersion != null) 'consentVersion': consentVersion,
    };
  }

  GdprConsent copyWith({
    bool? dataProcessing,
    bool? marketing,
    bool? analytics,
    DateTime? consentedAt,
    String? consentVersion,
  }) {
    return GdprConsent(
      dataProcessing: dataProcessing ?? this.dataProcessing,
      marketing: marketing ?? this.marketing,
      analytics: analytics ?? this.analytics,
      consentedAt: consentedAt ?? this.consentedAt,
      consentVersion: consentVersion ?? this.consentVersion,
    );
  }
}

class PrivacySettings {
  final bool analytics;
  final bool marketing;
  final bool functionalCookies;
  final int? dataRetention;

  PrivacySettings({
    required this.analytics,
    required this.marketing,
    required this.functionalCookies,
    this.dataRetention,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      analytics: json['analytics'] as bool? ?? true,
      marketing: json['marketing'] as bool? ?? false,
      functionalCookies: json['functionalCookies'] as bool? ?? true,
      dataRetention: json['dataRetention'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analytics': analytics,
      'marketing': marketing,
      'functionalCookies': functionalCookies,
      if (dataRetention != null) 'dataRetention': dataRetention,
    };
  }

  PrivacySettings copyWith({
    bool? analytics,
    bool? marketing,
    bool? functionalCookies,
    int? dataRetention,
  }) {
    return PrivacySettings(
      analytics: analytics ?? this.analytics,
      marketing: marketing ?? this.marketing,
      functionalCookies: functionalCookies ?? this.functionalCookies,
      dataRetention: dataRetention ?? this.dataRetention,
    );
  }
}

class PrivacyPolicy {
  final String content;
  final String version;
  final DateTime lastUpdated;

  PrivacyPolicy({
    required this.content,
    required this.version,
    required this.lastUpdated,
  });

  factory PrivacyPolicy.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicy(
      content: json['content'] as String? ?? '',
      version: json['version'] as String? ?? '1.0',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'version': version,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}