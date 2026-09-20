// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
// Temporary visual audit launcher, explicitly authorized. Debug builds only.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'main.dart' show GoldWenApp;
import 'core/routes/app_router.dart';
import 'core/services/navigation_service.dart';
import 'core/services/app_initialization_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/matching/pages/daily_matches_page.dart';
import 'features/reports/pages/report_page.dart';
import 'features/onboarding/pages/gender_selection_page.dart';
import 'features/onboarding/pages/gender_preferences_page.dart';
import 'features/onboarding/pages/location_setup_page.dart';
import 'features/onboarding/pages/preferences_setup_page.dart';
import 'features/onboarding/pages/additional_info_page.dart';
import 'core/models/models.dart';
import 'core/services/api_service.dart';
import 'core/widgets/rate_limit_dialog.dart';
import 'features/matching/providers/matching_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/chat/widgets/match_acceptance_dialog.dart';

Future<void> main() async {
  if (!kDebugMode) throw StateError('Audit entrypoint is debug-only');
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await AppInitializationService.initialize();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(resizeToAvoidBottomInset: false, body: AuditHost()),
  ));
}

class AuditHost extends StatefulWidget {
  const AuditHost({super.key});
  @override
  State<AuditHost> createState() => _AuditHostState();
}

class _AuditHostState extends State<AuditHost> {
  bool expanded = false;
  static const routes = <String, String>{
    'Accueil': '/home',
    'Candidat Alex — profil': '/profile/0822071d-8a93-4b63-acef-9e1943a2ac14',
    'Chat fictif actif': '/chat/333885df-8c96-42ff-ab61-e88cff9f563f',
    'Matches': '/matches',
    'Qui m’a choisi': '/who-liked-me',
    'Recommandations sans paramètres': '/advanced-recommendations',
    'Recommandations fixture Alex': '/advanced-recommendations?userId=51d817d4-7152-4b45-8eda-61e8aa5efb85&candidateIds=67f3bdcb-9702-4da4-b54a-144977c4de24',
    'Consentement séparé': '/consent',
    'Profil séparé': '/user-profile',
    'Réglages séparés': '/settings',
    'Archives': '/archived-chats',
    'Conditions': '/terms',
    'Confidentialité': '/privacy',
    'Questionnaire': '/questionnaire',
    'Création profil': '/profile-setup',
    'Notifications': '/notifications',
    'Abonnement': '/subscription',
    'Export': '/data-export',
  };

