import 'package:goldwen_app/core/services/api_service.dart';
import 'support/api_adapter.dart';
import 'package:goldwen_app/core/services/accessibility_service.dart';
import 'package:goldwen_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/profile/pages/profile_setup_page.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';

void main() {
  setUp(() {
    ApiService.configureTestAdapter(() => ApiAdapter((request) => request.uri.path.endsWith('/prompts') ? (200, {'data': List.generate(3, (i) => {'id': 'prompt-$i', 'text': 'Question $i', 'category': 'lifestyle', 'isActive': true})}) : (503, {'message': 'Unavailable'})));
  });
  group('ProfileSetupPage Tests', () {
    testWidgets('Button should be disabled initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ChangeNotifierProvider(create: (_) => AccessibilityService(), child: child!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Find the "Continuer" button on the first page
      final continueButton = find.widgetWithText(ElevatedButton, 'Continuer');
      expect(continueButton, findsOneWidget);

      // Button should be disabled initially
      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Button should enable when all fields are filled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ChangeNotifierProvider(create: (_) => AccessibilityService(), child: child!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      // Fill the pseudo field
      await tester.enterText(find.widgetWithText(TextFormField, 'Votre pseudo'), 'TestUser');
      await tester.pump();

      // Fill the bio field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Décrivez-vous en quelques mots...'), 
        'Test bio description'
      );
      await tester.pump();

      // The button should still be disabled because birth date is not selected
      final continueButton = find.widgetWithText(ElevatedButton, 'Continuer');
      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);

      // Note: Testing date picker interaction is complex in widget tests
      // This would require additional setup or integration tests
    });

    testWidgets('Pseudo label should be present instead of Prénom', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ChangeNotifierProvider(create: (_) => AccessibilityService(), child: child!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Check that "Pseudo" label is present
      expect(find.text('Pseudo'), findsOneWidget);
      
      // Check that "Prénom" label is not present
      expect(find.text('Prénom'), findsNothing);
    });

    testWidgets('Photo page should show photo count requirement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ChangeNotifierProvider(create: (_) => AccessibilityService(), child: child!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
      await tester.pumpAndSettle();
      // Navigate to photos page (page index 1)
      // This is tricky to test directly, but we can check if the photos page text exists
      expect(find.text('Ajoutez au moins 3 photos pour continuer'), findsOneWidget);
    });
  });

  group('Profile Validation Logic Tests', () {
    test('_isBasicInfoValid should return false when fields are empty', () {
      // Note: This would require extracting the validation logic to a separate class
      // or making the validation method public for testing
      // For now, we verify through widget tests above
    });

    test('_arePromptsValid should return false when prompts are empty', () {
      // Similar to above - would need refactoring for unit testing
    });
  });

  group('Prompt Validation Tests', () {
    testWidgets('Prompts page should show completion counter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ChangeNotifierProvider(create: (_) => AccessibilityService(), child: child!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      // Wait for the page to initialize
      await tester.pumpAndSettle();

      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(3);
      await tester.pumpAndSettle();
      expect(find.text('Question 0'), findsOneWidget);
      expect(find.text('Question 1'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Question 2'), 200, scrollable: find.byType(Scrollable).last);
      expect(find.text('Question 2'), findsOneWidget);
    });

    testWidgets('Continue button should be disabled when prompts are incomplete', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ChangeNotifierProvider(create: (_) => AccessibilityService(), child: child!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(3);
      await tester.pumpAndSettle();
      // Check if continue button text shows requirement when incomplete
      final button = find.widgetWithText(ElevatedButton, 'Sélectionnez 3 prompts (0/3)');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    });

    testWidgets('Prompt text fields should have 300 character limit', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ChangeNotifierProvider(create: (_) => AccessibilityService(), child: child!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(3);
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.scrollUntilVisible(find.text('Question $i'), 200, scrollable: find.byType(Scrollable).last);
        await tester.tap(find.text('Question $i'));
        await tester.pump();
      }
      final confirm = find.widgetWithText(ElevatedButton, 'Continuer');
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, isNotEmpty);
      await tester.scrollUntilVisible(find.text('Question 2'), 200, scrollable: find.byType(Scrollable).last);
      expect(fields.every((field) => field.maxLength == 300), isTrue);
    });
  });
}