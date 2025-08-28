import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/pages/welcome_page.dart';
import '../../features/onboarding/pages/personality_questionnaire_page.dart';
import '../../features/auth/pages/auth_page.dart';
import '../../features/auth/pages/email_auth_page.dart';
import '../../features/profile/pages/profile_setup_page.dart';
import '../../features/matching/pages/daily_matches_page.dart';
import '../../features/matching/pages/profile_detail_page.dart';
import '../../features/chat/pages/chat_page.dart';
import '../../features/subscription/pages/subscription_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      // Welcome & Authentication
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/auth/email',
        name: 'email-auth',
        builder: (context, state) => const EmailAuthPage(),
      ),

      // Onboarding Flow
      GoRoute(
        path: '/questionnaire',
        name: 'questionnaire',
        builder: (context, state) => const PersonalityQuestionnairePage(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),

      // Main App
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const DailyMatchesPage(),
      ),
      GoRoute(
        path: '/profile/:profileId',
        name: 'profile-detail',
        builder: (context, state) {
          final profileId = state.pathParameters['profileId']!;
          return ProfileDetailPage(profileId: profileId);
        },
      ),
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatPage(chatId: chatId);
        },
      ),

      // Subscription
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
    ],
  );
}
