import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/matching.dart';
import 'package:goldwen_app/core/models/profile.dart';

void main() {
  group('MatchingProvider Quota Logic via Models', () {

    test('DailySelection correctly determines selection state', () {
      // Test active selection state
      final profiles = <Profile>[];
      final activeSelection = DailySelection(
        profiles: profiles,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 24)),
        remainingLikes: 0,
        hasUsedSuperLike: false,
        choicesRemaining: 2,
        choicesMade: 1,
        maxChoices: 3,
      );
      
      expect(activeSelection.canSelectMore, true);
      expect(activeSelection.isSelectionComplete, false);
      
      // Test completed selection state
      final completedSelection = DailySelection(
        profiles: profiles,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 24)),
        remainingLikes: 0,
        hasUsedSuperLike: false,
        choicesRemaining: 0,
        choicesMade: 3,
        maxChoices: 3,
      );
      
      expect(completedSelection.canSelectMore, false);
      expect(completedSelection.isSelectionComplete, true);
    });

    test('DailySelection handles edge cases correctly', () {
      final profiles = <Profile>[];
      
      // Test free user limits
      final freeUserSelection = DailySelection(
        profiles: profiles,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 24)),
        remainingLikes: 0,
        hasUsedSuperLike: false,
        choicesRemaining: 0,
        choicesMade: 1,
        maxChoices: 1,
      );
      
      expect(freeUserSelection.canSelectMore, false);
      expect(freeUserSelection.isSelectionComplete, true);
      
      // Test premium user with remaining choices
      final premiumUserSelection = DailySelection(
        profiles: profiles,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 24)),
        remainingLikes: 0,
        hasUsedSuperLike: false,
        choicesRemaining: 1,
        choicesMade: 2,
        maxChoices: 3,
      );
      
      expect(premiumUserSelection.canSelectMore, true);
      expect(premiumUserSelection.isSelectionComplete, false);
    });
  });
}