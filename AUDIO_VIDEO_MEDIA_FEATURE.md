# Audio/Video Profile Media Feature

## Overview
This feature adds support for uploading and playing audio and video files in user profiles. Users can add up to 2 audio files and 1 video file to enrich their profiles.

## Components

### 1. MediaFile Model (`lib/core/models/profile.dart`)
A data model representing audio or video files in a user's profile.

**Properties:**
- `id`: Unique identifier
- `url`: URL to the media file
- `type`: Either 'audio' or 'video'
- `order`: Display order in the profile
- `duration`: Duration in seconds (optional)
- `thumbnailUrl`: Thumbnail image URL for videos (optional)
- `createdAt`: Creation timestamp

### 2. MediaManagementWidget (`lib/features/profile/widgets/media_management_widget.dart`)
A widget for uploading and managing media files in the profile setup flow.

**Features:**
- File picker with format validation
- Size validation (50MB limit)
- Separate counters for audio and video files
- Error handling and user feedback
- Delete confirmation dialog

**Supported Formats:**
- **Audio**: mp3, wav, m4a, aac, ogg
- **Video**: mp4, mov, avi, mkv, webm

### 3. MediaPlayerWidget (`lib/features/profile/widgets/media_player_widget.dart`)
A widget for playing audio and video files with playback controls.

**Features:**
- Video player with standard controls
- Audio player with custom UI
- Progress bar with seek functionality
- Play/pause toggle
- Duration display
- Auto-play support
- Error handling

### 4. API Service Methods (`lib/core/services/api_service.dart`)
New API methods for media file operations:

- `uploadMediaFile(String filePath, {required String type, int? order})`: Upload audio or video file
- `deleteMediaFile(String mediaId)`: Delete a media file
- `updateMediaFileOrder(String mediaId, int newOrder)`: Update display order

## Integration

### Profile Setup Flow
The media upload page is integrated into the profile setup flow between photos and prompts:
1. Basic Info
2. Photos
3. **Media (Audio/Video)** ← New page
4. Prompts
5. Validation
6. Review

### Profile Display
Media files are displayed in:
- Profile detail page (`lib/features/matching/pages/profile_detail_page.dart`)
- User profile page

## Usage

### Adding Media to Profile
```dart
Consumer<ProfileProvider>(
  builder: (context, profileProvider, child) {
    return MediaManagementWidget(
      mediaFiles: profileProvider.mediaFiles,
      onMediaFilesChanged: (mediaFiles) {
        profileProvider.updateMediaFiles(mediaFiles);
      },
      maxAudioFiles: 2,
      maxVideoFiles: 1,
      showAddButton: true,
    );
  },
)
```

### Displaying Media in Profile
```dart
if (profile.mediaFiles.isNotEmpty) {
  ...profile.mediaFiles.map((mediaFile) {
    return MediaPlayerWidget(
      mediaFile: mediaFile,
      autoPlay: false,
      showControls: true,
    );
  }).toList(),
}
```

## Validation Rules

### File Size
- Maximum file size: 50MB
- Users receive an error message if file exceeds limit

### File Format
- Only specified formats are accepted
- File extension validation on client side
- MIME type validation on upload

### Quantity Limits
- Maximum 2 audio files per profile
- Maximum 1 video file per profile
- Add button is disabled when limits are reached

## Dependencies

### New Packages Added
```yaml
file_picker: ^8.1.6      # File selection
video_player: ^2.9.2     # Video playback
audioplayers: ^6.1.0     # Audio playback
```

### Existing Dependencies Used
- `image_picker`: For potential video recording
- `http`: For file uploads
- `provider`: State management

## Testing

### Unit Tests
Tests are located in `test/media_file_test.dart`:
- MediaFile model creation
- JSON serialization/deserialization
- Profile integration with media files
- Handling optional fields
- Empty and missing media arrays

Run tests:
```bash
flutter test test/media_file_test.dart
```

## Backend Requirements

The backend API must support:

### Endpoints
- `POST /api/v1/profiles/me/media` - Upload media file
  - Accepts multipart/form-data
  - Fields: `mediaFile` (file), `type` (audio|video), `order` (int)
  - Returns: MediaFile object

- `DELETE /api/v1/profiles/me/media/:mediaId` - Delete media file
  - Returns: Success status

- `PUT /api/v1/profiles/me/media/:mediaId/order` - Update order
  - Body: `{ "newOrder": number }`
  - Returns: Updated MediaFile object

### Profile Model Extension
The backend Profile model should include:
```json
{
  "mediaFiles": [
    {
      "id": "string",
      "url": "string",
      "type": "audio|video",
      "order": "number",
      "duration": "number?",
      "thumbnailUrl": "string?",
      "createdAt": "ISO8601 date"
    }
  ]
}
```

## Future Enhancements

1. **Video Thumbnail Generation**: Automatically generate thumbnails for uploaded videos
2. **Audio Waveform Visualization**: Display waveform for audio files
3. **Recording Support**: Allow users to record audio/video directly in-app
4. **Compression**: Compress media files before upload
5. **Progress Indicators**: Show upload progress for large files
6. **Preview Before Upload**: Preview media before confirming upload
7. **Captions/Subtitles**: Support for video captions

## Accessibility

- Semantic labels for all controls
- Keyboard navigation support
- Screen reader support for media controls
- Color contrast compliance
- Touch target size compliance (48x48dp minimum)

## Performance Considerations

- Lazy loading of media players
- Dispose controllers when widgets are destroyed
- Stream media instead of downloading entirely
- Caching strategies for frequently accessed media
- Network-aware loading (WiFi vs cellular)

## Security

- File type validation on both client and server
- Size limits to prevent abuse
- Secure file storage on backend
- Content scanning for inappropriate media (backend)
- HTTPS for all media URLs
