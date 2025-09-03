# Profile Completion Fix - Manual Testing Guide

## Changes Made

### Backend Changes

1. **Fixed API Endpoint Routes:**
   - Changed `POST /profiles/prompt-answers` to `POST /profiles/me/prompt-answers`
   - Added `PUT /profiles/me/status` endpoint for marking profile completion

2. **Added Profile Status Update:**
   - New `UpdateProfileStatusDto` with validation
   - New `updateProfileStatus()` method in ProfilesService
   - Proper handling of completion flags

3. **Fixed Completion Logic:**
   - Profile requirements: 3+ photos, 3 prompt answers, personality answers, birthDate + bio
   - Onboarding completion: personality questionnaire completed
   - Gender and interested genders are now optional

### Frontend Changes

1. **Fixed API Service:**
   - Corrected endpoint URLs to match backend
   - Added `updateProfileStatus()` method
   - Removed duplicate `getPrompts()` method

2. **Updated Profile Setup:**
   - Added call to `updateProfileStatus()` when completing profile
   - Proper error handling and user feedback

## Testing Steps

### Backend Testing

1. **Unit Tests:**
   ```bash
   cd main-api
   npm test -- --testPathPatterns=profiles.service.spec.ts
   ```

2. **Build Verification:**
   ```bash
   cd main-api
   npm run build
   ```

### API Endpoints to Test

1. **Submit Personality Answers:**
   ```
   POST /api/v1/profiles/me/personality-answers
   Headers: Authorization: Bearer <token>
   Body: {
     "answers": [
       {"questionId": "uuid", "answer": "text", "category": "motivation"}
     ]
   }
   ```

2. **Update Profile:**
   ```
   PUT /api/v1/profiles/me
   Headers: Authorization: Bearer <token>
   Body: {
     "bio": "My bio",
     "birthDate": "1990-01-01"
   }
   ```

3. **Submit Prompt Answers:**
   ```
   POST /api/v1/profiles/me/prompt-answers
   Headers: Authorization: Bearer <token>
   Body: {
     "answers": [
       {"promptId": "uuid", "answer": "My answer"}
     ]
   }
   ```

4. **Update Profile Status:**
   ```
   PUT /api/v1/profiles/me/status
   Headers: Authorization: Bearer <token>
   Body: {
     "status": "active",
     "completed": true
   }
   ```

5. **Get User Data:**
   ```
   GET /api/v1/users/me
   Headers: Authorization: Bearer <token>
   ```

### Expected Behavior

1. **After personality questionnaire completion:**
   - `isOnboardingCompleted` should be `true`
   - User should proceed to profile setup

2. **After profile setup completion:**
   - `isProfileCompleted` should be `true`
   - `isOnboardingCompleted` should be `true`
   - User status should be `active`

3. **Profile completion criteria:**
   - At least 3 photos uploaded
   - 3 prompt answers provided
   - Personality questionnaire completed
   - Birth date and bio provided

### Database Verification

Check that the following fields are updated in the database:

```sql
-- Check user completion status
SELECT id, email, "isOnboardingCompleted", "isProfileCompleted", status 
FROM users 
WHERE email = 'test@example.com';

-- Check profile data
SELECT p.id, p."userId", p."birthDate", p.bio, 
       COUNT(ph.id) as photo_count,
       COUNT(pa.id) as prompt_answer_count
FROM profiles p
LEFT JOIN photos ph ON ph."profileId" = p.id
LEFT JOIN prompt_answers pa ON pa."profileId" = p.id
WHERE p."userId" = 'user-uuid'
GROUP BY p.id;

-- Check personality answers
SELECT COUNT(*) as personality_answer_count
FROM personality_answers pa
WHERE pa."userId" = 'user-uuid';
```

## Key Files Modified

### Backend:
- `main-api/src/modules/profiles/profiles.controller.ts`
- `main-api/src/modules/profiles/profiles.service.ts`
- `main-api/src/modules/profiles/dto/profiles.dto.ts`

### Frontend:
- `lib/core/services/api_service.dart`
- `lib/features/profile/pages/profile_setup_page.dart`

## Error Scenarios to Test

1. **Incomplete profile submission** - should return appropriate validation errors
2. **Network errors** - should be handled gracefully with user feedback  
3. **Authentication failures** - should redirect to login
4. **Partial data completion** - completion flags should remain false

## Success Criteria

✅ Users can complete personality questionnaire and see `isOnboardingCompleted = true`
✅ Users can complete profile setup and see `isProfileCompleted = true`  
✅ Prompt answers are saved correctly to database
✅ Profile information is updated in database
✅ API endpoints respond with correct status codes
✅ Frontend shows appropriate success/error messages