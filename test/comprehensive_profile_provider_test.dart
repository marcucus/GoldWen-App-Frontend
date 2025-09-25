import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';
import 'package:goldwen_app/core/models/profile.dart';
import 'package:goldwen_app/core/services/api_service.dart';

// Create mock classes
class MockApiService extends Mock {}

@GenerateMocks([MockApiService])
void main() {
  group('ProfileProvider Tests', () {
    late ProfileProvider profileProvider;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      profileProvider = ProfileProvider();
    });

    test('should initialize with default values', () {
      expect(profileProvider.name, isNull);
      expect(profileProvider.age, isNull);
      expect(profileProvider.bio, isNull);
      expect(profileProvider.photos, isEmpty);
      expect(profileProvider.promptAnswers, isEmpty);
      expect(profileProvider.personalityAnswers, isEmpty);
      expect(profileProvider.isProfileComplete, isFalse);
      expect(profileProvider.isLoading, isFalse);
      expect(profileProvider.error, isNull);
    });

    test('should update basic profile information', () {
      // Test name update
      profileProvider.updateName('John Doe');
      expect(profileProvider.name, equals('John Doe'));

      // Test bio update
      profileProvider.updateBio('Test bio');
      expect(profileProvider.bio, equals('Test bio'));

      // Test age calculation from birth date
      final birthDate = DateTime(1990, 1, 1);
      profileProvider.updateBirthDate(birthDate);
      expect(profileProvider.birthDate, equals(birthDate));
      expect(profileProvider.age, greaterThan(30)); // Approximate age
    });

    test('should manage photos correctly', () {
      // Add photos
      profileProvider.addPhoto('photo1.jpg');
      profileProvider.addPhoto('photo2.jpg');
      profileProvider.addPhoto('photo3.jpg');

      expect(profileProvider.photos.length, equals(3));
      expect(profileProvider.photos.contains('photo1.jpg'), isTrue);

      // Remove photo
      profileProvider.removePhoto('photo2.jpg');
      expect(profileProvider.photos.length, equals(2));
      expect(profileProvider.photos.contains('photo2.jpg'), isFalse);

      // Reorder photos
      profileProvider.reorderPhotos(['photo3.jpg', 'photo1.jpg']);
      expect(profileProvider.photos[0], equals('photo3.jpg'));
      expect(profileProvider.photos[1], equals('photo1.jpg'));
    });

    test('should validate photo requirements', () {
      expect(profileProvider.hasMinimumPhotos, isFalse);

      profileProvider.addPhoto('photo1.jpg');
      profileProvider.addPhoto('photo2.jpg');
      expect(profileProvider.hasMinimumPhotos, isFalse);

      profileProvider.addPhoto('photo3.jpg');
      expect(profileProvider.hasMinimumPhotos, isTrue);
    });

    test('should manage prompt answers correctly', () {
      expect(profileProvider.hasRequiredPrompts, isFalse);

      // Add prompt answers
      profileProvider.updatePromptAnswer('prompt1', 'Answer 1');
      profileProvider.updatePromptAnswer('prompt2', 'Answer 2');
      expect(profileProvider.hasRequiredPrompts, isFalse);

      profileProvider.updatePromptAnswer('prompt3', 'Answer 3');
      expect(profileProvider.hasRequiredPrompts, isTrue);
      expect(profileProvider.promptAnswers.length, equals(3));

      // Remove prompt answer
      profileProvider.removePromptAnswer('prompt2');
      expect(profileProvider.promptAnswers.length, equals(2));
      expect(profileProvider.hasRequiredPrompts, isFalse);
    });

    test('should manage personality answers correctly', () {
      expect(profileProvider.hasCompletedPersonality, isFalse);

      // Add some personality answers (less than required 10)
      for (int i = 0; i < 5; i++) {
        profileProvider.updatePersonalityAnswer('question-$i', i % 5);
      }
      expect(profileProvider.hasCompletedPersonality, isFalse);

      // Complete all 10 required answers
      for (int i = 5; i < 10; i++) {
        profileProvider.updatePersonalityAnswer('question-$i', i % 5);
      }
      expect(profileProvider.hasCompletedPersonality, isTrue);
      expect(profileProvider.personalityAnswers.length, equals(10));
    });

    test('should calculate profile completion correctly', () {
      expect(profileProvider.isProfileComplete, isFalse);

      // Add basic info
      profileProvider.updateName('John Doe');
      profileProvider.updateBio('Test bio');
      profileProvider.updateBirthDate(DateTime(1990, 1, 1));

      // Add required photos
      profileProvider.addPhoto('photo1.jpg');
      profileProvider.addPhoto('photo2.jpg');
      profileProvider.addPhoto('photo3.jpg');

      // Add required prompts
      profileProvider.updatePromptAnswer('prompt1', 'Answer 1');
      profileProvider.updatePromptAnswer('prompt2', 'Answer 2');
      profileProvider.updatePromptAnswer('prompt3', 'Answer 3');

      // Add personality answers
      for (int i = 0; i < 10; i++) {
        profileProvider.updatePersonalityAnswer('question-$i', i % 5);
      }

      // Now profile should be complete
      expect(profileProvider.isProfileComplete, isTrue);
    });

    test('should handle errors properly', () {
      const errorMessage = 'Network error';
      profileProvider.setError(errorMessage);
      
      expect(profileProvider.error, equals(errorMessage));
      expect(profileProvider.hasError, isTrue);

      profileProvider.clearError();
      expect(profileProvider.error, isNull);
      expect(profileProvider.hasError, isFalse);
    });

    test('should manage loading state', () {
      expect(profileProvider.isLoading, isFalse);

      profileProvider.setLoading(true);
      expect(profileProvider.isLoading, isTrue);

      profileProvider.setLoading(false);
      expect(profileProvider.isLoading, isFalse);
    });

    test('should update preferences correctly', () {
      // Test gender and interested genders
      profileProvider.updateGender('male');
      expect(profileProvider.gender, equals('male'));

      profileProvider.updateInterestedInGenders(['female', 'non-binary']);
      expect(profileProvider.interestedInGenders, contains('female'));
      expect(profileProvider.interestedInGenders, contains('non-binary'));

      // Test age preferences
      profileProvider.updateAgePreferences(25, 35);
      expect(profileProvider.minAge, equals(25));
      expect(profileProvider.maxAge, equals(35));

      // Test location
      profileProvider.updateLocation('Paris', 48.8566, 2.3522);
      expect(profileProvider.location, equals('Paris'));
      expect(profileProvider.latitude, equals(48.8566));
      expect(profileProvider.longitude, equals(2.3522));
    });

    test('should validate required fields for profile completion', () {
      // Profile should be incomplete initially
      expect(profileProvider.canCompleteProfile, isFalse);

      // Add all required fields
      profileProvider.updateName('John Doe');
      profileProvider.updateBio('Test bio');
      profileProvider.updateBirthDate(DateTime(1990, 1, 1));
      
      // Add 3 photos
      for (int i = 1; i <= 3; i++) {
        profileProvider.addPhoto('photo$i.jpg');
      }

      // Add 3 prompt answers
      for (int i = 1; i <= 3; i++) {
        profileProvider.updatePromptAnswer('prompt$i', 'Answer $i');
      }

      // Add personality answers
      for (int i = 0; i < 10; i++) {
        profileProvider.updatePersonalityAnswer('question-$i', i % 5);
      }

      expect(profileProvider.canCompleteProfile, isTrue);
    });

    test('should reset profile data', () {
      // Add some data first
      profileProvider.updateName('John Doe');
      profileProvider.updateBio('Test bio');
      profileProvider.addPhoto('photo1.jpg');
      profileProvider.updatePromptAnswer('prompt1', 'Answer 1');

      expect(profileProvider.name, isNotNull);
      expect(profileProvider.bio, isNotNull);
      expect(profileProvider.photos.isNotEmpty, isTrue);
      expect(profileProvider.promptAnswers.isNotEmpty, isTrue);

      // Reset profile
      profileProvider.resetProfile();

      expect(profileProvider.name, isNull);
      expect(profileProvider.bio, isNull);
      expect(profileProvider.photos, isEmpty);
      expect(profileProvider.promptAnswers, isEmpty);
      expect(profileProvider.personalityAnswers, isEmpty);
      expect(profileProvider.error, isNull);
      expect(profileProvider.isLoading, isFalse);
    });

    test('should calculate profile completion percentage', () {
      expect(profileProvider.completionPercentage, equals(0));

      // Add basic info (20%)
      profileProvider.updateName('John Doe');
      profileProvider.updateBio('Test bio');
      profileProvider.updateBirthDate(DateTime(1990, 1, 1));
      expect(profileProvider.completionPercentage, greaterThan(0));

      // Add photos (40%)
      profileProvider.addPhoto('photo1.jpg');
      profileProvider.addPhoto('photo2.jpg');
      profileProvider.addPhoto('photo3.jpg');
      expect(profileProvider.completionPercentage, greaterThan(20));

      // Add prompts (70%)
      profileProvider.updatePromptAnswer('prompt1', 'Answer 1');
      profileProvider.updatePromptAnswer('prompt2', 'Answer 2');
      profileProvider.updatePromptAnswer('prompt3', 'Answer 3');
      expect(profileProvider.completionPercentage, greaterThan(40));

      // Add personality (100%)
      for (int i = 0; i < 10; i++) {
        profileProvider.updatePersonalityAnswer('question-$i', i % 5);
      }
      expect(profileProvider.completionPercentage, equals(100));
    });

    test('should handle available prompts', () {
      expect(profileProvider.availablePrompts, isEmpty);

      final testPrompts = [
        Prompt(
          id: 'prompt1',
          text: 'What makes you laugh?',
          category: 'personality',
          isActive: true,
          order: 1,
        ),
        Prompt(
          id: 'prompt2',
          text: 'My dream vacation is...',
          category: 'lifestyle',
          isActive: true,
          order: 2,
        ),
      ];

      profileProvider.setAvailablePrompts(testPrompts);
      expect(profileProvider.availablePrompts.length, equals(2));
      expect(profileProvider.availablePrompts[0].text, equals('What makes you laugh?'));
    });
  });

  group('ProfileProvider Model Integration Tests', () {
    test('should create Profile model from provider data', () {
      final profileProvider = ProfileProvider();
      
      // Set up profile data
      profileProvider.updateName('John Doe');
      profileProvider.updateBio('Test bio');
      profileProvider.updateBirthDate(DateTime(1990, 1, 1));
      profileProvider.addPhoto('photo1.jpg');

      // Create profile model (this would typically be done in the API service)
      final profile = Profile(
        id: 'test-profile-id',
        userId: 'test-user-id',
        name: profileProvider.name,
        bio: profileProvider.bio,
        birthDate: profileProvider.birthDate,
        photos: profileProvider.photos.map((url) => Photo(
          id: 'photo-id',
          userId: 'test-user-id',
          url: url,
          isPrimary: false,
          order: 1,
        )).toList(),
        isComplete: profileProvider.isProfileComplete,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.name, equals('John Doe'));
      expect(profile.bio, equals('Test bio'));
      expect(profile.photos.length, equals(1));
    });
  });
});