import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/matching.dart';
import 'package:goldwen_app/features/matching/widgets/score_breakdown_card.dart';

void main() {
  group('ScoreBreakdownCard Widget Tests', () {
    testWidgets('should display all score components', (WidgetTester tester) async {
      final breakdown = ScoreBreakdown(
        personalityScore: 51.0,
        preferencesScore: 34.0,
        activityBonus: 8.0,
        responseRateBonus: 7.0,
        reciprocityBonus: 15.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreBreakdownCard(breakdown: breakdown),
          ),
        ),
      );

      // Check that the title is displayed
      expect(find.text('Détails du score'), findsOneWidget);

      // Check that base scores are displayed
      expect(find.text('Personnalité'), findsOneWidget);
      expect(find.text('Préférences'), findsOneWidget);

      // Check that bonus section is displayed
      expect(find.text('Bonus'), findsOneWidget);
      expect(find.text('Activité'), findsOneWidget);
      expect(find.text('Taux de réponse'), findsOneWidget);
      expect(find.text('Réciprocité'), findsOneWidget);

      // Check that summary is displayed
      expect(find.text('Score de base'), findsOneWidget);
      expect(find.text('Total bonus'), findsOneWidget);
    });

    testWidgets('should display correct score values', (WidgetTester tester) async {
      final breakdown = ScoreBreakdown(
        personalityScore: 51.0,
        preferencesScore: 34.0,
        activityBonus: 8.0,
        responseRateBonus: 7.0,
        reciprocityBonus: 15.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreBreakdownCard(breakdown: breakdown),
          ),
        ),
      );

      // Check personality score
      expect(find.text('51.0'), findsOneWidget);
      
      // Check preferences score
      expect(find.text('34.0'), findsOneWidget);

      // Check base score (51 + 34 = 85)
      expect(find.text('85.0'), findsOneWidget);

      // Check total bonuses (8 + 7 + 15 = 30)
      expect(find.text('30.0'), findsOneWidget);
    });

    testWidgets('should display positive bonuses with green color', (WidgetTester tester) async {
      final breakdown = ScoreBreakdown(
        personalityScore: 50.0,
        preferencesScore: 30.0,
        activityBonus: 10.0,
        responseRateBonus: 5.0,
        reciprocityBonus: 8.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreBreakdownCard(breakdown: breakdown),
          ),
        ),
      );

      // Check that positive bonuses are displayed with + prefix
      expect(find.text('+10.0'), findsOneWidget);
      expect(find.text('+5.0'), findsOneWidget);
      expect(find.text('+8.0'), findsOneWidget);
    });

    testWidgets('should display negative bonuses correctly', (WidgetTester tester) async {
      final breakdown = ScoreBreakdown(
        personalityScore: 50.0,
        preferencesScore: 30.0,
        activityBonus: -5.0,
        responseRateBonus: 7.0,
        reciprocityBonus: 10.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreBreakdownCard(breakdown: breakdown),
          ),
        ),
      );

      // Check that negative bonus is displayed with - prefix
      expect(find.text('-5.0'), findsOneWidget);
    });

    testWidgets('should have upward arrows for positive bonuses', (WidgetTester tester) async {
      final breakdown = ScoreBreakdown(
        personalityScore: 50.0,
        preferencesScore: 30.0,
        activityBonus: 10.0,
        responseRateBonus: 5.0,
        reciprocityBonus: 8.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreBreakdownCard(breakdown: breakdown),
          ),
        ),
      );

      // Find upward arrow icons
      expect(find.byIcon(Icons.arrow_upward), findsAtLeastNWidgets(3));
    });

    testWidgets('should have downward arrow for negative bonus', (WidgetTester tester) async {
      final breakdown = ScoreBreakdown(
        personalityScore: 50.0,
        preferencesScore: 30.0,
        activityBonus: -5.0,
        responseRateBonus: 0.0,
        reciprocityBonus: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreBreakdownCard(breakdown: breakdown),
          ),
        ),
      );

      // Find downward arrow icon
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });
  });
}
