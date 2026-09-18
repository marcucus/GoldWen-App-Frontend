import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/core/services/accessibility_service.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';
import 'package:goldwen_app/features/onboarding/pages/personality_questionnaire_page.dart';
import 'package:goldwen_app/l10n/app_localizations.dart';
import 'support/api_adapter.dart';

void main() {
  for (final fixture in <Object>[[], {'invalid': true}]) {
    testWidgets('questionnaire handles missing or invalid server questions: $fixture', (tester) async {
      ApiService.configureTestAdapter(() => ApiAdapter((_) => (200, {'data': fixture})));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
          ChangeNotifierProvider(create: (_) => AccessibilityService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const PersonalityQuestionnairePage(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
