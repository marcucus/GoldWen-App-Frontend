import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/models.dart';
import 'api_service.dart';

class RevenueCatService {
  static const String _apiKey = 'your_revenue_cat_api_key_here';
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await Purchases.configure(
        PurchasesConfiguration(_apiKey)
          ..appUserID = null, // Let RevenueCat generate the user ID
      );
      _isInitialized = true;
    } catch (e) {
      print('Error initializing RevenueCat: $e');
      rethrow;
    }
  }

  static Future<void> setUserId(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      print('Error setting RevenueCat user ID: $e');
    }
  }

  static Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      print('Error logging out of RevenueCat: $e');
    }
  }

  static Future<List<Package>> getAvailablePackages() async {
    try {
      await initialize();
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;
      
      if (currentOffering != null) {
        return currentOffering.availablePackages;
      }
      return [];
    } catch (e) {
      print('Error getting available packages: $e');
      return [];
    }
  }

  static Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      await initialize();
      final purchaserInfo = await Purchases.purchasePackage(package);
      return purchaserInfo.customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('Purchase error: $e');
        rethrow;
      }
      return null; // User cancelled
    } catch (e) {
      print('Unexpected purchase error: $e');
      rethrow;
    }
  }

  static Future<CustomerInfo> restorePurchases() async {
    try {
      await initialize();
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo;
    } catch (e) {
      print('Error restoring purchases: $e');
      rethrow;
    }
  }

  static Future<CustomerInfo?> getCurrentCustomerInfo() async {
    try {
      await initialize();
      return await Purchases.getCustomerInfo();
    } catch (e) {
      print('Error getting customer info: $e');
      return null;
    }
  }

  static Future<bool> verifySubscriptionWithBackend(CustomerInfo customerInfo) async {
    try {
      final activeEntitlements = customerInfo.entitlements.active;
      if (activeEntitlements.isEmpty) return false;

      // Get the receipt data based on platform
      String receiptData;
      String platform;
      
      if (Platform.isIOS) {
        platform = 'ios';
        // For iOS, we need to get the original app transaction ID
        final latestTransaction = customerInfo.originalAppUserId;
        receiptData = latestTransaction ?? '';
      } else {
        platform = 'android';
        // For Android, get the purchase token from the latest entitlement
        final entitlement = activeEntitlements.values.first;
        receiptData = entitlement.originalPurchaseDate.toString();
      }

      if (receiptData.isEmpty) return false;

      // Verify with backend
      final response = await ApiService.verifyReceipt(
        receiptData: receiptData,
        platform: platform,
      );
      
      return response != null;
    } catch (e) {
      print('Error verifying subscription with backend: $e');
      return false;
    }
  }

  static bool hasActiveSubscription(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.isNotEmpty;
  }

  static EntitlementInfo? getActiveEntitlement(CustomerInfo customerInfo) {
    final activeEntitlements = customerInfo.entitlements.active;
    if (activeEntitlements.isEmpty) return null;
    
    // Return the first active entitlement (assuming one subscription type)
    return activeEntitlements.values.first;
  }

  static DateTime? getExpirationDate(CustomerInfo customerInfo) {
    final entitlement = getActiveEntitlement(customerInfo);
    final expirationDate = entitlement?.expirationDate;
    if (expirationDate != null) {
      // Handle both DateTime and String types
      if (expirationDate is DateTime) {
        return expirationDate as DateTime;
      } else if (expirationDate is String) {
        try {
          return DateTime.parse(expirationDate as String);
        } catch (e) {
          print('Error parsing expiration date: $expirationDate');
          return null;
        }
      }
    }
    return null;
  }

  static bool willRenew(CustomerInfo customerInfo) {
    final entitlement = getActiveEntitlement(customerInfo);
    return entitlement?.willRenew ?? false;
  }

  static String? getProductIdentifier(CustomerInfo customerInfo) {
    final entitlement = getActiveEntitlement(customerInfo);
    return entitlement?.productIdentifier;
  }

  // Convert RevenueCat Package to our SubscriptionPlan model
  static SubscriptionPlan packageToSubscriptionPlan(Package package) {
    final product = package.storeProduct;
    
    return SubscriptionPlan(
      id: product.identifier,
      name: product.title,
      description: product.description,
      price: product.price,
      currency: product.currencyCode,
      interval: _getIntervalFromIdentifier(product.identifier),
      intervalCount: _getIntervalCountFromIdentifier(product.identifier),
      features: _getFeaturesByPlan(product.identifier),
      metadata: {
        'package_type': package.packageType.name,
        'popular': _isPopularPlan(product.identifier),
      },
      active: true,
    );
  }

  static String _getIntervalFromIdentifier(String identifier) {
    if (identifier.contains('monthly') || identifier.contains('month')) {
      return 'month';
    } else if (identifier.contains('quarterly') || identifier.contains('quarter')) {
      return 'month';
    } else if (identifier.contains('annual') || identifier.contains('year')) {
      return 'year';
    }
    return 'month';
  }

  static int _getIntervalCountFromIdentifier(String identifier) {
    if (identifier.contains('quarterly') || identifier.contains('quarter')) {
      return 3;
    } else if (identifier.contains('semiannual') || identifier.contains('6month')) {
      return 6;
    }
    return 1;
  }

  static List<String> _getFeaturesByPlan(String identifier) {
    return [
      '3 sélections par jour',
      'Chat illimité',
      'Voir qui vous a sélectionné',
      'Profil prioritaire',
    ];
  }

  static bool _isPopularPlan(String identifier) {
    // Mark quarterly/3-month plans as popular
    return identifier.contains('quarterly') || 
           identifier.contains('quarter') || 
           identifier.contains('3month');
  }
}