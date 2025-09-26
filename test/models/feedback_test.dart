import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/feedback.dart';

void main() {
  group('Feedback Model Tests', () {
    test('should create feedback with all required fields', () {
      final metadata = FeedbackMetadata(
        page: 'test_page',
        userAgent: 'test_agent',
        appVersion: '1.0.0',
      );
      
      final feedback = Feedback(
        type: FeedbackType.bug,
        subject: 'Test Subject',
        message: 'Test message content',
        rating: 4,
        metadata: metadata,
      );
      
      expect(feedback.type, FeedbackType.bug);
      expect(feedback.subject, 'Test Subject');
      expect(feedback.message, 'Test message content');
      expect(feedback.rating, 4);
      expect(feedback.metadata?.page, 'test_page');
    });
    
    test('should serialize to JSON correctly', () {
      final metadata = FeedbackMetadata(
        page: 'test_page',
        userAgent: 'test_agent',
        appVersion: '1.0.0',
      );
      
      final feedback = Feedback(
        type: FeedbackType.feature,
        subject: 'Test Feature',
        message: 'Feature request message',
        rating: 5,
        metadata: metadata,
      );
      
      final json = feedback.toJson();
      
      expect(json['type'], 'feature');
      expect(json['subject'], 'Test Feature');
      expect(json['message'], 'Feature request message');
      expect(json['rating'], 5);
      expect(json['metadata']['page'], 'test_page');
    });
    
    test('should deserialize from JSON correctly', () {
      final json = {
        'type': 'general',
        'subject': 'Test General',
        'message': 'General feedback message',
        'rating': 3,
        'metadata': {
          'page': 'settings',
          'userAgent': 'mobile_app',
          'appVersion': '1.0.0',
        },
      };
      
      final feedback = Feedback.fromJson(json);
      
      expect(feedback.type, FeedbackType.general);
      expect(feedback.subject, 'Test General');
      expect(feedback.message, 'General feedback message');
      expect(feedback.rating, 3);
      expect(feedback.metadata?.page, 'settings');
      expect(feedback.metadata?.userAgent, 'mobile_app');
      expect(feedback.metadata?.appVersion, '1.0.0');
    });
    
    test('should handle feedback without rating and metadata', () {
      final feedback = Feedback(
        type: FeedbackType.bug,
        subject: 'Simple Bug',
        message: 'Simple bug message',
      );
      
      expect(feedback.type, FeedbackType.bug);
      expect(feedback.subject, 'Simple Bug');
      expect(feedback.message, 'Simple bug message');
      expect(feedback.rating, null);
      expect(feedback.metadata, null);
    });
    
    test('should provide correct display text for feedback types', () {
      expect(
        Feedback(
          type: FeedbackType.bug,
          subject: 'Test',
          message: 'Test',
        ).typeDisplayText,
        'Signaler un bug',
      );
      
      expect(
        Feedback(
          type: FeedbackType.feature,
          subject: 'Test',
          message: 'Test',
        ).typeDisplayText,
        'Suggérer une fonctionnalité',
      );
      
      expect(
        Feedback(
          type: FeedbackType.general,
          subject: 'Test',
          message: 'Test',
        ).typeDisplayText,
        'Commentaire général',
      );
    });
  });
  
  group('FeedbackMetadata Tests', () {
    test('should create metadata with all fields', () {
      final metadata = FeedbackMetadata(
        page: 'test_page',
        userAgent: 'test_agent',
        appVersion: '1.0.0',
      );
      
      expect(metadata.page, 'test_page');
      expect(metadata.userAgent, 'test_agent');
      expect(metadata.appVersion, '1.0.0');
    });
    
    test('should serialize to JSON correctly', () {
      final metadata = FeedbackMetadata(
        page: 'feedback_page',
        userAgent: 'ios_app',
        appVersion: '2.1.0',
      );
      
      final json = metadata.toJson();
      
      expect(json['page'], 'feedback_page');
      expect(json['userAgent'], 'ios_app');
      expect(json['appVersion'], '2.1.0');
    });
    
    test('should handle null fields in JSON', () {
      final metadata = FeedbackMetadata(
        page: 'test_page',
        // userAgent and appVersion are null
      );
      
      final json = metadata.toJson();
      
      expect(json['page'], 'test_page');
      expect(json.containsKey('userAgent'), false);
      expect(json.containsKey('appVersion'), false);
    });
  });
}