import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/core/services/gdpr_service.dart';
import 'package:goldwen_app/core/theme/app_theme.dart';
import 'package:goldwen_app/features/legal/pages/data_export_page.dart';
import 'package:goldwen_app/core/models/gdpr_consent.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DataExportPage Widget Tests', () {
    late GdprService gdprService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gdprService = GdprService();
    });

    Widget createTestWidget() {
      return ChangeNotifierProvider<GdprService>.value(
        value: gdprService,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DataExportPage(),
        ),
      );
    }

    testWidgets('should display page title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Export de mes données'), findsOneWidget);
    });

    testWidgets('should display RGPD info banner', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify RGPD information is displayed
      expect(find.text('Droit d\'accès RGPD'), findsOneWidget);
      expect(find.textContaining('article 20 du RGPD'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should display included data list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify section title
      expect(find.text('Données incluses dans l\'export'), findsOneWidget);

      // Verify some of the included data items
      expect(find.textContaining('Informations de profil'), findsOneWidget);
      expect(find.textContaining('Photos et média'), findsOneWidget);
      expect(find.textContaining('questionnaire de personnalité'), findsOneWidget);
      expect(find.textContaining('conversations'), findsOneWidget);
    });

    testWidgets('should display request export button when no request exists', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify request button is shown
      expect(find.text('Demander un export'), findsOneWidget);
      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets('should display processing status when request is processing', (WidgetTester tester) async {
      gdprService.currentExportRequest = DataExportRequest(
        requestId: 'test-123',
        status: 'processing',
        requestedAt: DateTime.now(),
        estimatedTime: '24 heures',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify processing status is shown
      expect(find.text('Export en cours de préparation...'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.text('Temps estimé : 24 heures'), findsOneWidget);
    });

    testWidgets('should display ready status with download button', (WidgetTester tester) async {
      gdprService.currentExportRequest = DataExportRequest(
        requestId: 'test-123',
        status: 'ready',
        requestedAt: DateTime.now().subtract(const Duration(hours: 12)),
        downloadUrl: 'https://example.com/download',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify ready status is shown
      expect(find.text('Votre export est prêt !'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Télécharger'), findsOneWidget);
    });

    testWidgets('should display failed status with retry option', (WidgetTester tester) async {
      gdprService.currentExportRequest = DataExportRequest(
        requestId: 'test-123',
        status: 'failed',
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify failed status is shown
      expect(find.text('L\'export a échoué'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('should display expired status', (WidgetTester tester) async {
      gdprService.currentExportRequest = DataExportRequest(
        requestId: 'test-123',
        status: 'expired',
        requestedAt: DateTime.now().subtract(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify expired status is shown
      expect(find.text('L\'export a expiré'), findsOneWidget);
      expect(find.text('Nouvelle demande'), findsOneWidget);
    });

    testWidgets('should display refresh button when processing', (WidgetTester tester) async {
      gdprService.currentExportRequest = DataExportRequest(
        requestId: 'test-123',
        status: 'processing',
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify refresh button is shown
      expect(find.text('Actualiser'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should show expiration date when ready', (WidgetTester tester) async {
      final expiresAt = DateTime.now().add(const Duration(days: 7));
      gdprService.currentExportRequest = DataExportRequest(
        requestId: 'test-123',
        status: 'ready',
        requestedAt: DateTime.now(),
        downloadUrl: 'https://example.com/download',
        expiresAt: expiresAt,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify expiration date is shown
      expect(find.textContaining('Expire le'), findsOneWidget);
    });

    testWidgets('should display processing time information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify processing time info is shown
      expect(find.text('Temps de traitement'), findsOneWidget);
      expect(find.textContaining('24 heures'), findsOneWidget);
      expect(find.textContaining('email'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('should have back button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify back button exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should show all data categories with icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify icons for different data categories
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.photo), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byIcon(Icons.chat), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('should use appropriate colors for status', (WidgetTester tester) async {
      gdprService.currentExportRequest = DataExportRequest(
        requestId: 'test-123',
        status: 'ready',
        requestedAt: DateTime.now(),
        downloadUrl: 'https://example.com/download',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The success icon should be green
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, AppColors.successGreen);
    });

    testWidgets('should use error color for failed status', (WidgetTester tester) async {
      gdprService.currentExportRequest = DataExportRequest(
        requestId: 'test-123',
        status: 'failed',
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The error icon should be red
      final icon = tester.widget<Icon>(find.byIcon(Icons.error));
      expect(icon.color, AppColors.errorRed);
    });

    testWidgets('should show loading state for request button', (WidgetTester tester) async {
      gdprService.isLoading = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // When loading, button should show progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display comprehensive data export information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify all important information elements are present
      expect(find.text('Export de mes données'), findsOneWidget);
      expect(find.text('Droit d\'accès RGPD'), findsOneWidget);
      expect(find.text('Données incluses dans l\'export'), findsOneWidget);
      expect(find.text('Temps de traitement'), findsOneWidget);
    });
  });
}
