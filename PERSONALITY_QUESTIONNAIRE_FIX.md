# Personality Questionnaire UUID Fix

## Problem
When completing the personality questionnaire, users received this error:
```
I/flutter ( 4980): API Response Body: {"success":false,"message":"Validation failed","code":"Bad Request","errors":["answers.0.questionId must be a UUID","answers.1.questionId must be a UUID",...]}
```

## Root Cause
The frontend was sending hardcoded string keys (like 'motivation', 'free_time') as questionIds, but the backend expects UUIDs from the PersonalityQuestion entity.

## Solution
1. **Load backend questions first**: The page now loads personality questions from the backend API to get their actual UUIDs
2. **Create question mapping**: Maps hardcoded question keys to backend UUIDs using either:
   - Category matching (preferred)
   - Order-based fallback if categories don't match
3. **Use UUIDs in submission**: Submit answers with actual UUIDs instead of string keys

## Files Modified

### `/lib/features/onboarding/pages/personality_questionnaire_page.dart`
- Added `initState()` to load questions from backend
- Added loading/error states for question loading
- Created `_createQuestionMapping()` for UUID mapping
- Modified `_finishQuestionnaire()` to use UUIDs
- Added comprehensive error handling

### `/lib/features/profile/providers/profile_provider.dart`  
- Fixed `loadPersonalityQuestions()` to handle different API response formats
- Added support for nested response structures

## Testing Steps

1. **Verify question loading**:
   - Open personality questionnaire page
   - Should show loading spinner initially
   - Should load questions from backend and show first question

2. **Check error handling**:
   - If backend is down, should show error message with retry button
   - If questions can't be mapped, should show appropriate error

3. **Test successful submission**:
   - Complete all 10 questions
   - Click "Terminer" 
   - Should successfully submit with UUIDs and navigate to profile setup
   - No more "questionId must be a UUID" errors

4. **Debug information**:
   - Check console logs for "Question mapping created: ..." to verify UUIDs are mapped
   - Check "Submitting X personality answers" to verify submission

## API Requirements
- Backend must have personality questions available at `/api/v1/profiles/personality-questions`
- Questions must have UUIDs as primary keys
- Questions should ideally have categories matching our hardcoded keys, or be in the correct order

## Fallback Strategy
If category mapping fails, the code falls back to order-based mapping, so questions will work as long as the backend has at least 10 personality questions in order.