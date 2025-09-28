import 'dart:io' show Platform;

class AppConfig {
  // Environment-based API URLs with fallback to localhost for development
  static const String mainApiBaseUrl = String.fromEnvironment(
    'MAIN_API_BASE_URL',
    defaultValue: 'https://api.goldwen.app/api/v1', // Production URL
  );
  static const String matchingServiceBaseUrl = String.fromEnvironment(
    'MATCHING_SERVICE_BASE_URL', 
    defaultValue: 'https://matching.goldwen.app/api/v1', // Production URL
  );
  static const String webSocketBaseUrl = String.fromEnvironment(
    'WEBSOCKET_BASE_URL',
    defaultValue: 'wss://api.goldwen.app/chat', // Production WebSocket URL
  );
  static const String matchingServiceApiKey = String.fromEnvironment(
    'MATCHING_SERVICE_API_KEY',
    defaultValue: 'matching-service-secret-key',
  );
  
  // Development URLs (can be overridden with environment variables)
  // Use 10.0.2.2 for Android emulator to access host machine, localhost for others
  static String get devMainApiBaseUrl => _getDevUrl('3000');
  static String get devMatchingServiceBaseUrl => _getDevUrl('8000');
  static String get devWebSocketBaseUrl => _getDevWebSocketUrl('3000');
  
  // Helper method to get the correct development URL based on platform
  static String _getDevUrl(String port) {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:$port/api/v1';
      } else if (Platform.isIOS) {
        // Use your Mac's local IP address for iOS physical devices
        return 'http://192.168.1.171:$port/api/v1';
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
        return 'ws://10.0.2.2:$port/chat';
      } else if (Platform.isIOS) {
        // Use your Mac's local IP address for iOS physical devices
        return 'ws://192.168.1.171:$port/chat';
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
  static const bool enableMatchingService = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  
  // Environment detection
  static bool get isDevelopment => const bool.fromEnvironment('dart.vm.product') == false;
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product') == true;
  
  // Logging
  static const bool enableDebugLogs = true;
  static const bool enableNetworkLogs = true;
}