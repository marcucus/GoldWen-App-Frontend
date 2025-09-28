import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/revenue_cat_service.dart';
import '../../../core/models/models.dart';

class SubscriptionProvider with ChangeNotifier {
  List<SubscriptionPlan> _plans = [];
  List<Package> _revenueCatPackages = [];
  Subscription? _currentSubscription;
  SubscriptionUsage? _usage;
  CustomerInfo? _customerInfo;
  bool _isLoading = false;
  String? _error;

  List<SubscriptionPlan> get plans => _plans;
  List<SubscriptionPlan> get activePlans =>
      _plans.where((plan) => plan.active).toList();
  List<Package> get revenueCatPackages => _revenueCatPackages;
  Subscription? get currentSubscription => _currentSubscription;
  SubscriptionUsage? get usage => _usage;
  CustomerInfo? get customerInfo => _customerInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasActiveSubscription =>
      _customerInfo != null &&
      RevenueCatService.hasActiveSubscription(_customerInfo!);
  bool get hasExpiredSubscription => _currentSubscription?.isExpired ?? false;
  bool get willRenew =>
      _customerInfo != null && RevenueCatService.willRenew(_customerInfo!);

  String? get currentPlanName => _customerInfo != null
      ? RevenueCatService.getProductIdentifier(_customerInfo!)
      : null;
  DateTime? get nextRenewalDate => _customerInfo != null
      ? RevenueCatService.getExpirationDate(_customerInfo!)
      : null;
  int? get daysUntilExpiry {
    final expiryDate = nextRenewalDate;
    if (expiryDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;
    return expiryDate.difference(now).inDays;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> initializeWithUser(String userId) async {
    try {
      await RevenueCatService.initialize();
      await RevenueCatService.setUserId(userId);
      _customerInfo = await RevenueCatService.getCurrentCustomerInfo();
      notifyListeners();
    } catch (e) {
      print('Error initializing RevenueCat with user: $e');
    }
  }

  Future<void> logout() async {
    try {
      await RevenueCatService.logOut();
      _customerInfo = null;
      _currentSubscription = null;
      _usage = null;
      notifyListeners();
    } catch (e) {
      print('Error logging out of RevenueCat: $e');
    }
  }

  Future<void> loadSubscriptionPlans() async {
    _setLoading();

    try {
      // Initialize RevenueCat if not already initialized
      await RevenueCatService.initialize();

      // Load packages from RevenueCat
      _revenueCatPackages = await RevenueCatService.getAvailablePackages();

      // Convert packages to subscription plans
      _plans = _revenueCatPackages
          .map(
              (package) => RevenueCatService.packageToSubscriptionPlan(package))
          .toList();

      // Also try to load plans from API as fallback
      try {
        final response = await ApiService.getSubscriptionPlans();
        final plansData = response['data'] ?? response['plans'] ?? [];

        final apiPlans = (plansData as List)
            .map((p) => SubscriptionPlan.fromJson(p as Map<String, dynamic>))
            .toList();

        // Merge or prioritize RevenueCat plans
        if (_plans.isEmpty && apiPlans.isNotEmpty) {
          _plans = apiPlans;
        }
      } catch (apiError) {
        print('API plans loading failed, using RevenueCat only: $apiError');
      }

      // If both fail, create mock plans for development
      if (_plans.isEmpty) {
        _createMockPlans();
      }

      _error = null;
    } catch (e) {
      // If all loading methods fail, provide mock data
      if (e.toString().contains('NetworkException') ||
          e.toString().contains('ECONNREFUSED') ||
          e.toString().contains('Failed to connect')) {
        _createMockPlans();
        _error = null;
      } else {
        _handleError(e, 'Failed to load subscription plans');
      }
    } finally {
      _setLoaded();
    }
  }

  void _createMockPlans() {
    _plans = [
      SubscriptionPlan(
        id: 'goldwen_monthly',
        name: 'Mensuel',
        description: 'Abonnement mensuel GoldWen Plus',
        price: 19.99,
        currency: '€',
        interval: 'month',
        intervalCount: 1,
        features: [
          '3 sélections par jour',
          'Chat illimité',
          'Voir qui vous a sélectionné',
          'Profil prioritaire',
        ],
        metadata: {'popular': false},
        active: true,
      ),
      SubscriptionPlan(
        id: 'goldwen_quarterly',
        name: 'Trimestriel',
        description: 'Abonnement trimestriel GoldWen Plus',
        price: 49.99,
        currency: '€',
        interval: 'month',
        intervalCount: 3,
        features: [
          '3 sélections par jour',
          'Chat illimité',
          'Voir qui vous a sélectionné',
          'Profil prioritaire',
          '🔥 Plan le plus populaire',
        ],
        metadata: {'popular': true},
        active: true,
      ),
      SubscriptionPlan(
        id: 'goldwen_yearly',
        name: 'Annuel',
        description: 'Abonnement annuel GoldWen Plus',
        price: 149.99,
        currency: '€',
        interval: 'year',
        intervalCount: 1,
        features: [
          '3 sélections par jour',
          'Chat illimité',
          'Voir qui vous a sélectionné',
          'Profil prioritaire',
          'Meilleure valeur',
        ],
        metadata: {'popular': false},
        active: true,
      ),
    ];
  }

  Future<void> loadCurrentSubscription() async {
    try {
      // Load from RevenueCat
      _customerInfo = await RevenueCatService.getCurrentCustomerInfo();

      // Load from API
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
      // Find the corresponding RevenueCat package
      final package = _revenueCatPackages
          .where((p) => p.storeProduct.identifier == planId)
          .firstOrNull;

      if (package != null) {
        // Use RevenueCat for purchase
        _customerInfo = await RevenueCatService.purchasePackage(package);

        if (_customerInfo != null &&
            RevenueCatService.hasActiveSubscription(_customerInfo!)) {
          // Verify with backend
          final verified =
              await RevenueCatService.verifySubscriptionWithBackend(
                  _customerInfo!);

          if (verified) {
            // Reload data
            await loadCurrentSubscription();
            await loadSubscriptionUsage();

            _error = null;
            _setLoaded();
            return true;
          }
        }
      }

      // Fallback to API purchase
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
      // Use RevenueCat to restore purchases
      _customerInfo = await RevenueCatService.restorePurchases();

      if (_customerInfo != null &&
          RevenueCatService.hasActiveSubscription(_customerInfo!)) {
        // Verify with backend
        final verified = await RevenueCatService.verifySubscriptionWithBackend(
            _customerInfo!);

        if (verified) {
          await loadCurrentSubscription();
          await loadSubscriptionUsage();
          _error = null;
          _setLoaded();
          return true;
        }
      }

      // Fallback to API restore
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

  // List<SubscriptionPlan> get activePlans {
  //   return _plans.where((plan) => plan.active).toList();
  // }

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
