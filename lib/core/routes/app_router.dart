import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/pages/welcome_page.dart';
import '../../features/onboarding/pages/personality_questionnaire_page.dart';
import '../../features/auth/pages/auth_page.dart';
import '../../features/auth/pages/email_auth_page.dart';
import '../../features/auth/pages/splash_page.dart';
import '../../features/profile/pages/profile_setup_page.dart';
import '../../features/main/pages/main_navigation_page.dart';
import '../../features/matching/pages/daily_matches_page.dart';
import '../../features/matching/pages/profile_detail_page.dart';
import '../../features/matching/pages/matches_page.dart';
import '../../features/matching/pages/history_page.dart';
import '../../features/matching/pages/who_liked_me_page.dart';
import '../../features/matching/pages/advanced_recommendations_page.dart';
import '../../features/chat/pages/chat_page.dart';
import '../../features/subscription/pages/subscription_page.dart';
import '../../features/legal/pages/terms_page.dart';
import '../../features/legal/pages/privacy_page.dart';
import '../../features/legal/pages/privacy_settings_page.dart';
import '../../features/user/pages/user_profile_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/notifications/pages/notifications_page.dart';
import '../../features/notifications/pages/notification_test_page.dart';
import '../../features/admin/pages/admin_login_page.dart';
import '../../features/admin/pages/admin_dashboard_page.dart';
import '../../features/admin/pages/admin_users_page.dart';
import '../../features/admin/pages/admin_reports_page.dart';
import '../../features/admin/pages/admin_support_page.dart';
import '../../features/admin/guards/admin_auth_guard.dart';
import '../../features/reports/pages/user_reports_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
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
        builder: (context, state) => const MainNavigationPage(),
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

      // Matching Features
      GoRoute(
        path: '/matches',
        name: 'matches',
        builder: (context, state) => const MatchesPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/who-liked-me',
        name: 'who-liked-me',
        builder: (context, state) => const WhoLikedMePage(),
      ),
      GoRoute(
        path: '/advanced-recommendations',
        name: 'advanced-recommendations',
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          final candidateIdsParam = state.uri.queryParameters['candidateIds'];
          final candidateIds = candidateIdsParam?.split(',');
          return AdvancedRecommendationsPage(
            userId: userId,
            candidateIds: candidateIds,
          );
        },
      ),

      // Subscription
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),

      // Legal Pages
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: '/privacy-settings',
        name: 'privacy-settings',
        builder: (context, state) => const PrivacySettingsPage(),
      ),

      // User Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const UserProfilePage(),
      ),
      GoRoute(
        path: '/user-profile',
        name: 'user-profile',
        builder: (context, state) => const UserProfilePage(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // User Reports
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const UserReportsPage(),
      ),

      // Notification Testing (Development only)
      GoRoute(
        path: '/notifications/test',
        name: 'notification-test',
        builder: (context, state) => const NotificationTestPage(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'admin-reports',
        builder: (context, state) => const AdminReportsPage(),
      ),
      GoRoute(
        path: '/admin/support',
        name: 'admin-support',
        builder: (context, state) => const AdminSupportPage(),
      ),
    ],
  );
}
