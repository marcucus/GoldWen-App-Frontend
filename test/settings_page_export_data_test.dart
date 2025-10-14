import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/settings/pages/settings_page.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';
import 'package:goldwen_app/features/subscription/providers/subscription_provider.dart';
import 'package:goldwen_app/features/notifications/providers/notification_provider.dart';
import 'package:goldwen_app/features/auth/providers/auth_provider.dart';
import 'package:goldwen_app/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsPage - Data Export Feature Tests', () {
    late ProfileProvider profileProvider;
    late SubscriptionProvider subscriptionProvider;
    late NotificationProvider notificationProvider;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      profileProvider = ProfileProvider();
      subscriptionProvider = SubscriptionProvider();
      notificationProvider = NotificationProvider(prefs);
      authProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
          ChangeNotifierProvider<SubscriptionProvider>.value(value: subscriptionProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const SettingsPage(),
        ),
      );
    }

    testWidgets('should display "Télécharger mes données" button in help section', 
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the data export button is present
      expect(find.text('Télécharger mes données'), findsOneWidget);
      expect(find.text('Exporter toutes vos données personnelles (RGPD)'), findsOneWidget);
    });

    testWidgets('should display download icon for data export button', 
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find all file_download icons (including the one for data export)
      expect(find.byIcon(Icons.file_download), findsWidgets);
    });

    testWidgets('should have data export button in the help & legal section', 
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to the help section (data export is in the lower part of the page)
      await tester.scrollUntilVisible(
        find.text('Télécharger mes données'),
        500.0,
        scrollable: find.byType(Scrollable).last,
      );

      // Verify the button exists
      expect(find.text('Télécharger mes données'), findsOneWidget);
    });

    testWidgets('should display data export button near privacy settings', 
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to the help section
      await tester.scrollUntilVisible(
        find.text('Paramètres de confidentialité'),
        500.0,
        scrollable: find.byType(Scrollable).last,
      );

      // Both privacy settings and data export should be visible together
      expect(find.text('Paramètres de confidentialité'), findsOneWidget);
      
      // Scroll a bit more to ensure data export is visible
      await tester.scrollUntilVisible(
        find.text('Télécharger mes données'),
        100.0,
        scrollable: find.byType(Scrollable).last,
      );
      
      expect(find.text('Télécharger mes données'), findsOneWidget);
    });

    testWidgets('data export button should be tappable', 
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to the data export button
      await tester.scrollUntilVisible(
        find.text('Télécharger mes données'),
        500.0,
        scrollable: find.byType(Scrollable).last,
      );

      // Find the ListTile containing the data export button
      final dataExportTile = find.ancestor(
        of: find.text('Télécharger mes données'),
        matching: find.byType(ListTile),
      );

      expect(dataExportTile, findsOneWidget);
      
      // Verify it's tappable (has onTap callback)
      final listTile = tester.widget<ListTile>(dataExportTile);
      expect(listTile.onTap, isNotNull);
    });

    testWidgets('should show correct section title "Aide & Confidentialité"', 
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the section title
      expect(find.text('Aide & Confidentialité'), findsOneWidget);
    });
  });
}
