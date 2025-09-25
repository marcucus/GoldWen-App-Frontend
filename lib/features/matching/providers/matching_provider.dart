import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/notification_manager.dart';
import '../../../core/models/models.dart';
import '../../subscription/providers/subscription_provider.dart';

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
  int get maxSelections {
    // Use daily selection metadata if available, otherwise fall back to subscription usage
    if (_dailySelection != null) {
      return _dailySelection!.maxChoices;
    }
    // Use subscription status to determine max selections
    // Free users: 1 selection, Premium users: 3 selections
    return (_subscriptionUsage?.dailyChoicesLimit ?? (hasSubscription ? 3 : 1));
  }
  int get remainingSelections {
    // Use daily selection metadata if available
    if (_dailySelection != null) {
      return _dailySelection!.choicesRemaining;
    }
    // Fall back to subscription usage
    return _subscriptionUsage?.remainingChoices ?? 1;
  }
  bool get canSelectMore {
    // Use daily selection metadata if available
    if (_dailySelection != null) {
      return _dailySelection!.canSelectMore;
    }
    return remainingSelections > 0;
  }

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
      
      // Schedule next day's notification
      await _scheduleDailyNotifications();
    } catch (e) {
      _handleError(e, 'Failed to load daily selection');
    } finally {
      _setLoaded();
    }
  }

  Future<void> _scheduleDailyNotifications() async {
    try {
      // Note: This would need a context, which should be passed from the UI level
      // For now, we'll keep the direct local notification service call
      // In a real implementation, this should be called from a context-aware component
      await LocalNotificationService().scheduleDailySelectionNotification();
    } catch (e) {
      // Don't fail the whole operation if notifications fail
      print('Failed to schedule daily notifications: $e');
    }
  }

  Future<void> initializeNotifications() async {
    try {
      await LocalNotificationService().initialize();
      final permissionGranted = await LocalNotificationService().requestPermissions();
      
      if (permissionGranted) {
        await _scheduleDailyNotifications();
      }
    } catch (e) {
      print('Failed to initialize notifications: $e');
    }
  }

  /// Schedule daily notifications with context (should be called from UI)
  Future<void> scheduleDailyNotificationsWithContext(BuildContext context) async {
    try {
      await NotificationManager().scheduleDailySelectionNotifications(context);
    } catch (e) {
      print('Failed to schedule daily notifications: $e');
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

  Future<Map<String, dynamic>?> selectProfile(String profileId, {SubscriptionProvider? subscriptionProvider}) async {
    // Check if user has remaining selections
    if (!canSelectMore) {
      if (subscriptionProvider != null && !subscriptionProvider.hasActiveSubscription) {
        _error = 'Vous avez atteint votre limite quotidienne. Passez à GoldWen Plus pour 3 sélections par jour !';
      } else {
        _error = 'Limite quotidienne de sélections atteinte';
      }
      notifyListeners();
      return null;
    }

    if (_selectedProfileIds.contains(profileId)) {
      _error = 'Profil déjà sélectionné';
      notifyListeners();
      return null;
    }

    try {
      final response = await ApiService.chooseProfile(profileId);
      
      // Check if it's a match
      final responseData = response['data'] ?? response;
      final isMatch = responseData['isMatch'] ?? false;
      final matchedUserName = responseData['matchedUserName'] as String?;
      final matchId = responseData['matchId'] as String?;
      final choicesRemaining = responseData['choicesRemaining'] as int?;
      
      if (isMatch) {
        // Reload matches to include the new one
        await loadMatches();
        
        // Trigger new match notification
        if (matchedUserName != null) {
          try {
            await LocalNotificationService().showMatchNotification(
              matchedUserName: matchedUserName,
            );
          } catch (e) {
            print('Failed to show match notification: $e');
            // Don't fail the entire operation if notification fails
          }
        }
        
        // Return match information for UI to handle
        final matchInfo = {
          'isMatch': true,
          'matchedUserName': matchedUserName,
          'matchId': matchId,
          'profile': _dailyProfiles.firstWhere((p) => p.id == profileId),
        };
        
        _selectedProfileIds.add(profileId);
        _updateDailySelectionAfterChoice(choicesRemaining);
        _error = null;
        notifyListeners();
        
        return matchInfo;
      }
      
      _selectedProfileIds.add(profileId);
      _updateDailySelectionAfterChoice(choicesRemaining);
      _error = null;
      notifyListeners();
      
      return {'isMatch': false};
    } catch (e) {
      _handleError(e, 'Failed to select profile');
      return null;
    }
  }

  void _updateDailySelectionAfterChoice(int? choicesRemaining) {
    if (_dailySelection != null) {
      final newChoicesRemaining = choicesRemaining ?? (_dailySelection!.choicesRemaining - 1).clamp(0, _dailySelection!.maxChoices);
      
      _dailySelection = DailySelection(
        profiles: _dailySelection!.profiles,
        generatedAt: _dailySelection!.generatedAt,
        expiresAt: _dailySelection!.expiresAt,
        remainingLikes: _dailySelection!.remainingLikes,
        hasUsedSuperLike: _dailySelection!.hasUsedSuperLike,
        choicesRemaining: newChoicesRemaining,
        choicesMade: _dailySelection!.choicesMade + 1,
        maxChoices: _dailySelection!.maxChoices,
        refreshTime: _dailySelection!.refreshTime,
      );
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

  Future<Map<String, dynamic>?> acceptMatch(String matchId, {required bool accept}) async {
    try {
      _setLoading();
      
      final response = await ApiService.acceptMatch(matchId, accept: accept);
      final result = response['data'] ?? response;
      
      if (accept && result != null) {
        // If accepted, the response should contain chat details
        return result;
      }
      
      _error = null;
      notifyListeners();
      return result;
    } catch (e) {
      _handleError(e, accept ? 'Failed to accept match' : 'Failed to decline match');
      return null;
    } finally {
      _setLoaded();
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

  bool get isSelectionComplete {
    return _dailySelection?.isSelectionComplete ?? false;
  }

  String? get selectionCompleteMessage {
    if (isSelectionComplete) {
      return 'Votre choix est fait. Revenez demain pour votre nouvelle sélection !';
    }
    return null;
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