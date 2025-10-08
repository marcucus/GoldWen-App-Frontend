import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/matching.dart';
import 'package:goldwen_app/core/models/profile.dart';

void main() {
  group('Daily Quota UI Logic', () {
    test('Reset time formatting shows hours and minutes correctly', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final resetTime = DateTime(2024, 1, 15, 14, 45);
      
      final difference = resetTime.difference(now);
      expect(difference.inHours, 4);
      expect(difference.inMinutes % 60, 15);
      
      // Expected format: "4h15"
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      final formatted = '${hours}h${minutes > 0 ? minutes.toString().padLeft(2, '0') : ''}';
      expect(formatted, '4h15');
    });

    test('Reset time formatting shows minutes only when less than 1 hour', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final resetTime = DateTime(2024, 1, 15, 11, 15);
      
      final difference = resetTime.difference(now);
      expect(difference.inHours, 0);
      expect(difference.inMinutes, 45);
      
      final formatted = '${difference.inMinutes}min';
      expect(formatted, '45min');
    });

    test('Reset time formatting shows tomorrow with time for next day', () {
      final resetTime = DateTime(2024, 1, 16, 12, 0);
      
      final hour = resetTime.hour;
      final minute = resetTime.minute;
      final formatted = 'demain à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      expect(formatted, 'demain à 12:00');
    });

    test('DailySelection with refreshTime can be accessed for UI display', () {
      final refreshTime = DateTime(2024, 1, 16, 12, 0);
      final selection = DailySelection(
        profiles: [],
        generatedAt: DateTime(2024, 1, 15, 12, 0),
        expiresAt: DateTime(2024, 1, 16, 12, 0),
        remainingLikes: 10,
        hasUsedSuperLike: false,
        choicesRemaining: 0,
        choicesMade: 1,
        maxChoices: 1,
        refreshTime: refreshTime,
      );

      expect(selection.refreshTime, refreshTime);
      expect(selection.isSelectionComplete, true);
      expect(selection.canSelectMore, false);
    });

    test('Premium user selection has correct max choices', () {
      final selection = DailySelection(
        profiles: [],
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 1)),
        remainingLikes: 10,
        hasUsedSuperLike: false,
        choicesRemaining: 2,
        choicesMade: 1,
        maxChoices: 3,
        refreshTime: DateTime.now().add(Duration(days: 1)),
      );

      expect(selection.maxChoices, 3);
      expect(selection.choicesRemaining, 2);
      expect(selection.choicesMade, 1);
      expect(selection.canSelectMore, true);
      expect(selection.isSelectionComplete, false);
    });

    test('Free user reaches limit after 1 choice', () {
      final selection = DailySelection(
        profiles: [],
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 1)),
        remainingLikes: 10,
        hasUsedSuperLike: false,
        choicesRemaining: 0,
        choicesMade: 1,
        maxChoices: 1,
        refreshTime: DateTime.now().add(Duration(days: 1)),
      );

      expect(selection.maxChoices, 1);
      expect(selection.choicesRemaining, 0);
      expect(selection.choicesMade, 1);
      expect(selection.canSelectMore, false);
      expect(selection.isSelectionComplete, true);
    });

    test('Selection completion is based on choices made vs max choices', () {
      // Not complete - 2 out of 3 choices made
      final selection1 = DailySelection(
        profiles: [],
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 1)),
        remainingLikes: 10,
        hasUsedSuperLike: false,
        choicesRemaining: 1,
        choicesMade: 2,
        maxChoices: 3,
      );
      expect(selection1.isSelectionComplete, false);

      // Complete - 3 out of 3 choices made
      final selection2 = DailySelection(
        profiles: [],
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 1)),
        remainingLikes: 10,
        hasUsedSuperLike: false,
        choicesRemaining: 0,
        choicesMade: 3,
        maxChoices: 3,
      );
      expect(selection2.isSelectionComplete, true);
    });
  });
}
