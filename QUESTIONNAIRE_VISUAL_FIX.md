# Questionnaire Visual Style Fix

## Issue
The visual display when selecting answers in the personality questionnaire was degraded, lacking clear visual feedback and design consistency with the rest of the application.

## Root Cause
The Card widgets for multiple choice and boolean question answers were missing:
1. Rounded border styling (`RoundedRectangleBorder`)
2. Visible colored border when selected
3. Consistent design pattern used elsewhere in the app (e.g., feedback page)

## Solution
Added rounded borders and colored selection borders to Card widgets:

### Changes Made
1. **Multiple Choice Questions** (line ~398-407):
   - Added `RoundedRectangleBorder` with `AppBorderRadius.medium` (12px)
   - Added `BorderSide` with `AppColors.primaryGold` when selected, transparent otherwise
   - Border width: 2px when selected

2. **Boolean Questions** (line ~507-516):
   - Applied same styling as multiple choice questions
   - Ensures consistency across all question types

### Visual Improvements
- **Before**: Cards had basic elevation change, no visible border
- **After**: Cards have rounded corners and clear gold border when selected

### Design Pattern Alignment
The styling now matches the pattern used in:
- `lib/features/feedback/pages/feedback_page.dart` (line 248-253)
- Consistent with app's design system using `AppBorderRadius.medium`
- Uses brand color `AppColors.primaryGold` for selection feedback

## Testing
Visual testing recommended:
1. Navigate to personality questionnaire during onboarding
2. Select different answers for multiple choice questions
3. Verify rounded borders appear on all cards
4. Verify gold border (2px) appears when an option is selected
5. Verify unselected options have transparent border
6. Test with boolean questions (Yes/No)
7. Verify visual consistency with other parts of the app

## Files Modified
- `lib/features/onboarding/pages/personality_questionnaire_page.dart`

## Code Diff
```dart
// Added to both multiple choice and boolean Card widgets:
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
  side: BorderSide(
    color: isSelected ? AppColors.primaryGold : Colors.transparent,
    width: 2,
  ),
),
```

## Impact
- **Low risk**: Only visual styling changes, no logic modification
- **Non-breaking**: Maintains all existing functionality
- **Consistent**: Aligns with app-wide design patterns
- **Accessible**: Improves visual feedback for user selections
