import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goldwen_app/core/routes/app_router.dart';
import 'package:goldwen_app/features/auth/pages/splash_page.dart';
import 'package:goldwen_app/features/auth/providers/auth_provider.dart';
import 'package:goldwen_app/l10n/app_localizations.dart';

void main() {
  testWidgets('initial route shows splash then welcome for an unauthenticated user', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    AppRouter.router.go('/splash');
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp.router(
        routerConfig: AppRouter.router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
      ),
    ));
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('GoldWen'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(AppRouter.router.routeInformationProvider.value.uri.path, '/welcome');
    expect(find.byType(SplashPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
