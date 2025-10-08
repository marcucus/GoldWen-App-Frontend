# Advanced Recommendations (Matching V2)

## Overview

This feature implements the advanced recommendations screen with detailed compatibility scoring based on the matching V2 algorithm. It displays comprehensive score breakdowns including personality, preferences, and advanced factors like activity, response rate, and reciprocity.

## Features

### 1. Advanced Compatibility Scoring

The system calculates compatibility scores with the following components:

- **Personality Score**: Compatibility based on personality questionnaire answers
- **Preferences Score**: Match based on user preferences
- **Activity Bonus**: Bonus points for active users
- **Response Rate Bonus**: Bonus for users with good response rates
- **Reciprocity Bonus**: Bonus based on mutual interest patterns

### 2. Score Breakdown Display

The UI displays a detailed breakdown of the compatibility score:

- Visual progress bars for base scores
- Color-coded bonus/malus indicators
- Summary showing base score and total bonuses
- Clear differentiation between positive and negative factors

### 3. Match Reasons

Detailed explanations for why profiles match, categorized by:

- Personality traits
- Common interests
- Shared values
- Lifestyle compatibility
- Communication styles
- Activity levels
- Reciprocity patterns

## API Integration

### Endpoint

```
POST /api/v1/matching/calculate-compatibility-v2
```

### Request Body

```json
{
  "userId": "uuid",
  "candidateIds": ["uuid1", "uuid2", ...],
  "personalityAnswers": {...},
  "preferences": {...},
  "userLocation": {...},
  "includeAdvancedScoring": true
}
```

### Response Format

```json
{
  "compatibilityScores": [
    {
      "userId": "uuid1",
      "score": 87.5,
      "breakdown": {
        "personalityScore": 51,
        "preferencesScore": 34,
        "activityBonus": 8,
        "responseRateBonus": 7,
        "reciprocityBonus": 15
      },
      "matchReasons": [
        {
          "category": "personality",
          "description": "Vous partagez des traits de personnalité similaires",
          "impact": 0.15
        }
      ]
    }
  ]
}
```

## Models

### ScoreBreakdown

```dart
class ScoreBreakdown {
  final double personalityScore;
  final double preferencesScore;
  final double activityBonus;
  final double responseRateBonus;
  final double reciprocityBonus;

  double get baseScore => personalityScore + preferencesScore;
  double get totalBonuses => activityBonus + responseRateBonus + reciprocityBonus;
}
```

### MatchReason

```dart
class MatchReason {
  final String category;
  final String description;
  final double impact;
}
```

### CompatibilityScoreV2

```dart
class CompatibilityScoreV2 {
  final String userId;
  final double score;
  final ScoreBreakdown breakdown;
  final List<MatchReason> matchReasons;
}
```

## UI Components

### AdvancedRecommendationsPage

Main page that displays the advanced recommendations list. Features:

- Loading state with animation
- Error handling with retry capability
- Empty state messaging
- Pull-to-refresh functionality
- Scrollable list of recommendation cards

### ScoreBreakdownCard

Widget that displays the score breakdown with:

- Progress bars for base scores
- Color-coded bonus indicators (green for positive, red for negative)
- Up/down arrows for bonus direction
- Summary section with totals

### MatchReasonsWidget

Displays detailed match reasons with:

- Category icons
- Color-coded categories
- Impact percentage indicators
- French language labels
- Responsive card layout

## Navigation

Access the advanced recommendations page via:

```dart
context.go('/advanced-recommendations?userId=xxx&candidateIds=id1,id2,id3');
```

Or programmatically:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => AdvancedRecommendationsPage(
      userId: 'user-id',
      candidateIds: ['candidate1', 'candidate2'],
    ),
  ),
);
```

## Responsive Design

The UI is fully responsive and adapts to:

- Mobile screens (phones)
- Tablet screens
- Desktop screens

All components use flexible layouts and follow Material Design guidelines.

## Testing

### Unit Tests

- Model serialization/deserialization tests
- Score calculation tests
- Bonus/malus logic tests

Run unit tests:

```bash
flutter test test/advanced_compatibility_models_test.dart
```

### Widget Tests

- ScoreBreakdownCard rendering tests
- MatchReasonsWidget display tests
- Color and icon verification tests

Run widget tests:

```bash
flutter test test/score_breakdown_card_test.dart
flutter test test/match_reasons_widget_test.dart
```

## Accessibility

All components include proper accessibility features:

- Semantic labels for screen readers
- High contrast mode support
- Reduced motion support
- Keyboard navigation
- WCAG AAA compliance

## Performance

The implementation is optimized for:

- Efficient rendering with const constructors
- Lazy loading of images
- Minimal rebuilds with proper state management
- Smooth animations (respecting reduced motion preferences)

## Future Enhancements

Potential future improvements:

1. Real-time score updates
2. Interactive score explanations
3. Comparison between multiple profiles
4. Historical score tracking
5. A/B testing for algorithm improvements
6. Machine learning integration for V3 algorithm

## References

- Backend Issue #6: [Améliorer l'algorithme de matching avec scoring avancé](../main-api/BACKEND_ISSUES_READY.md)
- Specifications: [specifications.md](../specifications.md) §4.2
