import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/chat/widgets/chat_countdown_timer.dart';

void main() {
  group('ChatCountdownTimer', () {
    testWidgets('displays correct time format', (WidgetTester tester) async {
      // Create a DateTime 2 hours from now
      final expiresAt = DateTime.now().add(const Duration(hours: 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCountdownTimer(
              expiresAt: expiresAt,
            ),
          ),
        ),
      );

      // Should display timer with hours, minutes, seconds
      expect(find.byType(Icon), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d{2}:\d{2}:\d{2}')), findsOneWidget);
    });

    testWidgets('shows expired message when time is past', (WidgetTester tester) async {
      // Create a DateTime 1 hour ago
      final expiresAt = DateTime.now().subtract(const Duration(hours: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCountdownTimer(
              expiresAt: expiresAt,
            ),
          ),
        ),
      );

      // Allow time for initial state update
      await tester.pump();

      // Should show expired message
      expect(find.text('Conversation expirée'), findsOneWidget);
      expect(find.byIcon(Icons.timer_off), findsOneWidget);
    });

    testWidgets('calls onExpired callback when timer expires', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      // Create a DateTime very close to now (1 second)
      final expiresAt = DateTime.now().add(const Duration(seconds: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCountdownTimer(
              expiresAt: expiresAt,
              onExpired: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      // Wait for timer to expire
      await tester.pump(const Duration(seconds: 2));

      expect(callbackCalled, isTrue);
    });

    testWidgets('displays different colors based on remaining time', (WidgetTester tester) async {
      // Test with 12 hours remaining (should be gold)
      final expiresAt = DateTime.now().add(const Duration(hours: 12));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatCountdownTimer(
              expiresAt: expiresAt,
            ),
          ),
        ),
      );

      // Should find a container with decoration
      expect(find.byType(Container), findsOneWidget);
      
      // Check that timer icon is present (not expired icon)
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.timer_off), findsNothing);
    });
  });
}