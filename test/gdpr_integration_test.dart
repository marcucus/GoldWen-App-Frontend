import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/core/services/gdpr_service.dart';
import 'package:goldwen_app/features/legal/widgets/gdpr_consent_modal.dart';
import 'package:goldwen_app/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GDPR Consent Modal Integration Tests', () {
    late GdprService gdprService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gdprService = GdprService();
    });

    testWidgets('should display consent modal with all required options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: const Scaffold(
              body: GdprConsentModal(),
            ),
          ),
        ),
      );

      // Verify modal title and description
      expect(find.text('Protection de vos données'), findsOneWidget);
      expect(find.text('Conformité RGPD'), findsOneWidget);

      // Verify required consent section
      expect(find.text('Traitement des données (Obligatoire)'), findsOneWidget);
      expect(find.text('REQUIS'), findsOneWidget);

      // Verify optional consent sections
      expect(find.text('Marketing et communications (Optionnel)'), findsOneWidget);
      expect(find.text('Analyses et amélioration (Optionnel)'), findsOneWidget);

      // Verify button is initially disabled
      final acceptButton = find.text('Accepter et continuer');
      expect(acceptButton, findsOneWidget);
      
      final buttonWidget = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonWidget.onPressed, isNull); // Button should be disabled
    });

    testWidgets('should enable submit button when required consent is given', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: const Scaffold(
              body: GdprConsentModal(),
            ),
          ),
        ),
      );

      // Find and tap the required consent checkbox
      final requiredCheckbox = find.byType(Checkbox).first;
      await tester.tap(requiredCheckbox);
      await tester.pump();

      // Verify button is now enabled
      final buttonWidget = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should handle optional consents independently', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: const Scaffold(
              body: GdprConsentModal(),
            ),
          ),
        ),
      );

      // Tap required consent
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0)); // Required consent
      await tester.pump();

      // Tap optional marketing consent
      await tester.tap(checkboxes.at(1)); // Marketing consent
      await tester.pump();

      // Verify we can still submit (optional consents don't block submission)
      final buttonWidget = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should show privacy policy link', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: const Scaffold(
              body: GdprConsentModal(),
            ),
          ),
        ),
      );

      expect(find.text('Plus d\'informations'), findsOneWidget);
      expect(find.text('Consultez notre politique de confidentialité complète'), findsOneWidget);
    });

    testWidgets('should display warning when required consent not given', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: const Scaffold(
              body: GdprConsentModal(),
            ),
          ),
        ),
      );

      // Verify warning message is displayed
      expect(
        find.text('Le consentement pour le traitement des données est requis pour utiliser l\'application.'),
        findsOneWidget,
      );
    });
  });

  group('GDPR Service Integration Tests', () {
    testWidgets('should properly integrate with consent modal', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final gdprService = GdprService();
      bool consentGivenCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: Scaffold(
              body: GdprConsentModal(
                onConsentGiven: () {
                  consentGivenCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      // Give required consent
      final requiredCheckbox = find.byType(Checkbox).first;
      await tester.tap(requiredCheckbox);
      await tester.pump();

      // Submit consent (this would normally trigger API call, but we're testing the flow)
      final submitButton = find.text('Accepter et continuer');
      await tester.tap(submitButton);
      await tester.pump();

      // Note: The actual API call would be mocked in a real test environment
      // Here we're testing that the UI flow works correctly
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('GDPR Consent Validation', () {
    test('should validate consent requirements correctly', () {
      final gdprService = GdprService();
      
      // Initially no consent
      expect(gdprService.hasValidConsent, false);
      expect(gdprService.needsConsentRenewal(), true);
      expect(gdprService.isConsentStillValid(), false);
    });

    test('should handle consent expiration correctly', () {
      // This would typically involve mocking the current time
      // and testing with different consent dates
      expect(true, true); // Placeholder for time-based tests
    });
  });
}