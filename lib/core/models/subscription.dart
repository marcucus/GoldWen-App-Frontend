class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String interval;
  final int intervalCount;
  final List<String> features;
  final Map<String, dynamic> metadata;
  final bool active;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.interval,
    required this.intervalCount,
    required this.features,
    required this.metadata,
    required this.active,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      interval: json['interval'] as String,
      intervalCount: json['intervalCount'] as int,
      features: (json['features'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval,
      'intervalCount': intervalCount,
      'features': features,
      'metadata': metadata,
      'active': active,
    };
  }

  String get priceText {
    final formattedPrice = price.toStringAsFixed(2);
    return '$formattedPrice $currency';
  }

  String get intervalText {
    if (intervalCount == 1) {
      return interval;
    }
    return '$intervalCount ${interval}s';
  }
}

class Subscription {
  final String id;
  final String userId;
  final String planId;
  final String status;
  final String platform;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? canceledAt;
  final DateTime? endedAt;
  final bool autoRenew;
  final String? originalTransactionId;
  final SubscriptionPlan? plan;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.platform,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.canceledAt,
    this.endedAt,
    required this.autoRenew,
    this.originalTransactionId,
    this.plan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planId: json['planId'] as String,
      status: json['status'] as String,
      platform: json['platform'] as String,
      currentPeriodStart: DateTime.parse(json['currentPeriodStart'] as String),
      currentPeriodEnd: DateTime.parse(json['currentPeriodEnd'] as String),
      canceledAt: json['canceledAt'] != null
          ? DateTime.parse(json['canceledAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      autoRenew: json['autoRenew'] as bool? ?? true,
      originalTransactionId: json['originalTransactionId'] as String?,
      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'status': status,
      'platform': platform,
      'currentPeriodStart': currentPeriodStart.toIso8601String(),
      'currentPeriodEnd': currentPeriodEnd.toIso8601String(),
      'canceledAt': canceledAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'autoRenew': autoRenew,
      'originalTransactionId': originalTransactionId,
      'plan': plan?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isCanceled => status == 'canceled';
  bool get isExpired => DateTime.now().isAfter(currentPeriodEnd);
  bool get willRenew => isActive && autoRenew && !isCanceled;

  int get daysUntilExpiry {
    final now = DateTime.now();
    if (now.isAfter(currentPeriodEnd)) return 0;
    return currentPeriodEnd.difference(now).inDays;
  }
}

class SubscriptionUsage {
  final int dailyLikesUsed;
  final int dailyLikesLimit;
  final int dailyChoicesUsed;
  final int dailyChoicesLimit;
  final int superLikesUsed;
  final int superLikesLimit;
  final int boostsUsed;
  final int boostsLimit;
  final bool canSeeWhoLikedYou;
  final bool canUseAdvancedFilters;
  final bool hasUnlimitedRewinds;
  final DateTime resetDate;

  SubscriptionUsage({
    required this.dailyLikesUsed,
    required this.dailyLikesLimit,
    required this.dailyChoicesUsed,
    required this.dailyChoicesLimit,
    required this.superLikesUsed,
    required this.superLikesLimit,
    required this.boostsUsed,
    required this.boostsLimit,
    required this.canSeeWhoLikedYou,
    required this.canUseAdvancedFilters,
    required this.hasUnlimitedRewinds,
    required this.resetDate,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) {
    final dailyChoices = json['dailyChoices'] as Map<String, dynamic>?;
    
    return SubscriptionUsage(
      dailyLikesUsed: json['dailyLikesUsed'] as int? ?? 0,
      dailyLikesLimit: json['dailyLikesLimit'] as int? ?? 5,
      dailyChoicesUsed: dailyChoices?['used'] as int? ?? 0,
      dailyChoicesLimit: dailyChoices?['limit'] as int? ?? 1,
      superLikesUsed: json['superLikesUsed'] as int? ?? 0,
      superLikesLimit: json['superLikesLimit'] as int? ?? 1,
      boostsUsed: json['boostsUsed'] as int? ?? 0,
      boostsLimit: json['boostsLimit'] as int? ?? 0,
      canSeeWhoLikedYou: json['canSeeWhoLikedYou'] as bool? ?? false,
      canUseAdvancedFilters: json['canUseAdvancedFilters'] as bool? ?? false,
      hasUnlimitedRewinds: json['hasUnlimitedRewinds'] as bool? ?? false,
      resetDate: DateTime.parse(json['resetDate'] as String? ?? dailyChoices?['resetTime'] as String? ?? DateTime.now().add(Duration(days: 1)).toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyLikesUsed': dailyLikesUsed,
      'dailyLikesLimit': dailyLikesLimit,
      'dailyChoicesUsed': dailyChoicesUsed,
      'dailyChoicesLimit': dailyChoicesLimit,
      'superLikesUsed': superLikesUsed,
      'superLikesLimit': superLikesLimit,
      'boostsUsed': boostsUsed,
      'boostsLimit': boostsLimit,
      'canSeeWhoLikedYou': canSeeWhoLikedYou,
      'canUseAdvancedFilters': canUseAdvancedFilters,
      'hasUnlimitedRewinds': hasUnlimitedRewinds,
      'resetDate': resetDate.toIso8601String(),
    };
  }

  bool get hasRemainingLikes => dailyLikesUsed < dailyLikesLimit;
  bool get hasRemainingChoices => dailyChoicesUsed < dailyChoicesLimit;
  bool get hasRemainingSuperLikes => superLikesUsed < superLikesLimit;
  bool get hasRemainingBoosts => boostsUsed < boostsLimit;

  int get remainingLikes => (dailyLikesLimit - dailyLikesUsed).clamp(0, dailyLikesLimit);
  int get remainingChoices => (dailyChoicesLimit - dailyChoicesUsed).clamp(0, dailyChoicesLimit);
  int get remainingSuperLikes => (superLikesLimit - superLikesUsed).clamp(0, superLikesLimit);
  int get remainingBoosts => (boostsLimit - boostsUsed).clamp(0, boostsLimit);
}