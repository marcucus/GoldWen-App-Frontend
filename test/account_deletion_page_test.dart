import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/core/services/gdpr_service.dart';
import 'package:goldwen_app/core/theme/app_theme.dart';
import 'package:goldwen_app/features/legal/pages/account_deletion_page.dart';
import 'package:goldwen_app/features/auth/providers/auth_provider.dart';
import 'package:goldwen_app/core/models/gdpr_consent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  group('AccountDeletionPage Widget Tests', () {
    late GdprService gdprService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gdprService = GdprService();
      mockAuthProvider = MockAuthProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<GdprService>.value(value: gdprService),
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const AccountDeletionPage(),
        ),
      );
    }

    testWidgets('should display deletion form when no deletion is scheduled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify warning banner is present
      expect(find.text('Attention'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Verify password field is present
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);

      // Verify delete button is present
      expect(find.text('Supprimer mon compte'), findsOneWidget);
    });

    testWidgets('should display grace period option', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the checkbox for immediate deletion
      expect(find.text('Supprimer immédiatement'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      // Initially should not be checked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('should toggle immediate delete option', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Verify message changed for immediate deletion
      expect(find.text('Votre compte sera supprimé immédiatement et de façon irréversible.'), findsOneWidget);
    });

    testWidgets('should display what will be deleted', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify list of items to be deleted
      expect(find.text('Ce qui sera supprimé'), findsOneWidget);
      expect(find.text('Votre profil et toutes vos photos'), findsOneWidget);
      expect(find.text('Vos réponses au questionnaire de personnalité'), findsOneWidget);
      expect(find.text('Tous vos matches et conversations'), findsOneWidget);
    });

    testWidgets('should display scheduled deletion view when deletion is scheduled', (WidgetTester tester) async {
      // Set scheduled deletion status
      final deletionDate = DateTime.now().add(const Duration(days: 25));
      // gdprService.accountDeletionStatus = AccountDeletionStatus(
        status: 'scheduled_deletion',
        deletionDate: deletionDate,
        message: 'Votre compte sera supprimé dans 30 jours',
        canCancel: true,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify scheduled deletion view is shown
      expect(find.text('Suppression programmée'), findsOneWidget);
      expect(find.text('Votre compte sera supprimé dans'), findsOneWidget);
      expect(find.text('25 jours'), findsOneWidget);
    });

    testWidgets('should display cancel button when deletion can be cancelled', (WidgetTester tester) async {
      final deletionDate = DateTime.now().add(const Duration(days: 20));
      // gdprService.accountDeletionStatus = AccountDeletionStatus(
        status: 'scheduled_deletion',
        deletionDate: deletionDate,
        canCancel: true,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify cancel button is present
      expect(find.text('Annuler la suppression'), findsOneWidget);
    });

    testWidgets('should show deletion date in scheduled view', (WidgetTester tester) async {
      final deletionDate = DateTime.now().add(const Duration(days: 30));
      // gdprService.accountDeletionStatus = AccountDeletionStatus(
        status: 'scheduled_deletion',
        deletionDate: deletionDate,
        canCancel: true,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify deletion date is shown
      expect(find.text('Date de suppression'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should require password for deletion', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Try to submit without password
      await tester.tap(find.text('Supprimer mon compte'));
      await tester.pumpAndSettle();

      // Verify validation message (form validation should prevent submission)
      final passwordField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(passwordField.validator != null, true);
    });

    testWidgets('should have optional reason field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find reason field
      expect(find.text('Raison (optionnel)'), findsOneWidget);
      expect(find.text('Pourquoi souhaitez-vous supprimer votre compte ?'), findsOneWidget);
    });

    testWidgets('should show password visibility toggle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap to toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should have back button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify back button exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should show correct title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify page title
      expect(find.text('Suppression de compte'), findsOneWidget);
    });

    testWidgets('should display warning icon in scheduled view', (WidgetTester tester) async {
      // gdprService.accountDeletionStatus = AccountDeletionStatus(
        status: 'scheduled_deletion',
        deletionDate: DateTime.now().add(const Duration(days: 15)),
        canCancel: true,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify warning icon is shown
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
    });

    testWidgets('should have cancel action in form view', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify cancel button exists
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('should show appropriate colors for destructive actions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The delete button should use error color
      final deleteButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Supprimer mon compte'),
      );

      expect(deleteButton.style?.backgroundColor?.resolve({}), AppColors.errorRed);
    });
  });
}
