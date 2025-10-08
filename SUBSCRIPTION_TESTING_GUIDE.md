# GoldWen Plus Subscription - Testing Guide

## Overview

This guide provides comprehensive testing scenarios for the GoldWen Plus subscription feature. Follow these test cases to ensure all functionality works correctly.

## Prerequisites

### Test Environment Setup

1. **RevenueCat Configuration**
   - [ ] RevenueCat account created
   - [ ] Test project configured
   - [ ] Test API key configured in app
   - [ ] Sandbox products created:
     - goldwen_plus_monthly
     - goldwen_plus_quarterly
     - goldwen_plus_semiannual

2. **Device/Emulator Setup**
   - [ ] iOS Simulator with sandbox Apple ID
   - [ ] Android Emulator with test Google account
   - [ ] Physical devices (optional but recommended)

3. **Backend Setup**
   - [ ] API endpoints accessible
   - [ ] Test database available
   - [ ] Webhook URLs configured (if testing backend integration)

## Test Cases

### TC-001: Subscription Page Load

**Objective**: Verify subscription page loads correctly

**Steps**:
1. Open the app as a free user
2. Navigate to Daily Matches page
3. Tap on subscription promo banner
4. Observe subscription page loading

**Expected Results**:
- ✓ Page loads with gold gradient background
- ✓ Header shows "GoldWen Plus" title
- ✓ Loading state appears briefly
- ✓ Features section displays 4 premium features
- ✓ Plans section shows available subscription plans
- ✓ Subscribe button is visible and enabled
- ✓ Legal links are accessible

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-002: Plan Selection

**Objective**: Verify users can select different plans

**Steps**:
1. On subscription page with plans loaded
2. Observe default selected plan (should be quarterly)
3. Tap on monthly plan card
4. Tap on semi-annual plan card
5. Tap back to quarterly plan

**Expected Results**:
- ✓ Quarterly plan selected by default
- ✓ Tapping a plan highlights it with white border
- ✓ Previously selected plan is unhighlighted
- ✓ Radio indicator shows filled circle on selected
- ✓ No errors occur during selection

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-003: Purchase Flow - Success

**Objective**: Complete a successful test purchase

**Steps**:
1. Select quarterly plan (marked as "POPULAIRE")
2. Tap "S'abonner maintenant" button
3. When payment sheet appears, complete test purchase
4. Wait for verification

**Expected Results**:
- ✓ Button changes to "Traitement..."
- ✓ Loading indicator appears
- ✓ RevenueCat payment sheet opens
- ✓ Payment sheet shows correct plan and price
- ✓ After purchase, success dialog appears
- ✓ Success dialog shows congratulations message
- ✓ Tapping "Commencer" navigates to home
- ✓ User status is now premium

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-004: Purchase Flow - User Cancellation

**Objective**: Verify graceful handling of purchase cancellation

**Steps**:
1. Select any plan
2. Tap "S'abonner maintenant"
3. When payment sheet appears, tap "Cancel" or dismiss

**Expected Results**:
- ✓ Payment sheet closes
- ✓ Returns to subscription page
- ✓ NO error dialog appears
- ✓ Button returns to "S'abonner maintenant"
- ✓ User can try again

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-005: Error Handling - Network Error

**Objective**: Verify error handling when network fails

**Steps**:
1. Disable network connection (airplane mode)
2. Navigate to subscription page
3. Observe error state
4. Re-enable network
5. Tap "Réessayer" button

**Expected Results**:
- ✓ Error icon appears
- ✓ Error message is user-friendly
- ✓ "Réessayer" button is visible
- ✓ Tapping retry reloads plans successfully
- ✓ Error state clears when plans load

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-006: Subscription Banner (Daily Matches)

**Objective**: Verify promo banner displays correctly

**Steps**:
1. Login as free user
2. Navigate to Daily Matches page
3. Observe banner (should be at top of page)
4. Make one profile selection
5. Observe banner changes to "Limite atteinte" message

**Expected Results**:
- ✓ Banner appears with compact design
- ✓ Shows gold star icon
- ✓ Message: "Passez à GoldWen Plus pour 3 choix/jour"
- ✓ Has arrow indicator
- ✓ After selection, message updates
- ✓ Tapping banner navigates to subscription page

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-007: Daily Selection Limit - Free User

**Objective**: Verify free users are limited to 1 selection/day

**Steps**:
1. Login as free user
2. Navigate to Daily Matches
3. Select one profile (tap "Choisir")
4. Try to select a second profile

**Expected Results**:
- ✓ First selection succeeds
- ✓ Button changes to "Limite de sélection atteinte"
- ✓ Cannot select second profile
- ✓ SubscriptionLimitReachedDialog appears
- ✓ Dialog shows "1/1 sélections aujourd'hui"
- ✓ Premium features listed in dialog

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-008: Daily Selection Limit - Premium User

**Objective**: Verify premium users can select 3 profiles/day

