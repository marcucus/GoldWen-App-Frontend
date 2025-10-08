import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/models/matching.dart';

void main() {
  group('ScoreBreakdown', () {
    test('should create from JSON correctly', () {
      final json = {
        'personalityScore': 51.0,
        'preferencesScore': 34.0,
        'activityBonus': 8.0,
        'responseRateBonus': 7.0,
        'reciprocityBonus': 15.0,
      };

      final breakdown = ScoreBreakdown.fromJson(json);

      expect(breakdown.personalityScore, 51.0);
      expect(breakdown.preferencesScore, 34.0);
      expect(breakdown.activityBonus, 8.0);
      expect(breakdown.responseRateBonus, 7.0);
      expect(breakdown.reciprocityBonus, 15.0);
    });

    test('should convert to JSON correctly', () {
      final breakdown = ScoreBreakdown(
        personalityScore: 51.0,
        preferencesScore: 34.0,
        activityBonus: 8.0,
        responseRateBonus: 7.0,
        reciprocityBonus: 15.0,
      );

      final json = breakdown.toJson();

      expect(json['personalityScore'], 51.0);
      expect(json['preferencesScore'], 34.0);
      expect(json['activityBonus'], 8.0);
      expect(json['responseRateBonus'], 7.0);
      expect(json['reciprocityBonus'], 15.0);
    });

    test('should calculate baseScore correctly', () {
      final breakdown = ScoreBreakdown(
        personalityScore: 51.0,
        preferencesScore: 34.0,
        activityBonus: 8.0,
        responseRateBonus: 7.0,
        reciprocityBonus: 15.0,
      );

      expect(breakdown.baseScore, 85.0);
    });

    test('should calculate totalBonuses correctly', () {
      final breakdown = ScoreBreakdown(
        personalityScore: 51.0,
        preferencesScore: 34.0,
        activityBonus: 8.0,
        responseRateBonus: 7.0,
        reciprocityBonus: 15.0,
      );

      expect(breakdown.totalBonuses, 30.0);
    });

    test('should handle negative bonuses', () {
      final breakdown = ScoreBreakdown(
        personalityScore: 51.0,
        preferencesScore: 34.0,
        activityBonus: -5.0,
        responseRateBonus: 7.0,
        reciprocityBonus: 15.0,
      );

      expect(breakdown.totalBonuses, 17.0);
    });
  });

  group('MatchReason', () {
    test('should create from JSON correctly', () {
      final json = {
        'category': 'personality',
        'description': 'Vous partagez des traits de personnalité similaires',
        'impact': 0.15,
      };

      final reason = MatchReason.fromJson(json);

      expect(reason.category, 'personality');
      expect(reason.description, 'Vous partagez des traits de personnalité similaires');
      expect(reason.impact, 0.15);
    });

    test('should convert to JSON correctly', () {
      final reason = MatchReason(
        category: 'interests',
        description: 'Intérêts communs',
        impact: 0.10,
      );

      final json = reason.toJson();

      expect(json['category'], 'interests');
      expect(json['description'], 'Intérêts communs');
      expect(json['impact'], 0.10);
    });
  });

  group('CompatibilityScoreV2', () {
    test('should create from JSON correctly', () {
      final json = {
        'userId': 'user-123',
        'score': 87.5,
        'breakdown': {
          'personalityScore': 51.0,
          'preferencesScore': 34.0,
          'activityBonus': 8.0,
          'responseRateBonus': 7.0,
          'reciprocityBonus': 15.0,
        },
        'matchReasons': [
          {
            'category': 'personality',
            'description': 'Vous partagez des traits de personnalité similaires',
            'impact': 0.15,
          },
        ],
      };

      final scoreV2 = CompatibilityScoreV2.fromJson(json);

      expect(scoreV2.userId, 'user-123');
      expect(scoreV2.score, 87.5);
      expect(scoreV2.breakdown.personalityScore, 51.0);
      expect(scoreV2.matchReasons.length, 1);
      expect(scoreV2.matchReasons[0].category, 'personality');
    });

    test('should handle empty matchReasons', () {
      final json = {
        'userId': 'user-123',
        'score': 87.5,
        'breakdown': {
          'personalityScore': 51.0,
          'preferencesScore': 34.0,
          'activityBonus': 8.0,
          'responseRateBonus': 7.0,
          'reciprocityBonus': 15.0,
        },
      };

      final scoreV2 = CompatibilityScoreV2.fromJson(json);

      expect(scoreV2.matchReasons, isEmpty);
    });

    test('should convert to JSON correctly', () {
      final scoreV2 = CompatibilityScoreV2(
        userId: 'user-456',
        score: 92.0,
        breakdown: ScoreBreakdown(
          personalityScore: 55.0,
          preferencesScore: 40.0,
          activityBonus: 10.0,
          responseRateBonus: 8.0,
          reciprocityBonus: 12.0,
        ),
        matchReasons: [
          MatchReason(
            category: 'values',
            description: 'Valeurs communes',
            impact: 0.20,
          ),
        ],
      );

      final json = scoreV2.toJson();

      expect(json['userId'], 'user-456');
      expect(json['score'], 92.0);
      expect(json['breakdown']['personalityScore'], 55.0);
      expect((json['matchReasons'] as List).length, 1);
    });

    test('should handle multiple match reasons', () {
      final json = {
        'userId': 'user-789',
        'score': 88.0,
        'breakdown': {
          'personalityScore': 50.0,
          'preferencesScore': 35.0,
          'activityBonus': 9.0,
          'responseRateBonus': 6.0,
          'reciprocityBonus': 13.0,
        },
        'matchReasons': [
          {
            'category': 'personality',
            'description': 'Traits similaires',
            'impact': 0.15,
          },
          {
            'category': 'interests',
            'description': 'Intérêts communs',
            'impact': 0.12,
          },
          {
            'category': 'values',
            'description': 'Valeurs partagées',
            'impact': 0.18,
          },
        ],
      };

      final scoreV2 = CompatibilityScoreV2.fromJson(json);

      expect(scoreV2.matchReasons.length, 3);
      expect(scoreV2.matchReasons[0].category, 'personality');
      expect(scoreV2.matchReasons[1].category, 'interests');
      expect(scoreV2.matchReasons[2].category, 'values');
    });
  });
}
