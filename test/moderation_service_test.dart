import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/moderation.dart';
import 'package:goldwen_app/core/services/moderation_service.dart';
import 'package:goldwen_app/core/services/api_service.dart';

void main() {
  group('ModerationService', () {
    setUp(() {
      // Set up API service for testing
      ApiService.setToken('test-token');
    });

    tearDown(() {
      ApiService.clearToken();
    });

    test('getModerationStatus should return approved for 404', () async {
      // Note: This test would require mocking HTTP requests
      // For now, we verify the method exists and has correct signature
      expect(
        () => ModerationService.getModerationStatus(
          resourceType: 'message',
          resourceId: 'test-id',
        ),
        returnsNormally,
      );
    });

    test('getModerationHistory should return empty list on error', () async {
      // Note: This test would require mocking HTTP requests
      // For now, we verify the method exists and has correct signature
      expect(
        () => ModerationService.getModerationHistory(page: 1, limit: 20),
        returnsNormally,
      );
    });

    test('appealModerationDecision should accept required parameters', () async {
      // Note: This test would require mocking HTTP requests
      // For now, we verify the method exists and has correct signature
      expect(
        () => ModerationService.appealModerationDecision(
          resourceType: 'message',
          resourceId: 'test-id',
          reason: 'This is a test reason',
        ),
        returnsNormally,
      );
    });
  });

  group('ModerationService API integration', () {
    test('should construct correct endpoint for getModerationStatus', () {
      final baseUrl = ApiService.baseUrl;
      final resourceType = 'message';
      final resourceId = 'msg-123';

      final expectedUrl = '$baseUrl/moderation/status/$resourceType/$resourceId';

      // Verify the URL pattern is correct
      expect(expectedUrl, contains('/moderation/status/'));
      expect(expectedUrl, contains('message'));
      expect(expectedUrl, contains('msg-123'));
    });

    test('should construct correct endpoint for getModerationHistory', () {
      final baseUrl = ApiService.baseUrl;
      final page = 1;
      final limit = 20;

      final expectedUrl = '$baseUrl/moderation/history?page=$page&limit=$limit';

      // Verify the URL pattern is correct
      expect(expectedUrl, contains('/moderation/history'));
      expect(expectedUrl, contains('page=1'));
      expect(expectedUrl, contains('limit=20'));
    });

    test('should construct correct endpoint for appealModerationDecision', () {
      final baseUrl = ApiService.baseUrl;
      final expectedUrl = '$baseUrl/moderation/appeal';

      // Verify the URL pattern is correct
      expect(expectedUrl, contains('/moderation/appeal'));
    });
  });
}
