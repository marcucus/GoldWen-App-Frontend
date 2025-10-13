# Strict Profile Validation - Implementation Guide

## Overview

This document describes the implementation of strict profile validation in the GoldWen app, ensuring that user profiles are not visible until they meet all completion requirements as specified in `specifications.md`.

## Requirements from specifications.md

As per **Module 1: Onboarding et Création de Profil**, section 4.1, Critères d'Acceptation #6:

> "Le profil n'est pas visible par les autres tant que ces conditions ne sont pas remplies."

### Required conditions:
1. **Minimum 3 photos** uploaded
2. **3 prompt responses** completed
3. **Personality questionnaire** (10 questions) completed
4. **Basic profile information** (name, birth date, bio)

## Implementation Details

### 1. Backend-First Validation Approach

The implementation follows a **backend-authoritative** approach where:
- The backend endpoint `GET /api/v1/profiles/completion` is the single source of truth
- Local validation in the frontend is used only for UI guidance
- The `isProfileTrulyComplete` getter always uses backend completion status

### 2. Key Components Modified

#### ProfileProvider (`lib/features/profile/providers/profile_provider.dart`)

**New/Enhanced Methods:**

```dart
// Authoritative completion check - uses backend status
bool get isProfileTrulyComplete {
  return _profileCompletion?.isCompleted ?? false;
}

// Get the next step user should complete
String? getNextIncompleteStep() {
  // Returns: 'basic_info', 'photos', 'prompts', 'personality', or null
}

// Load completion status from backend
Future<void> loadProfileCompletion() async {
  // Fetches from /api/v1/profiles/completion
}

// Validate and activate profile (requires 100% completion)
Future<void> validateAndActivateProfile() async {
  // Throws exception if profile is not complete
}
```

**Key Points:**
- `_checkProfileCompletion()` is now explicitly marked as for UI guidance only
- Backend completion status (`_profileCompletion`) is always authoritative
- Added helper method `getNextIncompleteStep()` for consistent navigation

#### ProfileCompletionWidget (`lib/features/profile/widgets/profile_completion_widget.dart`)

**Enhanced Features:**
- Detailed progress bar showing percentage complete
- Status indicators for each requirement (✓ or ○)
- Clear messaging for missing steps
- **New:** Prominent warning message when profile is not visible

```dart
'Votre profil n\'est pas encore visible. Complétez toutes les étapes pour le rendre visible.'
```

#### ProfileSetupPage (`lib/features/profile/pages/profile_setup_page.dart`)

**Enhanced Features:**
- Automatic redirection to first incomplete step on page load
- Uses `getNextIncompleteStep()` for consistent navigation logic
- **New:** Prominent visibility status indicator on validation page
- Clear button states (enabled only when complete)

**Validation Page Improvements:**
- Shows green success banner when profile is complete and visible
- Shows amber warning banner when profile is incomplete and not visible
- Banner includes visibility icon (check_circle or visibility_off)

### 3. User Flow

#### New User Flow:
```
1. Register → Auth Complete
2. Complete Personality Questionnaire → isOnboardingCompleted = true
3. Profile Setup:
   a. Basic Info (name, birth date, bio)
   b. Upload 3+ photos
   c. Answer 3 prompts
   d. Validation page shows completion status
4. If all complete → Activate Profile → isProfileCompleted = true
5. Access Main App
```

#### Incomplete Profile Handling:
```
User with incomplete profile:
→ Splash page checks isProfileCompleted flag
→ If false, redirects to /profile-setup
→ Profile setup automatically navigates to first incomplete step
→ User completes missing steps
→ Validation page blocks progression until all steps complete
→ Once complete, profile activated and user can access main app
```

### 4. Navigation Priority

The `getNextIncompleteStep()` method prioritizes steps in this order:

1. **basic_info** - Basic profile fields (name, birth date, bio)
2. **photos** - Minimum 3 photos
3. **prompts** - 3 prompt responses
4. **personality** - Personality questionnaire (should be done in onboarding)

This ensures users complete foundational information first before adding richer content.

### 5. Backend Integration

**API Endpoint Used:**
```http
GET /api/v1/profiles/completion
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "isComplete": boolean,
    "completionPercentage": number,
    "requirements": {
      "minimumPhotos": {
        "required": 3,
        "current": number,
        "satisfied": boolean
      },
      "promptAnswers": {
        "required": 3,
        "current": number,
        "satisfied": boolean
      },
      "personalityQuestionnaire": boolean,
      "basicInfo": boolean
    },
    "missingSteps": string[],
    "nextStep": string
  }
}
```

**Profile Visibility Control:**
The backend endpoint `PUT /api/v1/profiles/me/status` is called when profile is complete to mark it as validated and visible.

## Testing

### Unit Tests Added

File: `test/profile_validation_test.dart`

**Test Groups:**

1. **Profile Validation Tests** - Model parsing and basic validation
2. **Profile Validation Requirements** - Requirement-specific tests
3. **Photo Validation UI Tests** - Photo count validation
4. **Strict Profile Validation - Backend Enforcement** - NEW
   - Backend completion status enforcement
   - `isProfileTrulyComplete` getter tests
   - `getNextIncompleteStep()` method tests
   - Step prioritization verification
   - Local vs backend validation precedence

### Manual Testing Checklist

