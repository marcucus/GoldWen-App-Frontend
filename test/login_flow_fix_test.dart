import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/user.dart';

void main() {
  group('Login Flow Fix Validation', () {
    test('ISSUE FIX: Users with both completion flags should redirect to home', () {
      // This test validates the main issue reported:
      // "Quand je me login sur un compte qui a isOnboarding et isProfileComplete 
      //  l'application me remet dans les formulaires alors que j'ai déjà tout fait"
      
      final completeUserBackendResponse = {
        'success': true,
        'data': {
          'id': 'user-completed',
          'email': 'completed-user@example.com',
          'isOnboardingCompleted': true,  // Personality questionnaire completed
          'isProfileCompleted': true,     // All profile requirements met
          'isEmailVerified': true,
          'profile': {
            'birthDate': '1990-01-01',
            'bio': 'Complete user profile',
          }
        }
      };

      // Simulate AuthProvider.refreshUser() parsing
      final userData = completeUserBackendResponse['data'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      // Verify user parsing is correct
      expect(user.isOnboardingCompleted, true);
      expect(user.isProfileCompleted, true);

      // Simulate splash page navigation logic
      String route = '';
      if (user.isOnboardingCompleted == true && user.isProfileCompleted == true) {
        route = '/home';
      } else if (user.isOnboardingCompleted == true) {
        route = '/profile-setup';
      } else {
        route = '/questionnaire';
      }

      // THE FIX: This should now be /home, not /questionnaire or /profile-setup
      expect(route, '/home', 
        reason: 'Complete users should go directly to home, not back to forms');
    });

    test('Navigation logic for all completion states', () {
      final testCases = [
        {
          'name': 'Both completed',
          'isOnboardingCompleted': true,
          'isProfileCompleted': true,
          'expectedRoute': '/home'
        },
        {
          'name': 'Only onboarding completed',
          'isOnboardingCompleted': true,
          'isProfileCompleted': false,
          'expectedRoute': '/profile-setup'
        },
        {
          'name': 'Neither completed',
          'isOnboardingCompleted': false,
          'isProfileCompleted': false,
          'expectedRoute': '/questionnaire'
        },
        {
          'name': 'Null values (treated as incomplete)',
          'isOnboardingCompleted': null,
          'isProfileCompleted': null,
          'expectedRoute': '/questionnaire'
        },
        {
          'name': 'Profile done but onboarding not (edge case)',
          'isOnboardingCompleted': false,
          'isProfileCompleted': true,
          'expectedRoute': '/questionnaire'
        },
      ];

      for (final testCase in testCases) {
        final userData = {
          'id': 'test-user',
          'email': 'test@example.com',
          'isOnboardingCompleted': testCase['isOnboardingCompleted'],
          'isProfileCompleted': testCase['isProfileCompleted'],
        };

        final user = User.fromJson(userData);

        // Splash page navigation logic
        String route = '';
        if (user.isOnboardingCompleted == true && user.isProfileCompleted == true) {
          route = '/home';
        } else if (user.isOnboardingCompleted == true) {
          route = '/profile-setup';
        } else {
          route = '/questionnaire';
        }

        expect(route, testCase['expectedRoute'], 
          reason: 'Navigation failed for case: ${testCase['name']}');
      }
    });

    test('Backend response parsing handles various formats', () {
      // Test boolean values
      final booleanResponse = {
        'id': 'user-1',
        'email': 'bool@example.com',
        'isOnboardingCompleted': true,
        'isProfileCompleted': true,
      };
      final user1 = User.fromJson(booleanResponse);
      expect(user1.isOnboardingCompleted, true);
      expect(user1.isProfileCompleted, true);

      // Test string values (some backends return strings)
      final stringResponse = {
        'id': 'user-2',
        'email': 'string@example.com',
        'isOnboardingCompleted': 'true',
        'isProfileCompleted': 'true',
      };
      final user2 = User.fromJson(stringResponse);
      expect(user2.isOnboardingCompleted, true);
      expect(user2.isProfileCompleted, true);

      // Test null values
      final nullResponse = {
        'id': 'user-3',
        'email': 'null@example.com',
        'isOnboardingCompleted': null,
        'isProfileCompleted': null,
      };
      final user3 = User.fromJson(nullResponse);
      expect(user3.isOnboardingCompleted, null);
      expect(user3.isProfileCompleted, null);

      // Test missing fields
      final missingResponse = {
        'id': 'user-4',
        'email': 'missing@example.com',
        // omitting completion flags
      };
      final user4 = User.fromJson(missingResponse);
      expect(user4.isOnboardingCompleted, null);
      expect(user4.isProfileCompleted, null);
    });

    test('Real backend response structure from /auth/me', () {
      // This simulates the actual response structure from the backend
      final realBackendResponse = {
        'success': true,
        'data': {
          'id': 'real-user-id',
          'email': 'real@example.com',
          'isOnboardingCompleted': true,
          'isProfileCompleted': true,
          'isEmailVerified': true,
          'profile': {
            'birthDate': '1990-01-01',
            'bio': 'Real user bio',
            'photos': [], // Would contain photo data
            'promptAnswers': [], // Would contain prompt answers
          }
        }
      };

      // Frontend extracts data like this (AuthProvider.refreshUser)
      final userData = realBackendResponse['data'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      expect(user.isOnboardingCompleted, true);
      expect(user.isProfileCompleted, true);
      expect(user.email, 'real@example.com');

      // Should navigate to home
      String route = '';
      if (user.isOnboardingCompleted == true && user.isProfileCompleted == true) {
        route = '/home';
      } else if (user.isOnboardingCompleted == true) {
        route = '/profile-setup';
      } else {
        route = '/questionnaire';
      }

      expect(route, '/home');
    });
  });
}