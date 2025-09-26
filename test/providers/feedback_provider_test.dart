import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:goldwen_app/features/feedback/providers/feedback_provider.dart';
import 'package:goldwen_app/core/models/feedback.dart';

void main() {
  group('FeedbackProvider Tests', () {
    late FeedbackProvider feedbackProvider;

    setUp(() {
      feedbackProvider = FeedbackProvider();
    });

    test('should initialize with correct default state', () {
      expect(feedbackProvider.isLoading, false);
      expect(feedbackProvider.isSubmitted, false);
      expect(feedbackProvider.error, null);
      expect(feedbackProvider.successMessage, null);
    });

    test('should provide correct feedback type options', () {
      final options = feedbackProvider.getFeedbackTypeOptions();
      
      expect(options, hasLength(3));
      expect(options[0].type, FeedbackType.bug);
      expect(options[0].title, 'Signaler un bug');
      expect(options[1].type, FeedbackType.feature);
      expect(options[1].title, 'Suggérer une fonctionnalité');
      expect(options[2].type, FeedbackType.general);
      expect(options[2].title, 'Commentaire général');
    });

    test('should clear state and notify listeners', () {
      bool listenerCalled = false;
      
      feedbackProvider.addListener(() {
        listenerCalled = true;
      });
      
      feedbackProvider.clearState();
      
      expect(listenerCalled, true);
      expect(feedbackProvider.isLoading, false);
      expect(feedbackProvider.isSubmitted, false);
      expect(feedbackProvider.error, null);
      expect(feedbackProvider.successMessage, null);
    });
  });

  group('FeedbackTypeOption Tests', () {
    test('should create feedback type option correctly', () {
      final option = FeedbackTypeOption(
        type: FeedbackType.bug,
        title: 'Test Title',
        subtitle: 'Test Subtitle',
        icon: Icons.bug_report,
        color: Colors.red,
      );

      expect(option.type, FeedbackType.bug);
      expect(option.title, 'Test Title');
      expect(option.subtitle, 'Test Subtitle');
      expect(option.icon, Icons.bug_report);
      expect(option.color, Colors.red);
    });
  });
}