import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/profile/widgets/profile_completion_widget.dart';
import 'package:goldwen_app/features/profile/providers/profile_provider.dart';
import 'package:goldwen_app/core/models/profile.dart';

// Test ProfileProvider that allows setting completion for testing
class TestProfileProvider extends ProfileProvider {
  ProfileCompletion? _testCompletion;
  
  void setTestCompletion(ProfileCompletion? completion) {
    _testCompletion = completion;
    notifyListeners();
  }
  
  @override
  ProfileCompletion? get profileCompletion => _testCompletion;
}

void main() {
  group('Profile Validation Integration Tests', () {
    late TestProfileProvider profileProvider;

    setUp(() {
      profileProvider = TestProfileProvider();
    });

    testWidgets('ProfileCompletionWidget displays correctly for incomplete profile', 
        (WidgetTester tester) async {
      // Set up incomplete profile data
      final incompleteCompletion = ProfileCompletion(
        isCompleted: false,
        hasPhotos: false,
        hasPrompts: true,
        hasPersonalityAnswers: false,
        hasRequiredProfileFields: true,
        missingSteps: [
          'Upload at least 3 photos',
          'Complete personality questionnaire'
        ],
      );
      
      profileProvider.setTestCompletion(incompleteCompletion);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider,
            child: Scaffold(
              body: ProfileCompletionWidget(
                showProgress: true,
                onMissingStepTap: () {},
              ),
            ),
          ),
        ),
      );

      // Widget should be visible
      expect(find.byType(ProfileCompletionWidget), findsOneWidget);
      
      // Should show incomplete status
      expect(find.text('Profil incomplet'), findsOneWidget);
      
      // Should show missing steps
      expect(find.text('Upload at least 3 photos'), findsOneWidget);
      expect(find.text('Complete personality questionnaire'), findsOneWidget);
      
      // Should show progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      
      // Button should be for completing profile
      expect(find.text('Compléter le profil'), findsOneWidget);
    });

    testWidgets('ProfileCompletionWidget displays correctly for complete profile', 
        (WidgetTester tester) async {
      // Set up complete profile data
      final completeCompletion = ProfileCompletion(
        isCompleted: true,
        hasPhotos: true,
        hasPrompts: true,
        hasPersonalityAnswers: true,
        hasRequiredProfileFields: true,
        missingSteps: [],
      );
      
      profileProvider.setTestCompletion(completeCompletion);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider,
            child: Scaffold(
              body: ProfileCompletionWidget(
                showProgress: true,
                onMissingStepTap: () {},
              ),
            ),
          ),
        ),
      );

      // Should show completed status
      expect(find.text('Profil complet et validé'), findsOneWidget);
      
      // Should not show missing steps section
      expect(find.text('Étapes manquantes:'), findsNothing);
      
      // Should show progress indicator at 100%
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      
      // All status rows should show as completed
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('ProfileCompletionWidget handles null completion data', 
        (WidgetTester tester) async {
      // Profile provider with null completion
      profileProvider.setTestCompletion(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider,
            child: Scaffold(
              body: ProfileCompletionWidget(
                showProgress: true,
                onMissingStepTap: () {},
              ),
            ),
          ),
        ),
      );

      // Widget should not be visible when completion data is null
      expect(find.byType(ProfileCompletionWidget), findsOneWidget);
      
      // But the content should be empty (SizedBox.shrink)
      expect(find.text('Profil incomplet'), findsNothing);
      expect(find.text('Profil complet et validé'), findsNothing);
    });

    testWidgets('ProfileCompletionWidget button callback works', 
        (WidgetTester tester) async {
      bool callbackCalled = false;
      
      final incompleteCompletion = ProfileCompletion(
        isCompleted: false,
        hasPhotos: false,
        hasPrompts: true,
        hasPersonalityAnswers: false,
        hasRequiredProfileFields: true,
        missingSteps: ['Upload at least 3 photos'],
      );
      
      profileProvider.setTestCompletion(incompleteCompletion);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider,
            child: Scaffold(
              body: ProfileCompletionWidget(
                showProgress: true,
                onMissingStepTap: () {
                  callbackCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      // Find and tap the complete profile button
      final button = find.text('Compléter le profil');
      expect(button, findsOneWidget);
      
      await tester.tap(button);
      await tester.pump();
      
      expect(callbackCalled, isTrue);
    });

    test('Profile completion progress calculation', () {
      // Test 25% completion
      var completion = ProfileCompletion(
        isCompleted: false,
        hasPhotos: true,
        hasPrompts: false,
        hasPersonalityAnswers: false,
        hasRequiredProfileFields: false,
        missingSteps: ['Answer 3 prompts', 'Complete personality questionnaire', 'Complete basic profile information'],
      );
      
      final completedSteps = [
        completion.hasPhotos,
        completion.hasPrompts,
        completion.hasPersonalityAnswers,
        completion.hasRequiredProfileFields,
      ];
      final completedCount = completedSteps.where((step) => step).length;
      final progress = completedCount / completedSteps.length;
      
      expect(progress, equals(0.25));
      
      // Test 75% completion  
      completion = ProfileCompletion(
        isCompleted: false,
        hasPhotos: true,
        hasPrompts: true,
        hasPersonalityAnswers: true,
        hasRequiredProfileFields: false,
        missingSteps: ['Complete basic profile information'],
      );
      
      final completedSteps2 = [
        completion.hasPhotos,
        completion.hasPrompts,
        completion.hasPersonalityAnswers,
        completion.hasRequiredProfileFields,
      ];
      final completedCount2 = completedSteps2.where((step) => step).length;
      final progress2 = completedCount2 / completedSteps2.length;
      
      expect(progress2, equals(0.75));
      
      // Test 100% completion
      completion = ProfileCompletion(
        isCompleted: true,
        hasPhotos: true,
        hasPrompts: true,
        hasPersonalityAnswers: true,
        hasRequiredProfileFields: true,
        missingSteps: [],
      );
      
      final completedSteps3 = [
        completion.hasPhotos,
        completion.hasPrompts,
        completion.hasPersonalityAnswers,
        completion.hasRequiredProfileFields,
      ];
      final completedCount3 = completedSteps3.where((step) => step).length;
      final progress3 = completedCount3 / completedSteps3.length;
      
      expect(progress3, equals(1.0));
    });
  });
}