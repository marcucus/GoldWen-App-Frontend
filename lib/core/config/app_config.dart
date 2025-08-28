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
  static const String devMainApiBaseUrl = 'http://localhost:3000/api/v1';
  static const String devMatchingServiceBaseUrl = 'http://localhost:8000/api/v1';
  static const String devWebSocketBaseUrl = 'ws://localhost:3000/chat';
  
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