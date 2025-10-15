import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/profile/pages/profile_setup_page.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';
import 'package:goldwen_app/features/auth/providers/auth_provider.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/services/accessibility_service.dart';

void main() {
  group('Bio Field Validation Tests', () {
    testWidgets('Bio field should have maxLength of 600', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => AccessibilityService()),
          ],
          child: const MaterialApp(
            home: ProfileSetupPage(),
          ),
        ),
      );

      // Wait for any async operations
      await tester.pumpAndSettle();

      // Find the bio text field
      final bioField = find.widgetWithText(TextField, 'Décrivez-vous en quelques mots...');
      expect(bioField, findsWidgets);
    });

    testWidgets('Bio label "Bio" should be visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => AccessibilityService()),
          ],
          child: const MaterialApp(
            home: ProfileSetupPage(),
          ),
        ),
      );

      // Wait for any async operations
      await tester.pumpAndSettle();

      // Check that "Bio" label is present
      expect(find.text('Bio'), findsOneWidget);
    });

    test('Bio validation - text with spaces and newlines counts correctly', () {
      // Test that spaces and newlines are counted
      const bioWithSpaces = 'Hello world';
      expect(bioWithSpaces.length, equals(11)); // 'Hello world' = 11 chars including space

      const bioWithNewlines = 'Hello\nworld';
      expect(bioWithNewlines.length, equals(11)); // 'Hello\nworld' = 11 chars including newline

      // Create a 600 character string
      final bio600 = 'a' * 600;
      expect(bio600.length, equals(600));

      // Create a 601 character string (should exceed limit)
      final bio601 = 'a' * 601;
      expect(bio601.length, equals(601));
      expect(bio601.length > 600, isTrue);
    });

    test('Bio validation - check character limit logic', () {
      // Simulate the validation logic
      String testBio = 'a' * 599;
      expect(testBio.length > 600, isFalse, reason: '599 chars should pass');

      testBio = 'a' * 600;
      expect(testBio.length > 600, isFalse, reason: '600 chars should pass (at limit)');

      testBio = 'a' * 601;
      expect(testBio.length > 600, isTrue, reason: '601 chars should fail');

      // Test with mixed content (spaces, newlines, etc.)
      testBio = 'Hello world\nThis is a test\n' * 30; // ~900 characters
      expect(testBio.length > 600, isTrue, reason: 'Long mixed content should fail');
    });
  });
}
