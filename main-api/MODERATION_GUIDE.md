# Content Moderation System

## Overview

The GoldWen backend implements an automated content moderation system for both text and images using AI services and configurable forbidden words:

- **Text Moderation**: OpenAI's Moderation API for AI-based content analysis
- **Forbidden Words**: Configurable list of forbidden words/phrases
- **Image Moderation**: AWS Rekognition

## Configuration

### Environment Variables

Add the following to your `.env` file:

```bash
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key
OPENAI_MODERATION_MODEL=text-moderation-latest

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key

# Moderation Settings
MODERATION_AUTO_BLOCK=true
MODERATION_TEXT_THRESHOLD=0.7
MODERATION_IMAGE_THRESHOLD=80

# Forbidden Words Configuration
FORBIDDEN_WORDS_ENABLED=true
FORBIDDEN_WORDS=badword1,badword2,inappropriate phrase,offensive term
```

### Configuration Options

- `MODERATION_AUTO_BLOCK`: Enable/disable automatic blocking (default: `false`)
- `MODERATION_TEXT_THRESHOLD`: Confidence threshold for text blocking (0-1, default: `0.7`)
- `MODERATION_IMAGE_THRESHOLD`: Confidence threshold for image blocking (0-100, default: `80`)
- `FORBIDDEN_WORDS_ENABLED`: Enable/disable forbidden words checking (default: `false`)
- `FORBIDDEN_WORDS`: Comma-separated list of forbidden words/phrases (case-insensitive)

## API Endpoints

### Webhook for Photo Moderation

Automatically moderate photos after upload:

```bash
POST /api/v1/moderation/webhook/photo
Content-Type: application/json

{
  "photoId": "uuid-of-photo",
  "userId": "uuid-of-user",
  "action": "uploaded"
}
```

### Get Photo Moderation Status

Check the moderation status of a photo:

```bash
GET /api/v1/moderation/photo/:photoId/status
Authorization: Bearer <jwt-token>
```

Response:
```json
{
  "success": true,
  "data": {
    "photoId": "uuid",
    "isApproved": true,
    "rejectionReason": null
  }
}
```

### Admin: Manual Photo Moderation

Admins can manually trigger photo moderation:

```bash
POST /api/v1/moderation/admin/photo/:photoId
Authorization: Bearer <admin-jwt-token>
```

### Admin: Text Content Moderation

Moderate text content:

```bash
POST /api/v1/moderation/admin/text
Authorization: Bearer <admin-jwt-token>
Content-Type: application/json

{
  "text": "Content to moderate"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "approved": true,
    "reason": null
  }
}
```

### Admin: Batch Text Moderation

Moderate multiple text strings at once:

```bash
POST /api/v1/moderation/admin/text/batch
Authorization: Bearer <admin-jwt-token>
Content-Type: application/json

{
  "texts": [
    "First text to moderate",
    "Second text to moderate",
    "Third text to moderate"
  ]
}
```

## Integration Examples

### Moderated Text Fields

The following text fields throughout the application are automatically moderated for inappropriate content and forbidden words:

**Profile Fields:**
- Bio
- Pseudo (username)
- Job Title
- Company
- Education
- Favorite Song

**Questionnaire/Personality Answers:**
- Text answers (`textAnswer`)
- Multiple choice answers (`multipleChoiceAnswer`)

**Prompt Answers:**
- All prompt response texts

**Messages:**
- Chat messages (can be integrated using `moderateTextContent`)

### Photo Upload Flow

When a user uploads a photo, the system automatically moderates it:

```typescript
// In ProfilesService or similar
async uploadPhoto(userId: string, file: Express.Multer.File) {
  // Save photo to database
  const photo = await this.photoRepository.save({
    profileId: userId,
    url: uploadedUrl,
    filename: file.filename,
    isApproved: false, // Start as unapproved
  });

  // Trigger moderation webhook (can be done async)
  await this.moderationService.moderatePhoto(photo.id);

  return photo;
}
```

