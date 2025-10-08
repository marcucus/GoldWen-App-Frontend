import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import '../lib/features/reports/pages/user_reports_page.dart';
import '../lib/features/matching/providers/report_provider.dart';
import '../lib/core/models/models.dart';

// Use the centralized mocks file
import 'mocks.mocks.dart';

void main() {
  group('UserReportsPage Tests', () {
    late MockReportProvider mockReportProvider;

    setUp(() {
      mockReportProvider = MockReportProvider();
    });

    testWidgets('should display loading indicator when loading reports', (WidgetTester tester) async {
      // Arrange
      when(mockReportProvider.isLoading).thenReturn(true);
      when(mockReportProvider.myReports).thenReturn([]);
      when(mockReportProvider.error).thenReturn(null);
      when(mockReportProvider.hasMoreReports).thenReturn(false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ReportProvider>(
            create: (_) => mockReportProvider,
            child: const UserReportsPage(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no reports found', (WidgetTester tester) async {
      // Arrange
      when(mockReportProvider.isLoading).thenReturn(false);
      when(mockReportProvider.myReports).thenReturn([]);
      when(mockReportProvider.error).thenReturn(null);
      when(mockReportProvider.hasMoreReports).thenReturn(false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ReportProvider>(
            create: (_) => mockReportProvider,
            child: const UserReportsPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Aucun signalement'), findsOneWidget);
      expect(find.text('Vous n\'avez encore soumis aucun signalement.'), findsOneWidget);
    });

    testWidgets('should display reports list when reports are available', (WidgetTester tester) async {
      // Arrange
      final mockReports = [
        Report(
          id: '1',
          targetUserId: 'user-1',
          type: ReportType.inappropriateContent,
          reason: 'Test report reason',
          status: ReportStatus.pending,
          createdAt: DateTime(2023, 1, 1),
        ),
        Report(
          id: '2',
          targetUserId: 'user-2',
          type: ReportType.harassment,
          reason: 'Another test report',
          status: ReportStatus.resolved,
          createdAt: DateTime(2023, 1, 2),
        ),
      ];

      when(mockReportProvider.isLoading).thenReturn(false);
      when(mockReportProvider.myReports).thenReturn(mockReports);
      when(mockReportProvider.error).thenReturn(null);
      when(mockReportProvider.hasMoreReports).thenReturn(false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ReportProvider>(
            create: (_) => mockReportProvider,
            child: const UserReportsPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Contenu inapproprié'), findsOneWidget);
      expect(find.text('Harcèlement'), findsOneWidget);
      expect(find.text('Test report reason'), findsOneWidget);
      expect(find.text('Another test report'), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget);
      expect(find.text('Résolu'), findsOneWidget);
    });

    testWidgets('should display error state when error occurs', (WidgetTester tester) async {
      // Arrange
      when(mockReportProvider.isLoading).thenReturn(false);
      when(mockReportProvider.myReports).thenReturn([]);
      when(mockReportProvider.error).thenReturn('Test error message');
      when(mockReportProvider.hasMoreReports).thenReturn(false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ReportProvider>(
            create: (_) => mockReportProvider,
            child: const UserReportsPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Erreur de chargement'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('should show filter chips and update selection', (WidgetTester tester) async {
      // Arrange
      when(mockReportProvider.isLoading).thenReturn(false);
      when(mockReportProvider.myReports).thenReturn([]);
      when(mockReportProvider.error).thenReturn(null);
      when(mockReportProvider.hasMoreReports).thenReturn(false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ReportProvider>(
            create: (_) => mockReportProvider,
            child: const UserReportsPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget);
      expect(find.text('Examiné'), findsOneWidget);
      expect(find.text('Résolu'), findsOneWidget);
      expect(find.text('Rejeté'), findsOneWidget);

      // Test filter interaction
      await tester.tap(find.text('En attente'));
      await tester.pumpAndSettle();

      // Verify the provider method would be called
      // Note: In a real test, you might need to verify the method call
    });
  });
}