**Steps**:
1. Login as premium user (or complete TC-003 first)
2. Navigate to Daily Matches
3. Select first profile
4. Select second profile
5. Select third profile
6. Try to select fourth profile

**Expected Results**:
- ✓ First selection succeeds
- ✓ Second selection succeeds
- ✓ Third selection succeeds
- ✓ Fourth selection blocked
- ✓ Limit indicator shows "3/3 selections"
- ✓ No upgrade dialog (already premium)

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-009: Subscription Status Indicator

**Objective**: Verify status indicator shows correctly

**Steps**:
1. Login as premium user
2. Navigate to Daily Matches or Settings
3. Observe status indicator

**Expected Results**:
- ✓ Indicator shows "GoldWen Plus actif"
- ✓ Gold star icon visible
- ✓ Gold border and background
- ✓ If <7 days to expiry, shows warning
- ✓ If free user, indicator not shown

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-010: Settings - Subscription Management

**Objective**: Verify subscription section in settings

**Steps**:
1. Navigate to Settings page
2. Scroll to subscription section
3. For premium user, tap "Gérer mon abonnement"
4. For free user, observe "Upgrade" option

**Expected Results**:
- ✓ Subscription section visible
- ✓ Premium: Shows status card
- ✓ Premium: Shows renewal date
- ✓ Premium: "Gérer mon abonnement" button
- ✓ Free: Shows upgrade promotion
- ✓ Free: "Découvrir GoldWen Plus" button
- ✓ "Restaurer mes achats" option visible

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-011: Restore Purchases

**Objective**: Verify purchase restoration works

**Steps**:
1. Make a test purchase (TC-003)
2. Logout from app
3. Reinstall app or clear data
4. Login with same account
5. Go to Settings > Subscription
6. Tap "Restaurer mes achats"

**Expected Results**:
- ✓ Restoration process starts
- ✓ Loading indicator shows
- ✓ Previous purchase is found
- ✓ Subscription status updates to active
- ✓ Premium features are enabled
- ✓ Success message displayed

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-012: Plan Details Display

**Objective**: Verify all plan information displays correctly

**Steps**:
1. Navigate to subscription page
2. Review each plan card
3. Verify pricing calculations

**Expected Results**:
- ✓ Monthly plan: Shows monthly price
- ✓ Quarterly plan: Shows quarterly price and monthly breakdown
- ✓ Quarterly plan: Has "POPULAIRE" badge
- ✓ Semi-annual plan: Shows 6-month price and monthly breakdown
- ✓ Semi-annual plan: Shows savings text
- ✓ All prices in correct currency (€)
- ✓ Features listed for each plan

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-013: Navigation & Back Button

**Objective**: Verify navigation works correctly

**Steps**:
1. Navigate to subscription page
2. Tap back button in header
3. Navigate again via banner
4. Complete partial purchase then cancel
5. Use system back gesture

**Expected Results**:
- ✓ Back button returns to previous page
- ✓ System back also works
- ✓ Can navigate multiple times without issues
- ✓ State is preserved when returning
- ✓ No crashes or errors

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-014: Legal Links

**Objective**: Verify legal page navigation

**Steps**:
1. On subscription page, scroll to bottom
2. Tap "Conditions d'utilisation"
3. Go back
4. Tap "Politique de confidentialité"
5. Go back

**Expected Results**:
- ✓ Terms page opens correctly
- ✓ Content is readable
- ✓ Back navigation works
- ✓ Privacy page opens correctly
- ✓ Both pages are properly formatted

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-015: Responsive Design

**Objective**: Verify UI adapts to different screen sizes

**Steps**:
1. Test on small phone (iPhone SE)
2. Test on large phone (iPhone Pro Max)
3. Test on tablet (iPad)
4. Rotate to landscape
5. Rotate back to portrait

**Expected Results**:
- ✓ Content is readable on all sizes
- ✓ No text cutoff
- ✓ Buttons are accessible
- ✓ Spacing is appropriate
- ✓ Landscape mode works
- ✓ Animations remain smooth

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-016: Animation Performance

**Objective**: Verify animations are smooth

**Steps**:
1. Navigate to subscription page
2. Observe page load animations
3. Select different plans
4. Scroll through content
5. Complete purchase flow

**Expected Results**:
- ✓ All animations run at 60fps
- ✓ No janky transitions
- ✓ Background gradient animates smoothly
- ✓ Content fades/slides in properly
- ✓ Plan selection is responsive
- ✓ Loading indicators spin smoothly

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-017: Accessibility

**Objective**: Verify accessibility features work

**Steps**:
1. Enable VoiceOver (iOS) or TalkBack (Android)
2. Navigate through subscription page
3. Try to select a plan
4. Attempt purchase

**Expected Results**:
- ✓ All elements are announced
- ✓ Buttons have descriptive labels
- ✓ Plan prices are readable
- ✓ Features are announced clearly
- ✓ Can complete flow using only screen reader
- ✓ Focus order is logical

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

### TC-018: Multiple Purchase Attempts

