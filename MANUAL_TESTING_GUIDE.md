# Manual Testing Guide - Daily Selection Screen

## Prerequisites
- Flutter development environment set up
- App running on emulator or physical device
- Backend API accessible (or using mock data)
- User account created and logged in

## Test Scenarios

### Scenario 1: View Daily Selection
**Steps:**
1. Navigate to the daily selection screen (home/matches tab)
2. Observe the displayed profiles

**Expected Results:**
- ✅ Screen shows "Sélection du jour" header
- ✅ 3-5 profile cards are displayed (or mock data if backend unavailable)
- ✅ Each card shows: photo, name, age, location (if available), bio
- ✅ Profile counter shows "X profil(s) disponible(s)"
- ✅ Selection info shows remaining choices (e.g., "1/1" for free users)
- ✅ Loading animation appears briefly during data fetch

### Scenario 2: Pass on a Profile
**Steps:**
1. View a profile card
2. Tap the "Passer" button (outlined button with X icon)

**Expected Results:**
- ✅ Profile is marked as passed
- ✅ Snackbar appears: "Profil passé. Continuez à explorer !"
- ✅ Profile is removed from the list
- ✅ Quota counter does NOT decrease (passes don't count)
- ✅ Can continue browsing remaining profiles

### Scenario 3: Choose a Profile (Free User)
**Steps:**
1. As a free user (1 choice/day)
2. Tap "Choisir" button (red button with heart icon)
3. Confirm in the dialog

**Expected Results:**
- ✅ Confirmation dialog appears with choice details
- ✅ Shows "Ce sera votre dernier choix aujourd'hui"
- ✅ After confirmation, success message appears
- ✅ If match: Match dialog appears
- ✅ If no match: "Votre choix est fait ! Revenez demain..."
- ✅ Selection complete state shown
- ✅ Remaining profiles are hidden
- ✅ "Découvrir GoldWen Plus" button visible

### Scenario 4: Choose a Profile (Premium User)
**Steps:**
1. As a premium user (3 choices/day)
2. Make first selection

**Expected Results:**
- ✅ Success message shows remaining choices: "Il vous reste 2 choix"
- ✅ Can continue selecting from remaining profiles
- ✅ Premium badge shows "PLUS" on selection info
- ✅ After 3 selections, selection complete state shown

### Scenario 5: View Profile Details
**Steps:**
1. Tap anywhere on a profile card (not on action buttons)

**Expected Results:**
- ✅ Navigate to profile detail page
- ✅ Can view full profile information
- ✅ Can navigate back to daily selection

### Scenario 6: Empty State
**Steps:**
1. Use an account with no available profiles
2. Or wait until all profiles are processed

**Expected Results:**
- ✅ Shows empty state icon (search icon)
- ✅ Message: "Aucun profil disponible"
- ✅ Subtitle: "Revenez demain pour découvrir de nouveaux profils..."
- ✅ "Découvrir GoldWen Plus" button visible

### Scenario 7: Error Handling
**Steps:**
1. Disconnect internet
2. Try to load daily selection

**Expected Results:**
- ✅ Error state displayed with error icon
- ✅ Error message: "Vérifiez votre connexion internet et réessayez"
- ✅ "Réessayer" button visible
- ✅ Tapping retry attempts to reload

### Scenario 8: Selection Complete State
**Steps:**
1. Use all daily selections
2. View daily selection screen

**Expected Results:**
- ✅ Shows checkmark icon
- ✅ Title: "Sélection terminée !"
- ✅ Message: "Vous avez fait vos choix pour aujourd'hui..."
- ✅ For free users: "Découvrir GoldWen Plus" button
- ✅ No profiles visible

### Scenario 9: Subscription Banners
**Steps:**
1. View daily selection as free user

**Expected Results:**
- ✅ When quota not reached: Bottom banner shows GoldWen Plus features
- ✅ When quota reached: Top banner: "Limite atteinte ! Passez à GoldWen Plus..."
- ✅ Banners are non-intrusive
- ✅ Selection info shows: "GoldWen Plus: 3 choix/jour"

### Scenario 10: Accessibility
**Steps:**
1. Enable TalkBack (Android) or VoiceOver (iOS)
2. Navigate the daily selection screen

**Expected Results:**
- ✅ All elements have semantic labels
- ✅ Profile information is read aloud
- ✅ Button purposes are clearly announced
- ✅ Counter information is accessible
- ✅ Navigation is logical and intuitive

### Scenario 11: Animations and Responsiveness
**Steps:**
1. Navigate to daily selection
2. Observe animations
3. Test on different screen sizes

**Expected Results:**
- ✅ Cards slide in smoothly (unless reduced motion enabled)
- ✅ Header fades in
- ✅ Layout adapts to screen width
- ✅ Images load with fade-in effect
- ✅ Buttons are appropriately sized for touch
- ✅ No layout overflow or clipping

### Scenario 12: Match Flow
**Steps:**
1. Choose a profile that has also chosen you
2. Observe match notification

**Expected Results:**
- ✅ Match acceptance dialog appears
- ✅ Shows matched user's name and photo
- ✅ Options to accept or decline chat
- ✅ If accepted: Navigate to chat
- ✅ If declined: Return to selection screen
- ✅ Local notification may appear (if permissions granted)

## Performance Checks

### Image Loading
- ✅ Profile images load progressively
- ✅ Placeholder shown while loading
- ✅ No memory leaks with multiple profiles
- ✅ Smooth scrolling through profile list

### State Management
- ✅ No unnecessary rebuilds
- ✅ State persists during navigation
- ✅ Quick response to user actions
- ✅ Proper cleanup on screen disposal

## Cross-Platform Testing

### iOS
- [ ] Test on iPhone SE (small screen)
- [ ] Test on iPhone 14 Pro Max (large screen)
- [ ] Verify safe area handling
- [ ] Check iOS-specific gestures

### Android
- [ ] Test on small phone (5")
- [ ] Test on large phone (6.5"+)
- [ ] Test on tablet
- [ ] Verify back button behavior

## Edge Cases

### Edge Case 1: Rapid Button Taps
**Test:** Quickly tap "Choisir" multiple times
**Expected:** Only one action processed, no duplicate requests

### Edge Case 2: Network Interruption During Action
**Test:** Start a choose/pass action, then disconnect internet
**Expected:** Appropriate error message, state remains consistent

### Edge Case 3: Session Expiry
**Test:** Let session expire, then try to make selection
**Expected:** Redirect to login or refresh token automatically

### Edge Case 4: Simultaneous Match
**Test:** Choose profile at same time they choose you
**Expected:** Match detected correctly, no race conditions

## Regression Testing

Verify these existing features still work:
- ✅ Profile detail navigation
- ✅ Subscription upgrade flow
- ✅ Match acceptance dialog
- ✅ Notification system
- ✅ Loading animations
- ✅ Error recovery

## Report Template

```
Test Date: _______________
Tester: _______________
Device: _______________
OS Version: _______________

Scenario | Pass | Fail | Notes
---------|------|------|-------
1. View Daily Selection | ☐ | ☐ | 
2. Pass on Profile | ☐ | ☐ | 
3. Choose (Free) | ☐ | ☐ | 
4. Choose (Premium) | ☐ | ☐ | 
5. View Details | ☐ | ☐ | 
6. Empty State | ☐ | ☐ | 
7. Error Handling | ☐ | ☐ | 
8. Selection Complete | ☐ | ☐ | 
9. Subscription Banners | ☐ | ☐ | 
10. Accessibility | ☐ | ☐ | 
11. Animations | ☐ | ☐ | 
12. Match Flow | ☐ | ☐ | 

Overall Result: ☐ PASS | ☐ FAIL

Issues Found:
_______________________________________________
_______________________________________________
_______________________________________________
```

## Notes for Testers

1. **Mock Data**: If backend is not available, the app uses mock profiles for development
2. **Backend Status**: Verify backend is running before testing API-dependent features
3. **Compatibility Score**: Not yet displayed (awaiting backend implementation)
4. **Match Reasons**: Not yet displayed (awaiting backend implementation)
5. **First Run**: May need to go through onboarding flow first

## Known Limitations

- Compatibility scores not displayed (backend enhancement needed)
- Match reasons not displayed (backend enhancement needed)
- Offline mode limited (requires network for API calls)
