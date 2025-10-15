import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/profile.dart';

void main() {
  group('Profile FavoriteSong Tests', () {
    test('Profile should include favoriteSong in toJson when set', () {
      final profile = Profile(
        id: 'profile_id',
        userId: 'user_id',
        photos: [],
        mediaFiles: [],
        personalityAnswers: [],
        promptAnswers: [],
        favoriteSong: 'Bohemian Rhapsody - Queen (Spotify)',
        isComplete: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = profile.toJson();

      expect(json['favoriteSong'], isNotNull);
      expect(json['favoriteSong'], 'Bohemian Rhapsody - Queen (Spotify)');
    });

    test('Profile should not include favoriteSong in toJson when null', () {
      final profile = Profile(
        id: 'profile_id',
        userId: 'user_id',
        photos: [],
        mediaFiles: [],
        personalityAnswers: [],
        promptAnswers: [],
        favoriteSong: null,
        isComplete: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = profile.toJson();

      expect(json.containsKey('favoriteSong'), isFalse);
    });

    test('Profile should parse favoriteSong from JSON correctly', () {
      final json = {
        'id': 'profile_id',
        'userId': 'user_id',
        'photos': [],
        'mediaFiles': [],
        'personalityAnswers': [],
        'promptAnswers': [],
        'favoriteSong': 'Yesterday - The Beatles (Apple Music)',
        'isComplete': true,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };

      final profile = Profile.fromJson(json);

      expect(profile.favoriteSong, isNotNull);
      expect(profile.favoriteSong, 'Yesterday - The Beatles (Apple Music)');
    });

    test('Profile should handle missing favoriteSong field', () {
      final json = {
        'id': 'profile_id',
        'userId': 'user_id',
        'photos': [],
        'mediaFiles': [],
        'personalityAnswers': [],
        'promptAnswers': [],
        'isComplete': true,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };

      final profile = Profile.fromJson(json);

      expect(profile.favoriteSong, isNull);
    });

    test('Profile should handle favoriteSong without platform', () {
      final json = {
        'id': 'profile_id',
        'userId': 'user_id',
        'photos': [],
        'mediaFiles': [],
        'personalityAnswers': [],
        'promptAnswers': [],
        'favoriteSong': 'Imagine - John Lennon',
        'isComplete': true,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };

      final profile = Profile.fromJson(json);

      expect(profile.favoriteSong, 'Imagine - John Lennon');
    });

    test('Profile should handle different music platforms', () {
      final platforms = ['Apple Music', 'Spotify', 'Deezer'];
      
      for (final platform in platforms) {
        final json = {
          'id': 'profile_id',
          'userId': 'user_id',
          'photos': [],
          'mediaFiles': [],
          'personalityAnswers': [],
          'promptAnswers': [],
          'favoriteSong': 'Song Title - Artist ($platform)',
          'isComplete': true,
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-01T00:00:00.000',
        };

        final profile = Profile.fromJson(json);
        
        expect(profile.favoriteSong, contains(platform));
      }
    });
  });
}
