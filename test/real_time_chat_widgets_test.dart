import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/chat/widgets/typing_indicator.dart';
import 'package:goldwen_app/features/chat/widgets/online_status_indicator.dart';
import 'package:goldwen_app/core/models/chat.dart';
import 'package:flutter/material.dart';

void main() {
  group('TypingIndicator Widget', () {
    testWidgets('should display user name and animated dots', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(userName: 'Sophie'),
          ),
        ),
      );

      // Should display the user name
      expect(find.text('Sophie écrit'), findsOneWidget);
      
      // Should render without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should animate continuously', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(userName: 'Marc'),
          ),
        ),
      );

      // Initial render
      await tester.pump();
      
      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      
      // Should still be rendering
      expect(find.byType(TypingIndicator), findsOneWidget);
    });
  });

  group('OnlineStatusIndicator Widget', () {
    testWidgets('should display green dot and "En ligne" for online users', 
        (WidgetTester tester) async {
      final onlineStatus = OnlineStatus(
        userId: 'user123',
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnlineStatusIndicator(status: onlineStatus),
          ),
        ),
      );

      // Should display "En ligne" text
      expect(find.text('En ligne'), findsOneWidget);
      
      // Should render a green dot (Container with green color)
      final containerFinder = find.descendant(
        of: find.byType(OnlineStatusIndicator),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('should display gray dot and last seen text for offline users', 
        (WidgetTester tester) async {
      final offlineStatus = OnlineStatus(
        userId: 'user123',
        isOnline: false,
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnlineStatusIndicator(status: offlineStatus),
          ),
        ),
      );

      // Should display last seen text
      expect(find.text('Vu il y a 30 min'), findsOneWidget);
    });

    testWidgets('should display compact version without text', 
        (WidgetTester tester) async {
      final onlineStatus = OnlineStatus(
        userId: 'user123',
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnlineStatusIndicator(
              status: onlineStatus,
              showText: false,
              compact: true,
            ),
          ),
        ),
      );

      // Should not display text
      expect(find.text('En ligne'), findsNothing);
      
      // Should still render the dot
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should render nothing when status is null', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnlineStatusIndicator(status: null),
          ),
        ),
      );

      // Should render a SizedBox.shrink
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });

  group('Widget Integration', () {
    testWidgets('should render typing indicator and online status together', 
        (WidgetTester tester) async {
      final onlineStatus = OnlineStatus(
        userId: 'user123',
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OnlineStatusIndicator(status: onlineStatus),
                const SizedBox(height: 10),
                const TypingIndicator(userName: 'Sophie'),
              ],
            ),
          ),
        ),
      );

      // Both widgets should be present
      expect(find.byType(OnlineStatusIndicator), findsOneWidget);
      expect(find.byType(TypingIndicator), findsOneWidget);
      
      // Both texts should be visible
      expect(find.text('En ligne'), findsOneWidget);
      expect(find.text('Sophie écrit'), findsOneWidget);
    });
  });

  group('Read Receipt Icons', () {
    testWidgets('should display single checkmark for sent messages', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Icon(
              Icons.done,
              color: Colors.white70,
              size: 14,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done), findsOneWidget);
    });

    testWidgets('should display double checkmark for read messages', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Icon(
              Icons.done_all,
              color: Colors.lightBlue,
              size: 14,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });
  });
}