  void openStandalone(Widget page) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated ||
        auth.user?.isOnboardingCompleted != true ||
        auth.user?.isProfileCompleted != true) {
      return;
    }
    NavigationService.navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    setState(() => expanded = false);
  }

  Future<void> signInFixture() async {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;
    try {
      await context.read<AuthProvider>().signInWithEmail(
        email: 'recette-1789739438851@goldwen.invalid',
        password: 'Audit!f6ab3698325bae24b9bc2e88',
      );
      AppRouter.router.go('/home');
    } catch (_) {
      // The production login UI already owns error presentation; this is a
      // temporary local-only audit shortcut for the disposable fixture.
    }
  }

  void seedVisualFixture() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null || !context.read<AuthProvider>().isAuthenticated) return;
    final now = DateTime.now();
    final profile = Profile(
      id: '0822071d-8a93-4b63-acef-9e1943a2ac14',
      userId: '67f3bdcb-9702-4da4-b54a-144977c4de24',
      pseudo: 'AlexRecette', birthDate: DateTime(1995, 6, 15),
      bio: 'Profil fictif de recette visuelle. Aucune personne réelle.',
      jobTitle: 'Testeur', location: 'Ville fictive',
      interests: const ['Lecture', 'Nature'], sharedInterests: const ['Lecture'],
      compatibilityScore: 0.82,
      compatibilityDetails: const {'communication': 0.80, 'values': 0.90, 'lifestyle': 0.75, 'personality': 0.83},
      isComplete: true, createdAt: now, updatedAt: now,
    );
    final matching = context.read<MatchingProvider>();
    matching.dailyProfiles.removeWhere((p) => p.id == profile.id);
    matching.dailyProfiles.add(profile);
    matching.notifyListeners();
    final chat = context.read<ChatProvider>();
    chat.conversations.removeWhere((c) => c.id == '333885df-8c96-42ff-ab61-e88cff9f563f');
    chat.conversations.removeWhere((c) => c.id == 'audit-archived-chat');
    chat.conversations.add(Conversation(
      id: '333885df-8c96-42ff-ab61-e88cff9f563f',
      matchId: '8b489d05-f315-4bff-a9b0-dc0ed2356fcc',
      participantIds: const ['51d817d4-7152-4b45-8eda-61e8aa5efb85', '67f3bdcb-9702-4da4-b54a-144977c4de24'],
      unreadCount: 0, status: 'active', expiresAt: now.add(const Duration(hours: 20)),
      createdAt: now, updatedAt: now, otherParticipant: profile,
    ));
    chat.conversations.add(Conversation(
      id: 'audit-archived-chat', matchId: 'audit-archived-match',
      participantIds: const ['51d817d4-7152-4b45-8eda-61e8aa5efb85', '67f3bdcb-9702-4da4-b54a-144977c4de24'],
      unreadCount: 0, status: 'expired', expiresAt: now.subtract(const Duration(hours: 1)),
      createdAt: now.subtract(const Duration(hours: 25)), updatedAt: now,
      otherParticipant: profile,
    ));
    chat.notifyListeners();
    setState(() => expanded = false);
  }

  void showMatchAcceptanceFixture() {
    seedVisualFixture();
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;
    final profiles = context.read<MatchingProvider>().dailyProfiles;
    if (profiles.isEmpty) return;
    showDialog<void>(context: context, builder: (_) => MatchAcceptanceDialog(
      matchId: 'audit-dialog-only', otherUser: profiles.first,
    ));
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
    const GoldWenApp(),
    Positioned(top: 120, right: 4,
      child: Material(color: Colors.blueGrey.shade800,
        borderRadius: BorderRadius.circular(8),
        child: TextButton(
          onPressed: () => setState(() => expanded = !expanded),
          child: Text(expanded ? 'Fermer recette' : 'Recette',
            style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ),
    ),
    if (expanded)
      Positioned(top: 170, right: 4, bottom: 35, width: 310,
        child: Material(color: Colors.white, elevation: 12,
          child: ListView(children: [
            const Padding(padding: EdgeInsets.all(12),
              child: Text('Recette — accès hors parcours normal')),
            ListTile(title: const Text('Connexion compte fictif local'),
              onTap: () { signInFixture(); setState(() => expanded = false); }),
            ListTile(title: const Text('Injecter fixture visuelle mémoire (pas API)'),
              onTap: seedVisualFixture),
            ListTile(title: const Text('Archive fictive — liste'),
              onTap: () { AppRouter.router.go('/archived-chats'); setState(() => expanded = false); }),
            ListTile(title: const Text('Archive fictive — lecture seule'),
              onTap: () { AppRouter.router.go('/chat/audit-archived-chat?archived=true'); setState(() => expanded = false); }),
            ListTile(title: const Text('Dialogue match fictif (sans action)'),
              onTap: showMatchAcceptanceFixture),
            ListTile(title: const Text('Dialogue limite API fictive'),
              onTap: () {
                final context = NavigationService.navigatorKey.currentContext;
                if (context != null) {
                  RateLimitDialog.show(context, ApiException(
                    statusCode: 429, code: 'BRUTE_FORCE_DETECTED',
                    message: 'Trop de tentatives',
                    rateLimitInfo: RateLimitInfo(retryAfterSeconds: 5),
                  ));
                  setState(() => expanded = false);
                }
              }),
            ListTile(title: const Text('Onboarding — genre'),
              onTap: () => openStandalone(const GenderSelectionPage())),
            ListTile(title: const Text('Onboarding — genres recherchés'),
              onTap: () => openStandalone(const GenderPreferencesPage())),
            ListTile(title: const Text('Onboarding — localisation'),
              onTap: () => openStandalone(const LocationSetupPage())),
            ListTile(title: const Text('Onboarding — critères'),
              onTap: () => openStandalone(const PreferencesSetupPage())),
            ListTile(title: const Text('Onboarding — informations'),
              onTap: () => openStandalone(const AdditionalInfoPage())),
            for (final route in routes.entries)
              ListTile(title: Text(route.key),
                onTap: () {
                  AppRouter.router.go(route.value);
                  setState(() => expanded = false);
                }),
            ListTile(title: const Text('Ancienne sélection — page sans route'),
              onTap: () => openStandalone(const DailyMatchesPage())),
            ListTile(title: const Text('Signalement — page sans route'),
              onTap: () => openStandalone(const ReportPage(
                targetUserId: '67f3bdcb-9702-4da4-b54a-144977c4de24',
                targetUserName: 'AlexRecette',
              ))),
          ]),
        ),
      ),
  ]);
}
