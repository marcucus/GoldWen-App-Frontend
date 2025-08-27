import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/main.dart';

void main() {
  testWidgets('GoldWen app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GoldWenApp());

    // Verify that the welcome page loads
    expect(find.text('Bienvenue sur'), findsOneWidget);
    expect(find.text('GoldWen'), findsOneWidget);
    expect(find.text('Conçue pour être désinstallée'), findsOneWidget);
  });
}