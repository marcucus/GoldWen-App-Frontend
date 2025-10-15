# Quick Reference - Onboarding Fixes

## What Was Fixed?

✅ **Issue 1**: Onboarding pages (gender, preferences, location, etc.) not showing  
✅ **Issue 2**: Only 3 prompts available instead of all prompts  
✅ **Issue 3**: `isOnboardingCompleted` and `isProfileCompleted` flags not being set

---

## Files Modified

### Frontend (Flutter)
1. `lib/features/onboarding/pages/personality_questionnaire_page.dart`
   - **Change**: Navigate to GenderSelectionPage instead of ProfileSetupPage
   - **Line**: ~618

2. `lib/core/services/api_service.dart`
   - **Change**: Use `isVisible` parameter instead of `completed`
   - **Line**: ~267-281

3. `lib/features/profile/providers/profile_provider.dart`
   - **Change**: Call `updateProfileStatus(isVisible: true)`
   - **Line**: ~618

### Backend (NestJS)
1. `main-api/src/modules/profiles/profiles.service.ts`
   - **Changes**: 
     - Remove `take: 3` from prompts query (line ~422)
     - Add comprehensive debug logging to `updateProfileCompletionStatus` (line ~627-683)

2. `main-api/src/modules/profiles/profiles.controller.ts`
   - **Change**: Update API documentation for prompts endpoint
   - **Line**: ~200-208

---

## Quick Test Checklist

### Test 1: Onboarding Flow (5 min)
- [ ] Create new user account
- [ ] Complete personality questionnaire (10 questions)
- [ ] **CHECK**: Should navigate to "Je suis..." (gender selection)
- [ ] Select gender and continue
- [ ] **CHECK**: Should navigate to "Je suis intéressé(e) par..." (preferences)
- [ ] Select preferences and continue
- [ ] **CHECK**: Should navigate to location setup
- [ ] Allow location or enter city
- [ ] **CHECK**: Should navigate to age/distance preferences
- [ ] Set age range and distance
- [ ] **CHECK**: Should navigate to additional info (job, education, etc.)
- [ ] Fill or skip additional info
- [ ] **CHECK**: Should navigate to profile setup (photos + bio)

### Test 2: Prompts Selection (2 min)
- [ ] In profile setup, scroll to prompts section
- [ ] **CHECK**: Should see 10+ prompts to choose from (not just 3)
- [ ] Select any 3 prompts
- [ ] Answer all 3 prompts
- [ ] **CHECK**: Should be able to continue

### Test 3: Completion Flags (3 min)
- [ ] Complete entire registration flow
- [ ] Upload 3+ photos
- [ ] Fill bio and birthdate
- [ ] Answer 3 prompts
- [ ] Complete personality questionnaire
- [ ] Click "Start Adventure" or similar button
- [ ] **CHECK**: Should navigate to home page (not error)
- [ ] **CHECK BACKEND**: Look for logs with `[updateProfileCompletionStatus]`
- [ ] **CHECK DATABASE**: 
   ```sql
   SELECT id, email, isOnboardingCompleted, isProfileCompleted 
   FROM users 
   WHERE email = 'test@example.com';
   ```
   Both should be `true`

---

## Debug Commands

### Check backend logs
```bash
# If using docker
docker logs goldwen-api -f | grep updateProfileCompletionStatus

# If running locally
# Logs will show in terminal where you ran `npm run start:dev`
```

### Check database
```bash
# Connect to database
psql -U postgres -d goldwen

# Check user completion status
SELECT id, email, "isOnboardingCompleted", "isProfileCompleted" 
FROM users 
WHERE "createdAt" > NOW() - INTERVAL '1 hour';

# Check profile data
SELECT u.email, p.bio, p."birthDate", 
       (SELECT COUNT(*) FROM photos WHERE "profileId" = p.id) as photo_count,
       (SELECT COUNT(*) FROM prompt_answers WHERE "profileId" = p.id) as prompt_count,
       (SELECT COUNT(*) FROM personality_answers WHERE "userId" = u.id) as personality_count
FROM users u
JOIN profiles p ON p."userId" = u.id
WHERE u."createdAt" > NOW() - INTERVAL '1 hour';
```

---

## Common Issues & Solutions

### Issue: Still seeing only 3 prompts
**Solution**: Clear backend cache or restart backend server
```bash
# Restart backend
cd main-api
npm run start:dev
```

### Issue: Onboarding pages still not showing
**Solution**: Clear app cache and rebuild
```bash
# Flutter clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Issue: Completion flags still false
**Check**:
1. Backend logs show `[updateProfileCompletionStatus]` being called?
2. All requirements met? (3+ photos, 3 prompts, personality, bio, birthDate)
3. API call successful? Check for errors in logs

**Debug**: Look at the logged object from `updateProfileCompletionStatus`:
```json
{
  "hasMinPhotos": true/false,  // Need true
  "photosCount": 3,            // Need >= 3
  "hasPromptAnswers": true/false,  // Need true
  "promptsCount": 3,           // Need exactly 3
  "hasPersonalityAnswers": true/false,  // Need true
  "hasRequiredProfileFields": true/false,  // Need true
  "hasBirthDate": true/false,  // Need true
  "hasBio": true/false,        // Need true
  "isProfileCompleted": true/false,
  "isOnboardingCompleted": true/false
}
```

---

## Rollback (if needed)

If you need to revert these changes:

```bash
# Checkout the previous state
git checkout d96511b  # The commit before our fixes

# Or revert specific commits
git revert 803936f 66d55ce 413e11a 1bd766e
```

---

## Next Steps After Testing

If all tests pass:
1. Merge this PR to main/develop branch
2. Deploy to staging environment
3. Test again in staging
4. Deploy to production
5. Monitor backend logs for any issues
6. Monitor user completion rates

If tests fail:
1. Check the "Common Issues & Solutions" section above
2. Review backend logs
3. Check database state
4. Report specific error messages

---

## Support

For questions or issues:
1. Check `ONBOARDING_FIXES_SUMMARY.md` for detailed technical info
2. Check `VISUAL_FLOW_DIAGRAMS.md` for flow diagrams
3. Check backend logs for `[updateProfileCompletionStatus]` entries
4. Check this file for quick debugging tips
