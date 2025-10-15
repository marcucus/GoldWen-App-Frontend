import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/config/firebase_config.dart';
import 'core/services/location_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/app_initialization_service.dart';
import 'core/services/gdpr_service.dart';
import 'core/services/accessibility_service.dart';
import 'core/services/performance_cache_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/matching/providers/matching_provider.dart';
import 'features/matching/providers/report_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/subscription/providers/subscription_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/settings/providers/email_notification_provider.dart';
import 'features/admin/providers/admin_auth_provider.dart';
import 'features/admin/providers/admin_provider.dart';
import 'features/feedback/providers/feedback_provider.dart';
import 'core/config/app_config.dart';
import 'shared/widgets/keyboard_dismissible.dart';

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
  AppConfig.debugPrintApiUrl(); // Ajoute cette ligne

  runApp(const GoldWenApp());
}

class GoldWenApp extends StatelessWidget {
  const GoldWenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        ChangeNotifierProvider(
            create: (_) => AccessibilityService()..initialize()),
        ChangeNotifierProvider(
            create: (_) => PerformanceCacheService()..initialize()),

        // App providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (context) {
          final provider = MatchingProvider();
          // Initialize notifications when provider is created
          provider.initializeNotifications();
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => GdprService()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()
            ..loadNotificationSettings()
            ..loadNotifications()
                .catchError((e) => print('Failed to load notifications: $e')),
        ),
        ChangeNotifierProvider(
          create: (_) => EmailNotificationProvider(),
        ),
      ],
      child: Consumer<AccessibilityService>(
        builder: (context, accessibilityService, child) {
          return MaterialApp.router(
            title: 'GoldWen',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(
              highContrast: accessibilityService.highContrast,
              textScaleFactor: accessibilityService.textScaleFactor,
            ),
            routerConfig: AppRouter.router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('fr', ''),
            ],
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler:
                      TextScaler.linear(accessibilityService.textScaleFactor),
                ),
                child: KeyboardDismissible(
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
