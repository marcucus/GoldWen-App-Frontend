import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/moderation.dart';

void main() {
  group('ModerationStatus', () {
    test('should have correct enum values', () {
      expect(ModerationStatus.values.length, 3);
      expect(ModerationStatus.values, contains(ModerationStatus.approved));
      expect(ModerationStatus.values, contains(ModerationStatus.pending));
      expect(ModerationStatus.values, contains(ModerationStatus.blocked));
    });
  });

  group('ModerationFlag', () {
    test('should create from JSON with all fields', () {
      final json = {
        'name': 'Explicit Nudity',
        'confidence': 95.5,
        'parentName': 'Suggestive',
      };

      final flag = ModerationFlag.fromJson(json);

      expect(flag.name, 'Explicit Nudity');
      expect(flag.confidence, 95.5);
      expect(flag.parentName, 'Suggestive');
    });

    test('should create from JSON with AWS Rekognition format', () {
      final json = {
        'Name': 'Explicit Nudity',
        'Confidence': 95.5,
        'ParentName': 'Suggestive',
      };

      final flag = ModerationFlag.fromJson(json);

      expect(flag.name, 'Explicit Nudity');
      expect(flag.confidence, 95.5);
      expect(flag.parentName, 'Suggestive');
    });

    test('should create from JSON without parent name', () {
      final json = {
        'name': 'Violence',
        'confidence': 80.0,
      };

      final flag = ModerationFlag.fromJson(json);

      expect(flag.name, 'Violence');
      expect(flag.confidence, 80.0);
      expect(flag.parentName, null);
    });

    test('should convert to JSON correctly', () {
      final flag = ModerationFlag(
        name: 'Spam',
        confidence: 90.0,
        parentName: 'Text Violations',
      );

      final json = flag.toJson();

      expect(json['name'], 'Spam');
      expect(json['confidence'], 90.0);
      expect(json['parentName'], 'Text Violations');
    });
  });

  group('ModerationResult', () {
    test('should create from JSON with all fields', () {
      final json = {
        'status': 'blocked',
        'flags': [
          {'name': 'Explicit Content', 'confidence': 95.0},
          {'name': 'Violence', 'confidence': 85.0},
        ],
        'moderatedAt': '2024-01-15T10:00:00.000Z',
        'moderator': 'ai',
      };

      final result = ModerationResult.fromJson(json);

      expect(result.status, ModerationStatus.blocked);
      expect(result.flags.length, 2);
      expect(result.flags[0].name, 'Explicit Content');
      expect(result.flags[1].name, 'Violence');
      expect(result.moderatedAt, isNotNull);
      expect(result.moderator, 'ai');
    });

    test('should create from JSON with string flags', () {
      final json = {
        'status': 'blocked',
        'flags': ['Explicit Nudity', 'Violence'],
        'moderatedAt': '2024-01-15T10:00:00.000Z',
      };

      final result = ModerationResult.fromJson(json);

      expect(result.flags.length, 2);
      expect(result.flags[0].name, 'Explicit Nudity');
      expect(result.flags[0].confidence, 100.0);
      expect(result.flags[1].name, 'Violence');
    });

    test('should parse status correctly', () {
      expect(
        ModerationResult.fromJson({'status': 'approved'}).status,
        ModerationStatus.approved,
      );
      expect(
        ModerationResult.fromJson({'status': 'pending'}).status,
        ModerationStatus.pending,
      );
      expect(
        ModerationResult.fromJson({'status': 'blocked'}).status,
        ModerationStatus.blocked,
      );
      expect(
        ModerationResult.fromJson({'status': 'unknown'}).status,
        ModerationStatus.pending,
      );
    });

    test('should have correct status getters', () {
      final blocked = ModerationResult(status: ModerationStatus.blocked);
      expect(blocked.isBlocked, true);
      expect(blocked.isPending, false);
      expect(blocked.isApproved, false);

      final approved = ModerationResult(status: ModerationStatus.approved);
      expect(approved.isBlocked, false);
      expect(approved.isPending, false);
      expect(approved.isApproved, true);

      final pending = ModerationResult(status: ModerationStatus.pending);
      expect(pending.isBlocked, false);
      expect(pending.isPending, true);
      expect(pending.isApproved, false);
    });

    test('should detect flags correctly', () {
      final withFlags = ModerationResult(
        status: ModerationStatus.blocked,
        flags: [ModerationFlag(name: 'Test', confidence: 90.0)],
      );
      expect(withFlags.hasFlags, true);

      final withoutFlags = ModerationResult(
        status: ModerationStatus.approved,
      );
      expect(withoutFlags.hasFlags, false);
    });

    test('should convert to JSON correctly', () {
      final result = ModerationResult(
        status: ModerationStatus.blocked,
        flags: [
          ModerationFlag(name: 'Spam', confidence: 85.0),
        ],
        moderatedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        moderator: 'ai',
      );

      final json = result.toJson();

      expect(json['status'], 'blocked');
      expect(json['flags'], isA<List>());
      expect(json['flags'].length, 1);
      expect(json['moderatedAt'], '2024-01-15T10:00:00.000Z');
      expect(json['moderator'], 'ai');
    });
  });

  group('ModerationHistoryItem', () {
    test('should create from JSON correctly', () {
      final json = {
        'id': 'history-123',
        'resourceType': 'message',
        'resourceId': 'msg-456',
        'result': {
          'status': 'blocked',
          'flags': [
            {'name': 'Spam', 'confidence': 90.0}
          ],
        },
        'createdAt': '2024-01-15T10:00:00.000Z',
      };

      final item = ModerationHistoryItem.fromJson(json);

      expect(item.id, 'history-123');
      expect(item.resourceType, 'message');
      expect(item.resourceId, 'msg-456');
      expect(item.result.status, ModerationStatus.blocked);
      expect(item.createdAt, DateTime.parse('2024-01-15T10:00:00.000Z'));
    });

    test('should convert to JSON correctly', () {
      final item = ModerationHistoryItem(
        id: 'history-123',
        resourceType: 'photo',
        resourceId: 'photo-789',
        result: ModerationResult(
          status: ModerationStatus.blocked,
          flags: [ModerationFlag(name: 'Explicit', confidence: 95.0)],
        ),
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = item.toJson();

      expect(json['id'], 'history-123');
      expect(json['resourceType'], 'photo');
      expect(json['resourceId'], 'photo-789');
      expect(json['result'], isA<Map<String, dynamic>>());
      expect(json['createdAt'], '2024-01-15T10:00:00.000Z');
    });
  });
}
