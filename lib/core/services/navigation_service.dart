import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lets non-widget code (push notification handlers, background callbacks)
/// trigger navigation without a BuildContext of their own.
///
/// [navigatorKey] is wired into `AppRouter.router`'s own `navigatorKey`
/// (see `core/routes/app_router.dart`), so `context` below resolves to the
/// app's real root context once the router has built its first frame — this
/// is what makes `context!.go/push` below reach the live go_router instance
/// instead of being dead code.
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;

  static void navigateToDiscoverTab() {
    // Navigate to home which shows the discover/daily matches tab
    context?.go('/home');
  }

  static void navigateToMatches() {
    context?.push('/matches');
  }

  static void navigateToChat(String conversationId) {
    context?.push('/chat/$conversationId');
  }

  static void navigateToNotifications() {
    context?.push('/notifications');
  }

  /// Used when a refresh-token attempt has definitively failed (see
  /// ApiService.onSessionExpired / AuthProvider): drops the whole stack and
  /// lands on the welcome screen, since the user is no longer authenticated
  /// and every other page in the stack would just redirect there anyway.
  static void navigateToSessionExpired() {
    context?.go('/welcome');
  }
}
