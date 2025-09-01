import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/user.dart';

void main() {
  group('Auth Type Safety Tests', () {
    test('should handle non-string token fields without type cast error', () {
      // Simulate the problematic response that caused the original error
      final response = {
        'user': {
          'id': '123',
          'email': 'test@example.com',
          'firstName': 'John',
          'lastName': 'Doe',
          'createdAt': '2023-01-01T00:00:00.000Z',
          'updatedAt': '2023-01-01T00:00:00.000Z',
        },
        'token': 12345, // This is an int, not a string - would cause type cast error
      };

      final possibleTokenFields = [
        'token', 'accessToken', 'access_token', 'authToken', 'auth_token',
        'jwt', 'jwtToken', 'jwt_token', 'bearerToken', 'bearer_token'
      ];
      
      String? token;
      for (final field in possibleTokenFields) {
        // This is the fixed version that should not throw
        final dataToken = response[field] is String ? response[field] as String : null;
        token = dataToken;
        if (token != null && token.isNotEmpty) {
          break;
        }
      }

      // Should not find a token since it's an int
      expect(token, isNull);
    });

    test('should handle non-string user fields without type cast error', () {
      final userData = {
        'id': 123, // int instead of string
        'email': 'test@example.com',
        'firstName': 'John',
        'lastName': 'Doe',
        'notificationsEnabled': 'true', // string instead of bool
        'emailNotifications': 1, // int instead of bool
        'pushNotifications': null, // null value
        'status': 42, // int instead of string
      };

      // This should not throw a type cast error with our fixes
      expect(() => User.fromJson(userData), returnsNormally);
      
      final user = User.fromJson(userData);
      expect(user.id, equals('123')); // Should convert int to string
      expect(user.email, equals('test@example.com'));
      expect(user.firstName, equals('John'));
      expect(user.lastName, equals('Doe'));
      expect(user.notificationsEnabled, isTrue); // Should parse 'true' string
      expect(user.emailNotifications, isFalse); // Should handle non-bool int as false
      expect(user.pushNotifications, isTrue); // Should use default for null
      expect(user.status, equals('42')); // Should convert int to string
    });

    test('should handle null values in all user fields', () {
      final userData = {
        'id': null,
        'email': null,
        'firstName': null,
        'lastName': null,
        'fcmToken': null,
        'notificationsEnabled': null,
        'emailNotifications': null,
        'pushNotifications': null,
        'status': null,
      };

      // This should not throw with our fixes
      expect(() => User.fromJson(userData), returnsNormally);
      
      final user = User.fromJson(userData);
      expect(user.id, equals('')); // Should use default empty string
      expect(user.email, equals('')); // Should use default empty string
      expect(user.firstName, equals('')); // Should use default empty string
      expect(user.lastName, equals('')); // Should use default empty string
      expect(user.fcmToken, isNull); // Should remain null
      expect(user.notificationsEnabled, isTrue); // Should use default true
      expect(user.emailNotifications, isTrue); // Should use default true
      expect(user.pushNotifications, isTrue); // Should use default true
      expect(user.status, equals('active')); // Should use default 'active'
    });

    test('should handle mixed type response structures without type cast error', () {
      final response = {
        'data': {
          'user': 'not_a_map', // This is a string, not a Map - would cause type cast error
          'profile': {
            'id': 456,
            'email': 'profile@example.com',
            'firstName': 'Jane',
            'lastName': 'Smith',
          },
          'token': ['array', 'not', 'string'], // Array instead of string
        }
      };

      final data = response['data'] as Map<String, dynamic>;
      
      // Test userData extraction with type safety
      Map<String, dynamic>? userData;
      if (data['user'] != null) {
        if (data['user'] is Map<String, dynamic>) {
          userData = data['user'] as Map<String, dynamic>;
        } else {
          // Should print warning but not crash
          expect(data['user'], isA<String>());
        }
      } else if (data['profile'] != null) {
        if (data['profile'] is Map<String, dynamic>) {
          userData = data['profile'] as Map<String, dynamic>;
        }
      }

      // Should find userData in profile field
      expect(userData, isNotNull);
      expect(userData!['email'], equals('profile@example.com'));

      // Test token extraction with type safety
      final possibleTokenFields = ['token', 'accessToken'];
      String? token;
      for (final field in possibleTokenFields) {
        final dataToken = data[field] is String ? data[field] as String : null;
        token = dataToken;
        if (token != null && token.isNotEmpty) {
          break;
        }
      }

      // Should not find token since it's an array
      expect(token, isNull);
    });
  });
}