#### Test Case 1: New User Complete Flow
- [ ] Register new account
- [ ] Complete personality questionnaire (10 questions)
- [ ] Redirected to profile setup
- [ ] Page loads at first incomplete step (basic info)
- [ ] Complete basic info → Auto-navigates to photos
- [ ] Upload 3 photos → Can proceed to prompts
- [ ] Answer 3 prompts → Can proceed to validation
- [ ] Validation page shows 100% complete
- [ ] Green banner shows "Profile will be visible"
- [ ] Button "Continuer" is enabled
- [ ] Click Continuer → Profile activated → Main app accessible

#### Test Case 2: Incomplete Profile - Missing Photos
- [ ] User with only 2 photos uploaded
- [ ] Navigate to validation page
- [ ] Progress bar shows ~75% (3/4 steps complete)
- [ ] Photos section shows red ○ (not complete)
- [ ] Missing steps list includes "Upload at least 3 photos"
- [ ] Amber warning banner shows "Profile not visible"
- [ ] Button "Continuer" is disabled or shows "Profil incomplet"
- [ ] Click "Compléter le profil" → Redirects to photos page

#### Test Case 3: Incomplete Profile - Missing Prompts
- [ ] User with photos but no prompts
- [ ] Validation page shows prompts incomplete
- [ ] Click missing step tap handler → Redirects to prompts page
- [ ] Complete prompts
- [ ] Return to validation page
- [ ] Status updates to show prompts complete

#### Test Case 4: Backend Validation Override
- [ ] User completes all local requirements
- [ ] Backend returns incomplete status (e.g., photos not validated)
- [ ] App should show profile as incomplete
- [ ] User cannot proceed to main app
- [ ] Clear error message shown

#### Test Case 5: Automatic Redirection
- [ ] User with incomplete profile tries to access main app
- [ ] Splash page detects incomplete status
- [ ] Redirects to /profile-setup
- [ ] Profile setup automatically navigates to first incomplete step
- [ ] User sees appropriate page for what's missing

## UI Changes

### Before Implementation
- ❌ Profile completion status not prominently displayed
- ❌ No clear warning about profile visibility
- ❌ Inconsistent navigation logic
- ❌ Local validation could conflict with backend

### After Implementation
- ✅ Prominent visibility warning on validation page
- ✅ Color-coded status indicators (green = visible, amber = not visible)
- ✅ Detailed progress bar with percentage
- ✅ Clear messaging for each missing step
- ✅ Consistent navigation using `getNextIncompleteStep()`
- ✅ Backend validation is always authoritative
- ✅ Visual guidance at every step

## Security & Privacy Considerations

### Profile Visibility
- **Backend enforcement**: The backend must not return incomplete profiles in matching/discovery
- **Double verification**: Both frontend and backend check completion status
- **No workarounds**: Users cannot bypass validation to make profile visible

### Data Validation
- **Photos**: Backend validates uploaded photos (format, size, moderation)
- **Prompts**: Backend validates length and content (max 150 chars)
- **Personality**: Backend validates all required questions answered

## Performance Considerations

- **Lazy loading**: Profile completion status loaded on-demand
- **Caching**: Completion status cached in ProfileProvider
- **Refresh points**: Status refreshed after each save operation
- **Optimistic UI**: Local validation provides immediate feedback while backend processes

## Error Handling

### Network Errors
```dart
try {
  await profileProvider.loadProfileCompletion();
} catch (e) {
  // Show error message
  // Allow user to retry
  // Don't block UI completely
}
```

### Incomplete Data
- Missing completion data from backend → Assume incomplete
- Null values → Default to false/incomplete
- API errors → Show user-friendly message with retry option

## Future Enhancements

### V2 Considerations
- [ ] Progressive disclosure of profile (partial visibility)
- [ ] Profile quality score (beyond just completion)
- [ ] Additional optional sections (audio/video)
- [ ] Machine learning for profile optimization suggestions

## Related Documentation

- `specifications.md` - Original requirements
- `TACHES_FRONTEND.md` - Frontend task breakdown
- `TACHES_BACKEND.md` - Backend dependencies
- `API_ROUTES_DOCUMENTATION.md` - API endpoint details
- `PROFILE_VALIDATION_TESTING.md` - Original testing guide

## Support & Troubleshooting

### Common Issues

**Issue**: User can't proceed despite completing all steps
- **Solution**: Check backend `/profiles/completion` response
- **Debug**: Log completion status in console
- **Fix**: Ensure backend properly validates all requirements

**Issue**: Profile shows as complete but backend says incomplete
- **Solution**: Refresh profile completion status
- **Debug**: Check network tab for API responses
- **Fix**: Re-submit missing data to backend

**Issue**: Automatic redirection not working
- **Solution**: Check `getNextIncompleteStep()` logic
- **Debug**: Log completion object in console
- **Fix**: Ensure ProfileProvider properly loaded completion data

## Conclusion

The strict profile validation implementation ensures that:
1. ✅ Profiles are not visible until 100% complete
2. ✅ Backend is the single source of truth
3. ✅ Users receive clear guidance on what's missing
4. ✅ Automatic navigation to incomplete sections
5. ✅ Progress is clearly visualized
6. ✅ Comprehensive test coverage

This implementation aligns with the specifications and provides a robust, user-friendly experience while maintaining strict validation requirements.
