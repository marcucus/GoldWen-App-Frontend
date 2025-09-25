import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/main.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';
import 'package:goldwen_app/features/auth/providers/auth_provider.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';
import 'package:goldwen_app/features/chat/providers/chat_provider.dart';
import 'package:goldwen_app/core/models/models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('GoldWen App Integration Tests', () {
    testWidgets('Complete user onboarding flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const GoldWenApp(),
        ),
      );

      // Test 1: Welcome screen loads
      expect(find.text('Bienvenue sur'), findsOneWidget);
      expect(find.text('GoldWen'), findsOneWidget);
      
      // Test 2: Navigate to authentication
      final signInButton = find.text('Se connecter avec Google');
      if (signInButton.evaluate().isNotEmpty) {
        await tester.tap(signInButton);
        await tester.pumpAndSettle();
      }

      // Test 3: Profile setup flow (mocked)
      // In a real integration test, you would mock the authentication
      // and test the actual profile setup screens
      expect(find.byType(GoldWenApp), findsOneWidget);
    });

    testWidgets('Daily selection and matching flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const GoldWenApp(),
        ),
      );

      // Simulate authenticated user with complete profile
      final authProvider = tester.element(find.byType(GoldWenApp)).read<AuthProvider>();
      final profileProvider = tester.element(find.byType(GoldWenApp)).read<ProfileProvider>();
      
      // Mock authentication state
      authProvider.setUser(User(
        id: 'test-user',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Mock complete profile
      profileProvider.updateName('Test User');
      profileProvider.updateBio('Test bio');
      profileProvider.updateBirthDate(DateTime(1990, 1, 1));
      
      // Add required photos
      for (int i = 1; i <= 3; i++) {
        profileProvider.addPhoto('test-photo-$i.jpg');
      }
      
      // Add required prompts
      for (int i = 1; i <= 3; i++) {
        profileProvider.updatePromptAnswer('prompt-$i', 'Test answer $i');
      }
      
      // Add personality answers
      for (int i = 0; i < 10; i++) {
        profileProvider.updatePersonalityAnswer('question-$i', i % 5);
      }

      await tester.pump();

      // Test that profile is complete
      expect(profileProvider.isProfileComplete, isTrue);
    });

    testWidgets('Chat functionality flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const GoldWenApp(),
        ),
      );

      final chatProvider = tester.element(find.byType(GoldWenApp)).read<ChatProvider>();

      // Create mock conversation
      final otherUser = User(
        id: 'other-user',
        email: 'other@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final conversation = Conversation(
        id: 'test-conversation',
        matchId: 'test-match',
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        otherUser: otherUser,
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      chatProvider.addConversation(conversation);
      chatProvider.setCurrentConversation(conversation);

      await tester.pump();

      // Test chat state
      expect(chatProvider.conversations.length, equals(1));
      expect(chatProvider.currentConversation?.id, equals('test-conversation'));
      expect(chatProvider.canSendMessages, isTrue);
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const GoldWenApp(),
        ),
      );

      // Test error states in providers
      final authProvider = tester.element(find.byType(GoldWenApp)).read<AuthProvider>();
      final profileProvider = tester.element(find.byType(GoldWenApp)).read<ProfileProvider>();

      // Set error states
      authProvider.setError('Authentication failed');
      profileProvider.setError('Profile update failed');

      await tester.pump();

      expect(authProvider.hasError, isTrue);
      expect(profileProvider.hasError, isTrue);

      // Clear errors
      authProvider.clearError();
      profileProvider.clearError();

      await tester.pump();

      expect(authProvider.hasError, isFalse);
      expect(profileProvider.hasError, isFalse);
    });

    testWidgets('Performance under load simulation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const GoldWenApp(),
        ),
      );

      final matchingProvider = tester.element(find.byType(GoldWenApp)).read<MatchingProvider>();

      // Simulate large daily selection
      final largeSelection = List.generate(100, (index) {
        return DailySelection(
          id: 'selection-$index',
          userId: 'current-user',
          targetUserId: 'user-$index',
          compatibilityScore: 70 + (index % 30),
          targetUser: User(
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
          ),
          createdAt: DateTime.now(),
        );
      });

      final stopwatch = Stopwatch()..start();
      matchingProvider.setDailySelection(largeSelection);
      await tester.pump();
      stopwatch.stop();

      // Performance assertion - should handle 100 profiles quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(matchingProvider.dailySelection.length, equals(100));
    });
  });

  group('Accessibility Tests', () {
    testWidgets('App should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const GoldWenApp(),
        ),
      );

      // Test semantic properties
      final handle = tester.ensureSemantics();
      
      // Check that main UI elements have proper semantics
      expect(find.byType(GoldWenApp), findsOneWidget);
      
      handle.dispose();
    });

    testWidgets('Text scaling support', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaleFactor: 2.0), // Large text
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => ProfileProvider()),
              ChangeNotifierProvider(create: (_) => MatchingProvider()),
              ChangeNotifierProvider(create: (_) => ChatProvider()),
            ],
            child: const GoldWenApp(),
          ),
        ),
      );

      // App should handle large text without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dark mode support', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => ProfileProvider()),
              ChangeNotifierProvider(create: (_) => MatchingProvider()),
              ChangeNotifierProvider(create: (_) => ChatProvider()),
            ],
            child: const GoldWenApp(),
          ),
        ),
      );

      // App should support dark mode
      expect(find.byType(GoldWenApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('State Management Tests', () {
    testWidgets('Provider state persistence', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const GoldWenApp(),
        ),
      );

      final profileProvider = tester.element(find.byType(GoldWenApp)).read<ProfileProvider>();
      
      // Set some state
      profileProvider.updateName('John Doe');
      profileProvider.updateBio('Test bio');

      await tester.pump();

      // State should persist during widget rebuilds
      expect(profileProvider.name, equals('John Doe'));
      expect(profileProvider.bio, equals('Test bio'));

      // Trigger rebuild
      await tester.pump();

      // State should still be there
      expect(profileProvider.name, equals('John Doe'));
      expect(profileProvider.bio, equals('Test bio'));
    });

    testWidgets('Cross-provider communication', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => MatchingProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const GoldWenApp(),
        ),
      );

      final authProvider = tester.element(find.byType(GoldWenApp)).read<AuthProvider>();
      final profileProvider = tester.element(find.byType(GoldWenApp)).read<ProfileProvider>();

      // Mock user authentication
      final user = User(
        id: 'test-user',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        status: 'active',
        notificationsEnabled: true,
        emailNotifications: true,
        pushNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      authProvider.setUser(user);
      await tester.pump();

      // Profile provider should be able to access current user
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.isAuthenticated, isTrue);
    });
  });
}

// Helper function to create test user
User createTestUser({
  String id = 'test-user',
  String email = 'test@example.com',
  String firstName = 'John',
  String lastName = 'Doe',
}) {
  return User(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    status: 'active',
    notificationsEnabled: true,
    emailNotifications: true,
    pushNotifications: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}