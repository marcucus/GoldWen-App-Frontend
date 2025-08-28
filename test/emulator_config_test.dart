import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/config/app_config.dart';

void main() {
  group('Emulator Configuration Tests', () {
    test('should provide correct URLs for Android emulator compatibility', () {
      // Test that development URLs are properly configured
      // The URLs should support both localhost (iOS/web) and 10.0.2.2 (Android emulator)
      
      final mainApiUrl = AppConfig.devMainApiBaseUrl;
      final matchingUrl = AppConfig.devMatchingServiceBaseUrl;
      final wsUrl = AppConfig.devWebSocketBaseUrl;
      
      // Verify URLs are properly formatted
      expect(mainApiUrl, contains('/api/v1'));
      expect(matchingUrl, contains('/api/v1'));
      expect(wsUrl, contains('/chat'));
      
      // Verify they're either localhost or Android emulator compatible
      expect(mainApiUrl, anyOf(
        contains('localhost:3000'),
        contains('10.0.2.2:3000')
      ));
      
      expect(matchingUrl, anyOf(
        contains('localhost:8000'),
        contains('10.0.2.2:8000')
      ));
      
      expect(wsUrl, anyOf(
        contains('localhost:3000'),
        contains('10.0.2.2:3000')
      ));
      
      // Verify protocols are correct
      expect(mainApiUrl, startsWith('http://'));
      expect(matchingUrl, startsWith('http://'));
      expect(wsUrl, startsWith('ws://'));
    });
    
    test('should maintain production URLs unchanged', () {
      // Production URLs should not be affected by platform detection
      expect(AppConfig.mainApiBaseUrl, equals('https://api.goldwen.app/api/v1'));
      expect(AppConfig.matchingServiceBaseUrl, equals('https://matching.goldwen.app/api/v1'));
      expect(AppConfig.webSocketBaseUrl, equals('wss://api.goldwen.app/chat'));
    });
    
    test('should handle environment detection correctly', () {
      // Verify environment detection still works
      expect(AppConfig.isDevelopment, isNotNull);
      expect(AppConfig.isProduction, isNotNull);
      
      // In test environment, should be development
      expect(AppConfig.isDevelopment, isTrue);
      expect(AppConfig.isProduction, isFalse);
    });
  });
}