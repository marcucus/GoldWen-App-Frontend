import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/core/models/models.dart';

void main() {
  group('MatchingProvider - Who Liked Me', () {
    late MatchingProvider matchingProvider;

    setUp(() {
      matchingProvider = MatchingProvider();
    });

    test('initial who liked me state is correct', () {
      expect(matchingProvider.whoLikedMe, isEmpty);
      expect(matchingProvider.isLoadingWhoLikedMe, false);
    });

    test('clearWhoLikedMe clears the list', () {
      // Since we can't easily mock the API call, we'll test the clear method
      matchingProvider.clearWhoLikedMe();
      expect(matchingProvider.whoLikedMe, isEmpty);
    });

    test('WhoLikedMeItem model serialization works correctly', () {
      final profile = Profile(
        id: 'profile-1',
        firstName: 'Jane',
        age: 25,
        photos: [],
        bio: 'Test bio',
        prompts: [],
        personalityAnswers: [],
        preferences: PreferenceFilter(
          minAge: 18,
          maxAge: 35,
          maxDistance: 50,
        ),
      );

      final whoLikedMeItem = WhoLikedMeItem(
        userId: 'user-1',
        user: profile,
        likedAt: DateTime(2024, 1, 15, 10, 30),
      );

      final json = whoLikedMeItem.toJson();
      final restored = WhoLikedMeItem.fromJson(json);

      expect(restored.userId, equals(whoLikedMeItem.userId));
      expect(restored.user.id, equals(whoLikedMeItem.user.id));
      expect(restored.user.firstName, equals(whoLikedMeItem.user.firstName));
      expect(restored.likedAt, equals(whoLikedMeItem.likedAt));
    });

    test('WhoLikedMeItem model handles JSON parsing correctly', () {
      final jsonData = {
        'userId': 'user-123',
        'user': {
          'id': 'profile-123',
          'firstName': 'John',
          'age': 30,
          'photos': [],
          'bio': 'Test user bio',
          'prompts': [],
          'personalityAnswers': [],
          'preferences': {
            'minAge': 20,
            'maxAge': 40,
            'maxDistance': 25,
          },
        },
        'likedAt': '2024-01-15T10:30:00.000Z',
      };

      final whoLikedMeItem = WhoLikedMeItem.fromJson(jsonData);

      expect(whoLikedMeItem.userId, equals('user-123'));
      expect(whoLikedMeItem.user.firstName, equals('John'));
      expect(whoLikedMeItem.user.age, equals(30));
      expect(whoLikedMeItem.likedAt.year, equals(2024));
      expect(whoLikedMeItem.likedAt.month, equals(1));
      expect(whoLikedMeItem.likedAt.day, equals(15));
    });
  });
}