### Message Moderation

Moderate messages before sending:

```typescript
// In ChatService or similar
async sendMessage(userId: string, chatId: string, text: string) {
  // Moderate the message text
  const moderationResult = await this.moderationService.moderateTextContent(
    text,
    userId
  );

  if (!moderationResult.approved) {
    throw new BadRequestException(
      `Message rejected: ${moderationResult.reason}`
    );
  }

  // Save and send the message
  const message = await this.messageRepository.save({
    chatId,
    senderId: userId,
    content: text,
  });

  return message;
}
```

### Profile Description Moderation

Moderate profile descriptions on update:

```typescript
// In ProfilesService
async updateProfile(userId: string, updateData: UpdateProfileDto) {
  if (updateData.bio) {
    const moderationResult = await this.moderationService.moderateTextContent(
      updateData.bio,
      userId
    );

    if (!moderationResult.approved) {
      throw new BadRequestException(
        `Bio rejected: ${moderationResult.reason}`
      );
    }
  }

  // Update profile
  return await this.profileRepository.save({
    userId,
    ...updateData,
  });
}
```

## Moderation Categories

### Forbidden Words

The system checks for a configurable list of forbidden words/phrases:
- Words are matched case-insensitively with whole-word boundaries
- Supports both single words and multi-word phrases
- Configured via the `FORBIDDEN_WORDS` environment variable
- When enabled, this check runs **before** AI moderation for faster rejection
- Returns clear error messages indicating which forbidden words were found

### Text Content (AI-based)

The system checks for the following categories using OpenAI:
- Sexual content
- Hate speech
- Harassment
- Self-harm content
- Sexual content involving minors
- Threatening hate speech
- Graphic violence
- Violence

### Image Content

AWS Rekognition detects various types of inappropriate content including:
- Explicit nudity
- Suggestive content
- Violence
- Drugs
- Alcohol
- Gambling
- Hate symbols
- And more...

## Notifications

When content is blocked:

1. **Photo Rejection**: User receives a notification with the rejection reason
2. **Text Blocking**: User receives a notification explaining why their content was flagged

Notifications are sent using the existing `NotificationsService`.

## Logging

All moderation events are logged:

- `text_moderation_completed`: When text moderation completes
- `image_moderation_completed`: When image moderation completes
- `photo_moderation_completed`: When photo moderation completes
- `text_content_blocked`: When text content is blocked (includes AI or forbidden words)
- `forbidden_words_detected`: When forbidden words are found in text
- `photo_blocked_notification_sent`: When user is notified about photo rejection
- `user_content_blocked`: Security event when user content is blocked

## Error Handling

The moderation system uses a **fail-safe approach**:

- If OpenAI API fails → Content is **approved** (safe default)
- If AWS Rekognition fails → Content is **approved** (safe default)
- Errors are logged but don't block the user experience
- **Forbidden words checking always runs** (even if AI moderation fails)

This prevents false positives from disrupting the user experience while maintaining security.

### Error Responses

When content is rejected due to forbidden words or inappropriate content, the API returns a `400 Bad Request` with a clear error message:

```json
{
  "statusCode": 400,
  "message": "Content contains forbidden words: badword, offensive",
  "error": "Bad Request"
}
```

For batch operations (like personality questionnaires with multiple answers):

```json
{
  "statusCode": 400,
  "message": "Some questionnaire answers contain inappropriate content: Answer 2: Content contains forbidden words: badword",
  "error": "Bad Request"
}
```

## Testing

Run the moderation tests:

```bash
npm run test -- moderation
```

## Future Enhancements

Potential improvements for V2:
- Strike system (3 violations = temporary suspension)
- Manual review queue for borderline cases
- Custom moderation rules per category
- Multi-language support
- Image hash-based duplicate detection
- Integration with external moderation services
