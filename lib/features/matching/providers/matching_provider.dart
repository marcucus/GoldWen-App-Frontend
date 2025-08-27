import 'package:flutter/material.dart';
import '../models/match_profile.dart';

class MatchingProvider with ChangeNotifier {
  List<MatchProfile> _dailyProfiles = [];
  List<String> _selectedProfileIds = [];
  bool _isLoading = false;
  DateTime? _lastUpdateTime;
  bool _hasSubscription = false;

  List<MatchProfile> get dailyProfiles => _dailyProfiles;
  List<String> get selectedProfileIds => _selectedProfileIds;
  bool get isLoading => _isLoading;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  bool get hasSubscription => _hasSubscription;
  int get maxSelections => _hasSubscription ? 3 : 1;
  bool get canSelectMore => _selectedProfileIds.length < maxSelections;

  Future<void> loadDailyProfiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement API call to get daily profiles
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock data
      _dailyProfiles = [
        MatchProfile(
          id: '1',
          name: 'Sophie',
          age: 29,
          bio: 'Passionate about art and meaningful conversations.',
          photos: ['photo1.jpg', 'photo2.jpg'],
          prompts: ['I love exploring new cultures', 'Coffee is my love language', 'Looking for genuine connections'],
          compatibilityScore: 0.92,
        ),
        MatchProfile(
          id: '2',
          name: 'Emma',
          age: 27,
          bio: 'Designer who loves hiking and good books.',
          photos: ['photo3.jpg', 'photo4.jpg'],
          prompts: ['Nature heals everything', 'Books over TV any day', 'Design is my passion'],
          compatibilityScore: 0.88,
        ),
        MatchProfile(
          id: '3',
          name: 'Claire',
          age: 31,
          bio: 'Yoga instructor and mindfulness enthusiast.',
          photos: ['photo5.jpg', 'photo6.jpg'],
          prompts: ['Mindfulness is key', 'Yoga changed my life', 'Seeking authentic connections'],
          compatibilityScore: 0.85,
        ),
      ];
      
      _lastUpdateTime = DateTime.now();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selectProfile(String profileId) async {
    if (!canSelectMore) {
      return false;
    }

    if (_selectedProfileIds.contains(profileId)) {
      return false;
    }

    try {
      // TODO: Implement API call to select profile
      await Future.delayed(const Duration(seconds: 1));
      
      _selectedProfileIds.add(profileId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  bool isProfileSelected(String profileId) {
    return _selectedProfileIds.contains(profileId);
  }

  void setSubscriptionStatus(bool hasSubscription) {
    _hasSubscription = hasSubscription;
    notifyListeners();
  }

  bool shouldShowNewProfiles() {
    if (_lastUpdateTime == null) return true;
    
    final now = DateTime.now();
    final noon = DateTime(now.year, now.month, now.day, 12, 0, 0);
    
    // Show new profiles if it's past noon and we haven't updated today
    return now.isAfter(noon) && 
           _lastUpdateTime!.isBefore(noon);
  }

  void clearDailySelection() {
    _selectedProfileIds.clear();
    _dailyProfiles.clear();
    notifyListeners();
  }
}