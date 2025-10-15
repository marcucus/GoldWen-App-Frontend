import 'package:flutter/material.dart';

/// A widget that dismisses the keyboard when tapping outside of text fields.
/// 
/// This widget wraps its child with a GestureDetector that unfocuses any
/// active text field when the user taps on an area that doesn't consume the tap.
/// This is particularly useful for mobile devices where there's no built-in
/// way to dismiss the keyboard.
///
/// The widget uses `HitTestBehavior.translucent` to allow child widgets to
/// receive tap events first, only dismissing the keyboard when taps occur
/// on empty areas.
///
/// Usage:
/// ```dart
/// KeyboardDismissible(
///   child: YourPageContent(),
/// )
/// ```
class KeyboardDismissible extends StatelessWidget {
  final Widget child;

  const KeyboardDismissible({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus any currently focused widget (like TextField)
        // This will cause the keyboard to close
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      // Use translucent to allow child widgets to handle taps first
      // Only dismiss keyboard when tap reaches this parent detector
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
