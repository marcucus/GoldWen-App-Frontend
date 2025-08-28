import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/models/models.dart';

class MatchingProvider with ChangeNotifier {
  DailySelection? _dailySelection;
  List<Match> _matches = [];
  List<Profile> _dailyProfiles = [];
  List<String> _selectedProfileIds = [];
  bool _isLoading = false;
  DateTime? _lastUpdateTime;
  String? _error;
  SubscriptionUsage? _subscriptionUsage;

  DailySelection? get dailySelection => _dailySelection;
  List<Match> get matches => _matches;
  List<Profile> get dailyProfiles => _dailySelection?.profiles ?? _dailyProfiles;
  List<String> get selectedProfileIds => _selectedProfileIds;
  bool get isLoading => _isLoading;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  String? get error => _error;
  SubscriptionUsage? get subscriptionUsage => _subscriptionUsage;

  bool get hasSubscription => _subscriptionUsage?.canSeeWhoLikedYou ?? false;
  int get maxSelections => _subscriptionUsage?.dailyLikesLimit ?? 1;
  int get remainingSelections => _subscriptionUsage?.remainingLikes ?? 0;
  bool get canSelectMore => remainingSelections > 0;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadDailySelection() async {
    _setLoading();

    try {
      final response = await ApiService.getDailySelection();
      final selectionData = response['data'] ?? response;
      
      _dailySelection = DailySelection.fromJson(selectionData);
      _dailyProfiles = _dailySelection!.profiles;
      _lastUpdateTime = DateTime.now();
      _error = null;
      
      // Load subscription usage to know limits
      await _loadSubscriptionUsage();
    } catch (e) {
      _handleError(e, 'Failed to load daily selection');
    } finally {
      _setLoaded();
    }
  }

  Future<void> loadMatches({int page = 1, int limit = 20, String? status}) async {
    if (page == 1) _setLoading();

    try {
      final response = await ApiService.getMatches(
        page: page,
        limit: limit,
        status: status,
      );
      
      final matchesData = response['data'] ?? response['matches'] ?? [];
      final newMatches = (matchesData as List)
          .map((m) => Match.fromJson(m as Map<String, dynamic>))
          .toList();

      if (page == 1) {
        _matches = newMatches;
      } else {
        _matches.addAll(newMatches);
      }
      
      _error = null;
    } catch (e) {
      _handleError(e, 'Failed to load matches');
    } finally {
      if (page == 1) _setLoaded();
    }
  }

  Future<bool> selectProfile(String profileId) async {
    if (!canSelectMore) {
      _error = 'No more selections available today';
      notifyListeners();
      return false;
    }

    if (_selectedProfileIds.contains(profileId)) {
      return false;
    }

    try {
      final response = await ApiService.chooseProfile(profileId);
      
      // Check if it's a match
      final isMatch = response['data']?['isMatch'] ?? false;
      if (isMatch) {
        // Reload matches to include the new one
        await loadMatches();
      }
      
      _selectedProfileIds.add(profileId);
      
      // Update subscription usage
      await _loadSubscriptionUsage();
      
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e, 'Failed to select profile');
      return false;
    }
  }

  Future<CompatibilityResult?> getCompatibility(String profileId) async {
    try {
      final response = await ApiService.getCompatibility(profileId);
      final compatibilityData = response['data'] ?? response;
      
      return CompatibilityResult.fromJson(compatibilityData);
    } catch (e) {
      _handleError(e, 'Failed to get compatibility score');
      return null;
    }
  }

  Future<void> deleteMatch(String matchId) async {
    try {
      await ApiService.deleteMatch(matchId);
      _matches.removeWhere((match) => match.id == matchId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _handleError(e, 'Failed to delete match');
    }
  }

  Future<Match?> getMatchDetails(String matchId) async {
    try {
      final response = await ApiService.getMatchDetails(matchId);
      final matchData = response['data'] ?? response;
      
      return Match.fromJson(matchData);
    } catch (e) {
      _handleError(e, 'Failed to get match details');
      return null;
    }
  }

  Future<void> _loadSubscriptionUsage() async {
    try {
      final response = await ApiService.getSubscriptionUsage();
      final usageData = response['data'] ?? response;
      
      _subscriptionUsage = SubscriptionUsage.fromJson(usageData);
    } catch (e) {
      // Don't handle error here as it's not critical
      // User might not have a subscription
    }
  }

  bool isProfileSelected(String profileId) {
    return _selectedProfileIds.contains(profileId);
  }

  bool shouldShowNewProfiles() {
    if (_dailySelection == null || _lastUpdateTime == null) return true;
    
    // Check if daily selection is expired
    return _dailySelection!.isExpired;
  }

  void clearDailySelection() {
    _selectedProfileIds.clear();
    _dailyProfiles.clear();
    _dailySelection = null;
    _lastUpdateTime = null;
    notifyListeners();
  }

  void refreshSelectionIfNeeded() {
    if (shouldShowNewProfiles()) {
      loadDailySelection();
    }
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

  // Subscription-related methods
  bool get canSeeWhoLikedYou => _subscriptionUsage?.canSeeWhoLikedYou ?? false;
  bool get canUseAdvancedFilters => _subscriptionUsage?.canUseAdvancedFilters ?? false;
  bool get hasUnlimitedRewinds => _subscriptionUsage?.hasUnlimitedRewinds ?? false;

  int get superLikesRemaining => _subscriptionUsage?.remainingSuperLikes ?? 0;
  int get boostsRemaining => _subscriptionUsage?.remainingBoosts ?? 0;

  DateTime? get usageResetDate => _subscriptionUsage?.resetDate;
}