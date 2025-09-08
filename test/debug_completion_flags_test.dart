import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/user.dart';

void main() {
  group('Debug Completion Flags Parsing', () {
    test('Test different backend response formats', () {
      // Test case 1: Backend returns boolean true/true
      final jsonBothTrue = {
        'id': 'test-id',
        'email': 'test@example.com',
        'isOnboardingCompleted': true,
        'isProfileCompleted': true,
      };

      final userBothTrue = User.fromJson(jsonBothTrue);
      print('Test 1 - Boolean true/true:');
      print('  isOnboardingCompleted: ${userBothTrue.isOnboardingCompleted}');
      print('  isProfileCompleted: ${userBothTrue.isProfileCompleted}');
      expect(userBothTrue.isOnboardingCompleted, true);
      expect(userBothTrue.isProfileCompleted, true);

      // Test case 2: Backend returns boolean false/false
      final jsonBothFalse = {
        'id': 'test-id',
        'email': 'test@example.com',
        'isOnboardingCompleted': false,
        'isProfileCompleted': false,
      };

      final userBothFalse = User.fromJson(jsonBothFalse);
      print('\nTest 2 - Boolean false/false:');
      print('  isOnboardingCompleted: ${userBothFalse.isOnboardingCompleted}');
      print('  isProfileCompleted: ${userBothFalse.isProfileCompleted}');
      expect(userBothFalse.isOnboardingCompleted, false);
      expect(userBothFalse.isProfileCompleted, false);

      // Test case 3: Backend returns null values
      final jsonNulls = {
        'id': 'test-id',
        'email': 'test@example.com',
        'isOnboardingCompleted': null,
        'isProfileCompleted': null,
      };

      final userNulls = User.fromJson(jsonNulls);
      print('\nTest 3 - Null values:');
      print('  isOnboardingCompleted: ${userNulls.isOnboardingCompleted}');
      print('  isProfileCompleted: ${userNulls.isProfileCompleted}');
      expect(userNulls.isOnboardingCompleted, null);
      expect(userNulls.isProfileCompleted, null);

      // Test case 4: Backend omits the fields
      final jsonOmitted = {
        'id': 'test-id',
        'email': 'test@example.com',
        // omitting completion flags
      };

      final userOmitted = User.fromJson(jsonOmitted);
      print('\nTest 4 - Omitted fields:');
      print('  isOnboardingCompleted: ${userOmitted.isOnboardingCompleted}');
      print('  isProfileCompleted: ${userOmitted.isProfileCompleted}');
      expect(userOmitted.isOnboardingCompleted, null);
      expect(userOmitted.isProfileCompleted, null);

      // Test case 5: Mixed completion status (common scenario)
      final jsonMixed = {
        'id': 'test-id',
        'email': 'test@example.com',
        'isOnboardingCompleted': true,
        'isProfileCompleted': false,
      };

      final userMixed = User.fromJson(jsonMixed);
      print('\nTest 5 - Mixed completion (onboarding true, profile false):');
      print('  isOnboardingCompleted: ${userMixed.isOnboardingCompleted}');
      print('  isProfileCompleted: ${userMixed.isProfileCompleted}');
      expect(userMixed.isOnboardingCompleted, true);
      expect(userMixed.isProfileCompleted, false);
    });

    test('Test navigation logic with different completion states', () {
      // Simulate the navigation logic from splash page
      String getExpectedRoute(bool? isOnboardingCompleted, bool? isProfileCompleted) {
        print('\nNavigation decision for:');
        print('  isOnboardingCompleted: $isOnboardingCompleted');
        print('  isProfileCompleted: $isProfileCompleted');
        
        if (isOnboardingCompleted == true && isProfileCompleted == true) {
          print('  → Redirecting to: /home');
          return '/home';
        } else if (isOnboardingCompleted == true) {
          print('  → Redirecting to: /profile-setup');
          return '/profile-setup';
        } else {
          print('  → Redirecting to: /questionnaire');
          return '/questionnaire';
        }
      }

      // Test the problematic case that should go to home
      expect(getExpectedRoute(true, true), '/home');
      
      // Test other valid cases
      expect(getExpectedRoute(true, false), '/profile-setup');
      expect(getExpectedRoute(true, null), '/profile-setup');
      expect(getExpectedRoute(false, true), '/questionnaire');
      expect(getExpectedRoute(false, false), '/questionnaire');
      expect(getExpectedRoute(null, true), '/questionnaire');
      expect(getExpectedRoute(null, false), '/questionnaire');
      expect(getExpectedRoute(null, null), '/questionnaire');
    });

    test('Test backend response structure that might be causing issues', () {
      // Simulate potential backend response with nested data
      final backendResponse = {
        'success': true,
        'data': {
          'id': 'test-id',
          'email': 'test@example.com',
          'isOnboardingCompleted': true,
          'isProfileCompleted': true,
          'isEmailVerified': true,
          'profile': {
            'birthDate': '1990-01-01',
            'bio': 'Test bio'
          }
        }
      };

      // This is what the frontend should extract
      final userData = backendResponse['data'] as Map<String, dynamic>;
      final user = User.fromJson(userData);
      
      print('\nBackend response test:');
      print('  Full response: $backendResponse');
      print('  Extracted data: $userData');
      print('  Parsed isOnboardingCompleted: ${user.isOnboardingCompleted}');
      print('  Parsed isProfileCompleted: ${user.isProfileCompleted}');
      
      expect(user.isOnboardingCompleted, true);
      expect(user.isProfileCompleted, true);
    });
  });
}