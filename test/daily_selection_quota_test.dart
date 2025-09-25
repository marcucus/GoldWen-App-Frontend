import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/matching.dart';
import 'package:goldwen_app/core/models/subscription.dart';

void main() {
  group('Daily Selection Quota Logic', () {
    test('DailySelection model correctly parses quota metadata', () {
      // Test with metadata wrapper
      final json1 = {
        'profiles': [],
        'metadata': {
          'choicesRemaining': 2,
          'choicesMade': 1,
          'maxChoices': 3,
        }
      };
      
      final selection1 = DailySelection.fromJson(json1);
      expect(selection1.choicesRemaining, 2);
      expect(selection1.choicesMade, 1);
      expect(selection1.maxChoices, 3);
      expect(selection1.canSelectMore, true);
      expect(selection1.isSelectionComplete, false);
      
      // Test with direct fields (fallback)
      final json2 = {
        'profiles': [],
        'choicesRemaining': 0,
        'choicesMade': 3,
        'maxChoices': 3,
      };
      
      final selection2 = DailySelection.fromJson(json2);
      expect(selection2.choicesRemaining, 0);
      expect(selection2.choicesMade, 3);
      expect(selection2.maxChoices, 3);
      expect(selection2.canSelectMore, false);
      expect(selection2.isSelectionComplete, true);
    });

    test('SubscriptionUsage model correctly parses daily choices data', () {
      final json = {
        'dailyChoices': {
          'used': 1,
          'limit': 3,
          'remaining': 2,
          'resetTime': '2023-12-01T12:00:00Z'
        },
        'subscription': {
          'tier': 'premium',
          'isActive': true
        }
      };
      
      final usage = SubscriptionUsage.fromJson(json);
      expect(usage.dailyChoicesUsed, 1);
      expect(usage.dailyChoicesLimit, 3);
      expect(usage.remainingChoices, 2);
      expect(usage.hasRemainingChoices, true);
    });

    test('Handles missing quota fields gracefully', () {
      // Test empty/missing data
      final json = {'profiles': []};
      
      final selection = DailySelection.fromJson(json);
      expect(selection.choicesRemaining, 1); // Default for free users
      expect(selection.choicesMade, 0);
      expect(selection.maxChoices, 1);
      expect(selection.canSelectMore, true);
      expect(selection.isSelectionComplete, false);
    });
  });
}