# Photo Management - Quick Reference Guide

## 🚀 Quick Start

### For Developers
```dart
// Use the widget
PhotoManagementWidget(
  photos: profileProvider.photos,
  onPhotosChanged: (photos) => profileProvider.updatePhotos(photos),
  minPhotos: 3,
  maxPhotos: 6,
  showAddButton: true,
)
```

### For Testers
1. Upload photos of various sizes (100KB - 10MB)
2. Verify compression happens automatically
3. Drag and drop to reorder
4. Check first photo is marked "Principal"
5. Delete photos and verify primary reassignment
6. Test error scenarios (invalid files, network issues)

### For Reviewers
- See `PHOTO_MANAGEMENT_IMPLEMENTATION.md` for technical details
- See `PHOTO_MANAGEMENT_FLOW_DIAGRAM.md` for visual flows
- See `PHOTO_MANAGEMENT_COMPLETE.md` for executive summary
- Check `test/photo_management_compression_test.dart` for test coverage

---

## 📋 What Was Implemented

### 1. Image Compression ✅
- **What**: Automatic compression to max 1MB
- **How**: `flutter_image_compress` with adaptive quality
- **Where**: `_compressImage()` method in `photo_management_widget.dart`

### 2. Primary Photo Logic ✅
- **What**: First photo = always primary
- **How**: Automatic on upload, reorder, delete
- **Where**: `_addPhoto()`, `_onReorder()`, `_deletePhoto()`

### 3. Backend Sync ✅
- **What**: Order and primary status sync
- **How**: API calls after each operation
- **Where**: `_updatePhotoOrder()`, `_setPrimaryPhotoOnBackend()`

### 4. Loading States ✅
- **What**: Progress indicators during operations
- **How**: `_isLoading` state with LinearProgressIndicator
- **Where**: Throughout all async methods

### 5. Error Handling ✅
- **What**: Validation and error messages
- **How**: Try-catch blocks with SnackBar feedback
- **Where**: All public methods

---

## 🔍 Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `photo_management_widget.dart` | Core implementation | +160 |
| `photo_management_page.dart` | UI page | +2 |
| `pubspec.yaml` | Dependencies | +1 |
| `photo_management_compression_test.dart` | Tests | +372 |
| `PHOTO_MANAGEMENT_*.md` | Docs | +964 |

---

## 🧪 Testing Checklist

### Automated ✅
```bash
flutter test test/photo_management_compression_test.dart
```

### Manual 📋
- [ ] Upload 100KB image → No compression
- [ ] Upload 5MB image → Compress to 1MB
- [ ] Upload 10MB image → Compress to 1MB
- [ ] Drag photo to position 0 → Becomes primary
- [ ] Delete primary photo → Next becomes primary
- [ ] Delete all photos → No errors
- [ ] Upload invalid file → Error message
- [ ] Network failure → Error message
- [ ] Upload 7th photo → Disabled/error

---

## 📊 Code Flow

### Upload Flow
```
Pick Image → Validate → Compress → Upload → Update UI
     ↓          ↓          ↓          ↓         ↓
  Camera/    Size &     To 1MB    Backend   Show Success
  Gallery    Format               Sync      + Loading
```

### Reorder Flow
```
Drag → Drop → Reorder → Update Primary → Sync Backend
                  ↓            ↓              ↓
               UI Update   Position 0    Background
               Instant     = Primary        Update
```

### Delete Flow
```
Click → Confirm → Delete → Reassign Primary → Update UI
   ↓       ↓        ↓            ↓             ↓
 Icon   Dialog   Backend    If needed      Success
                                           Message
```

---

## 🔧 Key Methods

### `_compressImage(String imagePath)`
Compresses image to max 1MB with adaptive quality.
```dart
Input: Image path (up to 10MB)
Output: Compressed image path (≤ 1MB)
```

### `_addPhoto()`
Handles photo upload with compression.
```dart
1. Pick image
2. Validate
3. Compress
4. Upload
5. Set primary if first
6. Update UI
```

### `_onReorder(int oldIndex, int newIndex)`
Handles drag & drop reordering.
```dart
1. Reorder array
2. Update orders
3. Set position 0 as primary
4. Sync backend
```

### `_setPrimaryPhoto(Photo photo)`
Sets photo as primary.
```dart
1. Move to position 0
2. Update isPrimary flags
3. Sync backend
4. Update UI
```

### `_deletePhoto(Photo photo)`
Deletes photo with confirmation.
```dart
1. Show dialog
2. Delete from backend
3. Remove from array
4. Reassign primary if needed
5. Update UI
```

---

## 🚨 Error Messages

| Scenario | Message (French) |
|----------|------------------|
| File too large | "La photo est trop volumineuse (max 10MB)..." |
| Invalid format | "Format d'image non supporté..." |
| Compression failed | "Erreur lors de la compression de l'image" |
| Upload failed | "Erreur d'upload: [details]" |
| Delete failed | "Erreur lors de la suppression: [details]" |

---

## 📱 Backend API

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/profiles/me/photos` | POST | Upload photo |
| `/photos/:id/order` | PUT | Update order |
| `/photos/:id/primary` | PUT | Set primary |
| `/photos/:id` | DELETE | Delete photo |

---

## ✅ Acceptance Criteria

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Upload 1-6 photos | ✅ |
| 2 | Auto-compress to 1MB | ✅ |
| 3 | Drag & drop sync | ✅ |
| 4 | First = primary | ✅ |
| 5 | Loading states | ✅ |
| 6 | Clear error messages | ✅ |

---

## 📖 Documentation

1. **Implementation Details** → `PHOTO_MANAGEMENT_IMPLEMENTATION.md`
2. **Flow Diagrams** → `PHOTO_MANAGEMENT_FLOW_DIAGRAM.md`
3. **Executive Summary** → `PHOTO_MANAGEMENT_COMPLETE.md`
4. **Tests** → `test/photo_management_compression_test.dart`

---

## 🎯 Common Questions

**Q: What happens if compression fails?**
A: Error message shown, upload cancelled, state cleaned up.

**Q: Can users upload uncompressed images?**
A: Yes, if already < 1MB, no compression happens.

**Q: What if network fails during upload?**
A: Error message shown, loading state cleared, user can retry.

**Q: How is primary photo determined?**
A: Always position 0 (first photo in grid).

**Q: What happens when deleting the primary photo?**
A: Next photo (new position 0) becomes primary automatically.

**Q: Are backend calls blocking?**
A: No, they happen in background with error logging.

---

## 🔗 Related Files

- Widget: `lib/features/profile/widgets/photo_management_widget.dart`
- Page: `lib/features/profile/pages/photo_management_page.dart`
- Provider: `lib/features/profile/providers/profile_provider.dart`
- API: `lib/core/services/api_service.dart`
- Model: `lib/core/models/profile.dart`
- Tests: `test/photo_management_compression_test.dart`

---

## ✨ Key Features

1. **Automatic Compression** - Transparent to user
2. **Smart Primary Logic** - Always position 0
3. **Instant Feedback** - UI updates immediately
4. **Background Sync** - Non-blocking operations
5. **Error Resilience** - Comprehensive handling
6. **Clear Messages** - French translations

---

**For more details, see the full documentation files listed above.**
