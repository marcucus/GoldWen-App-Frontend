import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/core/services/gdpr_service.dart';
import 'package:goldwen_app/features/legal/pages/consent_page.dart';
import 'package:goldwen_app/features/legal/widgets/consent_modal.dart';
import 'package:goldwen_app/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Consent Page Tests', () {
    late GdprService gdprService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gdprService = GdprService();
    });

    testWidgets('should display consent page with modal', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: const ConsentPage(),
          ),
        ),
      );

      // Verify app bar is present when page is dismissible
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Consentement RGPD'), findsOneWidget);

      // Verify consent modal is displayed
      expect(find.text('Protection de vos données'), findsOneWidget);
      expect(find.text('Conformité RGPD'), findsOneWidget);
    });

    testWidgets('should hide app bar when not dismissible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: const ConsentPage(canDismiss: false),
          ),
        ),
      );

      // Verify app bar is NOT present when page is not dismissible
      expect(find.byType(AppBar), findsNothing);

      // Verify consent modal is still displayed
      expect(find.text('Protection de vos données'), findsOneWidget);
    });

    testWidgets('should call onConsentGiven callback', (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: ConsentPage(
              onConsentGiven: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      // Tap the required consent checkbox
      final requiredCheckbox = find.byType(Checkbox).first;
      await tester.tap(requiredCheckbox);
      await tester.pump();

      // Tap the accept button
      final acceptButton = find.text('Accepter et continuer');
      await tester.tap(acceptButton);
      await tester.pump();

      // Wait for async operations
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(callbackCalled, true);
    });

    testWidgets('should display all consent options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: const ConsentPage(),
          ),
        ),
      );

      // Verify all consent sections are present
      expect(find.text('Traitement des données (Obligatoire)'), findsOneWidget);
      expect(find.text('Marketing et communications (Optionnel)'), findsOneWidget);
      expect(find.text('Analyses et amélioration (Optionnel)'), findsOneWidget);

      // Verify required badge
      expect(find.text('REQUIS'), findsOneWidget);
    });

    testWidgets('should have link to privacy policy', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ChangeNotifierProvider<GdprService>.value(
            value: gdprService,
            child: const ConsentPage(),
          ),
        ),
      );

      // Verify privacy policy link exists
      expect(
        find.text('Consultez notre politique de confidentialité complète'),
        findsOneWidget,
      );
    });
  });

  group('Consent Modal Export Tests', () {
    testWidgets('consent_modal.dart should export GdprConsentModal', 
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final gdprService = GdprService();

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

      // Verify modal is displayed correctly
      expect(find.text('Protection de vos données'), findsOneWidget);
      expect(find.text('Accepter et continuer'), findsOneWidget);
    });
  });
}
