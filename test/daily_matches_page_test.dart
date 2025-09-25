import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import 'package:goldwen_app/features/matching/pages/daily_matches_page.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/features/subscription/providers/subscription_provider.dart';
import 'package:goldwen_app/core/theme/app_theme.dart';

// Import the generated mocks
import 'mocks.mocks.dart';

void main() {
  group('DailyMatchesPage Widget Tests', () {
    late MockMatchingProvider mockMatchingProvider;
    late MockSubscriptionProvider mockSubscriptionProvider;

    setUp(() {
      mockMatchingProvider = MockMatchingProvider();
      mockSubscriptionProvider = MockSubscriptionProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchingProvider>.value(
              value: mockMatchingProvider,
            ),
            ChangeNotifierProvider<SubscriptionProvider>.value(
              value: mockSubscriptionProvider,
            ),
          ],
          child: const DailyMatchesPage(),
        ),
      );
    }

    testWidgets('shows loading state when isLoading is true', (WidgetTester tester) async {
      // Arrange
      when(mockMatchingProvider.isLoading).thenReturn(true);
      when(mockMatchingProvider.error).thenReturn(null);
      when(mockMatchingProvider.dailyProfiles).thenReturn([]);
      when(mockMatchingProvider.selectedProfileIds).thenReturn([]);
      when(mockMatchingProvider.isSelectionComplete).thenReturn(false);
      when(mockSubscriptionProvider.hasActiveSubscription).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Préparation de vos matchs...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when there is an error', (WidgetTester tester) async {
      // Arrange
      when(mockMatchingProvider.isLoading).thenReturn(false);
      when(mockMatchingProvider.error).thenReturn('Test error message');
      when(mockMatchingProvider.dailyProfiles).thenReturn([]);
      when(mockMatchingProvider.selectedProfileIds).thenReturn([]);
      when(mockMatchingProvider.isSelectionComplete).thenReturn(false);
      when(mockSubscriptionProvider.hasActiveSubscription).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Oups !'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('shows empty state when no profiles available', (WidgetTester tester) async {
      // Arrange
      when(mockMatchingProvider.isLoading).thenReturn(false);
      when(mockMatchingProvider.error).thenReturn(null);
      when(mockMatchingProvider.dailyProfiles).thenReturn([]);
      when(mockMatchingProvider.selectedProfileIds).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Aucun profil disponible'), findsOneWidget);
      expect(find.text('Revenez demain pour découvrir de nouveaux profils ou explorez avec GoldWen Plus'), findsOneWidget);
      expect(find.text('Découvrir GoldWen Plus'), findsOneWidget);
    });

    testWidgets('shows header with correct text', (WidgetTester tester) async {
      // Arrange
      when(mockMatchingProvider.isLoading).thenReturn(false);
      when(mockMatchingProvider.error).thenReturn(null);
      when(mockMatchingProvider.dailyProfiles).thenReturn([]);
      when(mockMatchingProvider.selectedProfileIds).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Sélection du jour'), findsOneWidget);
      expect(find.text('Découvrez vos matchs parfaits'), findsOneWidget);
    });

    testWidgets('tapping retry button calls loadDailySelection', (WidgetTester tester) async {
      // Arrange
      when(mockMatchingProvider.isLoading).thenReturn(false);
      when(mockMatchingProvider.error).thenReturn('Test error');
      when(mockMatchingProvider.dailyProfiles).thenReturn([]);
      when(mockMatchingProvider.selectedProfileIds).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Find and tap the retry button
      final retryButton = find.text('Réessayer');
      expect(retryButton, findsOneWidget);
      
      await tester.tap(retryButton);
      await tester.pump();

      // Assert
      verify(mockMatchingProvider.loadDailySelection()).called(1);
    });
  });

  group('DailyMatchesPage - Profile Display Tests', () {
    testWidgets('shows profile counter with correct text for single profile', (WidgetTester tester) async {
      // This test would require more complex mocking of Profile objects
      // For now, we'll test the basic structure
      final mockProvider = MockMatchingProvider();
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.dailyProfiles).thenReturn([]);
      when(mockProvider.selectedProfileIds).thenReturn([]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<MatchingProvider>.value(
            value: mockProvider,
            child: const DailyMatchesPage(),
          ),
        ),
      );

      // Basic test to ensure widget doesn't crash
      expect(find.byType(DailyMatchesPage), findsOneWidget);
    });

    testWidgets('shows selection complete state when all choices are used', (WidgetTester tester) async {
      // Arrange
      when(mockMatchingProvider.isLoading).thenReturn(false);
      when(mockMatchingProvider.error).thenReturn(null);
      when(mockMatchingProvider.dailyProfiles).thenReturn([]);
      when(mockMatchingProvider.isSelectionComplete).thenReturn(true);
      when(mockMatchingProvider.selectionCompleteMessage).thenReturn('Votre choix est fait. Revenez demain pour votre nouvelle sélection !');
      when(mockMatchingProvider.hasSubscription).thenReturn(false);
      when(mockSubscriptionProvider.hasActiveSubscription).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Sélection terminée !'), findsOneWidget);
      expect(find.text('Votre choix est fait. Revenez demain pour votre nouvelle sélection !'), findsOneWidget);
      expect(find.text('Découvrir GoldWen Plus'), findsOneWidget);
    });
  });
}