**Objective**: Verify system handles multiple purchases correctly

**Steps**:
1. Attempt purchase, then cancel
2. Attempt again with same plan, cancel
3. Attempt with different plan, complete
4. Try to purchase again while already subscribed

**Expected Results**:
- ✓ Each cancellation handled gracefully
- ✓ Can retry after cancellation
- ✓ Successful purchase updates status
- ✓ If already subscribed, appropriate message shown
- ✓ No duplicate subscriptions created

**Status**: [ ] Pass [ ] Fail

**Notes**: ___________________________

---

## Performance Tests

### PT-001: Page Load Time

**Test**: Measure time from navigation to full render

**Target**: < 2 seconds on 4G connection

**Actual**: _______ seconds

**Status**: [ ] Pass [ ] Fail

---

### PT-002: Animation Frame Rate

**Test**: Monitor FPS during animations

**Target**: 60 FPS

**Actual**: _______ FPS

**Status**: [ ] Pass [ ] Fail

---

### PT-003: Memory Usage

**Test**: Monitor memory during subscription flow

**Target**: No memory leaks, < 200MB total

**Actual**: _______ MB

**Status**: [ ] Pass [ ] Fail

---

## Integration Tests

### IT-001: Backend Sync

**Test**: Verify subscription syncs with backend

**Steps**:
1. Complete purchase
2. Check backend database
3. Verify user record updated

**Expected**:
- User has active subscription in DB
- Correct plan ID stored
- Expiry date is correct

**Status**: [ ] Pass [ ] Fail

---

### IT-002: RevenueCat Webhook

**Test**: Verify webhooks update backend

**Steps**:
1. Complete purchase
2. Wait for webhook
3. Check backend logs

**Expected**:
- Webhook received
- Subscription activated
- User status updated

**Status**: [ ] Pass [ ] Fail

---

## Cross-Platform Tests

### iOS Specific

- [ ] App Store payment sheet displays correctly
- [ ] Face ID / Touch ID works for authentication
- [ ] Sandbox testing works with test account
- [ ] Receipt validation succeeds

### Android Specific

- [ ] Google Play payment sheet displays correctly
- [ ] Fingerprint authentication works
- [ ] Test purchase flow completes
- [ ] Purchase token validation succeeds

---

## Edge Cases

### EC-001: Network Loss During Purchase

**Steps**:
1. Start purchase flow
2. Disable network when payment sheet appears
3. Complete purchase in payment sheet

**Expected**: Transaction is retried when network returns

**Status**: [ ] Pass [ ] Fail

---

### EC-002: App Backgrounded During Purchase

**Steps**:
1. Start purchase
2. Background app during payment
3. Return to app

**Expected**: Purchase state is preserved

**Status**: [ ] Pass [ ] Fail

---

### EC-003: Subscription Expired

**Steps**:
1. Use account with expired subscription
2. Navigate through app

**Expected**: 
- Treated as free user
- Prompted to resubscribe
- No crashes

**Status**: [ ] Pass [ ] Fail

---

## Regression Tests

After any code changes, verify:

- [ ] Purchase flow still works
- [ ] Error handling still works
- [ ] UI renders correctly
- [ ] Animations are smooth
- [ ] No new crashes introduced
- [ ] Tests still pass

---

## Sign-Off

**Tester Name**: _______________________

**Date**: _______________________

**Version Tested**: _______________________

**Overall Result**: [ ] Pass [ ] Fail [ ] Conditional

**Critical Issues**: _______________________

**Notes**: _______________________

---

## Appendix: Test Data

### Test Accounts

1. Free User:
   - Email: test-free@goldwen.app
   - Password: Test123!

2. Premium User:
   - Email: test-premium@goldwen.app
   - Password: Test123!

### Test Cards (Sandbox)

iOS:
- Test Apple ID: Use Sandbox tester from App Store Connect

Android:
- Test card: Use test card from Google Play Console

### Expected Plan IDs

- Monthly: `goldwen_plus_monthly`
- Quarterly: `goldwen_plus_quarterly`
- Semi-annual: `goldwen_plus_semiannual`

---

## Automated Test Execution

Run unit and integration tests:

```bash
# Run all subscription tests
flutter test test/subscription_integration_test.dart

# Run with coverage
flutter test --coverage test/subscription_integration_test.dart

# View coverage report
genhtml coverage/lcov.info -o coverage/html
```

Expected test results:
- All tests pass
- Coverage > 80%
- No flaky tests

---

## Troubleshooting

### Issue: Plans not loading

**Check**:
- RevenueCat API key is correct
- Network connection is available
- Offerings are configured in RevenueCat dashboard

### Issue: Purchase fails

**Check**:
- Using correct test account
- Sandbox mode enabled
- Products are approved in store

### Issue: Backend verification fails

**Check**:
- Webhook URL is correct
- API endpoints are accessible
- Backend is running

---

## Conclusion

All test cases should pass before considering the feature complete. Document any failures and create bug reports for issues found.
