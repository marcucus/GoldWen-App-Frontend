import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goldwen_app/core/services/accessibility_service.dart';
import 'package:goldwen_app/core/services/performance_cache_service.dart';
import 'package:goldwen_app/features/auth/providers/auth_provider.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/features/chat/providers/chat_provider.dart';
import 'package:goldwen_app/features/subscription/providers/subscription_provider.dart';
import 'package:goldwen_app/features/notifications/providers/notification_provider.dart';
import 'package:goldwen_app/features/main/pages/main_navigation_page.dart';
import 'package:goldwen_app/features/settings/pages/settings_page.dart';
import 'package:goldwen_app/features/user/pages/user_profile_page.dart';
import 'package:goldwen_app/features/chat/pages/chat_list_page.dart';
import 'package:goldwen_app/features/main/pages/home_page.dart';
import 'package:goldwen_app/l10n/app_localizations.dart';

void main() {
  testWidgets('real mobile shell switches between all four tabs', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'onboarding_tutorial_shown': true});
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MatchingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityService()),
        ChangeNotifierProvider(create: (_) => PerformanceCacheService()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const MainNavigationPage(),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // Dismiss the real first-run overlay if present.
    final skip = find.text('Passer');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip.first);
      await tester.pumpAndSettle();
    }
    final tabs = <String, Type>{'Du jour': HomePage, 'Messages': ChatListPage, 'Profil': UserProfilePage, 'Réglages': SettingsPage};
    for (final tab in tabs.entries) {
      final button = find.descendant(of: find.byType(MainNavigationPage), matching: find.text(tab.key)).last;
      await tester.tap(button);
      await tester.pumpAndSettle();
      final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(stack.index, tabs.keys.toList().indexOf(tab.key));
      expect(stack.children[stack.index!].runtimeType, tab.value);
    }
    expect(find.text('GoldWen+'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
