import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/core/models/matching.dart';
import 'package:goldwen_app/core/models/user.dart';
import 'package:goldwen_app/core/models/profile.dart';
import 'package:goldwen_app/core/services/api_service.dart';

class MockApiService extends Mock {}
class MockMatchingServiceApi extends Mock {}

@GenerateMocks([MockApiService, MockMatchingServiceApi])
void main() {
  group('Matching System Tests', () {
    late MatchingProvider matchingProvider;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      matchingProvider = MatchingProvider();
    });

    test('should initialize with default values', () {
      expect(matchingProvider.dailySelection, isEmpty);
      expect(matchingProvider.matches, isEmpty);
      expect(matchingProvider.isLoading, isFalse);
      expect(matchingProvider.error, isNull);
      expect(matchingProvider.hasLoadedToday, isFalse);
      expect(matchingProvider.choicesUsedToday, equals(0));
    });

    test('should load daily selection correctly', () async {
      final mockSelection = [
        DailySelection(
          id: 'selection-1',
          userId: 'current-user',
          targetUserId: 'target-1',
          compatibilityScore: 85,
          targetUser: User(
            id: 'target-1',
            email: 'target1@example.com',
            firstName: 'Jane',
            lastName: 'Doe',
            status: 'active',
            notificationsEnabled: true,
            emailNotifications: true,
            pushNotifications: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
        ),
        DailySelection(
          id: 'selection-2',
          userId: 'current-user',
          targetUserId: 'target-2',
          compatibilityScore: 92,
          targetUser: User(
            id: 'target-2',
            email: 'target2@example.com',
            firstName: 'Alice',
            lastName: 'Smith',
            status: 'active',
            notificationsEnabled: true,
            emailNotifications: true,
            pushNotifications: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
        ),
      ];

      matchingProvider.setDailySelection(mockSelection);

      expect(matchingProvider.dailySelection.length, equals(2));
      expect(matchingProvider.dailySelection[0].compatibilityScore, equals(85));
      expect(matchingProvider.dailySelection[1].compatibilityScore, equals(92));
      expect(matchingProvider.hasLoadedToday, isTrue);
    });

    test('should handle daily choice limits correctly', () {
      // Free user - 1 choice per day
      matchingProvider.setDailyChoicesLimit(1);
      matchingProvider.setChoicesUsedToday(0);

      expect(matchingProvider.canMakeChoice, isTrue);
      expect(matchingProvider.remainingChoices, equals(1));

      // After making one choice
      matchingProvider.incrementChoicesUsed();
      expect(matchingProvider.canMakeChoice, isFalse);
      expect(matchingProvider.remainingChoices, equals(0));
    });

    test('should handle premium user choice limits correctly', () {
      // Premium user - 3 choices per day
      matchingProvider.setDailyChoicesLimit(3);
      matchingProvider.setChoicesUsedToday(1);

      expect(matchingProvider.canMakeChoice, isTrue);
      expect(matchingProvider.remainingChoices, equals(2));

      // After making two more choices
      matchingProvider.incrementChoicesUsed();
      matchingProvider.incrementChoicesUsed();
      expect(matchingProvider.canMakeChoice, isFalse);
      expect(matchingProvider.remainingChoices, equals(0));
    });

    test('should make a choice and create match', () async {
      final targetUser = User(
        id: 'target-user-id',
        email: 'target@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockMatch = Match(
        id: 'match-id',
        userId: 'current-user',
        targetUserId: 'target-user-id',
        status: 'pending',
        targetUser: targetUser,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Setup daily selection
      matchingProvider.setDailySelection([
        DailySelection(
          id: 'selection-1',
          userId: 'current-user',
          targetUserId: 'target-user-id',
          compatibilityScore: 85,
          targetUser: targetUser,
          createdAt: DateTime.now(),
        ),
      ]);

      matchingProvider.setDailyChoicesLimit(1);
      matchingProvider.setChoicesUsedToday(0);

      // Make choice
      matchingProvider.makeChoice('target-user-id', mockMatch);

      expect(matchingProvider.matches.length, equals(1));
      expect(matchingProvider.matches[0].targetUserId, equals('target-user-id'));
      expect(matchingProvider.choicesUsedToday, equals(1));
      expect(matchingProvider.canMakeChoice, isFalse);

      // Verify the selected profile is removed from daily selection
      expect(matchingProvider.dailySelection, isEmpty);
    });

    test('should handle mutual match detection', () {
      final targetUser = User(
        id: 'target-user-id',
        email: 'target@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mutualMatch = Match(
        id: 'match-id',
        userId: 'current-user',
        targetUserId: 'target-user-id',
        status: 'matched', // Mutual match status
        targetUser: targetUser,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      matchingProvider.addMatch(mutualMatch);

      expect(matchingProvider.matches.length, equals(1));
      expect(matchingProvider.matches[0].status, equals('matched'));
      expect(matchingProvider.hasMutualMatches, isTrue);
    });

    test('should filter matches by status', () {
      final user1 = User(
        id: 'user-1',
        email: 'user1@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final user2 = User(
        id: 'user-2',
        email: 'user2@example.com',
        firstName: 'Alice',
        lastName: 'Smith',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pendingMatch = Match(
        id: 'match-1',
        userId: 'current-user',
        targetUserId: 'user-1',
        status: 'pending',
        targetUser: user1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mutualMatch = Match(
        id: 'match-2',
        userId: 'current-user',
        targetUserId: 'user-2',
        status: 'matched',
        targetUser: user2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      matchingProvider.setMatches([pendingMatch, mutualMatch]);

      expect(matchingProvider.pendingMatches.length, equals(1));
      expect(matchingProvider.mutualMatches.length, equals(1));
      expect(matchingProvider.pendingMatches[0].status, equals('pending'));
      expect(matchingProvider.mutualMatches[0].status, equals('matched'));
    });

    test('should handle compatibility calculation', () {
      final compatibility = CompatibilityResult(
        score: 85,
        factors: {
          'personality': 90,
          'interests': 80,
          'lifestyle': 85,
          'values': 85,
        },
        explanation: 'High compatibility based on shared values and interests',
      );

      matchingProvider.setLastCompatibilityResult(compatibility);

      expect(matchingProvider.lastCompatibilityResult?.score, equals(85));
      expect(matchingProvider.lastCompatibilityResult?.factors['personality'], equals(90));
      expect(matchingProvider.lastCompatibilityResult?.explanation, contains('High compatibility'));
    });

    test('should reset daily data correctly', () {
      final mockUser = User(
        id: 'target-1',
        email: 'target1@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockSelection = [
        DailySelection(
          id: 'selection-1',
          userId: 'current-user',
          targetUserId: 'target-1',
          compatibilityScore: 85,
          targetUser: mockUser,
          createdAt: DateTime.now(),
        ),
      ];

      matchingProvider.setDailySelection(mockSelection);
      matchingProvider.setChoicesUsedToday(2);
      matchingProvider.setHasLoadedToday(true);

      expect(matchingProvider.dailySelection.isNotEmpty, isTrue);
      expect(matchingProvider.choicesUsedToday, equals(2));
      expect(matchingProvider.hasLoadedToday, isTrue);

      // Reset daily data (simulating new day)
      matchingProvider.resetDailyData();

      expect(matchingProvider.dailySelection, isEmpty);
      expect(matchingProvider.choicesUsedToday, equals(0));
      expect(matchingProvider.hasLoadedToday, isFalse);
    });

    test('should handle loading states correctly', () {
      expect(matchingProvider.isLoading, isFalse);

      matchingProvider.setLoading(true);
      expect(matchingProvider.isLoading, isTrue);

      matchingProvider.setLoading(false);
      expect(matchingProvider.isLoading, isFalse);
    });

    test('should handle errors correctly', () {
      expect(matchingProvider.error, isNull);
      expect(matchingProvider.hasError, isFalse);

      const errorMessage = 'Failed to load daily selection';
      matchingProvider.setError(errorMessage);

      expect(matchingProvider.error, equals(errorMessage));
      expect(matchingProvider.hasError, isTrue);

      matchingProvider.clearError();
      expect(matchingProvider.error, isNull);
      expect(matchingProvider.hasError, isFalse);
    });

    test('should track selection view history', () {
      expect(matchingProvider.viewedProfiles, isEmpty);

      matchingProvider.markProfileAsViewed('profile-1');
      matchingProvider.markProfileAsViewed('profile-2');

      expect(matchingProvider.viewedProfiles.length, equals(2));
      expect(matchingProvider.viewedProfiles.contains('profile-1'), isTrue);
      expect(matchingProvider.hasViewedProfile('profile-1'), isTrue);
      expect(matchingProvider.hasViewedProfile('profile-3'), isFalse);
    });

    test('should validate choice constraints', () {
      // Test with no remaining choices
      matchingProvider.setDailyChoicesLimit(1);
      matchingProvider.setChoicesUsedToday(1);

      expect(matchingProvider.canMakeChoice, isFalse);
      expect(() => matchingProvider.validateChoice('target-id'), 
          throwsA(isA<Exception>()));

      // Test with available choices
      matchingProvider.setChoicesUsedToday(0);
      expect(matchingProvider.canMakeChoice, isTrue);
      expect(() => matchingProvider.validateChoice('target-id'), returnsNormally);
    });
  });

  group('Matching Models Tests', () {
    test('DailySelection should be created correctly', () {
      final targetUser = User(
        id: 'target-id',
        email: 'target@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final selection = DailySelection(
        id: 'selection-id',
        userId: 'user-id',
        targetUserId: 'target-id',
        compatibilityScore: 88,
        targetUser: targetUser,
        createdAt: DateTime.now(),
      );

      expect(selection.id, equals('selection-id'));
      expect(selection.compatibilityScore, equals(88));
      expect(selection.targetUser.firstName, equals('Jane'));
    });

    test('Match should handle status changes', () {
      final targetUser = User(
        id: 'target-id',
        email: 'target@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final match = Match(
        id: 'match-id',
        userId: 'user-id',
        targetUserId: 'target-id',
        status: 'pending',
        targetUser: targetUser,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(match.isPending, isTrue);
      expect(match.isMatched, isFalse);

      // Change status to matched
      final mutualMatch = match.copyWith(status: 'matched');
      expect(mutualMatch.isPending, isFalse);
      expect(mutualMatch.isMatched, isTrue);
    });

    test('CompatibilityResult should calculate overall score', () {
      final compatibility = CompatibilityResult(
        score: 85,
        factors: {
          'personality': 90,
          'interests': 80,
          'lifestyle': 85,
          'values': 85,
        },
        explanation: 'High compatibility score',
      );

      expect(compatibility.score, equals(85));
      expect(compatibility.isHighCompatibility, isTrue); // Assuming >80 is high
      expect(compatibility.factors.length, equals(4));
      expect(compatibility.getFactorScore('personality'), equals(90));
      expect(compatibility.getFactorScore('nonexistent'), isNull);
    });
  });

  group('Matching Integration Tests', () {
    test('should handle complete matching flow', () {
      final matchingProvider = MatchingProvider();
      
      // Set up user as premium (3 choices)
      matchingProvider.setDailyChoicesLimit(3);
      matchingProvider.setChoicesUsedToday(0);

      // Load daily selection
      final mockUsers = List.generate(5, (index) => User(
        id: 'user-$index',
        email: 'user$index@example.com',
        firstName: 'User$index',
        lastName: 'Test',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final mockSelection = mockUsers.map((user) => DailySelection(
        id: 'selection-${user.id}',
        userId: 'current-user',
        targetUserId: user.id,
        compatibilityScore: 80 + (mockUsers.indexOf(user) * 2),
        targetUser: user,
        createdAt: DateTime.now(),
      )).toList();

      matchingProvider.setDailySelection(mockSelection);

      expect(matchingProvider.dailySelection.length, equals(5));
      expect(matchingProvider.canMakeChoice, isTrue);
      expect(matchingProvider.remainingChoices, equals(3));

      // Make first choice
      final firstChoice = mockSelection.first;
      final firstMatch = Match(
        id: 'match-1',
        userId: 'current-user',
        targetUserId: firstChoice.targetUserId,
        status: 'pending',
        targetUser: firstChoice.targetUser,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      matchingProvider.makeChoice(firstChoice.targetUserId, firstMatch);

      expect(matchingProvider.matches.length, equals(1));
      expect(matchingProvider.choicesUsedToday, equals(1));
      expect(matchingProvider.remainingChoices, equals(2));
      expect(matchingProvider.dailySelection.length, equals(4)); // One removed

      // Make two more choices to exhaust limit
      for (int i = 1; i < 3; i++) {
        final choice = mockSelection[i];
        final match = Match(
          id: 'match-${i + 1}',
          userId: 'current-user',
          targetUserId: choice.targetUserId,
          status: 'pending',
          targetUser: choice.targetUser,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        matchingProvider.makeChoice(choice.targetUserId, match);
      }

      expect(matchingProvider.matches.length, equals(3));
      expect(matchingProvider.choicesUsedToday, equals(3));
      expect(matchingProvider.canMakeChoice, isFalse);
      expect(matchingProvider.remainingChoices, equals(0));
    });
  });
});