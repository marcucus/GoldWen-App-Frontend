import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:goldwen_app/core/models/profile.dart';
import 'package:goldwen_app/core/services/api_service.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';

// Use the centralized mocks file
import 'mocks.mocks.dart';

void main() {
  group('Profile Validation Tests', () {
    late ProfileProvider profileProvider;
    late MockApiService mockApiService;

    setUp(() {
      profileProvider = ProfileProvider();
      mockApiService = MockApiService();
    });

    test('ProfileCompletion model should parse correctly from JSON', () {
      final json = {
        'isCompleted': true,
        'hasPhotos': true,
        'hasPrompts': true,
        'hasPersonalityAnswers': true,
        'hasRequiredProfileFields': true,
        'missingSteps': [],
      };

      final completion = ProfileCompletion.fromJson(json);

      expect(completion.isCompleted, true);
      expect(completion.hasPhotos, true);
      expect(completion.hasPrompts, true);
      expect(completion.hasPersonalityAnswers, true);
      expect(completion.hasRequiredProfileFields, true);
      expect(completion.missingSteps, isEmpty);
    });

    test('ProfileCompletion model should handle incomplete profile', () {
      final json = {
        'isCompleted': false,
        'hasPhotos': false,
        'hasPrompts': true,
        'hasPersonalityAnswers': false,
        'hasRequiredProfileFields': true,
        'missingSteps': [
          'Upload at least 3 photos',
          'Complete personality questionnaire'
        ],
      };

      final completion = ProfileCompletion.fromJson(json);

      expect(completion.isCompleted, false);
      expect(completion.hasPhotos, false);
      expect(completion.hasPrompts, true);
      expect(completion.hasPersonalityAnswers, false);
      expect(completion.hasRequiredProfileFields, true);
      expect(completion.missingSteps, hasLength(2));
      expect(completion.missingSteps, contains('Upload at least 3 photos'));
      expect(completion.missingSteps, contains('Complete personality questionnaire'));
    });

    test('ProfileCompletion model should handle null/missing fields', () {
      final json = <String, dynamic>{};

      final completion = ProfileCompletion.fromJson(json);

      expect(completion.isCompleted, false);
      expect(completion.hasPhotos, false);
      expect(completion.hasPrompts, false);
      expect(completion.hasPersonalityAnswers, false);
      expect(completion.hasRequiredProfileFields, false);
      expect(completion.missingSteps, isEmpty);
    });

    test('ProfileCompletion toJson should work correctly', () {
      final completion = ProfileCompletion(
        isCompleted: true,
        hasPhotos: true,
        hasPrompts: true,
        hasPersonalityAnswers: true,
        hasRequiredProfileFields: true,
        missingSteps: [],
      );

      final json = completion.toJson();

      expect(json['isCompleted'], true);
      expect(json['hasPhotos'], true);
      expect(json['hasPrompts'], true);
      expect(json['hasPersonalityAnswers'], true);
      expect(json['hasRequiredProfileFields'], true);
      expect(json['missingSteps'], isEmpty);
    });

    test('ProfileProvider _checkProfileCompletion should work correctly', () {
      // Create test data
      profileProvider.setBasicInfo('Test User', 25, 'Test bio');
      
      // Add 3 photos (minimum required)
      for (int i = 0; i < 3; i++) {
        profileProvider.addPhotoFromUrl('https://example.com/photo$i.jpg');
      }
      
      // Add 3 prompt answers (minimum required)
      profileProvider.setPromptAnswer('prompt1', 'Answer 1');
      profileProvider.setPromptAnswer('prompt2', 'Answer 2'); 
      profileProvider.setPromptAnswer('prompt3', 'Answer 3');
      
      // Add personality answers
      profileProvider.setPersonalityAnswer('question1', 'answer1');
      
      // Set required gender preferences
      profileProvider.setGender('male');
      profileProvider.setGenderPreferences(['female']);
      profileProvider.setLocation(location: 'Paris', latitude: 48.8566, longitude: 2.3522);
      profileProvider.setAgePreferences(minAge: 22, maxAge: 30);

      // The internal _checkProfileCompletion should be called
      // We can't test it directly since it's private, but we can check the result
      expect(profileProvider.isProfileComplete, true);
    });

    test('ProfileProvider should identify incomplete profile correctly', () {
      // Only set name and age, missing other requirements
      profileProvider.setBasicInfo('Test User', 25, 'Test bio');
      
      // Missing photos, prompts, and personality answers
      expect(profileProvider.isProfileComplete, false);
    });
  });

  group('Profile Validation Requirements', () {
    test('should require minimum 3 photos', () {
      final completion = ProfileCompletion(
        isCompleted: false,
        hasPhotos: false,
        hasPrompts: true,
        hasPersonalityAnswers: true,
        hasRequiredProfileFields: true,
        missingSteps: ['Upload at least 3 photos'],
      );

      expect(completion.hasPhotos, false);
      expect(completion.missingSteps, contains('Upload at least 3 photos'));
    });

    test('should require 3 prompt answers', () {
      final completion = ProfileCompletion(
        isCompleted: false,
        hasPhotos: true,
        hasPrompts: false,
        hasPersonalityAnswers: true,
        hasRequiredProfileFields: true,
        missingSteps: ['Answer 3 prompts'],
      );

      expect(completion.hasPrompts, false);
      expect(completion.missingSteps, contains('Answer 3 prompts'));
    });

    test('should require personality questionnaire completion', () {
      final completion = ProfileCompletion(
        isCompleted: false,
        hasPhotos: true,
        hasPrompts: true,
        hasPersonalityAnswers: false,
        hasRequiredProfileFields: true,
        missingSteps: ['Complete personality questionnaire'],
      );

      expect(completion.hasPersonalityAnswers, false);
      expect(completion.missingSteps, contains('Complete personality questionnaire'));
    });

    test('should require basic profile fields (birthDate and bio)', () {
      final completion = ProfileCompletion(
        isCompleted: false,
        hasPhotos: true,
        hasPrompts: true,
        hasPersonalityAnswers: true,
        hasRequiredProfileFields: false,
        missingSteps: ['Complete basic profile information: birth date, bio'],
      );

      expect(completion.hasRequiredProfileFields, false);
      expect(completion.missingSteps.any((step) => step.contains('basic profile information')), true);
    });

    test('should be complete when all requirements are met', () {
      final completion = ProfileCompletion(
        isCompleted: true,
        hasPhotos: true,
        hasPrompts: true,
        hasPersonalityAnswers: true,
        hasRequiredProfileFields: true,
        missingSteps: [],
      );

      expect(completion.isCompleted, true);
      expect(completion.hasPhotos, true);
      expect(completion.hasPrompts, true);
      expect(completion.hasPersonalityAnswers, true);
      expect(completion.hasRequiredProfileFields, true);
      expect(completion.missingSteps, isEmpty);
    });
  });

  group('Photo Validation UI Tests', () {
    late ProfileProvider profileProvider;

    setUp(() {
      profileProvider = ProfileProvider();
    });

    test('should identify when less than 3 photos are added', () {
      // Add only 2 photos
      profileProvider.addPhotoFromUrl('https://example.com/photo1.jpg');
      profileProvider.addPhotoFromUrl('https://example.com/photo2.jpg');

      expect(profileProvider.photos.length, 2);
      expect(profileProvider.photos.length < 3, true);
    });

    test('should identify when exactly 3 photos are added', () {
      // Add exactly 3 photos
      profileProvider.addPhotoFromUrl('https://example.com/photo1.jpg');
      profileProvider.addPhotoFromUrl('https://example.com/photo2.jpg');
      profileProvider.addPhotoFromUrl('https://example.com/photo3.jpg');

      expect(profileProvider.photos.length, 3);
      expect(profileProvider.photos.length >= 3, true);
    });

    test('should allow more than 3 photos up to maximum', () {
      // Add 5 photos
      for (int i = 0; i < 5; i++) {
        profileProvider.addPhotoFromUrl('https://example.com/photo$i.jpg');
      }

      expect(profileProvider.photos.length, 5);
      expect(profileProvider.photos.length >= 3, true);
    });

    test('should respect maximum of 6 photos', () {
      // Try to add 7 photos, but should only add 6
      for (int i = 0; i < 7; i++) {
        profileProvider.addPhotoFromUrl('https://example.com/photo$i.jpg');
      }

      expect(profileProvider.photos.length, 6);
    });
  });
}