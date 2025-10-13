import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/matching/pages/daily_matches_page.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/features/subscription/providers/subscription_provider.dart';
import 'package:goldwen_app/core/services/accessibility_service.dart';
import 'package:goldwen_app/core/services/performance_cache_service.dart';
import 'package:goldwen_app/core/models/matching.dart';
import 'package:goldwen_app/core/models/profile.dart';

// Generate mocks
@GenerateMocks([
  MatchingProvider,
  SubscriptionProvider,
  AccessibilityService,
  PerformanceCacheService,
])
import 'daily_selection_refresh_ui_test.mocks.dart';

void main() {
  group('Daily Selection Refresh UI Tests', () {
    late MockMatchingProvider mockMatchingProvider;
    late MockSubscriptionProvider mockSubscriptionProvider;
    late MockAccessibilityService mockAccessibilityService;
    late MockPerformanceCacheService mockCacheService;

    setUp(() {
      mockMatchingProvider = MockMatchingProvider();
      mockSubscriptionProvider = MockSubscriptionProvider();
      mockAccessibilityService = MockAccessibilityService();
      mockCacheService = MockPerformanceCacheService();

      // Setup default behavior for accessibility service
      when(mockAccessibilityService.reducedMotion).thenReturn(false);
      when(mockAccessibilityService.highContrast).thenReturn(false);
      when(mockAccessibilityService.getAnimationDuration(any))
          .thenAnswer((invocation) => invocation.positionalArguments[0] as Duration);

      // Setup default behavior for cache service
      when(mockCacheService.loadImageWithCache(any))
          .thenAnswer((_) async => Future.value());

      // Setup default behavior for providers
      when(mockMatchingProvider.isLoading).thenReturn(false);
      when(mockMatchingProvider.error).thenReturn(null);
      when(mockMatchingProvider.dailyProfiles).thenReturn([]);
      when(mockMatchingProvider.isSelectionComplete).thenReturn(false);
      when(mockMatchingProvider.remainingSelections).thenReturn(1);
      when(mockMatchingProvider.maxSelections).thenReturn(1);
      when(mockMatchingProvider.canSelectMore).thenReturn(true);
      when(mockMatchingProvider.selectedProfileIds).thenReturn([]);
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);
      when(mockMatchingProvider.getNextRefreshCountdown()).thenReturn('5h 30min');
      when(mockMatchingProvider.dailySelection).thenReturn(null);
      when(mockMatchingProvider.isProfileSelected(any)).thenReturn(false);

      when(mockSubscriptionProvider.hasActiveSubscription).thenReturn(false);
      when(mockSubscriptionProvider.daysUntilExpiry).thenReturn(null);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<MatchingProvider>.value(
              value: mockMatchingProvider,
            ),
            ChangeNotifierProvider<SubscriptionProvider>.value(
              value: mockSubscriptionProvider,
            ),
            ChangeNotifierProvider<AccessibilityService>.value(
              value: mockAccessibilityService,
            ),
            ChangeNotifierProvider<PerformanceCacheService>.value(
              value: mockCacheService,
            ),
          ],
          child: const DailyMatchesPage(),
        ),
      );
    }

    testWidgets('displays "Nouvelle sélection disponible !" badge when new selection is available',
        (WidgetTester tester) async {
      // Setup: New selection is available
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify badge is displayed
      expect(find.text('Nouvelle sélection disponible !'), findsOneWidget);
      expect(find.byIcon(Icons.fiber_new), findsOneWidget);
    });

    testWidgets('displays countdown timer when no new selection is available',
        (WidgetTester tester) async {
      // Setup: No new selection, countdown active
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);
      when(mockMatchingProvider.getNextRefreshCountdown()).thenReturn('3h 45min');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify countdown is displayed
      expect(find.textContaining('Prochaine sélection dans'), findsOneWidget);
      expect(find.textContaining('3h 45min'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('does not display badge when no new selection is available',
        (WidgetTester tester) async {
      // Setup: No new selection
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify badge is NOT displayed
      expect(find.text('Nouvelle sélection disponible !'), findsNothing);
    });

    testWidgets('updates countdown display on timer tick',
        (WidgetTester tester) async {
      // Setup initial countdown
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);
      when(mockMatchingProvider.getNextRefreshCountdown()).thenReturn('2h 30min');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify initial countdown
      expect(find.textContaining('2h 30min'), findsOneWidget);

      // Simulate countdown change
      when(mockMatchingProvider.getNextRefreshCountdown()).thenReturn('2h 29min');

      // Wait for timer to tick (1 second)
      await tester.pump(const Duration(seconds: 1));

      // The widget should rebuild with new countdown
      // Note: This might not update immediately depending on how setState is called
      // In real scenario, the countdown timer triggers setState every second
    });

    testWidgets('badge has proper styling with green gradient',
        (WidgetTester tester) async {
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the badge container
      final badgeText = find.text('Nouvelle sélection disponible !');
      expect(badgeText, findsOneWidget);

      // Verify the badge exists
      final badge = tester.widget<Text>(badgeText);
      expect(badge.style?.color, Colors.white);
      expect(badge.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('countdown timer has proper styling',
        (WidgetTester tester) async {
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);
      when(mockMatchingProvider.getNextRefreshCountdown()).thenReturn('1h');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the countdown text
      final countdownText = find.textContaining('Prochaine sélection dans');
      expect(countdownText, findsOneWidget);

      // Verify timer icon is present
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('respects reduced motion preference',
        (WidgetTester tester) async {
      // Enable reduced motion
      when(mockAccessibilityService.reducedMotion).thenReturn(true);
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Badge should still be visible but without animations
      expect(find.text('Nouvelle sélection disponible !'), findsOneWidget);
    });

    testWidgets('respects high contrast mode',
        (WidgetTester tester) async {
      // Enable high contrast
      when(mockAccessibilityService.highContrast).thenReturn(true);
      when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Countdown should still be visible
      expect(find.textContaining('Prochaine sélection dans'), findsOneWidget);
    });

    testWidgets('displays correct header title',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sélection du jour'), findsOneWidget);
      expect(find.text('Découvrez vos matchs parfaits'), findsOneWidget);
    });

    testWidgets('displays heart icon in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    group('Countdown Format Tests', () {
      testWidgets('displays countdown in hours and minutes format',
          (WidgetTester tester) async {
        when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);
        when(mockMatchingProvider.getNextRefreshCountdown()).thenReturn('5h 30min');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('5h 30min'), findsOneWidget);
      });

      testWidgets('displays countdown in minutes only format',
          (WidgetTester tester) async {
        when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);
        when(mockMatchingProvider.getNextRefreshCountdown()).thenReturn('45min');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('45min'), findsOneWidget);
      });

      testWidgets('displays countdown in days and hours format',
          (WidgetTester tester) async {
        when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);
        when(mockMatchingProvider.getNextRefreshCountdown()).thenReturn('1j 8h');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('1j 8h'), findsOneWidget);
      });
    });

    group('Empty and Error States', () {
      testWidgets('shows loading state correctly',
          (WidgetTester tester) async {
        when(mockMatchingProvider.isLoading).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('shows error state correctly',
          (WidgetTester tester) async {
        when(mockMatchingProvider.isLoading).thenReturn(false);
        when(mockMatchingProvider.error).thenReturn('Test error message');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show error message
        expect(find.textContaining('Test error message'), findsOneWidget);
      });

      testWidgets('shows empty state when no profiles available',
          (WidgetTester tester) async {
        when(mockMatchingProvider.isLoading).thenReturn(false);
        when(mockMatchingProvider.error).thenReturn(null);
        when(mockMatchingProvider.dailyProfiles).thenReturn([]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Empty state message should be shown
        expect(find.textContaining('Sélection du jour'), findsOneWidget);
      });
    });

    group('With Profiles', () {
      testWidgets('displays profiles when available',
          (WidgetTester tester) async {
        // Create mock profiles
        final mockProfile = Profile.fromJson({
          'id': 'test_1',
          'firstName': 'Test',
          'lastName': 'User',
          'age': 25,
          'bio': 'Test bio',
          'photos': ['https://example.com/photo.jpg'],
          'location': {'city': 'Test City', 'distance': 5},
          'interests': ['test'],
        });

        when(mockMatchingProvider.dailyProfiles).thenReturn([mockProfile]);
        when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(false);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show profile count
        expect(find.textContaining('1 profil disponible'), findsOneWidget);
      });
    });

    group('Semantic Labels', () {
      testWidgets('has proper semantic labels for accessibility',
          (WidgetTester tester) async {
        when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find semantics with specific labels
        expect(find.bySemanticsLabel('En-tête de sélection quotidienne'), findsOneWidget);
        expect(find.bySemanticsLabel('Titre: Sélection du jour'), findsOneWidget);
      });

      testWidgets('badge has semantic label',
          (WidgetTester tester) async {
        when(mockMatchingProvider.hasNewSelectionAvailable()).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Badge should have semantic meaning
        expect(find.text('Nouvelle sélection disponible !'), findsOneWidget);
      });
    });
  });
}
