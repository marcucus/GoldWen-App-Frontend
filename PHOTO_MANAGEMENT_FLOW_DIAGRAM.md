# Photo Management Feature - Technical Flow Diagram

## 📸 Photo Upload Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INITIATES UPLOAD                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ Select Source  │
                    │ (Camera/Gallery)│
                    └────────┬───────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  Pick Image    │
                    │ (ImagePicker)  │
                    └────────┬───────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ Validate Image │
                    │ • Size < 10MB  │
                    │ • Format OK    │
                    └────────┬───────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                 ❌ FAIL          ✅ PASS
                    │                 │
                    ▼                 ▼
            ┌───────────┐     ┌──────────────┐
            │Show Error │     │Set Loading   │
            │  Message  │     │   State      │
            └───────────┘     └──────┬───────┘
                                     │
                                     ▼
                            ┌─────────────────┐
                            │ Compress Image  │
                            │ Target: 1MB     │
                            │ Quality: 85→50% │
                            └────────┬────────┘
                                     │
                            ┌────────┴────────┐
                            │                 │
                         ❌ FAIL          ✅ SUCCESS
                            │                 │
                            ▼                 ▼
                    ┌───────────┐     ┌──────────────┐
                    │Show Error │     │ Upload to    │
                    └───────────┘     │   Backend    │
                                      │(Multipart)   │
                                      └──────┬───────┘
                                             │
                                    ┌────────┴────────┐
                                    │                 │
                                 ❌ FAIL          ✅ SUCCESS
                                    │                 │
                                    ▼                 ▼
                            ┌───────────┐     ┌──────────────┐
                            │Show Error │     │ Parse Response│
                            └───────────┘     └──────┬───────┘
                                                     │
                                                     ▼
                                            ┌─────────────────┐
                                            │ Is First Photo? │
                                            └────────┬────────┘
                                                     │
                                            ┌────────┴────────┐
                                            │                 │
                                          YES               NO
                                            │                 │
                                            ▼                 ▼
                                    ┌───────────┐     ┌──────────────┐
                                    │Set Primary│     │   Add Photo  │
                                    │on Backend │     │   to List    │
                                    └─────┬─────┘     └──────┬───────┘
                                          │                   │
                                          └────────┬──────────┘
                                                   │
                                                   ▼
                                          ┌─────────────────┐
                                          │ Update UI State │
                                          │ Show Success    │
                                          │ Clear Loading   │
                                          └─────────────────┘
```

## 🔄 Photo Reorder Flow (Drag & Drop)

```
┌─────────────────────────────────────────────────────────────────┐
│                      USER DRAGS PHOTO                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  Drop Photo    │
                    │ at New Position│
                    └────────┬───────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ Reorder Array  │
                    │ Update Orders  │
                    └────────┬───────┘
                             │
                             ▼
                    ┌────────────────┐
                    │Set Position 0  │
                    │  as Primary    │
                    └────────┬───────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ Update UI      │
                    │(Immediate)     │
                    └────────┬───────┘
                             │
                  ┌──────────┴──────────┐
                  │                     │
                  ▼                     ▼
        ┌─────────────────┐   ┌─────────────────┐
        │ Update Order on │   │Set Primary on   │
        │    Backend      │   │   Backend       │
        │(Background Sync)│   │ (if position 0) │
        └─────────────────┘   └─────────────────┘
```

## ⭐ Set Primary Photo Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  USER CLICKS "SET PRIMARY"                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │Set Loading     │
                    │   State        │
                    └────────┬───────┘
                             │
                             ▼
                    ┌────────────────┐
                    │Move Photo to   │
                    │  Position 0    │
                    └────────┬───────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ Update isPrimary│
                    │ for All Photos │
                    └────────┬───────┘
                             │
                             ▼
                    ┌────────────────┐
                    │Backend: Set    │
                    │   Primary      │
                    └────────┬───────┘
                             │
                  ┌──────────┴──────────┐
                  │                     │
               ✅ SUCCESS             ❌ FAIL
                  │                     │
                  ▼                     ▼
        ┌─────────────────┐   ┌─────────────────┐
        │Backend: Update  │   │  Show Error     │
        │All Photo Orders │   │    Message      │
        └────────┬────────┘   └─────────────────┘
                 │
                 ▼
        ┌─────────────────┐
        │ Update UI       │
        │ Show Success    │
        │ Clear Loading   │
        └─────────────────┘
```

## 🗑️ Delete Photo Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER CLICKS DELETE                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │Show Confirmation│
                    │    Dialog      │
                    └────────┬───────┘
                             │
                  ┌──────────┴──────────┐
                  │                     │
               CANCEL                CONFIRM
                  │                     │
                  ▼                     ▼
        ┌─────────────────┐   ┌─────────────────┐
        │ Close Dialog    │   │Set Loading      │
        │ No Action       │   │   State         │
        └─────────────────┘   └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │Delete on Backend│
                              └────────┬────────┘
                                       │
                            ┌──────────┴──────────┐
                            │                     │
                         ✅ SUCCESS             ❌ FAIL
                            │                     │
                            ▼                     ▼
                   ┌─────────────────┐   ┌─────────────────┐
                   │Remove from Array│   │  Show Error     │
                   │Reorder Remaining│   │    Message      │
                   └────────┬────────┘   └─────────────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │Set Position 0   │
                   │  as Primary     │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │Set Primary on   │
                   │   Backend       │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ Update UI       │
                   │ Show Success    │
                   │ Clear Loading   │
                   └─────────────────┘
