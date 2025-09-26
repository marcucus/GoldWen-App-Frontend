import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/core/models/models.dart';

void main() {
  group('History Feature Tests', () {
    late MatchingProvider matchingProvider;

    setUp(() {
      matchingProvider = MatchingProvider();
    });

    test('initial history state is correct', () {
      expect(matchingProvider.historyItems, isEmpty);
      expect(matchingProvider.hasMoreHistory, true);
      expect(matchingProvider.isLoading, false);
      expect(matchingProvider.error, null);
    });

    test('HistoryItem model parsing is correct', () {
      final json = {
        'date': '2024-01-15',
        'choices': [
          {
            'targetUserId': 'user-123',
            'targetUser': {
              'name': 'Test User',
              'photos': ['photo1.jpg']
            },
            'choice': 'like',
            'chosenAt': '2024-01-15T14:30:00Z',
            'isMatch': true
          }
        ]
      };

      final historyItem = HistoryItem.fromJson(json);
      
      expect(historyItem.date, '2024-01-15');
      expect(historyItem.choices.length, 1);
      
      final choice = historyItem.choices.first;
      expect(choice.targetUserId, 'user-123');
      expect(choice.choice, 'like');
      expect(choice.isMatch, true);
      expect(choice.chosenAt, DateTime.parse('2024-01-15T14:30:00Z'));
    });

    test('PaginatedHistory model parsing is correct', () {
      final json = {
        'data': [
          {
            'date': '2024-01-15',
            'choices': []
          }
        ],
        'pagination': {
          'page': 1,
          'limit': 20,
          'total': 1,
          'hasMore': false
        }
      };

      final paginatedHistory = PaginatedHistory.fromJson(json);
      
      expect(paginatedHistory.data.length, 1);
      expect(paginatedHistory.page, 1);
      expect(paginatedHistory.limit, 20);
      expect(paginatedHistory.total, 1);
      expect(paginatedHistory.hasMore, false);
    });

    test('HistoryChoice handles different targetUser formats', () {
      // Test with Map format
      final jsonMap = {
        'targetUserId': 'user-123',
        'targetUser': {
          'name': 'Test User',
          'photos': ['photo1.jpg']
        },
        'choice': 'like',
        'chosenAt': '2024-01-15T14:30:00Z',
        'isMatch': false
      };

      final choiceMap = HistoryChoice.fromJson(jsonMap);
      expect(choiceMap.targetUser, isA<Map<String, dynamic>>());

      // Test with String format (edge case)
      final jsonString = {
        'targetUserId': 'user-456',
        'targetUser': 'Test User Name',
        'choice': 'pass',
        'chosenAt': '2024-01-15T15:30:00Z',
        'isMatch': false
      };

      final choiceString = HistoryChoice.fromJson(jsonString);
      expect(choiceString.targetUser, isA<String>());
    });

    test('choice types are properly recognized', () {
      final likeChoice = {
        'targetUserId': 'user-1',
        'targetUser': {'name': 'User 1'},
        'choice': 'like',
        'chosenAt': '2024-01-15T14:30:00Z',
        'isMatch': true
      };

      final passChoice = {
        'targetUserId': 'user-2',
        'targetUser': {'name': 'User 2'},
        'choice': 'pass',
        'chosenAt': '2024-01-15T14:31:00Z',
        'isMatch': false
      };

      final choice1 = HistoryChoice.fromJson(likeChoice);
      final choice2 = HistoryChoice.fromJson(passChoice);

      expect(choice1.choice, 'like');
      expect(choice1.isMatch, true);
      
      expect(choice2.choice, 'pass');
      expect(choice2.isMatch, false);
    });
  });
}