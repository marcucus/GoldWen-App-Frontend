import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  
  static void navigateToDiscoverTab() {
    // For now, just navigate to main and let the tab controller handle it
    navigator?.pushNamedAndRemoveUntil('/', (route) => false);
  }
  
  static void navigateToMatches() {
    navigator?.pushNamed('/matches');
  }
  
  static void navigateToChat(String conversationId) {
    navigator?.pushNamed('/chat/$conversationId');
  }
  
  static void navigateToNotifications() {
    navigator?.pushNamed('/notifications');
  }
}