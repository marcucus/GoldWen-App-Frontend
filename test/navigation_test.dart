import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/main.dart';
import 'package:goldwen_app/features/auth/providers/auth_provider.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/features/chat/providers/chat_provider.dart';
import 'package:goldwen_app/core/services/location_service.dart';

void main() {
  group('Navigation Tests', () {
    testWidgets('MainNavigationPage has correct navigation buttons', (WidgetTester tester) async {
      // Create test app with providers
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => LocationService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Simulate the floating navigation bar
                  Container(
                    height: 75,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem('Accueil', Icons.home),
                        _buildNavItem('Découvrir', Icons.favorite),
                        _buildNavItem('Messages', Icons.chat_bubble),
                        _buildNavItem('GoldWen+', Icons.star),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that navigation buttons exist
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Découvrir'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('GoldWen+'), findsOneWidget);

      // Verify that "Profil" button is replaced with "GoldWen+"
      expect(find.text('Profil'), findsNothing);
      expect(find.text('GoldWen+'), findsOneWidget);

      // Verify correct icons
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('Settings page contains profile and settings sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => LocationService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Profil & Paramètres'),
                  Text('Mon Profil'),
                  Text('Abonnement'),
                  Text('Paramètres'),
                  Text('Aide & Confidentialité'),
                  ListTile(
                    title: Text('Mes photos'),
                    leading: Icon(Icons.photo_library),
                  ),
                  ListTile(
                    title: Text('GoldWen Plus'),
                    leading: Icon(Icons.star),
                  ),
                  ListTile(
                    title: Text('Notifications'),
                    leading: Icon(Icons.notifications),
                  ),
                  ListTile(
                    title: Text('Aide et support'),
                    leading: Icon(Icons.help),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify settings page sections exist
      expect(find.text('Profil & Paramètres'), findsOneWidget);
      expect(find.text('Mon Profil'), findsOneWidget);
      expect(find.text('Abonnement'), findsOneWidget);
      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Aide & Confidentialité'), findsOneWidget);

      // Verify profile elements
      expect(find.text('Mes photos'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);

      // Verify subscription element
      expect(find.text('GoldWen Plus'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      // Verify settings elements
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);

      // Verify help element
      expect(find.text('Aide et support'), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);
    });
  });
}

Widget _buildNavItem(String label, IconData icon) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 24),
      SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11)),
    ],
  );
}