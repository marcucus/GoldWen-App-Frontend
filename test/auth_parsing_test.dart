import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/user.dart';
import 'package:goldwen_app/features/auth/providers/auth_provider.dart';

void main() {
  group('Authentication Response Parsing Tests', () {
    test('should handle direct user and token response', () {
      final response = {
        'user': {
          'id': '123',
          'email': 'test@example.com',
          'firstName': 'John',
          'lastName': 'Doe',
          'createdAt': '2023-01-01T00:00:00.000Z',
          'updatedAt': '2023-01-01T00:00:00.000Z',
        },
        'token': 'jwt_token_here'
      };

      // Test User.fromJson
      final userData = response['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);
      
      expect(user.id, equals('123'));
      expect(user.email, equals('test@example.com'));
      expect(user.firstName, equals('John'));
      expect(user.lastName, equals('Doe'));
    });

    test('should handle nested data response', () {
      final response = {
        'data': {
          'user': {
            'id': '123',
            'email': 'test@example.com',
            'firstName': 'John',
            'lastName': 'Doe',
            'createdAt': '2023-01-01T00:00:00.000Z',
            'updatedAt': '2023-01-01T00:00:00.000Z',
          },
          'token': 'jwt_token_here'
        }
      };

      final data = response['data'] as Map<String, dynamic>;
      final userData = data['user'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = User.fromJson(userData);
      
      expect(user.id, equals('123'));
      expect(user.email, equals('test@example.com'));
      expect(token, equals('jwt_token_here'));
    });

    test('should handle flat response with accessToken', () {
      final response = {
        'id': '123',
        'email': 'test@example.com',
        'firstName': 'John',
        'lastName': 'Doe',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-01T00:00:00.000Z',
        'accessToken': 'jwt_token_here'
      };

      final user = User.fromJson(response);
      final token = response['accessToken'] as String;
      
      expect(user.id, equals('123'));
      expect(user.email, equals('test@example.com'));
      expect(token, equals('jwt_token_here'));
    });

    test('should handle missing optional fields', () {
      final response = {
        'id': '123',
        'email': 'test@example.com',
        'firstName': 'John',
        'lastName': 'Doe',
        // Missing createdAt, updatedAt - should use defaults
      };

      final user = User.fromJson(response);
      
      expect(user.id, equals('123'));
      expect(user.email, equals('test@example.com'));
      expect(user.firstName, equals('John'));
      expect(user.lastName, equals('Doe'));
      expect(user.status, equals('active')); // default value
    });

    test('should handle snake_case field names', () {
      final response = {
        'id': '123',
        'email': 'test@example.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      final user = User.fromJson(response);
      
      expect(user.id, equals('123'));
      expect(user.email, equals('test@example.com'));
      expect(user.firstName, equals('John'));
      expect(user.lastName, equals('Doe'));
    });
  });
}