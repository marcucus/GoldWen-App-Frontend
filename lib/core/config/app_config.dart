class AppConfig {
  static const String mainApiBaseUrl = 'http://localhost:3000/api/v1';
  static const String matchingServiceBaseUrl = 'http://localhost:8000/api/v1';
  static const String webSocketBaseUrl = 'ws://localhost:3000/chat';
  static const String matchingServiceApiKey = 'matching-service-secret-key';
  
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