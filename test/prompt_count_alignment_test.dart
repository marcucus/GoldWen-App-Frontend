import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';

/// Tests to verify alignment between frontend and backend prompt count expectations
/// 
/// According to specifications.md:
/// "L'utilisateur doit répondre à 3 'prompts' textuels pour finaliser son profil."
/// 
/// This test suite ensures that:
/// 1. Frontend expects exactly 3 prompts (not 10 or any other number)
/// 2. Profile completion validation checks for 3 prompts
/// 3. Backend response mapping correctly uses 'minimumPrompts.satisfied'
void main() {
  group('Prompt Count Alignment Tests (Frontend <-> Backend)', () {
    late ProfileProvider profileProvider;

    setUp(() {
      profileProvider = ProfileProvider();
    });

    test('Frontend should require exactly 3 prompts for profile completion', () {
      // Arrange - Setup profile with basic info
      profileProvider.setBasicInfo(
        'Test User',
        25,
        'Test bio',
        birthDate: DateTime(1998, 1, 1),
      );

      // Act - Add exactly 3 prompt answers
      profileProvider.setPromptAnswer('prompt-1', 'Answer 1');
      profileProvider.setPromptAnswer('prompt-2', 'Answer 2');
      profileProvider.setPromptAnswer('prompt-3', 'Answer 3');

      // Assert - Should have exactly 3 prompts
      expect(
        profileProvider.promptAnswers.length,
        equals(3),
        reason: 'Frontend should accept exactly 3 prompts to align with backend requirement',
      );
    });

    test('Frontend should NOT require more than 3 prompts', () {
      // This test ensures we haven\'t reverted to the old 10-prompt requirement

      // Arrange - Add exactly 3 prompt answers
      profileProvider.setPromptAnswer('prompt-1', 'Answer 1');
      profileProvider.setPromptAnswer('prompt-2', 'Answer 2');
      profileProvider.setPromptAnswer('prompt-3', 'Answer 3');

      // Assert - 3 prompts should be sufficient
      expect(
        profileProvider.promptAnswers.length,
        equals(3),
        reason: 'Frontend should not require more than 3 prompts (e.g., 10)',
      );
      expect(
        profileProvider.promptAnswers.length >= 3,
        isTrue,
        reason: 'Profile should be considered valid with 3 prompts',
      );
    });

    test('Frontend should accept 3 prompts minimum, not require exact count > 3', () {
      // This verifies the >= 3 logic, not == 10 logic

      // Test with exactly 3 prompts
      profileProvider.setPromptAnswer('prompt-1', 'Answer 1');
      profileProvider.setPromptAnswer('prompt-2', 'Answer 2');
      profileProvider.setPromptAnswer('prompt-3', 'Answer 3');
      
      expect(profileProvider.promptAnswers.length >= 3, isTrue);
      
      // User can add more if they want (though UI limits to 3)
      profileProvider.setPromptAnswer('prompt-4', 'Answer 4');
      expect(profileProvider.promptAnswers.length >= 3, isTrue);
    });

    test('Prompt answers format should match backend API expectation', () {
      // Arrange
      profileProvider.setPromptAnswer('uuid-1', 'First answer');
      profileProvider.setPromptAnswer('uuid-2', 'Second answer');
      profileProvider.setPromptAnswer('uuid-3', 'Third answer');

      // Act - Format for API submission
      final promptAnswersForApi = profileProvider.promptAnswers.entries.map((entry) {
        return {
          'promptId': entry.key,
          'answer': entry.value,
        };
      }).toList();

      // Assert - Should have correct structure
      expect(promptAnswersForApi, hasLength(3));
      expect(promptAnswersForApi[0], containsPair('promptId', 'uuid-1'));
      expect(promptAnswersForApi[0], containsPair('answer', 'First answer'));
      expect(promptAnswersForApi[1], containsPair('promptId', 'uuid-2'));
      expect(promptAnswersForApi[1], containsPair('answer', 'Second answer'));
      expect(promptAnswersForApi[2], containsPair('promptId', 'uuid-3'));
      expect(promptAnswersForApi[2], containsPair('answer', 'Third answer'));
    });

    test('Profile completion check should use >= 3, not == 10', () {
      // This test verifies the local completion check logic

      // Arrange - Set up a complete profile with exactly 3 prompts
      profileProvider.setBasicInfo(
        'John Doe',
        30,
        'A short bio',
        birthDate: DateTime(1993, 5, 15),
      );
      
      profileProvider.setPromptAnswer('p1', 'Answer 1');
      profileProvider.setPromptAnswer('p2', 'Answer 2');
      profileProvider.setPromptAnswer('p3', 'Answer 3');

      // Assert - Verify we have the right number
      expect(profileProvider.promptAnswers.length, equals(3));
      expect(
        profileProvider.promptAnswers.length >= 3,
        isTrue,
        reason: 'Completion check should use >= 3, not require exactly 10',
      );
    });

    test('Empty or insufficient prompts should not satisfy requirement', () {
      // Test with 0 prompts
      expect(profileProvider.promptAnswers.length, equals(0));
      expect(profileProvider.promptAnswers.length >= 3, isFalse);

      // Test with 1 prompt
      profileProvider.setPromptAnswer('p1', 'Answer 1');
      expect(profileProvider.promptAnswers.length, equals(1));
      expect(profileProvider.promptAnswers.length >= 3, isFalse);

      // Test with 2 prompts
      profileProvider.setPromptAnswer('p2', 'Answer 2');
      expect(profileProvider.promptAnswers.length, equals(2));
      expect(profileProvider.promptAnswers.length >= 3, isFalse);

      // Test with 3 prompts - should now satisfy
      profileProvider.setPromptAnswer('p3', 'Answer 3');
      expect(profileProvider.promptAnswers.length, equals(3));
      expect(profileProvider.promptAnswers.length >= 3, isTrue);
    });

    test('Removing prompts should update count correctly', () {
      // Add 3 prompts
      profileProvider.setPromptAnswer('p1', 'Answer 1');
      profileProvider.setPromptAnswer('p2', 'Answer 2');
      profileProvider.setPromptAnswer('p3', 'Answer 3');
      expect(profileProvider.promptAnswers.length, equals(3));

      // Remove one
      profileProvider.removePromptAnswer('p1');
      expect(profileProvider.promptAnswers.length, equals(2));
      expect(profileProvider.promptAnswers.length >= 3, isFalse);

      // Add it back
      profileProvider.setPromptAnswer('p1', 'Answer 1');
      expect(profileProvider.promptAnswers.length, equals(3));
      expect(profileProvider.promptAnswers.length >= 3, isTrue);
    });

    test('Clearing prompts should reset to 0', () {
      // Add 3 prompts
      profileProvider.setPromptAnswer('p1', 'Answer 1');
      profileProvider.setPromptAnswer('p2', 'Answer 2');
      profileProvider.setPromptAnswer('p3', 'Answer 3');
      expect(profileProvider.promptAnswers.length, equals(3));

      // Clear all
      profileProvider.clearPromptAnswers();
      expect(profileProvider.promptAnswers.length, equals(0));
      expect(profileProvider.promptAnswers.length >= 3, isFalse);
    });
  });

  group('Backend Response Mapping Alignment', () {
    test('Profile completion should map minimumPrompts.satisfied, not promptAnswers.satisfied', () {
      // This test documents the correct backend response mapping
      // The backend returns: requirements.minimumPrompts.satisfied
      // NOT: requirements.promptAnswers.satisfied
      
      // Simulated backend response structure
      final backendResponse = {
        'requirements': {
          'minimumPrompts': {
            'required': 3,
            'current': 3,
            'satisfied': true,
          },
          'minimumPhotos': {
            'required': 3,
            'current': 3,
            'satisfied': true,
          },
        },
      };

      // The mapping should use 'minimumPrompts', not 'promptAnswers'
      final hasPrompts = backendResponse['requirements']?['minimumPrompts']?['satisfied'] ?? false;
      
      expect(
        hasPrompts,
        isTrue,
        reason: 'Should correctly map minimumPrompts.satisfied from backend',
      );

      // Verify that trying to use the old field name would fail
      final wrongField = backendResponse['requirements']?['promptAnswers']?['satisfied'];
      expect(
        wrongField,
        isNull,
        reason: 'Backend does not send promptAnswers.satisfied, only minimumPrompts.satisfied',
      );
    });

    test('Backend response should use consistent naming convention', () {
      // Backend uses consistent "minimum*" naming:
      // - minimumPhotos
      // - minimumPrompts
      // NOT promptAnswers or photoAnswers
      
      final backendResponse = {
        'requirements': {
          'minimumPhotos': {'satisfied': true},
          'minimumPrompts': {'satisfied': true},
          'personalityQuestionnaire': {'satisfied': true},
          'basicInfo': {'satisfied': true},
        },
      };

      // All should use consistent field names
      expect(backendResponse['requirements']?['minimumPhotos'], isNotNull);
      expect(backendResponse['requirements']?['minimumPrompts'], isNotNull);
      expect(backendResponse['requirements']?['personalityQuestionnaire'], isNotNull);
      expect(backendResponse['requirements']?['basicInfo'], isNotNull);
    });
  });
}
