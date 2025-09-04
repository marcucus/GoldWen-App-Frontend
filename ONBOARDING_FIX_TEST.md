# Integration Test Scenario for Onboarding Completion Fix

## Test Case: Complete Onboarding Flow

### Setup
1. Start with a fresh user account (isOnboardingCompleted: false, isProfileCompleted: false)
2. Ensure backend is running and can accept API calls

### Test Steps

#### Step 1: Complete Personality Questionnaire
1. Navigate to PersonalityQuestionnairePage
2. Answer all 10 personality questions
3. Submit answers
4. Verify navigation to ProfileSetupPage
5. **Expected State**: isOnboardingCompleted: still false/null (this is expected)

#### Step 2: Complete Profile Setup - Basic Info
1. Fill in pseudo/name field
2. Select birth date
3. Fill in bio field
4. Click "Continuer"
5. Verify navigation to photos page

#### Step 3: Complete Profile Setup - Photos  
1. Add at least 3 photos
2. Click "Continuer"
3. Verify navigation to prompts page

#### Step 4: Complete Profile Setup - Prompts
1. Answer all 3 prompt questions  
2. Click "Continuer"
3. Verify navigation to review page

#### Step 5: Complete Profile Setup - Finish (THE CRITICAL STEP)
1. Click "Commencer mon aventure"
2. Verify loading dialog appears
3. **Check logs for**:
   - "Profile basic data saved successfully"
   - "Prompt answers submitted successfully" 
   - "Profile status updated successfully"
   - **"Profile completion flags updated successfully"** ← NEW LOG FROM FIX
   - "User data refreshed successfully"
4. Verify navigation to MainNavigationPage
5. **Expected State**: isOnboardingCompleted: true, isProfileCompleted: true

#### Step 6: Test Session Persistence (THE KEY TEST)
1. Force close the app or log out
2. Restart app or log back in
3. Verify SplashPage loads
4. **Verify**: App navigates directly to MainNavigationPage (home)
5. **Verify**: NO navigation to PersonalityQuestionnairePage or ProfileSetupPage
6. **Expected Behavior**: User should NOT have to redo onboarding

### Success Criteria
- [ ] User can complete full onboarding flow without errors
- [ ] Both completion flags are set to true after profile setup
- [ ] User goes directly to main app on subsequent logins
- [ ] No re-onboarding required after logout/login

### Failure Scenarios to Test
- [ ] Network error during markProfileCompleted() → should show retry option
- [ ] Partial profile completion → should resume from correct step
- [ ] Backend returns different flag values → should handle gracefully

### Log Messages to Verify
```
Profile basic data saved successfully
Prompt answers submitted successfully
Profile status updated successfully
Profile completion flags updated successfully  ← NEW MESSAGE FROM FIX
User data refreshed successfully
```

## Expected Impact
This fix should resolve the issue where users have to redo onboarding when they reconnect, ensuring a smooth user experience.