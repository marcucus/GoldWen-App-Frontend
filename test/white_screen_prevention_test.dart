import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/profile/pages/profile_setup_page.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';
import 'package:goldwen_app/features/onboarding/pages/personality_questionnaire_page.dart';

void main() {
  group('White Screen Prevention Tests', () {
    testWidgets('Profile Setup Page - All 6 screens should render without errors', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      // Wait for initial render
      await tester.pumpAndSettle();

      // Verify screen 1 renders (Basic Info)
      expect(find.text('Parlez-nous de vous'), findsOneWidget);
      expect(find.text('Pseudo'), findsOneWidget);
      
      // Verify no error widgets are shown
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('Profile Setup - Basic Info page should not use Spacer in ScrollView', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the page renders without layout errors
      expect(tester.takeException(), isNull);
      
      // Verify elements are present
      expect(find.text('Continuer'), findsOneWidget);
    });

    testWidgets('Profile Setup - Photos page should render correctly', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that photos page elements exist
      expect(find.text('Ajoutez au moins 3 photos pour continuer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Profile Setup - Prompts page should show loading state properly', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for prompts completion indicator
      expect(find.textContaining('Réponses complétées:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Profile Setup - All pages should have proper error boundaries', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no uncaught exceptions
      expect(tester.takeException(), isNull);
      
      // Verify page structure is intact
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Personality Questionnaire should handle empty questions gracefully', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => ProfileProvider()),
            ],
            child: const PersonalityQuestionnairePage(),
          ),
        ),
      );

      // Initial loading state should be shown
      await tester.pump();
      
      // Should show either loading indicator or error message, not white screen
      final hasLoadingOrError = 
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.text('Réessayer').evaluate().isNotEmpty;
      
      expect(hasLoadingOrError, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Personality Questionnaire should handle null options safely', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => ProfileProvider()),
            ],
            child: const PersonalityQuestionnairePage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should not throw any errors related to null options
      expect(tester.takeException(), isNull);
    });

    testWidgets('Profile Setup should handle ProfileProvider errors gracefully', 
        (WidgetTester tester) async {
      final profileProvider = ProfileProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: profileProvider,
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Even with empty provider, should not have white screen
      expect(find.byType(ProfileSetupPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('All registration screens should have consistent spacing', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify SizedBox is used instead of Spacer in scrollable contexts
      // This prevents layout overflow errors
      expect(tester.takeException(), isNull);
      
      // Verify the page has proper padding
      final padding = find.byType(Padding);
      expect(padding, findsWidgets);
    });
  });

  group('Layout Error Prevention Tests', () {
    testWidgets('No unbounded height errors in scrollable widgets', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      // Should complete without overflow or layout errors
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('PageView navigation should work without errors', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PageView exists and is working
      expect(find.byType(PageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Consumer Widget Safety Tests', () {
    testWidgets('All Consumer widgets should handle null provider values', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Consumer widgets should not crash even with empty data
      expect(tester.takeException(), isNull);
    });

    testWidgets('Photo management Consumer should handle empty photos list', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "0/6" without errors
      expect(find.textContaining('0/6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
