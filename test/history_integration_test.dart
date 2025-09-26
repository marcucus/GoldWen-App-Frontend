import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/matching/pages/history_page.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/core/models/models.dart';
import 'package:provider/provider.dart';

void main() {
  group('History Page Integration Tests', () {
    late MatchingProvider mockProvider;

    setUp(() {
      mockProvider = MatchingProvider();
    });

    Widget createHistoryPage() {
      return MaterialApp(
        home: ChangeNotifierProvider<MatchingProvider>(
          create: (_) => mockProvider,
          child: const HistoryPage(),
        ),
      );
    }

    testWidgets('History page displays loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(createHistoryPage());
      
      // Should show loading indicator when no history items
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Historique'), findsOneWidget);
    });

    testWidgets('History page displays empty state when no history', (WidgetTester tester) async {
      await tester.pumpWidget(createHistoryPage());
      await tester.pumpAndSettle();
      
      // Should show empty state
      expect(find.text('Aucun historique'), findsOneWidget);
      expect(find.text('Votre historique de sélections apparaîtra ici une fois que vous aurez commencé à faire des choix.'), findsOneWidget);
      expect(find.text('Commencer les sélections'), findsOneWidget);
    });

    testWidgets('History page navigation elements work', (WidgetTester tester) async {
      await tester.pumpWidget(createHistoryPage());
      await tester.pumpAndSettle();
      
      // Should have back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      // Should have app bar title
      expect(find.text('Historique'), findsOneWidget);
    });

    testWidgets('History page handles refresh gesture', (WidgetTester tester) async {
      await tester.pumpWidget(createHistoryPage());
      await tester.pumpAndSettle();
      
      // Look for RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('History Models Validation', () {
    test('HistoryChoice correctly parses like choice with match', () {
      final json = {
        'targetUserId': 'user-123',
        'targetUser': {
          'name': 'John Doe',
          'photos': ['photo1.jpg', 'photo2.jpg']
        },
        'choice': 'like',
        'chosenAt': '2024-01-15T14:30:00.000Z',
        'isMatch': true
      };

      final choice = HistoryChoice.fromJson(json);
      
      expect(choice.targetUserId, 'user-123');
      expect(choice.choice, 'like');
      expect(choice.isMatch, true);
      expect(choice.chosenAt.year, 2024);
      expect(choice.chosenAt.month, 1);
      expect(choice.chosenAt.day, 15);
      
      final targetUser = choice.targetUser as Map<String, dynamic>;
      expect(targetUser['name'], 'John Doe');
      expect(targetUser['photos'], ['photo1.jpg', 'photo2.jpg']);
    });

    test('HistoryChoice correctly parses pass choice without match', () {
      final json = {
        'targetUserId': 'user-456',
        'targetUser': {
          'name': 'Jane Smith',
          'photos': ['photo3.jpg']
        },
        'choice': 'pass',
        'chosenAt': '2024-01-15T15:45:00.000Z',
        'isMatch': false
      };

      final choice = HistoryChoice.fromJson(json);
      
      expect(choice.targetUserId, 'user-456');
      expect(choice.choice, 'pass');
      expect(choice.isMatch, false);
      
      final targetUser = choice.targetUser as Map<String, dynamic>;
      expect(targetUser['name'], 'Jane Smith');
    });

    test('HistoryItem groups choices by date correctly', () {
      final json = {
        'date': '2024-01-15',
        'choices': [
          {
            'targetUserId': 'user-1',
            'targetUser': {'name': 'User 1'},
            'choice': 'like',
            'chosenAt': '2024-01-15T14:30:00.000Z',
            'isMatch': true
          },
          {
            'targetUserId': 'user-2',
            'targetUser': {'name': 'User 2'},
            'choice': 'pass',
            'chosenAt': '2024-01-15T15:00:00.000Z',
            'isMatch': false
          }
        ]
      };

      final historyItem = HistoryItem.fromJson(json);
      
      expect(historyItem.date, '2024-01-15');
      expect(historyItem.choices.length, 2);
      
      final firstChoice = historyItem.choices[0];
      expect(firstChoice.choice, 'like');
      expect(firstChoice.isMatch, true);
      
      final secondChoice = historyItem.choices[1];
      expect(secondChoice.choice, 'pass');
      expect(secondChoice.isMatch, false);
    });

    test('PaginatedHistory handles pagination correctly', () {
      final json = {
        'data': [
          {
            'date': '2024-01-15',
            'choices': []
          },
          {
            'date': '2024-01-14',
            'choices': []
          }
        ],
        'pagination': {
          'page': 1,
          'limit': 20,
          'total': 25,
          'hasMore': true
        }
      };

      final paginatedHistory = PaginatedHistory.fromJson(json);
      
      expect(paginatedHistory.data.length, 2);
      expect(paginatedHistory.page, 1);
      expect(paginatedHistory.limit, 20);
      expect(paginatedHistory.total, 25);
      expect(paginatedHistory.hasMore, true);
    });
  });
}