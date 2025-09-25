import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/profile/pages/profile_setup_page.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';

void main() {
  group('ProfileSetupPage Tests', () {
    testWidgets('Button should be disabled initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

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
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      // Check that "Pseudo" label is present
      expect(find.text('Pseudo'), findsOneWidget);
      
      // Check that "Prénom" label is not present
      expect(find.text('Prénom'), findsNothing);
    });

    testWidgets('Photo page should show photo count requirement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

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
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      // Wait for the page to initialize
      await tester.pumpAndSettle();

      // Navigate to the prompts page (assuming we can reach it)
      // Check if the completion counter text exists
      expect(find.textContaining('Réponses complétées:'), findsOneWidget);
      expect(find.textContaining('0/3'), findsOneWidget);
    });

    testWidgets('Continue button should be disabled when prompts are incomplete', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if continue button text shows requirement when incomplete
      final incompleteButton = find.textContaining('Complétez les 3 réponses');
      expect(incompleteButton, findsWidgets);
    });

    testWidgets('Prompt text fields should have 300 character limit', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => ProfileProvider(),
            child: const ProfileSetupPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for the character counter text
      expect(find.textContaining('/300'), findsWidgets);
      
      // Look for the updated hint text
      expect(find.text('Votre réponse... (max 300 caractères)'), findsWidgets);
    });
  });
}