```

## 🎯 Image Compression Details

```
┌─────────────────────────────────────────────────────────────────┐
│                     INPUT IMAGE (up to 10MB)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │Check File Size │
                    └────────┬───────┘
                             │
                  ┌──────────┴──────────┐
                  │                     │
            Size ≤ 1MB              Size > 1MB
                  │                     │
                  ▼                     ▼
        ┌─────────────────┐   ┌─────────────────┐
        │Return Original  │   │Start Compression│
        │    Path         │   │  Loop           │
        └─────────────────┘   └────────┬────────┘
                                       │
                              Quality = 85
                                       │
                                       ▼
                              ┌─────────────────┐
                              │   Compress      │
                              │ • Max 1200x1200 │
                              │ • JPEG format   │
                              │ • Quality: X%   │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │Check Compressed │
                              │      Size       │
                              └────────┬────────┘
                                       │
                            ┌──────────┴──────────┐
                            │                     │
                      Size ≤ 1MB            Size > 1MB
                            │                     │
                            ▼                     ▼
                   ┌─────────────────┐   ┌─────────────────┐
                   │Return Compressed│   │  Quality ≥ 50?  │
                   │      Path       │   └────────┬────────┘
                   └─────────────────┘            │
                                         ┌────────┴────────┐
                                         │                 │
                                       YES               NO
                                         │                 │
                                         ▼                 ▼
                              ┌─────────────────┐ ┌────────────────┐
                              │Reduce Quality   │ │Return Last     │
                              │  by 10%         │ │Compressed File │
                              └────────┬────────┘ └────────────────┘
                                       │
                                       └─────► Loop Back
```

## 📊 State Management

```
┌──────────────────────────────────────────────────────────────┐
│                    PhotoManagementWidget                      │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  State Variables:                                            │
│  ├─ _photos: List<Photo>           (current photos)         │
│  ├─ _isLoading: bool                (loading indicator)     │
│  └─ _picker: ImagePicker            (image picker instance) │
│                                                               │
│  Key Methods:                                                │
│  ├─ _addPhoto()                     (upload flow)           │
│  ├─ _compressImage()                (compression logic)     │
│  ├─ _validateImage()                (validation)            │
│  ├─ _deletePhoto()                  (delete flow)           │
│  ├─ _setPrimaryPhoto()              (set primary flow)      │
│  ├─ _onReorder()                    (drag & drop)           │
│  ├─ _updatePhotoOrder()             (backend order sync)    │
│  └─ _setPrimaryPhotoOnBackend()     (backend primary sync)  │
│                                                               │
│  Backend Sync:                                               │
│  ├─ ApiService.uploadPhoto()                                │
│  ├─ ApiService.deletePhoto()                                │
│  ├─ ApiService.setPrimaryPhoto()                            │
│  └─ ApiService.updatePhotoOrder()                           │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## 🔐 Error Handling Strategy

```
┌──────────────────────────────────────────────────────────────┐
│                      ERROR HANDLING                           │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Level 1: Validation (Before Operation)                      │
│  ├─ File size check                                          │
│  ├─ Format verification                                      │
│  └─ Photo count limits                                       │
│                                                               │
│  Level 2: Operation (During Process)                         │
│  ├─ Compression failures                                     │
│  ├─ Network errors                                           │
│  ├─ Backend errors                                           │
│  └─ Parse errors                                             │
│                                                               │
│  Level 3: State Management                                   │
│  ├─ Mounted checks before setState                           │
│  ├─ Loading state cleanup                                    │
│  └─ Rollback on failure                                      │
│                                                               │
│  User Feedback:                                              │
│  ├─ SnackBar for errors (red)                               │
│  ├─ SnackBar for success (green)                            │
│  └─ Progress indicator during operations                     │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## ✅ Testing Coverage Map

```
┌──────────────────────────────────────────────────────────────┐
│                    TEST COVERAGE                              │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  UI Tests (12 test cases):                                   │
│  ✅ Photo grid display (6 slots)                            │
│  ✅ Photo count with minimum requirement                    │
│  ✅ Add photo button visibility                             │
│  ✅ Primary photo indicator                                 │
│  ✅ Loading indicator                                        │
│  ✅ Photo order numbers                                      │
│  ✅ Delete button presence                                   │
│  ✅ Set primary button (non-primary photos)                 │
│  ✅ Empty slots with add icon                               │
│  ✅ First slot primary photo label                          │
│  ✅ Drag indicator hint                                      │
│  ✅ Grid layout structure                                    │
│                                                               │
│  Integration Points (Backend):                               │
│  ✅ Upload API call                                          │
│  ✅ Delete API call                                          │
│  ✅ Set primary API call                                     │
│  ✅ Update order API call                                    │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```
