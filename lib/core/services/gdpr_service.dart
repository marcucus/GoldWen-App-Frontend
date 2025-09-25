import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gdpr_consent.dart';
import 'api_service.dart';

class GdprService extends ChangeNotifier {
  GdprConsent? _currentConsent;
  PrivacySettings? _currentPrivacySettings;
  PrivacyPolicy? _currentPrivacyPolicy;
  bool _isLoading = false;
  String? _error;

  // Getters
  GdprConsent? get currentConsent => _currentConsent;
  PrivacySettings? get currentPrivacySettings => _currentPrivacySettings;
  PrivacyPolicy? get currentPrivacyPolicy => _currentPrivacyPolicy;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasValidConsent => _currentConsent?.dataProcessing == true;

  // Check if consent has been given
  Future<bool> checkConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final consentGiven = prefs.getBool('gdpr_consent_given') ?? false;
    final consentDate = prefs.getString('gdpr_consent_date');
    
    if (consentGiven && consentDate != null) {
      try {
        final date = DateTime.parse(consentDate);
        _currentConsent = GdprConsent(
          dataProcessing: true,
          marketing: prefs.getBool('gdpr_marketing_consent'),
          analytics: prefs.getBool('gdpr_analytics_consent'),
          consentedAt: date,
        );
        notifyListeners();
        return true;
      } catch (e) {
        print('Error parsing consent date: $e');
      }
    }
    
    return false;
  }

  // Submit GDPR consent
  Future<bool> submitConsent({
    required bool dataProcessing,
    bool? marketing,
    bool? analytics,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.submitGdprConsent(
        dataProcessing: dataProcessing,
        marketing: marketing,
        analytics: analytics,
      );

      // Store consent locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gdpr_consent_given', dataProcessing);
      await prefs.setString('gdpr_consent_date', DateTime.now().toIso8601String());
      if (marketing != null) {
        await prefs.setBool('gdpr_marketing_consent', marketing);
      }
      if (analytics != null) {
        await prefs.setBool('gdpr_analytics_consent', analytics);
      }

      _currentConsent = GdprConsent(
        dataProcessing: dataProcessing,
        marketing: marketing,
        analytics: analytics,
        consentedAt: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Load privacy policy
  Future<bool> loadPrivacyPolicy({String? version, String format = 'json'}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.getPrivacyPolicy(
        version: version,
        format: format,
      );

      _currentPrivacyPolicy = PrivacyPolicy.fromJson(response);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Export user data
  Future<dynamic> exportUserData({String format = 'json'}) async {
    _setLoading(true);
    _error = null;

    try {
      final data = await ApiService.exportUserData(format: format);
      _setLoading(false);
      notifyListeners();
      return data;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      throw e;
    }
  }

  // Load privacy settings
  Future<bool> loadPrivacySettings() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.getPrivacySettings();
      _currentPrivacySettings = PrivacySettings.fromJson(response);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update privacy settings
  Future<bool> updatePrivacySettings({
    required bool analytics,
    required bool marketing,
    required bool functionalCookies,
    int? dataRetention,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.updatePrivacySettings(
        analytics: analytics,
        marketing: marketing,
        functionalCookies: functionalCookies,
        dataRetention: dataRetention,
      );

      _currentPrivacySettings = PrivacySettings(
        analytics: analytics,
        marketing: marketing,
        functionalCookies: functionalCookies,
        dataRetention: dataRetention,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete account with GDPR compliance
  Future<bool> deleteAccountWithGdprCompliance() async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.deleteAccountWithGdpr();
      
      // Clear all local consent data
      await clearLocalConsentData();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Clear local consent data
  Future<void> clearLocalConsentData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gdpr_consent_given');
    await prefs.remove('gdpr_consent_date');
    await prefs.remove('gdpr_marketing_consent');
    await prefs.remove('gdpr_analytics_consent');

    _currentConsent = null;
    _currentPrivacySettings = null;
    _currentPrivacyPolicy = null;
    notifyListeners();
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) {
      notifyListeners();
    }
  }

  // Validate if consent is still valid (not older than 1 year)
  bool isConsentStillValid() {
    if (_currentConsent == null) return false;
    
    final consentAge = DateTime.now().difference(_currentConsent!.consentedAt);
    return consentAge.inDays < 365; // Valid for 1 year
  }

  // Check if consent needs to be renewed
  bool needsConsentRenewal() {
    if (_currentConsent == null) return true;
    
    final consentAge = DateTime.now().difference(_currentConsent!.consentedAt);
    return consentAge.inDays >= 300; // Remind to renew after 10 months
  }
}