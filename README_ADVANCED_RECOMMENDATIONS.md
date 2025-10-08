# Advanced Recommendations Feature

## Quick Start

This feature provides detailed compatibility scoring with advanced factors including activity, response rate, and reciprocity bonuses.

## Usage

### Navigate to Advanced Recommendations

```dart
import 'package:go_router/go_router.dart';

// Navigate from anywhere in the app
context.go('/advanced-recommendations?userId=$currentUserId&candidateIds=$profileId');
```

### Using the Provider

```dart
import 'package:provider/provider.dart';
import 'package:goldwen_app/features/matching/providers/matching_provider.dart';

// Load recommendations
final matchingProvider = Provider.of<MatchingProvider>(context, listen: false);
await matchingProvider.loadAdvancedRecommendations(
  userId: 'current-user-id',
  candidateIds: ['profile-1', 'profile-2'],
  includeAdvancedScoring: true,
);

// Display results
Consumer<MatchingProvider>(
  builder: (context, provider, child) {
    final recommendations = provider.advancedRecommendations;
    // Use recommendations...
  },
);
```

## Features

### Score Breakdown
- **Personality Score**: Compatibility from personality questionnaire
- **Preferences Score**: Match based on user preferences
- **Activity Bonus**: Reward for active users
- **Response Rate Bonus**: Reward for good responders
- **Reciprocity Bonus**: Reward for mutual interests

### Match Reasons
Detailed explanations organized by category:
- Personality traits
- Common interests
- Shared values
- Lifestyle compatibility
- Communication styles
- Activity levels
- Reciprocity patterns

## Components

### AdvancedRecommendationsPage
Main page displaying recommendations list.

### ScoreBreakdownCard
Widget showing detailed score components with progress bars and indicators.

### MatchReasonsWidget
Widget displaying categorized match reasons with impact percentages.

## API

### Endpoint
```
POST /api/v1/matching/calculate-compatibility-v2
```

### Request
```json
{
  "userId": "uuid",
  "candidateIds": ["uuid1", "uuid2"],
  "personalityAnswers": {},
  "preferences": {},
  "userLocation": {},
  "includeAdvancedScoring": true
}
```

### Response
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
      "matchReasons": [...]
    }
  ]
}
```

## Testing

```bash
# Run all tests
flutter test

# Run specific tests
flutter test test/advanced_compatibility_models_test.dart
```

## Documentation

See [ADVANCED_RECOMMENDATIONS_IMPLEMENTATION.md](./ADVANCED_RECOMMENDATIONS_IMPLEMENTATION.md) for full documentation.

## Examples

See [advanced_recommendations_usage_example.dart](./lib/features/matching/examples/advanced_recommendations_usage_example.dart) for code examples.
