import 'package:goldwen_app/core/services/accessibility_service.dart';
import 'package:goldwen_app/core/services/performance_cache_service.dart';
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
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);
      when(mockMatchingProvider.getNextRefreshCountdown()).thenReturn('5h');
      when(mockMatchingProvider.loadDailySelection()).thenAnswer((_) async {});
      when(mockMatchingProvider.dailyProfiles).thenReturn([]);
      when(mockMatchingProvider.isSelectionComplete).thenReturn(false);
      when(mockSubscriptionProvider.hasActiveSubscription).thenReturn(false);
    });

    Widget createTestWidget() {
      return MaterialApp(
        builder: (context, child) => MultiProvider(providers: [ChangeNotifierProvider(create: (_) => AccessibilityService()), ChangeNotifierProvider(create: (_) => PerformanceCacheService())], child: child!),
        theme: AppTheme.lightTheme(),
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
      expect(find.byType(SingleChildScrollView), findsOneWidget);
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
      verify(mockMatchingProvider.loadDailySelection()).called(2);
    });
  });

}
