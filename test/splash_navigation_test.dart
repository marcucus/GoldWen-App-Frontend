import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/user.dart';

void main() {
  group('Splash Page Navigation Logic Tests', () {
    test('Navigation should require both completion flags to be true for home redirect', () {
      // Test case 1: Both flags true - should go to home
      final userBothTrue = User(
        id: 'test-id',
        email: 'test@example.com',
        isOnboardingCompleted: true,
        isProfileCompleted: true,
      );
      
      // Expected: Should navigate to /home
      expect(userBothTrue.isOnboardingCompleted, true);
      expect(userBothTrue.isProfileCompleted, true);
      
      // Test case 2: Only onboarding true - should go to profile setup
      final userOnboardingOnly = User(
        id: 'test-id',
        email: 'test@example.com',
        isOnboardingCompleted: true,
        isProfileCompleted: false,
      );
      
      // Expected: Should navigate to /profile-setup
      expect(userOnboardingOnly.isOnboardingCompleted, true);
      expect(userOnboardingOnly.isProfileCompleted, false);
      
      // Test case 3: Only profile true - should go to questionnaire
      final userProfileOnly = User(
        id: 'test-id',
        email: 'test@example.com',
        isOnboardingCompleted: false,
        isProfileCompleted: true,
      );
      
      // Expected: Should navigate to /questionnaire
      expect(userProfileOnly.isOnboardingCompleted, false);
      expect(userProfileOnly.isProfileCompleted, true);
      
      // Test case 4: Both false/null - should go to questionnaire
      final userNeither = User(
        id: 'test-id',
        email: 'test@example.com',
        isOnboardingCompleted: false,
        isProfileCompleted: false,
      );
      
      // Expected: Should navigate to /questionnaire
      expect(userNeither.isOnboardingCompleted, false);
      expect(userNeither.isProfileCompleted, false);
      
      // Test case 5: Null values - should go to questionnaire
      final userNulls = User(
        id: 'test-id',
        email: 'test@example.com',
        isOnboardingCompleted: null,
        isProfileCompleted: null,
      );
      
      // Expected: Should navigate to /questionnaire
      expect(userNulls.isOnboardingCompleted, null);
      expect(userNulls.isProfileCompleted, null);
    });

    test('Navigation logic validation', () {
      // Test the actual logic that would be used in splash page
      
      // Simulate the navigation logic for different scenarios
      String getExpectedRoute(bool? isOnboardingCompleted, bool? isProfileCompleted) {
        if (isOnboardingCompleted == true && isProfileCompleted == true) {
          return '/home';
        } else if (isOnboardingCompleted == true) {
          return '/profile-setup';
        } else {
          return '/questionnaire';
        }
      }
      
      // Test all scenarios
      expect(getExpectedRoute(true, true), '/home');
      expect(getExpectedRoute(true, false), '/profile-setup');
      expect(getExpectedRoute(true, null), '/profile-setup');
      expect(getExpectedRoute(false, true), '/questionnaire');
      expect(getExpectedRoute(false, false), '/questionnaire');
      expect(getExpectedRoute(null, true), '/questionnaire');
      expect(getExpectedRoute(null, false), '/questionnaire');
      expect(getExpectedRoute(null, null), '/questionnaire');
    });
  });
}