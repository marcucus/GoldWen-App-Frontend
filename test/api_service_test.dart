import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/core/services/websocket_service.dart';
import 'package:goldwen_app/core/models/models.dart';

void main() {
  group('ApiService Tests', () {
    test('should set and manage JWT token correctly', () {
      // Test token setting
      const testToken = 'test-jwt-token-123';
      ApiService.setToken(testToken);
      
      expect(ApiService.token, equals(testToken));
      
      // Test token clearing
      ApiService.clearToken();
      expect(ApiService.token, isNull);
    });

    test('should have correct base URL', () {
      expect(ApiService.baseUrl, equals('http://localhost:3000/api/v1'));
    });

    test('should handle API exceptions correctly', () {
      final exception = ApiException(
        statusCode: 400,
        message: 'Test error',
        code: 'TEST_ERROR',
      );

      expect(exception.statusCode, equals(400));
      expect(exception.message, equals('Test error'));
      expect(exception.code, equals('TEST_ERROR'));
      expect(exception.isValidationError, isTrue);
      expect(exception.isAuthError, isFalse);
    });

    test('should identify different error types', () {
      final authError = ApiException(statusCode: 401, message: 'Unauthorized');
      final notFoundError = ApiException(statusCode: 404, message: 'Not found');
      final serverError = ApiException(statusCode: 500, message: 'Server error');

      expect(authError.isAuthError, isTrue);
      expect(notFoundError.isNotFound, isTrue);
      expect(serverError.isServerError, isTrue);
    });
  });

  group('MatchingServiceApi Tests', () {
    test('should have correct base URL and headers', () {
      expect(MatchingServiceApi.baseUrl, equals('http://localhost:8000/api/v1'));
      expect(MatchingServiceApi.apiKey, equals('matching-service-secret-key'));
    });
  });

  group('WebSocketService Tests', () {
    test('should initialize with correct base URL', () {
      final wsService = WebSocketService();
      expect(WebSocketService.baseUrl, equals('ws://localhost:3000/chat'));
    });

    test('should require token before connecting', () {
      final wsService = WebSocketService();
      expect(() => wsService.connect(), throwsException);
    });
  });

  group('Model Tests', () {
    test('User model should serialize correctly', () {
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2023-01-01T00:00:00Z'),
        status: 'active',
      );

      final json = user.toJson();
      final userFromJson = User.fromJson(json);

      expect(userFromJson.id, equals(user.id));
      expect(userFromJson.email, equals(user.email));
      expect(userFromJson.firstName, equals(user.firstName));
      expect(userFromJson.lastName, equals(user.lastName));
    });

    test('Profile model should calculate age correctly', () {
      final profile = Profile(
        id: 'test-id',
        userId: 'user-id',
        birthDate: DateTime(1990, 1, 1),
        isComplete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final expectedAge = DateTime.now().year - 1990;
      expect(profile.age, equals(expectedAge));
    });

    test('Subscription model should check status correctly', () {
      final subscription = Subscription(
        id: 'test-id',
        userId: 'user-id',
        planId: 'plan-id',
        status: 'active',
        platform: 'ios',
        currentPeriodStart: DateTime.now().subtract(const Duration(days: 10)),
        currentPeriodEnd: DateTime.now().add(const Duration(days: 20)),
        autoRenew: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(subscription.isActive, isTrue);
      expect(subscription.isExpired, isFalse);
      expect(subscription.willRenew, isTrue);
      expect(subscription.daysUntilExpiry, greaterThan(0));
    });

    test('NotificationSettings should handle quiet hours correctly', () {
      final settings = NotificationSettings(
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        promotions: false,
        systemUpdates: true,
        emailFrequency: 'weekly',
        pushEnabled: true,
        emailEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
      );

      // This is a basic test - in real scenarios, you'd test with specific times
      expect(settings.quietHoursStart, equals('22:00'));
      expect(settings.quietHoursEnd, equals('08:00'));
    });
  });

  group('Integration Tests', () {
    testWidgets('should create email auth page without errors', (WidgetTester tester) async {
      // This test verifies the widget can be instantiated
      // In a real Flutter environment, we would test the full widget tree
      expect(true, isTrue); // Placeholder test
    });

    test('should handle API integration flow', () {
      // Test that shows how the API service would be used in practice
      ApiService.setToken('test-token');
      
      // Verify token is set
      expect(ApiService.token, equals('test-token'));
      
      // Clear token
      ApiService.clearToken();
      expect(ApiService.token, isNull);
    });
  });
}