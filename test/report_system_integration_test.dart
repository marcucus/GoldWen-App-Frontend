import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import 'package:goldwen_app/core/models/models.dart';
import 'package:goldwen_app/features/matching/providers/report_provider.dart';
import 'package:goldwen_app/features/matching/widgets/report_dialog.dart';

// Use the centralized mocks file
import 'mocks.mocks.dart';

// Integration test for the complete report system
void main() {
  group('Report System Integration Tests', () {
    testWidgets('Report dialog should submit report successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
      // Test that the report dialog works with the provider
      final mockProvider = MockReportProvider();
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.submitReport(targetUserId: anyNamed('targetUserId'), type: anyNamed('type'), reason: anyNamed('reason'), messageId: anyNamed('messageId'), chatId: anyNamed('chatId'))).thenAnswer((_) async {});

      // The provider sits above MaterialApp, as in main.dart: showDialog pushes
      // a route on the root Navigator, so a provider placed under `home` is not
      // visible from the dialog (ProviderNotFoundException, caught by the
      // dialog, and submitReport was never called).
      await tester.pumpWidget(
        ChangeNotifierProvider<ReportProvider>.value(
          value: mockProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(context: context, builder: (_) => ReportDialog(
                    targetUserId: 'test-user-id',
                    targetUserName: 'Test User',
                  )),
                  child: const Text('Report'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show dialog
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();

      // Verify the dialog is shown
      expect(find.text('Signaler un problème'), findsOneWidget);
      expect(find.text('Contenu inapproprié'), findsOneWidget);
      
      // Fill in the reason
      await tester.enterText(find.byType(TextFormField), 'Test report reason');
      
      // Submit the report
      await tester.ensureVisible(find.text('Signaler'));
      await tester.tap(find.text('Signaler'));
      await tester.pumpAndSettle();

      // Verify that submitReport was called on the provider
      verify(mockProvider.submitReport(
        targetUserId: 'test-user-id',
        type: ReportType.inappropriateContent,
        reason: 'Test report reason',
      )).called(1);
    });
  });

  group('Report Model Tests', () {
    test('Report model should serialize/deserialize correctly', () {
      final report = Report(
        id: 'test-id',
        targetUserId: 'user-123',
        type: ReportType.harassment,
        reason: 'Test harassment report',
        status: ReportStatus.pending,
        createdAt: DateTime(2023, 1, 1, 10, 0, 0),
      );

      final json = report.toJson();
      expect(json['id'], equals('test-id'));
      expect(json['targetUserId'], equals('user-123'));
      expect(json['type'], equals('harassment'));
      expect(json['status'], equals('pending'));

      final deserializedReport = Report.fromJson(json);
      expect(deserializedReport.id, equals(report.id));
      expect(deserializedReport.targetUserId, equals(report.targetUserId));
      expect(deserializedReport.type, equals(report.type));
      expect(deserializedReport.status, equals(report.status));
    });

    test('ReportType enum should serialize correctly to JSON', () {
      final reportInappropriate = Report(
        id: 'r1',
        targetUserId: 'user1',
        type: ReportType.inappropriateContent,
        reason: 'test',
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(reportInappropriate.toJson()['type'], equals('inappropriate_content'));
      
      final reportHarassment = Report(
        id: 'r2',
        targetUserId: 'user2',
        type: ReportType.harassment,
        reason: 'test',
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(reportHarassment.toJson()['type'], equals('harassment'));
    });

    test('ReportStatus enum should serialize correctly to JSON', () {
      final reportPending = Report(
        id: 'r1',
        targetUserId: 'user1',
        type: ReportType.spam,
        reason: 'test',
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(reportPending.toJson()['status'], equals('pending'));
      
      final reportReviewed = Report(
        id: 'r2',
        targetUserId: 'user2',
        type: ReportType.spam,
        reason: 'test',
        status: ReportStatus.reviewed,
        createdAt: DateTime.now(),
      );
      expect(reportReviewed.toJson()['status'], equals('reviewed'));
    });
  });
}

// Mock extension to enable the static method calls
extension ReportMockExtension on MockReportProvider {
  Future<void> submitReport({
    required String targetUserId,
    required ReportType type,
    required String reason,
    String? messageId,
    String? chatId,
    List<String>? evidence,
  }) async {
    // Extension methods cannot use super.noSuchMethod
    // This should be handled by mockito's generated code instead
    throw UnimplementedError('This method should be mocked using when() from mockito');
  }
}
