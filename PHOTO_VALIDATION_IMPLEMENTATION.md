# Photo Validation Implementation - Minimum 3 Photos

## Summary of Changes

This implementation adds comprehensive photo validation to ensure users add at least 3 photos before continuing in the profile setup flow.

## Files Modified

### 1. `lib/features/profile/pages/profile_setup_page.dart`

#### Changes Made:

1. **Added Alert Method** (Line 139-164)
   - New method `_showMinPhotosAlert()` that displays a dialog when user tries to continue without 3 photos
   - Uses `AlertDialog` with warning icon and clear message
   - Provides user-friendly explanation of why 3 photos are required

2. **Enhanced Photo Page Button Section** (Line 355-401)
   - Added visual indicator showing "X/3 photos minimum ajoutées"
   - Icon changes based on completion:
     - Green check icon when 3+ photos added
     - Warning info icon when less than 3 photos
   - Button behavior updated:
     - When 3+ photos: Enabled, shows "Continuer (X/6)"
     - When < 3 photos: Shows alert on tap, displays "Continuer (X/3 minimum)"
   - Button color changes based on validation state

### 2. `test/profile_validation_test.dart`

#### Tests Added:

Added new test group "Photo Validation UI Tests" with 4 test cases:
1. `should identify when less than 3 photos are added` - Tests detection of insufficient photos
2. `should identify when exactly 3 photos are added` - Tests minimum requirement met
3. `should allow more than 3 photos up to maximum` - Tests multiple photos accepted
4. `should respect maximum of 6 photos` - Tests maximum limit enforced

## Features Implemented

### ✅ Block progression with less than 3 photos
- Button now calls `_showMinPhotosAlert()` instead of being disabled when < 3 photos
- User gets clear feedback on why they cannot continue

### ✅ Visual indicator "X/3 photos minimum"
- Prominent indicator above the button
- Color-coded: Green (success) when ≥3, Amber (warning) when <3
- Icon changes based on state

### ✅ Alert message on continue attempt
- Clear dialog explaining requirement
- User-friendly message about why photos are important
- "J'ai compris" button to dismiss

### ✅ Integration with profile completion check
- Uses existing `ProfileProvider.photos.length` 
- Maintains consistency with `PhotoManagementWidget` which already shows photo count
- Works with existing `_checkProfileCompletion()` method

## User Experience Flow

1. **User on Photos Page (0-2 photos):**
   - Sees warning indicator: "0/3 photos minimum ajoutées" (amber)
   - Button text: "Continuer (0/3 minimum)" (grayed out)
   - Clicking button shows alert dialog explaining requirement

2. **User on Photos Page (3+ photos):**
   - Sees success indicator: "3/3 photos minimum ajoutées" (green with check)
   - Button text: "Continuer (3/6)" (gold/enabled)
   - Clicking button proceeds to next page

## Technical Details

### Color Scheme
- Success: `AppColors.success` (Green)
- Warning: `AppColors.warningAmber` (Amber)
- Button enabled: `AppColors.primaryGold`
- Button disabled: `AppColors.textTertiary`

### Icons Used
- Success state: `Icons.check_circle`
- Warning state: `Icons.info_outline`
- Alert dialog: `Icons.warning_amber_rounded`

## Compliance with Specifications

According to `specifications.md` (line 59):
> "L'utilisateur doit télécharger un minimum de 3 photos."

This implementation fully satisfies this requirement by:
1. Preventing progression without 3 photos
2. Providing clear visual feedback
3. Explaining the requirement when user attempts to continue
4. Integrating with backend profile completion verification

## Testing

The implementation includes comprehensive unit tests covering:
- Photo count validation (< 3, = 3, > 3)
- Maximum photo limit (6 photos)
- Profile provider state management

To run tests (when Flutter is installed):
```bash
flutter test test/profile_validation_test.dart
```

## No Backend Changes

As specified in the issue, no backend modifications were made. The implementation only affects:
- Frontend UI/UX
- Client-side validation
- User feedback mechanisms

The existing backend validation remains unchanged and will still verify profile completion on submission.
