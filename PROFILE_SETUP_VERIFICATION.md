# Profile Setup Verification Checklist

This document provides a step-by-step verification process for the profile setup fixes.

## Issues Addressed

### 1. ✅ Changed "Prénom" to "Pseudo"
**Location**: Profile setup page, basic info section
**Expected**: The first text field should now show "Pseudo" as the label and "Votre pseudo" as the hint text.
**Verification**: Look for the text field in the first page of profile setup.

### 2. ✅ Implemented Image Picker Functionality 
**Location**: Profile setup page, photos section
**Expected**: Clicking on "Ajouter une photo" should now open a dialog with "Appareil photo" and "Galerie" options.
**Verification**: 
- Navigate to the photos page (second page)
- Click on any empty photo slot
- Verify dialog appears with camera and gallery options
- Select either option and confirm image picker opens
- Verify selected image appears in the grid

### 3. ✅ Fixed Button Validation
**Location**: Profile setup page, all pages with "Continuer" buttons
**Expected**: Continue buttons should only be enabled when all required fields are filled.
**Verification**:
- **Page 1 (Basic Info)**: Button should enable only when pseudo, birth date, and bio are all filled
- **Page 2 (Photos)**: Button should show count and enable only when 3+ photos are added
- **Page 3 (Prompts)**: Button should enable only when all 3 prompts are answered

## Manual Testing Steps

### Test 1: Basic Info Validation
1. Open the app and navigate to profile setup
2. Verify the first field says "Pseudo" (not "Prénom")
3. Try clicking "Continuer" - should be disabled
4. Fill in pseudo field - button should remain disabled
5. Fill in bio field - button should remain disabled  
6. Select birth date - button should now be enabled
7. Clear any field - button should become disabled again

### Test 2: Photo Picker Functionality
1. Navigate to photos page (second page)
2. Click on "Ajouter une photo" (first empty slot)
3. Verify dialog appears with "Appareil photo" and "Galerie" options
4. Select "Galerie" option
5. Verify system photo picker opens
6. Select an image
7. Verify image appears in the grid
8. Verify remove button (X) appears on selected photos
9. Test removing a photo by clicking the X button
10. Add at least 3 photos and verify "Continuer" button enables

### Test 3: Error Handling
1. Test photo picker cancellation (click "Annuler")
2. Test photo picker with no permission (if applicable)
3. Verify error messages appear in SnackBar for failed operations

### Test 4: Complete Flow
1. Complete all pages of profile setup
2. Verify navigation between pages works
3. Verify final submission works
4. Confirm profile data is saved correctly

## Code Changes Summary

### Files Modified
- `lib/features/profile/pages/profile_setup_page.dart`

### Key Changes
1. **Import added**: `image_picker` package and `dart:io`
2. **Label change**: "Prénom" → "Pseudo", "Votre prénom" → "Votre pseudo"
3. **ImagePicker instance**: Added `final ImagePicker _picker = ImagePicker();`
4. **Text controller listeners**: Added in `initState()` to update button states
5. **Photo selection**: Implemented `_addPhoto()` and `_showImageSourceDialog()` methods
6. **Image display**: Enhanced to show actual selected images
7. **Memory management**: Updated `dispose()` to remove listeners

### Validation Logic
- Pseudo field must not be empty
- Birth date must be selected
- Bio field must not be empty
- At least 3 photos must be added
- All 3 prompts must be answered

## Testing Notes
- Image picker requires device permissions for camera/gallery access
- File paths are stored with 'file://' prefix for local images
- Error handling includes user-friendly SnackBar messages
- Button states update in real-time as user types or selects options