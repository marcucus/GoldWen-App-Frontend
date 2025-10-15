import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/profile/pages/profile_setup_page.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';

/// Tests to verify scroll functionality on all registration pages
void main() {
  group('ProfileSetupPage Scroll Tests', () {
    testWidgets('Basic Info page (1/6) should have SingleChildScrollView',
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

      // Find SingleChildScrollView on page 1/6
      final scrollView = find.descendant(
        of: find.byType(PageView),
        matching: find.byType(SingleChildScrollView),
      );
      
      // Should find at least one SingleChildScrollView (the basic info page)
      expect(scrollView, findsWidgets);
    });

    testWidgets('Photos page (2/6) should be scrollable',
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

      // Navigate to photos page (index 1)
      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.controller.jumpToPage(1);
      await tester.pumpAndSettle();

      // Verify SingleChildScrollView exists on photos page
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsWidgets);

      // Verify photos page title
      expect(find.text('Ajoutez vos photos'), findsOneWidget);
    });

    testWidgets('Media page (3/6) should be scrollable',
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

      // Navigate to media page (index 2)
      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.controller.jumpToPage(2);
      await tester.pumpAndSettle();

      // Verify SingleChildScrollView exists on media page
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsWidgets);

      // Verify media page title
      expect(find.text('Médias Audio/Vidéo (Optionnel)'), findsOneWidget);
    });

    testWidgets('Validation page (5/6) should be scrollable',
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

      // Navigate to validation page (index 4)
      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.controller.jumpToPage(4);
      await tester.pumpAndSettle();

      // Verify SingleChildScrollView exists on validation page
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsWidgets);

      // Verify validation page title
      expect(find.text('Validation du profil'), findsOneWidget);
    });

    testWidgets('Review page (6/6) should be scrollable',
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

      // Navigate to review page (index 5)
      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.controller.jumpToPage(5);
      await tester.pumpAndSettle();

      // Verify SingleChildScrollView exists on review page
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsWidgets);

      // Verify review page title
      expect(find.text('Parfait !'), findsOneWidget);
    });

    testWidgets('No Expanded widgets inside SingleChildScrollView',
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

      // Test photos page (2/6) - should not have Expanded in ScrollView
      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.controller.jumpToPage(1);
      await tester.pumpAndSettle();

      // This test ensures no layout exceptions occur
      expect(tester.takeException(), isNull);

      // Navigate to media page (3/6)
      pageView.controller.jumpToPage(2);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Navigate to validation page (5/6)
      pageView.controller.jumpToPage(4);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Navigate to review page (6/6)
      pageView.controller.jumpToPage(5);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('All pages should render without overflow errors',
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

      // Test all pages
      final pageView = tester.widget<PageView>(find.byType(PageView));
      
      for (int i = 0; i < 6; i++) {
        pageView.controller.jumpToPage(i);
        await tester.pumpAndSettle();
        
        // No exceptions should occur
        expect(tester.takeException(), isNull);
      }
    });
  });
}
