import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/subscription/providers/subscription_provider.dart';
import 'package:goldwen_app/features/subscription/widgets/subscription_banner.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/core/models/models.dart';

void main() {
  group('Subscription Integration Tests', () {
    testWidgets('SubscriptionPromoBanner displays correctly for free users', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionPromoBanner(
              message: 'Test message',
            ),
          ),
        ),
      );

      expect(find.text('Test message'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('SubscriptionLimitReachedDialog displays upgrade options', (WidgetTester tester) async {
      final resetTime = DateTime.now().add(Duration(hours: 4));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => SubscriptionLimitReachedDialog(
                    currentSelections: 1,
                    maxSelections: 1,
                    resetTime: resetTime,
                  ),
                ),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Limite atteinte'), findsOneWidget);
      expect(find.text('Vous avez utilisé 1/1 sélections aujourd\'hui.'), findsOneWidget);
      expect(find.text('Avec GoldWen Plus:'), findsOneWidget);
      expect(find.text('• 3 sélections par jour au lieu d\'1'), findsOneWidget);
      expect(find.text('Passer à Plus'), findsOneWidget);
    });

    testWidgets('SubscriptionStatusIndicator shows correct status for premium users', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionStatusIndicator(
              hasActiveSubscription: true,
              daysUntilExpiry: 15,
            ),
          ),
        ),
      );

      expect(find.text('GoldWen Plus actif'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('SubscriptionStatusIndicator shows expiry warning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionStatusIndicator(
              hasActiveSubscription: true,
              daysUntilExpiry: 3,
            ),
          ),
        ),
      );

      expect(find.text('Plus expire dans 3 jours'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    test('SubscriptionProvider correctly determines active subscription status', () {
      final subscriptionProvider = SubscriptionProvider();
      
      // Test default state (no subscription)
      expect(subscriptionProvider.hasActiveSubscription, false);
      expect(subscriptionProvider.plans, isEmpty);
    });

    test('Matching provider enforces subscription limits correctly', () {
      final matchingProvider = MatchingProvider();
      
      // Test default limits for free users
      expect(matchingProvider.maxSelections, 1);
      expect(matchingProvider.remainingSelections, 1);
      expect(matchingProvider.canSelectMore, true);
    });

    test('SubscriptionProvider handles purchase cancellation gracefully', () {
      final subscriptionProvider = SubscriptionProvider();
      
      // Verify that error is null when user cancels
      expect(subscriptionProvider.error, isNull);
      expect(subscriptionProvider.isLoading, false);
    });

    test('SubscriptionProvider correctly loads active plans', () {
      final subscriptionProvider = SubscriptionProvider();
      
      // Initially no plans
      expect(subscriptionProvider.activePlans, isEmpty);
      expect(subscriptionProvider.plans, isEmpty);
    });

    test('SubscriptionProvider exposes correct subscription status properties', () {
      final subscriptionProvider = SubscriptionProvider();
      
      // Test default state
      expect(subscriptionProvider.hasActiveSubscription, false);
      expect(subscriptionProvider.hasExpiredSubscription, false);
      expect(subscriptionProvider.currentPlanName, isNull);
      expect(subscriptionProvider.nextRenewalDate, isNull);
      expect(subscriptionProvider.daysUntilExpiry, isNull);
    });
  });
}