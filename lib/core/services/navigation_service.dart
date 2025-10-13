import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;
  
  static void navigateToDiscoverTab() {
    // Navigate to home which shows the discover/daily matches tab
    if (context != null) {
      context!.go('/home');
    } else {
      navigator?.pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
  
  static void navigateToMatches() {
    if (context != null) {
      context!.push('/matches');
    } else {
      navigator?.pushNamed('/matches');
    }
  }
  
  static void navigateToChat(String conversationId) {
    if (context != null) {
      context!.push('/chat/$conversationId');
    } else {
      navigator?.pushNamed('/chat/$conversationId');
    }
  }
  
  static void navigateToNotifications() {
    if (context != null) {
      context!.push('/notifications');
    } else {
      navigator?.pushNamed('/notifications');
    }
  }
}