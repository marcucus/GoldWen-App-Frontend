import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/shared/widgets/keyboard_dismissible.dart';

void main() {
  group('KeyboardDismissible', () {
    testWidgets('should unfocus text field when tapping outside', (WidgetTester tester) async {
      final focusNode = FocusNode();
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardDismissible(
              child: Column(
                children: [
                  TextField(
                    focusNode: focusNode,
                    controller: controller,
                  ),
                  const SizedBox(height: 100),
                  const Text('Tap area'),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap on the text field to focus it
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Verify the text field is focused
      expect(focusNode.hasFocus, true);

      // Tap outside the text field (on the Text widget)
      await tester.tap(find.text('Tap area'));
      await tester.pump();

      // Verify the text field is unfocused
      expect(focusNode.hasFocus, false);

      focusNode.dispose();
      controller.dispose();
    });

    testWidgets('should not interfere with child widget taps', (WidgetTester tester) async {
      int buttonTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardDismissible(
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    buttonTapCount++;
                  },
                  child: const Text('Tap me'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap on the button
      await tester.tap(find.text('Tap me'));
      await tester.pump();

      // Verify the button was tapped
      expect(buttonTapCount, 1);
    });

    testWidgets('should allow text field to receive focus on tap', (WidgetTester tester) async {
      final focusNode = FocusNode();
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardDismissible(
              child: TextField(
                focusNode: focusNode,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Tap on the text field
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Verify the text field receives focus
      expect(focusNode.hasFocus, true);

      focusNode.dispose();
      controller.dispose();
    });

    testWidgets('should only unfocus when there is a focused child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardDismissible(
              child: const Center(
                child: Text('Empty area'),
              ),
            ),
          ),
        ),
      );

      // Tap on the empty area when nothing is focused
      // This should not cause any errors
      await tester.tap(find.text('Empty area'));
      await tester.pump();

      // Test passes if no exceptions are thrown
      expect(find.text('Empty area'), findsOneWidget);
    });
  });
}
