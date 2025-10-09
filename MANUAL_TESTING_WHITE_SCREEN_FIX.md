# Manual Testing Guide - White Screen Fix

## Prerequisites
1. Backend server running on `localhost:3000`
2. Database seeded with personality questions (should happen automatically via `DatabaseSeederService`)
3. Flutter app ready to run

## Test Scenarios

### Scenario 1: Successful Registration → Questionnaire Flow
**Steps:**
1. Launch the app
2. Go to registration page
3. Fill in registration form:
   - Email: `test@example.com`
   - Password: `Test123!`
   - First Name: `Test`
   - Last Name: `User`
4. Submit registration

**Expected Results:**
- ✅ Registration succeeds
- ✅ Navigate to `/splash`
- ✅ Splash checks user status
- ✅ Navigate to `/questionnaire` (since onboarding not completed)
- ✅ Loading spinner appears briefly
- ✅ Questions load successfully
- ✅ See "Question 1/10" in app bar
- ✅ See progress indicator at top
- ✅ See first question with multiple choice options
- ✅ **NO WHITE SCREEN**

**Console Output Expected:**
```
Loaded 10 personality questions successfully
```

### Scenario 2: Navigate Through All Questions
**Steps:**
1. After successful load, select an answer
2. Click "Suivant" button
3. Repeat for all 10 questions

**Expected Results for Multiple Choice Questions (Questions 1, 2, 5, 6, 8, 9, 10):**
- ✅ All options display correctly
- ✅ Selected option highlights in gold
- ✅ Checkmark appears on selected option
- ✅ Can change selection
- ✅ "Suivant" button enabled after selection

**Expected Results for Scale Questions (Questions 3, 4, 7):**
- ✅ Shows "Évaluez de 1 à 10"
- ✅ 10 circular buttons displayed
- ✅ Buttons wrapped properly (2 rows if needed)
- ✅ Selected number highlights in gold
- ✅ Can change selection
- ✅ "Suivant" button enabled after selection

**Expected Results for Last Question:**
- ✅ Button text shows "Terminer" instead of "Suivant"

### Scenario 3: Complete Questionnaire and Submit
**Steps:**
1. Answer all 10 questions
2. Click "Terminer" on last question

**Expected Results:**
- ✅ Loading indicator appears in button
- ✅ Answers submit successfully
- ✅ Navigate to `/profile-setup`
- ✅ No errors in console

**Console Output Expected:**
```
Submitting 10 personality answers
API Answers format: [...]
```

### Scenario 4: Backend Not Running (Error Handling)
**Steps:**
1. Stop backend server
2. Launch app
3. Register a new user
4. Navigate to questionnaire page

**Expected Results:**
- ✅ Loading spinner appears
- ✅ After timeout, error message appears
- ✅ Shows red error icon
- ✅ Shows error message: "Erreur lors du chargement des questions: ..."
- ✅ "Réessayer" button appears
- ✅ **NO WHITE SCREEN**

**Console Output Expected:**
```
Error loading personality questions: [error details]
```

### Scenario 5: Empty Questions from Backend
**Steps:**
1. Modify backend to return empty array for questions
2. Navigate to questionnaire page

**Expected Results:**
- ✅ Loading spinner appears
- ✅ Empty questions detected
- ✅ Shows orange warning icon
- ✅ Shows "Aucune question disponible" message
- ✅ Shows "Réessayer" button
- ✅ **NO WHITE SCREEN**

**Console Output Expected:**
```
WARNING: No personality questions found on server
```

### Scenario 6: Back Navigation
**Steps:**
1. Load questionnaire successfully
2. Answer first question and go to question 2
3. Click back arrow in app bar

**Expected Results:**
- ✅ Returns to question 1
- ✅ Previously selected answer still selected
- ✅ Progress indicator updates correctly
- ✅ Back button disappears on question 1

### Scenario 7: Different Question Types Rendering
**Verify the following questions render correctly:**

**Question 1 (Multiple Choice - First Date Activity):**
- ✅ 5 options visible
- ✅ All options are clickable cards
- ✅ Options in ListView with proper spacing

**Question 3 (Scale 1-10 - Spontaneity):**
- ✅ "Évaluez de 1 à 10" text visible
- ✅ All 10 numbers (1-10) visible
- ✅ Circles wrapped in 2 rows if screen narrow
- ✅ All numbers clickable

**Question 4 (Scale 1-10 - Family Importance):**
- ✅ Same as Question 3
- ✅ Renders correctly

## Known Issues Fixed

### ❌ Issue: White Screen After Registration
**Cause:** Empty questions list not handled
**Fix:** Added explicit check and error UI

### ❌ Issue: ListView Rendering Error
**Cause:** ListView.builder missing shrinkWrap and physics
**Fix:** Added shrinkWrap: true and physics: const NeverScrollableScrollPhysics()

### ❌ Issue: Scale Shows 1-5 Instead of 1-10
**Cause:** Hardcoded scale range
**Fix:** Dynamic scale based on minValue/maxValue from question

### ❌ Issue: No Error Feedback
**Cause:** Silent failures on empty data
**Fix:** Added logging and error detection

## Success Criteria

✅ No white screens at any point
✅ All questions load and display correctly
✅ All question types render properly
✅ Can navigate forward and backward
✅ Can select and change answers
✅ Can submit successfully
✅ Error states show helpful messages
✅ Loading states show spinner
✅ Empty states show appropriate message

## Screenshots Needed

Please capture screenshots of:
1. Question 1 (Multiple Choice)
2. Question 3 (Scale 1-10)
3. Progress indicator at different stages
4. Error state (backend down)
5. Empty state (no questions)
6. Final question showing "Terminer" button

## Debug Information

**Enable development mode logs in:**
- `lib/core/config/app_config.dart` → Set `isDevelopment = true`

**Monitor console for:**
- Question loading logs
- Error messages
- API response logs
- Navigation logs

## Rollback Plan

If issues persist:
1. Check backend is running: `curl http://localhost:3000/api/v1/health`
2. Check questions endpoint: `curl http://localhost:3000/api/v1/profiles/personality-questions`
3. Verify database has questions: Check `personality_questions` table
4. Clear app data and retry
5. Check for any console errors
