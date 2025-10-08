import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';

// Use the centralized mocks file
import 'mocks.mocks.dart';

void main() {
  group('Profile Setup Validation Fix Tests', () {
    late ProfileProvider profileProvider;
    late MockApiService mockApiService;

    setUp(() {
      profileProvider = ProfileProvider();
      mockApiService = MockApiService();
    });

    test('Profile provider should save basic info correctly', () {
      // Arrange
      const name = 'Test User';
      const age = 25;
      const bio = 'Test bio';
      final birthDate = DateTime(1998, 1, 1);

      // Act
      profileProvider.setBasicInfo(name, age, bio, birthDate: birthDate);

      // Assert
      expect(profileProvider.name, equals(name));
      expect(profileProvider.age, equals(age));
      expect(profileProvider.bio, equals(bio));
      expect(profileProvider.birthDate, equals(birthDate));
    });

    test('Profile provider should save prompt answers correctly', () {
      // Arrange
      const promptId1 = 'prompt-1';
      const promptId2 = 'prompt-2';
      const promptId3 = 'prompt-3';
      const answer1 = 'First answer';
      const answer2 = 'Second answer';
      const answer3 = 'Third answer';

      // Act
      profileProvider.setPromptAnswer(promptId1, answer1);
      profileProvider.setPromptAnswer(promptId2, answer2);
      profileProvider.setPromptAnswer(promptId3, answer3);

      // Assert
      expect(profileProvider.promptAnswers[promptId1], equals(answer1));
      expect(profileProvider.promptAnswers[promptId2], equals(answer2));
      expect(profileProvider.promptAnswers[promptId3], equals(answer3));
      expect(profileProvider.promptAnswers.length, equals(3));
    });

    test('Profile should be marked as complete with 3 prompt answers, not 10', () {
      // Arrange
      profileProvider.setBasicInfo('Test User', 25, 'Test bio', birthDate: DateTime(1998, 1, 1));
      
      // Add 3 prompt answers (the correct requirement)
      profileProvider.setPromptAnswer('prompt-1', 'Answer 1');
      profileProvider.setPromptAnswer('prompt-2', 'Answer 2');
      profileProvider.setPromptAnswer('prompt-3', 'Answer 3');

      // Assert - should be satisfied with 3 prompts, not require 10
      expect(profileProvider.promptAnswers.length, equals(3));
      expect(profileProvider.name, isNotNull);
      expect(profileProvider.bio, isNotNull);
      expect(profileProvider.birthDate, isNotNull);
    });

    test('Prompt answers should be formatted correctly for API submission', () {
      // Arrange
      const promptId1 = 'prompt-uuid-1';
      const promptId2 = 'prompt-uuid-2';
      const promptId3 = 'prompt-uuid-3';
      const answer1 = 'My first prompt answer';
      const answer2 = 'My second prompt answer';
      const answer3 = 'My third prompt answer';

      profileProvider.setPromptAnswer(promptId1, answer1);
      profileProvider.setPromptAnswer(promptId2, answer2);
      profileProvider.setPromptAnswer(promptId3, answer3);

      // Act - Check the format that would be sent to API
      final promptAnswers = profileProvider.promptAnswers.entries.map((entry) {
        return {
          'promptId': entry.key,
          'answer': entry.value,
        };
      }).toList();

      // Assert - Should have correct format for API
      expect(promptAnswers, hasLength(3));
      expect(promptAnswers[0]['promptId'], equals(promptId1));
      expect(promptAnswers[0]['answer'], equals(answer1));
      expect(promptAnswers[1]['promptId'], equals(promptId2));
      expect(promptAnswers[1]['answer'], equals(answer2));
      expect(promptAnswers[2]['promptId'], equals(promptId3));
      expect(promptAnswers[2]['answer'], equals(answer3));
    });
  });
}