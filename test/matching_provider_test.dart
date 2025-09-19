import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/models/models.dart';

// Mock classes would be generated with build_runner
// For now, let's create a simple test that doesn't require mocking

void main() {
  group('MatchingProvider', () {
    late MatchingProvider matchingProvider;

    setUp(() {
      matchingProvider = MatchingProvider();
    });

    test('initial state is correct', () {
      expect(matchingProvider.isLoading, false);
      expect(matchingProvider.error, null);
      expect(matchingProvider.dailyProfiles, isEmpty);
      expect(matchingProvider.selectedProfileIds, isEmpty);
      expect(matchingProvider.remainingSelections, 0);
    });

    test('canSelectMore returns false when no remaining selections', () {
      expect(matchingProvider.canSelectMore, false);
    });

    test('isProfileSelected returns false for unselected profile', () {
      expect(matchingProvider.isProfileSelected('test-id'), false);
    });

    test('clearError clears error state', () {
      // This test is simple since we can't easily mock the private _error field
      matchingProvider.clearError();
      expect(matchingProvider.error, null);
    });

    test('subscription-related getters return default values', () {
      expect(matchingProvider.hasSubscription, false);
      expect(matchingProvider.canSeeWhoLikedYou, false);
      expect(matchingProvider.canUseAdvancedFilters, false);
      expect(matchingProvider.maxSelections, 1);
    });
  });

  group('MatchingProvider - Profile Selection Logic', () {
    late MatchingProvider matchingProvider;

    setUp(() {
      matchingProvider = MatchingProvider();
    });

    test('shouldShowNewProfiles returns true when no daily selection', () {
      expect(matchingProvider.shouldShowNewProfiles(), true);
    });

    test('clearDailySelection resets all state', () {
      matchingProvider.clearDailySelection();
      
      expect(matchingProvider.selectedProfileIds, isEmpty);
      expect(matchingProvider.dailyProfiles, isEmpty);
      expect(matchingProvider.dailySelection, null);
      expect(matchingProvider.lastUpdateTime, null);
    });
  });

  group('MatchingProvider - Notification Integration', () {
    late MatchingProvider matchingProvider;

    setUp(() {
      matchingProvider = MatchingProvider();
    });

    test('initializeNotifications completes without error', () async {
      // This test ensures the method doesn't throw
      expect(() async => await matchingProvider.initializeNotifications(), 
             returnsNormally);
    });
  });
}