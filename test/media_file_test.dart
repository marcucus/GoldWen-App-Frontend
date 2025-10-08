import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/profile.dart';

void main() {
  group('MediaFile Model Tests', () {
    test('MediaFile should be created correctly', () {
      final mediaFile = MediaFile(
        id: 'test_id',
        url: 'https://example.com/audio.mp3',
        type: 'audio',
        order: 1,
        duration: 120,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(mediaFile.id, 'test_id');
      expect(mediaFile.url, 'https://example.com/audio.mp3');
      expect(mediaFile.type, 'audio');
      expect(mediaFile.order, 1);
      expect(mediaFile.duration, 120);
      expect(mediaFile.thumbnailUrl, isNull);
    });

    test('MediaFile should convert to JSON correctly', () {
      final mediaFile = MediaFile(
        id: 'test_id',
        url: 'https://example.com/video.mp4',
        type: 'video',
        order: 2,
        duration: 300,
        thumbnailUrl: 'https://example.com/thumb.jpg',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = mediaFile.toJson();

      expect(json['id'], 'test_id');
      expect(json['url'], 'https://example.com/video.mp4');
      expect(json['type'], 'video');
      expect(json['order'], 2);
      expect(json['duration'], 300);
      expect(json['thumbnailUrl'], 'https://example.com/thumb.jpg');
      expect(json['createdAt'], '2024-01-01T00:00:00.000');
    });

    test('MediaFile should be created from JSON correctly', () {
      final json = {
        'id': 'test_id',
        'url': 'https://example.com/audio.mp3',
        'type': 'audio',
        'order': 1,
        'duration': 120,
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final mediaFile = MediaFile.fromJson(json);

      expect(mediaFile.id, 'test_id');
      expect(mediaFile.url, 'https://example.com/audio.mp3');
      expect(mediaFile.type, 'audio');
      expect(mediaFile.order, 1);
      expect(mediaFile.duration, 120);
      expect(mediaFile.thumbnailUrl, isNull);
    });

    test('MediaFile should handle optional fields correctly', () {
      final json = {
        'id': 'test_id',
        'url': 'https://example.com/audio.mp3',
        'type': 'audio',
        'order': 1,
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final mediaFile = MediaFile.fromJson(json);

      expect(mediaFile.duration, isNull);
      expect(mediaFile.thumbnailUrl, isNull);
    });
  });

  group('Profile Model with MediaFiles Tests', () {
    test('Profile should include mediaFiles in toJson', () {
      final profile = Profile(
        id: 'profile_id',
        userId: 'user_id',
        photos: [],
        mediaFiles: [
          MediaFile(
            id: 'media1',
            url: 'https://example.com/audio.mp3',
            type: 'audio',
            order: 1,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
        personalityAnswers: [],
        promptAnswers: [],
        isComplete: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = profile.toJson();

      expect(json['mediaFiles'], isNotNull);
      expect(json['mediaFiles'], isList);
      expect(json['mediaFiles'].length, 1);
      expect(json['mediaFiles'][0]['type'], 'audio');
    });

    test('Profile should parse mediaFiles from JSON', () {
      final json = {
        'id': 'profile_id',
        'userId': 'user_id',
        'photos': [],
        'mediaFiles': [
          {
            'id': 'media1',
            'url': 'https://example.com/video.mp4',
            'type': 'video',
            'order': 1,
            'duration': 180,
            'createdAt': '2024-01-01T00:00:00.000',
          }
        ],
        'personalityAnswers': [],
        'promptAnswers': [],
        'isComplete': true,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };

      final profile = Profile.fromJson(json);

      expect(profile.mediaFiles, isNotNull);
      expect(profile.mediaFiles.length, 1);
      expect(profile.mediaFiles[0].type, 'video');
      expect(profile.mediaFiles[0].duration, 180);
    });

    test('Profile should handle empty mediaFiles array', () {
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

      expect(profile.mediaFiles, isEmpty);
    });

    test('Profile should handle missing mediaFiles field', () {
      final json = {
        'id': 'profile_id',
        'userId': 'user_id',
        'photos': [],
        'personalityAnswers': [],
        'promptAnswers': [],
        'isComplete': true,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };

      final profile = Profile.fromJson(json);

      expect(profile.mediaFiles, isEmpty);
    });
  });
}
