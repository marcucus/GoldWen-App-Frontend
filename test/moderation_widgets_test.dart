import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/moderation.dart';
import 'package:goldwen_app/core/widgets/moderation_widgets.dart';

void main() {
  group('ModerationStatusBadge', () {
    testWidgets('should not display for approved content without flags',
        (WidgetTester tester) async {
      final moderationResult = ModerationResult(
        status: ModerationStatus.approved,
        flags: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationStatusBadge(moderationResult: moderationResult),
          ),
        ),
      );

      expect(find.byType(ModerationStatusBadge), findsOneWidget);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('should display blocked status badge', (WidgetTester tester) async {
      final moderationResult = ModerationResult(
        status: ModerationStatus.blocked,
        flags: [ModerationFlag(name: 'Spam', confidence: 90.0)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationStatusBadge(moderationResult: moderationResult),
          ),
        ),
      );

      expect(find.text('Bloqué'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('should display pending status badge', (WidgetTester tester) async {
      final moderationResult = ModerationResult(
        status: ModerationStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationStatusBadge(moderationResult: moderationResult),
          ),
        ),
      );

      expect(find.text('En attente'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('should display compact badge when compact is true',
        (WidgetTester tester) async {
      final moderationResult = ModerationResult(
        status: ModerationStatus.blocked,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationStatusBadge(
              moderationResult: moderationResult,
              compact: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.text('Bloqué'), findsNothing);
    });

    testWidgets('should hide label when showLabel is false',
        (WidgetTester tester) async {
      final moderationResult = ModerationResult(
        status: ModerationStatus.blocked,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationStatusBadge(
              moderationResult: moderationResult,
              showLabel: false,
            ),
          ),
        ),
      );

      expect(find.text('Bloqué'), findsNothing);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });
  });

  group('ModerationFlagsWidget', () {
    testWidgets('should not display when flags are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModerationFlagsWidget(flags: []),
          ),
        ),
      );

      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('should display all flags', (WidgetTester tester) async {
      final flags = [
        ModerationFlag(name: 'Explicit Nudity', confidence: 95.0),
        ModerationFlag(name: 'Violence', confidence: 85.0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationFlagsWidget(flags: flags),
          ),
        ),
      );

      expect(find.text('Explicit Nudity'), findsOneWidget);
      expect(find.text('Violence'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
    });

    testWidgets('should show confidence when showConfidence is true',
        (WidgetTester tester) async {
      final flags = [
        ModerationFlag(name: 'Spam', confidence: 90.0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationFlagsWidget(
              flags: flags,
              showConfidence: true,
            ),
          ),
        ),
      );

      expect(find.text('(90%)'), findsOneWidget);
    });

    testWidgets('should format flag names correctly',
        (WidgetTester tester) async {
      final flags = [
        ModerationFlag(name: 'explicit_nudity', confidence: 95.0),
        ModerationFlag(name: 'ExplicitContent', confidence: 90.0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationFlagsWidget(flags: flags),
          ),
        ),
      );

      expect(find.text('Explicit Nudity'), findsOneWidget);
      expect(find.text('Explicit Content'), findsOneWidget);
    });
  });

  group('ModerationBlockedContent', () {
    testWidgets('should display blocked message for message type',
        (WidgetTester tester) async {
      final moderationResult = ModerationResult(
        status: ModerationStatus.blocked,
        flags: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationBlockedContent(
              moderationResult: moderationResult,
              resourceType: 'message',
            ),
          ),
        ),
      );

      expect(
        find.text(
            'Ce message a été bloqué par notre système de modération automatique.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('should display blocked message for photo type',
        (WidgetTester tester) async {
      final moderationResult = ModerationResult(
        status: ModerationStatus.blocked,
        flags: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationBlockedContent(
              moderationResult: moderationResult,
              resourceType: 'photo',
            ),
          ),
        ),
      );

      expect(
        find.text(
            'Cette photo a été bloquée par notre système de modération automatique.'),
        findsOneWidget,
      );
    });

    testWidgets('should display flags when present', (WidgetTester tester) async {
      final moderationResult = ModerationResult(
        status: ModerationStatus.blocked,
        flags: [
          ModerationFlag(name: 'Spam', confidence: 90.0),
          ModerationFlag(name: 'Violence', confidence: 85.0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationBlockedContent(
              moderationResult: moderationResult,
              resourceType: 'message',
            ),
          ),
        ),
      );

      expect(find.text('Raisons:'), findsOneWidget);
      expect(find.byType(ModerationFlagsWidget), findsOneWidget);
    });

    testWidgets('should show appeal button when onAppeal is provided',
        (WidgetTester tester) async {
      bool appealCalled = false;
      final moderationResult = ModerationResult(
        status: ModerationStatus.blocked,
        flags: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationBlockedContent(
              moderationResult: moderationResult,
              resourceType: 'message',
              onAppeal: () {
                appealCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Faire appel'), findsOneWidget);

      await tester.tap(find.text('Faire appel'));
      await tester.pump();

      expect(appealCalled, true);
    });

    testWidgets('should not show appeal button when onAppeal is null',
        (WidgetTester tester) async {
      final moderationResult = ModerationResult(
        status: ModerationStatus.blocked,
        flags: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModerationBlockedContent(
              moderationResult: moderationResult,
              resourceType: 'message',
            ),
          ),
        ),
      );

      expect(find.text('Faire appel'), findsNothing);
    });
  });
}
