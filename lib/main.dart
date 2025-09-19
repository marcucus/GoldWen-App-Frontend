import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/config/firebase_config.dart';
import 'core/services/location_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/app_initialization_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/matching/providers/matching_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/admin/providers/admin_auth_provider.dart';
import 'features/admin/providers/admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize app services (includes Firebase initialization)
  await AppInitializationService.initialize();

  // Set background message handler if Firebase is available
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Background message handler not set: $e');
  }

  runApp(const GoldWenApp());
}

class GoldWenApp extends StatelessWidget {
  const GoldWenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (context) {
          final provider = MatchingProvider();
          // Initialize notifications when provider is created
          provider.initializeNotifications();
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()
            ..loadNotificationSettings()
            ..loadNotifications().catchError((e) => print('Failed to load notifications: $e')),
        ),
      ],
      child: MaterialApp.router(
        title: 'GoldWen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        // Add the navigator key for deep linking
        navigatorKey: NavigationService.navigatorKey,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('fr', ''),
        ],
      ),
    );
  }
}
