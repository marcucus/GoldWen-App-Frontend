# Complete Profile Photo Management API

This document describes the complete photo profile management system implemented for the GoldWen App Backend.

## Overview

The photo management system provides comprehensive functionality for:
- Photo upload with automatic compression and resizing
- Validation of minimum (3) and maximum (6) photos per profile
- Drag & drop photo reordering
- Primary photo management
- Profile completion tracking based on photo requirements

## API Endpoints

### 1. Upload Photos

**POST** `/api/v1/profiles/me/photos`

Upload profile photos with automatic processing and validation.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Body:**
```
photos: File[] (max 6 files, max 10MB each)
```

**Supported formats:** JPEG, PNG, WebP

**Processing features:**
- Automatic compression (85% quality)
- Resizing (max 1200x1600 pixels, maintains aspect ratio)
- Format conversion to JPEG for consistency
- File size optimization

**Response:**
```json
[
  {
    "id": "uuid",
    "url": "/uploads/photos/filename.jpg",
    "filename": "photo-timestamp-random.jpg",
    "order": 1,
    "isPrimary": true,
    "width": 1200,
    "height": 800,
    "fileSize": 245760,
    "mimeType": "image/jpeg",
    "isApproved": true,
    "createdAt": "2025-01-XX",
    "updatedAt": "2025-01-XX"
  }
]
```

**Error responses:**
- `400` - Maximum 6 photos allowed
- `400` - At least one photo is required
- `400` - Invalid file type or size
- `404` - Profile not found

---

### 1b. Upload Media (Alias)

**POST** `/api/v1/profiles/me/media`

This endpoint is an alias for the photos upload endpoint (`/api/v1/profiles/me/photos`). It provides the same functionality and accepts the same parameters. This ensures compatibility with clients that may use the `/media` endpoint instead of `/photos`.

**Note:** All features, validation rules, and response formats are identical to the photos upload endpoint.

---

### 2. Delete Photo

**DELETE** `/api/v1/profiles/me/photos/:photoId`

Remove a photo from the profile.

**Response:**
```json
{
  "message": "Photo deleted successfully"
}
```

### 3. Set Primary Photo

**PUT** `/api/v1/profiles/me/photos/:photoId/primary`

Set a specific photo as the primary profile photo.

**Response:**
```json
{
  "id": "uuid",
  "isPrimary": true,
  // ... other photo fields
}
```

### 4. Reorder Photos (NEW)

**PUT** `/api/v1/profiles/me/photos/:photoId/order`

Change the display order of photos for drag & drop functionality.

**Body:**
```json
{
  "newOrder": 3
}
```

**Validation:**
- `newOrder` must be between 1 and total number of photos
- Automatically adjusts other photos' order positions

**Response:**
```json
{
  "id": "uuid",
  "order": 3,
  // ... other photo fields
}
```

### 5. Profile Completion Status (ENHANCED)

**GET** `/api/v1/profiles/completion`

Get detailed profile completion information including photo requirements.

**Response:**
```json
{
  "isComplete": false,
  "completionPercentage": 75,
  "requirements": {
    "minimumPhotos": {
      "required": 3,
      "current": 2,
      "satisfied": false
    },
    "promptAnswers": {
      "required": 3,
      "current": 3,
      "satisfied": true
    },
    "personalityQuestionnaire": true,
    "basicInfo": true
  },
  "missingSteps": [
    "Upload at least 3 photos"
  ]
}
```

## Technical Implementation Details

### Image Processing
- **Library:** Sharp (high-performance image processing)
- **Compression:** 85% JPEG quality
- **Max dimensions:** 1200x1600 pixels
- **Format standardization:** All images converted to JPEG
- **Fallback:** Original file preserved if processing fails

### Photo Order Management
- Uses database transactions for atomic order updates
- Efficiently handles position shifting without conflicts
- Maintains order consistency across all profile photos

### Validation Rules
- **File types:** JPEG, PNG, WebP only
- **File size:** Maximum 10MB per file
- **Photo limit:** Maximum 6 photos per profile
- **Minimum requirement:** 3 photos for profile completion
- **Primary photo:** Automatically set for first photo if none exist

### Error Handling
- Comprehensive validation with descriptive error messages
- Graceful degradation for image processing failures
- Proper HTTP status codes for different error conditions

### Database Schema
The Photo entity includes all necessary fields:
```typescript
{
  id: string (UUID)
  profileId: string
  url: string
  filename: string
  order: number (indexed)
  isPrimary: boolean
  width: number
  height: number
  fileSize: number
  mimeType: string
  isApproved: boolean
  createdAt: Date
  updatedAt: Date
}
```

## Frontend Integration Notes

### File Upload
```javascript
const formData = new FormData();
files.forEach(file => formData.append('photos', file));

fetch('/api/v1/profiles/me/photos', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` },
  body: formData
});
```

### Drag & Drop Reordering
```javascript
const reorderPhoto = async (photoId, newOrder) => {
  const response = await fetch(`/api/v1/profiles/me/photos/${photoId}/order`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ newOrder })
  });
  return response.json();
};
```

### Profile Completion Check
```javascript
const checkCompletion = async () => {
  const response = await fetch('/api/v1/profiles/completion', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const completion = await response.json();
  
  if (!completion.requirements.minimumPhotos.satisfied) {
    showUploadPhotosPrompt();
  }
};
```

## Testing

The implementation includes comprehensive test coverage:
- Unit tests for all service methods
- Validation testing for all endpoints
- Error condition testing
- Image processing utility testing

Run tests with:
```bash
npm test -- --testNamePattern="photo"
```

## Security Considerations

- All endpoints require authentication
- File type validation prevents malicious uploads
- File size limits prevent abuse
- Image processing sanitizes uploaded content
- Proper error messages don't expose internal details

## Performance Optimizations

- Efficient database queries with proper indexing
- Optimized image processing with Sharp
- Minimal file I/O operations
- Atomic database transactions for consistency