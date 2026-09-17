import 'package:flutter/foundation.dart';

import 'dart:io' show Platform;

class AppConfig {
  // Environment-based API URLs with fallback to localhost for development
  static const String mainApiBaseUrl = String.fromEnvironment(
    'MAIN_API_BASE_URL',
    defaultValue: 'https://api.goldwen.app/api/v1', // Production URL
  );
  static const String webSocketBaseUrl = String.fromEnvironment(
    'WEBSOCKET_BASE_URL',
    defaultValue: 'wss://api.goldwen.app/chat', // Production WebSocket URL
  );

  // Development host, used to reach a locally-running backend from a device
  // or emulator (see _getDevUrl / _getDevWebSocketUrl below). Defaults to
  // 10.0.2.2, the standard Android-emulator alias for the host machine's
  // localhost — this used to be a developer's real personal LAN IP address
  // hardcoded in source (192.168.1.183), which (a) leaked a piece of
  // someone's home network into the repo and (b) silently broke for anyone
  // else running the emulator. Testing against a physical device on a LAN
  // still works — override at build/run time:
  //   flutter run --dart-define=DEV_HOST_IP=192.168.1.42
  static const String devHostIp = String.fromEnvironment(
    'DEV_HOST_IP',
    defaultValue: '10.0.2.2',
  );

  // Development URLs (can be overridden with environment variables)
  static String get devMainApiBaseUrl => _getDevUrl('3000');
  static String get devWebSocketBaseUrl => _getDevWebSocketUrl('3000');

  /// Ajout d'un log pour debug l'URL utilisée sur le device
  static void debugPrintApiUrl() {
    final url = isDevelopment ? devMainApiBaseUrl : mainApiBaseUrl;
    // ignore: avoid_print
    debugPrint('[DEBUG] API URL utilisée: $url');
  }

  // Helper method to get the correct development URL based on platform
  static String _getDevUrl(String port) {
    try {
      if (Platform.isAndroid) {
        return 'http://$devHostIp:$port/api/v1';
      } else if (Platform.isIOS) {
        // iOS simulator shares the Mac's network stack — localhost works directly
        return 'http://localhost:$port/api/v1';
      }
    } catch (e) {
      // Platform.isAndroid might not be available in some contexts (like tests)
      // Fall back to localhost
    }
    return 'http://localhost:$port/api/v1';
  }

  // Helper method for WebSocket URLs
  static String _getDevWebSocketUrl(String port) {
    try {
      if (Platform.isAndroid) {
        return 'ws://$devHostIp:$port/chat';
      } else if (Platform.isIOS) {
        return 'ws://localhost:$port/chat';
      }
    } catch (e) {
      // Platform.isAndroid might not be available in some contexts (like tests)
      // Fall back to localhost
    }
    return 'ws://localhost:$port/chat';
  }

  // API Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);

  // WebSocket configuration
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 3;

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Feature flags (could be loaded from remote config)
  static const bool enableWebSocketChat = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;

  // Environment detection
  static bool get isDevelopment =>
      const bool.fromEnvironment('dart.vm.product') == false;
  static bool get isProduction =>
      const bool.fromEnvironment('dart.vm.product') == true;

  // Logging
  static const bool enableDebugLogs = true;
  static const bool enableNetworkLogs = true;
}
