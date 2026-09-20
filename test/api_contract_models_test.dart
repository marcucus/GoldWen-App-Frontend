import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/models.dart';

Map<String, dynamic> backendProfile({
  String id = 'profile-2',
  String userId = 'user-2',
}) {
  return {
    'id': id,
    'userId': userId,
    'firstName': 'Alex',
    'lastName': 'Martin',
    'birthDate': '1994-03-12T00:00:00.000Z',
    'latitude': '48.85660000',
    'longitude': '2.35220000',
    'maxDistance': 30,
    'minAge': 25,
    'maxAge': 40,
    'photos': <dynamic>[],
    'createdAt': '2026-09-19T10:00:00.000Z',
    'updatedAt': '2026-09-19T10:00:00.000Z',
  };
}

void main() {
  test('daily selection accepts the profile payload returned by NestJS', () {
    final selection = DailySelection.fromJson({
      'profiles': [backendProfile()],
      'metadata': {
        'choicesRemaining': 1,
        'choicesMade': 0,
        'maxChoices': 1,
        'refreshTime': '2026-09-20T12:00:00.000Z',
      },
    });

    expect(selection.profiles.single.userId, 'user-2');
    expect(selection.profiles.single.pseudo, 'Alex Martin');
    expect(selection.profiles.single.latitude, 48.8566);
  });

  test('match accepts decimal score and normalized other profile', () {
    final match = Match.fromJson({
      'id': 'match-1',
      'userId1': 'user-1',
      'userId2': 'user-2',
      'status': 'matched',
      'compatibilityScore': '82.50',
      'chatId': 'chat-1',
      'createdAt': '2026-09-19T10:00:00.000Z',
      'expiresAt': '2026-09-20T10:00:00.000Z',
      'otherProfile': backendProfile(),
    });

    expect(match.compatibilityScore, 82.5);
    expect(match.otherProfile?.userId, 'user-2');
  });

  test('conversation and message accept the normalized chat contract', () {
    final conversation = Conversation.fromJson({
      'id': 'chat-1',
      'matchId': 'match-1',
      'participantIds': ['user-1', 'user-2'],
      'lastMessage': {
        'id': 'message-1',
        'chatId': 'chat-1',
        'senderId': 'user-2',
        'type': 'text',
        'content': 'Bonjour',
        'isRead': false,
        'createdAt': '2026-09-19T10:05:00.000Z',
      },
      'unreadCount': 1,
      'status': 'active',
      'expiresAt': '2026-09-20T10:00:00.000Z',
      'createdAt': '2026-09-19T10:00:00.000Z',
      'updatedAt': '2026-09-19T10:05:00.000Z',
      'otherParticipant': backendProfile(),
    });

    expect(conversation.otherParticipant?.pseudo, 'Alex Martin');
    expect(conversation.lastMessage?.conversationId, 'chat-1');
    expect(conversation.unreadCount, 1);
  });
}
