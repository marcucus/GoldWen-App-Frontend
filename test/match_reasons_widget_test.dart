import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/matching.dart';
import 'package:goldwen_app/features/matching/widgets/match_reasons_widget.dart';

void main() {
  group('MatchReasonsWidget Widget Tests', () {
    testWidgets('should display all match reasons', (WidgetTester tester) async {
      final matchReasons = [
        MatchReason(
          category: 'personality',
          description: 'Vous partagez des traits de personnalité similaires',
          impact: 0.15,
        ),
        MatchReason(
          category: 'interests',
          description: 'Intérêts communs en musique et voyage',
          impact: 0.12,
        ),
        MatchReason(
          category: 'values',
          description: 'Valeurs et objectifs de vie alignés',
          impact: 0.18,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchReasonsWidget(matchReasons: matchReasons),
          ),
        ),
      );

      // Check that all descriptions are displayed
      expect(find.text('Vous partagez des traits de personnalité similaires'), findsOneWidget);
      expect(find.text('Intérêts communs en musique et voyage'), findsOneWidget);
      expect(find.text('Valeurs et objectifs de vie alignés'), findsOneWidget);
    });

    testWidgets('should display category labels in French', (WidgetTester tester) async {
      final matchReasons = [
        MatchReason(
          category: 'personality',
          description: 'Test personality',
          impact: 0.15,
        ),
        MatchReason(
          category: 'interests',
          description: 'Test interests',
          impact: 0.12,
        ),
        MatchReason(
          category: 'values',
          description: 'Test values',
          impact: 0.18,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchReasonsWidget(matchReasons: matchReasons),
          ),
        ),
      );

      // Check that French labels are displayed
      expect(find.text('Personnalité'), findsOneWidget);
      expect(find.text('Intérêts'), findsOneWidget);
      expect(find.text('Valeurs'), findsOneWidget);
    });

    testWidgets('should display impact percentages correctly', (WidgetTester tester) async {
      final matchReasons = [
        MatchReason(
          category: 'personality',
          description: 'Test',
          impact: 0.15,
        ),
        MatchReason(
          category: 'interests',
          description: 'Test',
          impact: 0.12,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchReasonsWidget(matchReasons: matchReasons),
          ),
        ),
      );

      // Check impact percentages (0.15 = 15%, 0.12 = 12%)
      expect(find.text('+15%'), findsOneWidget);
      expect(find.text('+12%'), findsOneWidget);
    });

    testWidgets('should handle negative impact', (WidgetTester tester) async {
      final matchReasons = [
        MatchReason(
          category: 'communication',
          description: 'Différent style de communication',
          impact: -0.05,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchReasonsWidget(matchReasons: matchReasons),
          ),
        ),
      );

      // Check negative impact
      expect(find.text('-5%'), findsOneWidget);
    });

    testWidgets('should display appropriate icons for categories', (WidgetTester tester) async {
      final matchReasons = [
        MatchReason(
          category: 'personality',
          description: 'Test personality',
          impact: 0.15,
        ),
        MatchReason(
          category: 'interests',
          description: 'Test interests',
          impact: 0.12,
        ),
        MatchReason(
          category: 'activity',
          description: 'Test activity',
          impact: 0.08,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchReasonsWidget(matchReasons: matchReasons),
          ),
        ),
      );

      // Check that icons are displayed
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byIcon(Icons.interests), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('should render empty list without errors', (WidgetTester tester) async {
      final matchReasons = <MatchReason>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchReasonsWidget(matchReasons: matchReasons),
          ),
        ),
      );

      // Widget should render without errors even with empty list
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should handle all supported categories', (WidgetTester tester) async {
      final matchReasons = [
        MatchReason(category: 'personality', description: 'Test', impact: 0.1),
        MatchReason(category: 'interests', description: 'Test', impact: 0.1),
        MatchReason(category: 'values', description: 'Test', impact: 0.1),
        MatchReason(category: 'lifestyle', description: 'Test', impact: 0.1),
        MatchReason(category: 'communication', description: 'Test', impact: 0.1),
        MatchReason(category: 'activity', description: 'Test', impact: 0.1),
        MatchReason(category: 'reciprocity', description: 'Test', impact: 0.1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchReasonsWidget(matchReasons: matchReasons),
            ),
          ),
        ),
      );

      // All categories should render
      expect(find.text('Personnalité'), findsOneWidget);
      expect(find.text('Intérêts'), findsOneWidget);
      expect(find.text('Valeurs'), findsOneWidget);
      expect(find.text('Mode de vie'), findsOneWidget);
      expect(find.text('Communication'), findsOneWidget);
      expect(find.text('Activité'), findsOneWidget);
      expect(find.text('Réciprocité'), findsOneWidget);
    });
  });
}
