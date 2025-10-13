import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/notification_manager.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/models/models.dart';
import '../../subscription/providers/subscription_provider.dart';

class MatchingProvider with ChangeNotifier {
  DailySelection? _dailySelection;
  List<Match> _matches = [];
  List<Profile> _dailyProfiles = [];
  List<String> _selectedProfileIds = [];
  List<WhoLikedMeItem> _whoLikedMe = [];
  bool _isLoading = false;
  bool _isLoadingWhoLikedMe = false;
  DateTime? _lastUpdateTime;
  String? _error;
  SubscriptionUsage? _subscriptionUsage;

  DailySelection? get dailySelection => _dailySelection;
  List<Match> get matches => _matches;
  List<Profile> get dailyProfiles => _dailySelection?.profiles ?? _dailyProfiles;
  List<String> get selectedProfileIds => _selectedProfileIds;
  List<WhoLikedMeItem> get whoLikedMe => _whoLikedMe;
  bool get isLoading => _isLoading;
  bool get isLoadingWhoLikedMe => _isLoadingWhoLikedMe;
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
      
      // Track daily selection viewed
      await AnalyticsService.trackDailySelectionViewed(_dailyProfiles.length);
      
      // Load subscription usage to know limits
      await _loadSubscriptionUsage();
      
      // Schedule next day's notification
      await _scheduleDailyNotifications();
    } catch (e) {
      // If API is not available, provide mock data for development
      if (e.toString().contains('NetworkException') || 
          e.toString().contains('ECONNREFUSED') ||
          e.toString().contains('Failed to connect')) {
        _createMockDailySelection();
        _error = null;
      } else {
        _handleError(e, 'Failed to load daily selection');
      }
    } finally {
      _setLoaded();
    }
  }

  void _createMockDailySelection() {
    // Create mock profiles for development when API is not available
    final mockProfiles = [
      Profile.fromJson({
        'id': 'mock_1',
        'firstName': 'Emma',
        'lastName': 'L.',
        'age': 25,
        'bio': 'Passionnée de voyage et de photographie. J\'adore découvrir de nouveaux endroits !',
        'photos': [
          {'id': 'photo_1', 'url': 'https://images.unsplash.com/photo-1494790108755-2616b612b714', 'order': 1, 'isMain': true}
        ],
        'location': {'city': 'Paris', 'distance': 5},
        'interests': ['voyage', 'photographie', 'art'],
      }),
      Profile.fromJson({
        'id': 'mock_2', 
        'firstName': 'Sophie',
        'lastName': 'M.',
        'age': 28,
        'bio': 'Cheffe passionnée qui aime cuisiner et partager de bons moments.',
        'photos': [
          {'id': 'photo_2', 'url': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80', 'order': 1, 'isMain': true}
        ],
        'location': {'city': 'Lyon', 'distance': 12},
        'interests': ['cuisine', 'vin', 'lecture'],
      }),
      Profile.fromJson({
        'id': 'mock_3',
        'firstName': 'Clara',
        'lastName': 'D.',
        'age': 24,
        'bio': 'Architecte créative qui aime l\'art moderne et les balades en nature.',
        'photos': [
          {'id': 'photo_3', 'url': 'https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb', 'order': 1, 'isMain': true}
        ],
        'location': {'city': 'Marseille', 'distance': 8},
        'interests': ['architecture', 'art', 'nature'],
      }),
    ];

    _dailySelection = DailySelection(
      profiles: mockProfiles,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      remainingLikes: 10,
      hasUsedSuperLike: false,
      choicesRemaining: 1,
      choicesMade: 0,
      maxChoices: 1,
      refreshTime: DateTime.now().add(const Duration(days: 1)),
    );
    
    _dailyProfiles = mockProfiles;
    _lastUpdateTime = DateTime.now();
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

  Future<Map<String, dynamic>?> selectProfile(String profileId, {SubscriptionProvider? subscriptionProvider, String choice = 'like'}) async {
    // Check if user has remaining selections (only for 'like' choice)
    if (choice == 'like' && !canSelectMore) {
      final refreshTime = _dailySelection?.refreshTime;
      final resetTimeInfo = refreshTime != null ? _formatResetTime(refreshTime) : null;
      
      if (subscriptionProvider != null && !subscriptionProvider.hasActiveSubscription) {
        _error = resetTimeInfo != null
          ? 'Vous avez atteint votre limite quotidienne. Nouvelle sélection dans $resetTimeInfo ou passez à GoldWen Plus pour 3 choix/jour !'
          : 'Vous avez atteint votre limite quotidienne. Passez à GoldWen Plus pour 3 sélections par jour !';
      } else {
        _error = resetTimeInfo != null
          ? 'Limite quotidienne de sélections atteinte. Nouvelle sélection dans $resetTimeInfo.'
          : 'Limite quotidienne de sélections atteinte';
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
      final response = await ApiService.chooseProfile(profileId, choice: choice);
      
      // Check if it's a match
      final responseData = response['data'] ?? response;
      final isMatch = responseData['isMatch'] ?? false;
      final matchedUserName = responseData['matchedUserName'] as String?;
      final matchId = responseData['matchId'] as String?;
      final choicesRemaining = responseData['choicesRemaining'] as int?;
      
      // Track profile chosen or passed
      if (choice == 'like') {
        final profile = _dailyProfiles.firstWhere((p) => p.id == profileId);
        await AnalyticsService.trackProfileChosen(
          profileId,
          compatibilityScore: profile.compatibilityScore,
        );
      } else if (choice == 'pass') {
        await AnalyticsService.trackProfilePassed(profileId);
      }
      
      if (isMatch) {
        // Track match created
        if (matchId != null) {
          await AnalyticsService.trackMatchCreated(matchId, profileId);
        }
        
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
      
      return {'isMatch': false, 'choice': choice};
    } catch (e) {
      _handleError(e, 'Failed to select profile');
      return null;
    }
  }

  String? _formatResetTime(DateTime resetTime) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);
    
    if (difference.isNegative) return null;
    
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (hours > 0) {
        return '${hours}h${minutes > 0 ? minutes.toString().padLeft(2, '0') : ''}';
      } else {
        return '${minutes}min';
      }
    }
    
    // Format as "demain à HH:MM"
    final hour = resetTime.hour;
    final minute = resetTime.minute;
    return 'demain à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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

  /// Check if there's a new selection available (different from current one)
  /// This is used to show the "Nouvelle sélection disponible !" badge
  bool hasNewSelectionAvailable() {
    if (_dailySelection == null) return true;
    
    // Check if the selection has expired
    if (_dailySelection!.isExpired) return true;
    
    // Check if it's past noon (12:00) local time and we haven't refreshed today
    final now = DateTime.now();
    final lastUpdate = _lastUpdateTime ?? _dailySelection!.generatedAt;
    
    // If last update was before today at noon, there might be a new selection
    final todayNoon = DateTime(now.year, now.month, now.day, 12, 0, 0);
    
    // If we're past noon today and last update was before today's noon
    if (now.isAfter(todayNoon) && lastUpdate.isBefore(todayNoon)) {
      return true;
    }
    
    // If refresh time is set and we're past it
    if (_dailySelection!.refreshTime != null && 
        now.isAfter(_dailySelection!.refreshTime!)) {
      return true;
    }
    
    return false;
  }

  /// Get time remaining until next selection refresh
  Duration? getTimeUntilNextRefresh() {
    final now = DateTime.now();
    
    // If we have a refresh time from the selection, use it
    if (_dailySelection?.refreshTime != null) {
      final difference = _dailySelection!.refreshTime!.difference(now);
      return difference.isNegative ? null : difference;
    }
    
    // Otherwise, calculate next noon (12:00)
    final todayNoon = DateTime(now.year, now.month, now.day, 12, 0, 0);
    
    if (now.isBefore(todayNoon)) {
      // Next refresh is today at noon
      return todayNoon.difference(now);
    } else {
      // Next refresh is tomorrow at noon
      final tomorrowNoon = todayNoon.add(const Duration(days: 1));
      return tomorrowNoon.difference(now);
    }
  }

  /// Format the time until next refresh as a countdown string
  String getNextRefreshCountdown() {
    final timeUntil = getTimeUntilNextRefresh();
    if (timeUntil == null) return 'Bientôt disponible';
    
    if (timeUntil.inDays > 0) {
      return '${timeUntil.inDays}j ${timeUntil.inHours % 24}h';
    } else if (timeUntil.inHours > 0) {
      return '${timeUntil.inHours}h ${timeUntil.inMinutes % 60}min';
    } else if (timeUntil.inMinutes > 0) {
      return '${timeUntil.inMinutes}min';
    } else {
      return '${timeUntil.inSeconds}s';
    }
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

  // History management
  List<HistoryItem> _historyItems = [];
  bool _hasMoreHistory = true;

  List<HistoryItem> get historyItems => _historyItems;
  bool get hasMoreHistory => _hasMoreHistory;

  Future<void> loadHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    bool refresh = false,
  }) async {
    if (refresh) {
      _historyItems.clear();
      _hasMoreHistory = true;
    }

    _setLoading();

    try {
      final response = await MatchingServiceApi.getHistory(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      final historyData = PaginatedHistory.fromJson(response);
      
      if (refresh || page == 1) {
        _historyItems = historyData.data;
      } else {
        _historyItems.addAll(historyData.data);
      }

      _hasMoreHistory = historyData.hasMore;
      _error = null;
    } catch (e) {
      _handleError(e, 'Impossible de charger l\'historique');
    } finally {
      _setLoaded();
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
    } else if (error.toString().contains('SocketException') || 
               error.toString().contains('NetworkException')) {
      _error = 'Vérifiez votre connexion internet et réessayez';
    } else if (error.toString().contains('TimeoutException')) {
      _error = 'La requête a pris trop de temps. Réessayez plus tard';
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

  // Premium feature: Who liked me
  Future<void> loadWhoLikedMe() async {
    _isLoadingWhoLikedMe = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getWhoLikedMe();
      final data = response['data'] as List<dynamic>? ?? [];
      
      _whoLikedMe = data
          .map((item) => WhoLikedMeItem.fromJson(item as Map<String, dynamic>))
          .toList();
      
      _error = null;
    } catch (e) {
      _handleError(e, 'Failed to load who liked you');
    } finally {
      _isLoadingWhoLikedMe = false;
      notifyListeners();
    }
  }

  void clearWhoLikedMe() {
    _whoLikedMe.clear();
    notifyListeners();
  }

  // Advanced Recommendations (Matching V2)
  List<CompatibilityScoreV2>? _advancedRecommendations;
  bool _isLoadingAdvancedRecommendations = false;

  List<CompatibilityScoreV2>? get advancedRecommendations => _advancedRecommendations;
  bool get isLoadingAdvancedRecommendations => _isLoadingAdvancedRecommendations;

  Future<void> loadAdvancedRecommendations({
    required String userId,
    required List<String> candidateIds,
    Map<String, dynamic>? personalityAnswers,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? userLocation,
    bool includeAdvancedScoring = true,
  }) async {
    _isLoadingAdvancedRecommendations = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.calculateCompatibilityV2(
        userId: userId,
        candidateIds: candidateIds,
        personalityAnswers: personalityAnswers ?? {},
        preferences: preferences ?? {},
        userLocation: userLocation,
        includeAdvancedScoring: includeAdvancedScoring,
      );

      final scoresData = response['data']?['compatibilityScores'] ?? response['compatibilityScores'];
      
      if (scoresData is List) {
        _advancedRecommendations = scoresData
            .map((score) => CompatibilityScoreV2.fromJson(score as Map<String, dynamic>))
            .toList();
        _error = null;
      } else {
        throw Exception('Invalid response format for advanced recommendations');
      }
    } catch (e) {
      _handleError(e, 'Failed to load advanced recommendations');
    } finally {
      _isLoadingAdvancedRecommendations = false;
      notifyListeners();
    }
  }

  void clearAdvancedRecommendations() {
    _advancedRecommendations = null;
    notifyListeners();
  }
}