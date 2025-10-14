import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/models.dart';

void main() {
  group('Match Model Tests', () {
    test('Match model includes hasUnreadMessages field', () {
      final match = Match(
        id: 'test-id',
        userId1: 'user1',
        userId2: 'user2',
        status: 'active',
        compatibilityScore: 0.87,
        chatId: 'chat-id',
        createdAt: DateTime.now(),
        hasUnreadMessages: true,
      );

      expect(match.hasUnreadMessages, true);
      expect(match.compatibilityScore, 0.87);
      expect(match.status, 'active');
    });

    test('Match model hasUnreadMessages defaults to false', () {
      final match = Match(
        id: 'test-id',
        userId1: 'user1',
        userId2: 'user2',
        status: 'active',
        compatibilityScore: 0.75,
        createdAt: DateTime.now(),
      );

      expect(match.hasUnreadMessages, false);
    });

    test('Match fromJson correctly parses hasUnreadMessages', () {
      final json = {
        'id': 'test-id',
        'userId1': 'user1',
        'userId2': 'user2',
        'status': 'active',
        'compatibilityScore': 0.90,
        'chatId': 'chat-id',
        'createdAt': DateTime.now().toIso8601String(),
        'hasUnreadMessages': true,
      };

      final match = Match.fromJson(json);
      
      expect(match.id, 'test-id');
      expect(match.hasUnreadMessages, true);
      expect(match.compatibilityScore, 0.90);
    });

    test('Match fromJson handles missing hasUnreadMessages field', () {
      final json = {
        'id': 'test-id',
        'userId1': 'user1',
        'userId2': 'user2',
        'status': 'active',
        'compatibilityScore': 0.80,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final match = Match.fromJson(json);
      
      expect(match.hasUnreadMessages, false);
    });

    test('Match toJson includes hasUnreadMessages', () {
      final match = Match(
        id: 'test-id',
        userId1: 'user1',
        userId2: 'user2',
        status: 'active',
        compatibilityScore: 0.85,
        createdAt: DateTime.now(),
        hasUnreadMessages: true,
      );

      final json = match.toJson();
      
      expect(json['hasUnreadMessages'], true);
      expect(json['compatibilityScore'], 0.85);
    });

    test('Match isExpired returns correct value', () {
      final expiredMatch = Match(
        id: 'test-id',
        userId1: 'user1',
        userId2: 'user2',
        status: 'active',
        compatibilityScore: 0.85,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final activeMatch = Match(
        id: 'test-id-2',
        userId1: 'user1',
        userId2: 'user2',
        status: 'active',
        compatibilityScore: 0.85,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );

      expect(expiredMatch.isExpired, true);
      expect(activeMatch.isExpired, false);
    });

    test('Match without expiresAt is not expired', () {
      final match = Match(
        id: 'test-id',
        userId1: 'user1',
        userId2: 'user2',
        status: 'active',
        compatibilityScore: 0.85,
        createdAt: DateTime.now(),
      );

      expect(match.isExpired, false);
    });
  });

  group('Match Filter Logic Tests', () {
    late List<Match> testMatches;

    setUp(() {
      final now = DateTime.now();
      testMatches = [
        // Active match with time remaining
        Match(
          id: 'match-1',
          userId1: 'user1',
          userId2: 'user2',
          status: 'active',
          compatibilityScore: 0.87,
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 12)),
          hasUnreadMessages: true,
        ),
        // Expiring soon match (2 hours remaining)
        Match(
          id: 'match-2',
          userId1: 'user1',
          userId2: 'user3',
          status: 'active',
          compatibilityScore: 0.75,
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 2)),
          hasUnreadMessages: false,
        ),
        // Expired match
        Match(
          id: 'match-3',
          userId1: 'user1',
          userId2: 'user4',
          status: 'active',
          compatibilityScore: 0.90,
          createdAt: now.subtract(const Duration(days: 1)),
          expiresAt: now.subtract(const Duration(hours: 1)),
          hasUnreadMessages: false,
        ),
        // Archived match
        Match(
          id: 'match-4',
          userId1: 'user1',
          userId2: 'user5',
          status: 'archived',
          compatibilityScore: 0.80,
          createdAt: now.subtract(const Duration(days: 2)),
          hasUnreadMessages: false,
        ),
      ];
    });

    test('Filter active matches excludes expired matches', () {
      final activeMatches = testMatches.where((match) {
        return match.status == 'active' && !match.isExpired;
      }).toList();

      expect(activeMatches.length, 2); // match-1 and match-2
      expect(activeMatches.any((m) => m.id == 'match-1'), true);
      expect(activeMatches.any((m) => m.id == 'match-2'), true);
      expect(activeMatches.any((m) => m.id == 'match-3'), false);
    });

    test('Filter expiring soon matches (<=3 hours remaining)', () {
      final expiringSoon = testMatches.where((match) {
        if (match.expiresAt == null || match.isExpired) return false;
        final hoursRemaining = match.expiresAt!.difference(DateTime.now()).inHours;
        return hoursRemaining <= 3 && match.status == 'active';
      }).toList();

      expect(expiringSoon.length, 1); // Only match-2
      expect(expiringSoon.first.id, 'match-2');
    });

    test('Filter archived matches includes expired matches', () {
      final archived = testMatches.where((match) {
        return match.status == 'archived' || match.isExpired;
      }).toList();

      expect(archived.length, 2); // match-3 and match-4
      expect(archived.any((m) => m.id == 'match-3'), true);
      expect(archived.any((m) => m.id == 'match-4'), true);
    });

    test('Unread messages badge should be shown correctly', () {
      final matchesWithUnread = testMatches.where((match) {
        return match.hasUnreadMessages && !match.isExpired;
      }).toList();

      expect(matchesWithUnread.length, 1); // Only match-1
      expect(matchesWithUnread.first.id, 'match-1');
    });
  });
}
