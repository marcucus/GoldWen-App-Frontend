# Backend Integration for Completion Flags

## Overview

The application's login flow now properly integrates with the backend API to fetch and use completion flags (`isOnboardingCompleted` and `isProfileCompleted`) that determine where authenticated users should be redirected.

## Backend Implementation

### User Entity
Located in `main-api/src/database/entities/user.entity.ts`:
- `isOnboardingCompleted?: boolean` - Indicates if user completed personality questionnaire
- `isProfileCompleted?: boolean` - Indicates if user completed full profile setup

### Automatic Flag Updates
The backend automatically updates these flags via the `updateProfileCompletionStatus()` method in `main-api/src/modules/profiles/profiles.service.ts`:

**Onboarding Completion Logic:**
```typescript
const isOnboardingCompleted = hasPersonalityAnswers;
```
- Set to `true` when user completes all required personality questions

**Profile Completion Logic:**
```typescript
const isProfileCompleted = 
  hasMinPhotos &&           // Minimum 3 photos
  hasPromptAnswers &&       // 3 prompt answers  
  hasPersonalityAnswers &&  // All required personality questions
  hasRequiredProfileFields; // birthDate and bio
```
- Set to `true` when ALL requirements are met

### API Endpoints
The completion flags are returned by:
- `/auth/login` - Returns flags after login
- `/auth/register` - Returns flags after registration  
- `/auth/social-login` - Returns flags after social login
- `/auth/me` - Returns current user with latest flags
- `/users/me` - Returns detailed user profile with flags

## Frontend Integration

### Splash Page Logic
Located in `lib/features/auth/pages/splash_page.dart`:

```dart
// Fetch fresh user data from backend on app startup
await authProvider.checkAuthStatus();
if (authProvider.isAuthenticated && authProvider.user != null) {
  await authProvider.refreshUser(); // Get latest completion flags
  final user = authProvider.user!;

  // Navigation logic based on backend flags
  if (user.isOnboardingCompleted == true && user.isProfileCompleted == true) {
    context.go('/home');           // Both complete -> main app
  } else if (user.isOnboardingCompleted == true) {
    context.go('/profile-setup');  // Only onboarding -> profile setup  
  } else {
    context.go('/questionnaire');  // Neither -> questionnaire
  }
}
```

### User Data Refresh
The `AuthProvider.refreshUser()` method:
1. Calls `ApiService.getCurrentUser()` which hits `/auth/me`
2. Gets fresh completion flags from backend
3. Updates local user model with backend data
4. Ensures splash page always has latest completion status

### Automatic Updates
The backend automatically updates completion flags when:
- User submits personality answers
- User uploads photos
- User answers prompts  
- User updates profile information

No manual flag setting needed - the backend calculates completion based on actual data.

## Testing the Integration

### Local Development
1. Start backend: `cd main-api && npm run start:dev`
2. Start frontend: `flutter run`
3. Test flow:
   - Register/login -> should go to questionnaire
   - Complete personality questionnaire -> should go to profile setup
   - Complete profile (photos, prompts, bio) -> should go to home

### Verification Points
- Check that splash page fetches fresh user data on startup
- Verify completion flags match actual user progress in backend
- Test that navigation correctly responds to backend completion status
- Ensure flags update automatically as user completes steps

## Key Benefits
1. **Single Source of Truth**: Backend determines completion based on actual data
2. **Automatic Updates**: No manual flag management required
3. **Consistent State**: Frontend always reflects backend reality
4. **Reliable Navigation**: Users can't get stuck in wrong flow
5. **Progress Persistence**: Completion status survives app restarts