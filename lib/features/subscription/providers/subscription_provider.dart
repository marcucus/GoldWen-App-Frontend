import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/models.dart';

class SubscriptionProvider with ChangeNotifier {
  List<SubscriptionPlan> _plans = [];
  Subscription? _currentSubscription;
  SubscriptionUsage? _usage;
  bool _isLoading = false;
  String? _error;

  List<SubscriptionPlan> get plans => _plans;
  Subscription? get currentSubscription => _currentSubscription;
  SubscriptionUsage? get usage => _usage;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasActiveSubscription => _currentSubscription?.isActive ?? false;
  bool get hasExpiredSubscription => _currentSubscription?.isExpired ?? false;
  bool get willRenew => _currentSubscription?.willRenew ?? false;

  String? get currentPlanName => _currentSubscription?.plan?.name;
  DateTime? get nextRenewalDate => _currentSubscription?.currentPeriodEnd;
  int? get daysUntilExpiry => _currentSubscription?.daysUntilExpiry;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadSubscriptionPlans() async {
    _setLoading();

    try {
      final response = await ApiService.getSubscriptionPlans();
      final plansData = response['data'] ?? response['plans'] ?? [];
      
      _plans = (plansData as List)
          .map((p) => SubscriptionPlan.fromJson(p as Map<String, dynamic>))
          .toList();
      
      _error = null;
    } catch (e) {
      _handleError(e, 'Failed to load subscription plans');
    } finally {
      _setLoaded();
    }
  }

  Future<void> loadCurrentSubscription() async {
    try {
      final response = await ApiService.getCurrentSubscription();
      final subscriptionData = response['data'] ?? response;
      
      if (subscriptionData != null) {
        _currentSubscription = Subscription.fromJson(subscriptionData);
      } else {
        _currentSubscription = null;
      }
      
      _error = null;
      notifyListeners();
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        // No subscription found is OK
        _currentSubscription = null;
        notifyListeners();
      } else {
        _handleError(e, 'Failed to load current subscription');
      }
    }
  }

  Future<void> loadSubscriptionUsage() async {
    try {
      final response = await ApiService.getSubscriptionUsage();
      final usageData = response['data'] ?? response;
      
      _usage = SubscriptionUsage.fromJson(usageData);
      _error = null;
      notifyListeners();
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        // No subscription usage found is OK for free users
        _usage = null;
        notifyListeners();
      } else {
        _handleError(e, 'Failed to load subscription usage');
      }
    }
  }

  Future<bool> purchaseSubscription({
    required String planId,
    required String platform,
    required String receiptData,
  }) async {
    _setLoading();

    try {
      final response = await ApiService.purchaseSubscription(
        plan: planId,
        platform: platform,
        receiptData: receiptData,
      );
      
      final subscriptionData = response['data'] ?? response;
      _currentSubscription = Subscription.fromJson(subscriptionData);
      
      // Reload usage data
      await loadSubscriptionUsage();
      
      _error = null;
      _setLoaded();
      return true;
    } catch (e) {
      _handleError(e, 'Failed to purchase subscription');
      return false;
    }
  }

  Future<bool> verifyReceipt({
    required String receiptData,
    required String platform,
  }) async {
    try {
      final response = await ApiService.verifyReceipt(
        receiptData: receiptData,
        platform: platform,
      );
      
      final subscriptionData = response['data'] ?? response;
      if (subscriptionData != null) {
        _currentSubscription = Subscription.fromJson(subscriptionData);
        await loadSubscriptionUsage();
      }
      
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e, 'Failed to verify receipt');
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    _setLoading();

    try {
      await ApiService.cancelSubscription();
      
      // Reload current subscription to get updated status
      await loadCurrentSubscription();
      
      _error = null;
      _setLoaded();
      return true;
    } catch (e) {
      _handleError(e, 'Failed to cancel subscription');
      return false;
    }
  }

  Future<bool> restoreSubscription() async {
    _setLoading();

    try {
      final response = await ApiService.restoreSubscription();
      
      final subscriptionData = response['data'] ?? response;
      if (subscriptionData != null) {
        _currentSubscription = Subscription.fromJson(subscriptionData);
        await loadSubscriptionUsage();
      }
      
      _error = null;
      _setLoaded();
      return true;
    } catch (e) {
      _handleError(e, 'Failed to restore subscription');
      return false;
    }
  }

  // Convenience methods for checking features
  bool get canSeeWhoLikedYou => _usage?.canSeeWhoLikedYou ?? false;
  bool get canUseAdvancedFilters => _usage?.canUseAdvancedFilters ?? false;
  bool get hasUnlimitedRewinds => _usage?.hasUnlimitedRewinds ?? false;

  int get dailyLikesRemaining => _usage?.remainingLikes ?? 0;
  int get superLikesRemaining => _usage?.remainingSuperLikes ?? 0;
  int get boostsRemaining => _usage?.remainingBoosts ?? 0;

  bool get hasRemainingLikes => _usage?.hasRemainingLikes ?? false;
  bool get hasRemainingSuperLikes => _usage?.hasRemainingSuperLikes ?? false;
  bool get hasRemainingBoosts => _usage?.hasRemainingBoosts ?? false;

  SubscriptionPlan? getPlanById(String planId) {
    try {
      return _plans.firstWhere((plan) => plan.id == planId);
    } catch (e) {
      return null;
    }
  }

  List<SubscriptionPlan> get activePlans {
    return _plans.where((plan) => plan.active).toList();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadSubscriptionPlans(),
      loadCurrentSubscription(),
      loadSubscriptionUsage(),
    ]);
  }

  // Utility methods
  void _setLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _setLoaded() {
    _isLoading = false;
    notifyListeners();
  }

  void _handleError(dynamic error, String fallbackMessage) {
    _isLoading = false;
    
    if (error is ApiException) {
      _error = error.message;
    } else {
      _error = fallbackMessage;
    }
    
    notifyListeners();
  }
}