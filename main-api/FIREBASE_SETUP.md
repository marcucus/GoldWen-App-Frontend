# Firebase Cloud Messaging (FCM) Integration Guide

This guide explains how to set up Firebase Cloud Messaging for push notifications in the GoldWen backend.

## Overview

The GoldWen backend uses **Firebase Admin SDK** for sending push notifications to iOS and Android devices. The implementation includes:

- ✅ Firebase Admin SDK integration with fallback to legacy HTTP API
- ✅ Automatic token invalidation for unregistered/invalid devices
- ✅ Push token CRUD operations
- ✅ User notification preferences
- ✅ Five notification types with deep linking support
- ✅ Comprehensive logging and error handling
- ✅ Full test coverage

## Firebase Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "goldwen-app")
4. Follow the setup wizard

### 2. Add Apps to Firebase Project

#### For iOS:
1. In Firebase Console, go to Project Settings
2. Click "Add app" → Choose iOS
3. Enter iOS bundle ID (e.g., `com.goldwen.app`)
4. Download `GoogleService-Info.plist`
5. Add to your iOS project

#### For Android:
1. In Firebase Console, go to Project Settings
2. Click "Add app" → Choose Android
3. Enter Android package name (e.g., `com.goldwen.app`)
4. Download `google-services.json`
5. Add to your Android project

### 3. Generate Service Account Key

1. In Firebase Console, go to Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save the JSON file securely (e.g., `firebase-service-account.json`)
4. **NEVER commit this file to version control**

## Backend Configuration

### Option 1: Using Service Account File (Recommended for Development)

1. Save the service account JSON file in a secure location
2. Set the environment variable:

```bash
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/firebase-service-account.json
```

### Option 2: Using Environment Variables (Recommended for Production)

Extract values from the service account JSON and set individual environment variables:

```bash
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour-Private-Key-Here\n-----END PRIVATE KEY-----\n"
```

**Important:** The private key must preserve newline characters. In some environments, you may need to replace actual newlines with `\n`.

### Legacy HTTP API (Fallback)

If Firebase Admin SDK is not configured, the service will fall back to the legacy FCM HTTP API:

```bash
FCM_SERVER_KEY=your-legacy-server-key
```

To get the server key:
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Copy the "Server key"

**Note:** Google recommends migrating to Firebase Admin SDK as the HTTP API may be deprecated.

## Environment Variables Summary

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `FIREBASE_SERVICE_ACCOUNT_PATH` | No* | Path to service account JSON | `/secrets/firebase.json` |
| `FIREBASE_PROJECT_ID` | No* | Firebase project ID | `goldwen-app-12345` |
| `FIREBASE_CLIENT_EMAIL` | No* | Service account email | `firebase-adminsdk-xxxxx@...` |
| `FIREBASE_PRIVATE_KEY` | No* | Service account private key | `-----BEGIN PRIVATE KEY-----...` |
| `FCM_SERVER_KEY` | No | Legacy FCM server key (fallback) | `AAAA...` |

\* Either `FIREBASE_SERVICE_ACCOUNT_PATH` OR all three individual credentials (`PROJECT_ID`, `CLIENT_EMAIL`, `PRIVATE_KEY`) are required for Firebase Admin SDK to work.

## API Endpoints

### Register Push Token

Register a device token for push notifications:

```http
POST /api/v1/notifications/push-tokens
Authorization: Bearer <token>
Content-Type: application/json

{
  "token": "fcm-device-token-here",
  "platform": "ios",  // or "android"
  "appVersion": "1.0.0",  // optional
  "deviceId": "iPhone13,2"  // optional
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "token-id-123",
    "platform": "ios",
    "isActive": true
  },
  "message": "Push token registered successfully"
}
```

### Delete Push Token

Remove a device token:

```http
DELETE /api/v1/notifications/push-tokens
Authorization: Bearer <token>
Content-Type: application/json

{
  "token": "fcm-device-token-here"
}
```

### Get User Push Tokens

Retrieve all active tokens for the authenticated user:

```http
GET /api/v1/notifications/push-tokens
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "token-id-123",
      "platform": "ios",
      "appVersion": "1.0.0",
      "deviceId": "iPhone13,2",
      "isActive": true,
      "lastUsedAt": "2024-01-15T12:00:00Z",
      "createdAt": "2024-01-01T10:00:00Z"
    }
  ]
}
```

### Update Notification Settings

Control which notifications the user receives:

```http
PUT /api/v1/notifications/settings
Authorization: Bearer <token>
Content-Type: application/json

{
  "dailySelection": true,
  "newMatches": true,
  "newMessages": true,
  "chatExpiring": true,
  "subscriptionUpdates": false,
  "pushNotifications": true,
  "emailNotifications": true,
  "marketingEmails": false
}
```

## Notification Types

The system supports five notification types with deep linking:

### 1. Daily Selection
Sent at noon to notify users of their daily profile selection.

**Data:**
```json
{
  "type": "daily_selection",
  "action": "open_daily_selection"
}
```

### 2. New Match
Sent when two users mutually select each other.

**Data:**
```json
{
  "type": "new_match",
  "conversationId": "conv-123",
  "matchedUserId": "user-456",
  "action": "open_chat"
}
```

### 3. New Message
Sent when a user receives a message in an active chat.

**Data:**
```json
{
  "type": "new_message",
  "conversationId": "conv-123",
  "senderId": "user-789",
  "action": "open_chat"
}
```

### 4. Chat Expiring
Sent when a chat is about to expire (24-hour window).

**Data:**
```json
{
  "type": "chat_expiring",
  "conversationId": "conv-123",
  "expiresAt": "2024-01-15T12:00:00Z",
  "action": "open_chat"
}
```

### 5. Chat Accepted
Sent when a chat request is accepted.

**Data:**
```json
{
  "type": "chat_accepted",
  "conversationId": "conv-123",
  "accepterId": "user-456",
  "action": "open_chat"
}
```

## Deep Linking

The mobile apps should handle the `action` field in notification data to navigate to the appropriate screen:

- `open_daily_selection`: Navigate to daily selection screen
- `open_chat`: Navigate to chat screen with the conversation ID

## Automatic Token Invalidation

The system automatically deactivates invalid tokens when:

1. Firebase returns error codes:
   - `messaging/invalid-registration-token`
   - `messaging/registration-token-not-registered`
   - `messaging/invalid-argument`

2. Legacy API returns errors:
   - `InvalidRegistration`
   - `NotRegistered`

Invalid tokens are marked as `isActive: false` and will not receive future notifications.

## Token Cleanup

Tokens that haven't been used in 90 days can be deactivated with:

```typescript
await notificationsService.deactivateInactivePushTokens();
```

This can be run as a scheduled job (e.g., weekly).

## Testing

### Unit Tests

Run the notification service tests:

```bash
npm test -- --testPathPatterns="firebase.service.spec|fcm.service.spec|notifications.service.spec"
```

### Manual Testing

1. **Test Notification Endpoint** (Development only):

```http
POST /api/v1/notifications/test
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Test Notification",
  "body": "This is a test",
  "type": "daily_selection"
}
```

2. **Trigger Daily Selection** (Development only):

```http
POST /api/v1/notifications/trigger-daily-selection
Authorization: Bearer <token>
```

## Monitoring & Logging

All FCM operations are logged with:

- Success/failure status
- Message IDs
- Error codes and messages
- Token information (first 10 characters only for security)
- User actions (register, delete, update)

Check logs for patterns like:
- `Firebase push notification sent successfully`
- `Failed to send Firebase push notification`
- `Deactivating invalid token`

## Error Handling

The service handles various error scenarios:

1. **Firebase Not Configured**: Falls back to legacy HTTP API or returns error
2. **Invalid Token**: Automatically deactivates the token
3. **Network Errors**: Logged with retry information
4. **Permission Errors**: Respects user notification preferences

## Security Considerations

1. **Never commit** service account files to version control
2. **Use environment variables** for sensitive credentials in production
3. **Rotate service account keys** periodically
4. **Limit service account permissions** to only what's needed (Cloud Messaging)
5. **Validate tokens** on registration to prevent spam
6. **Rate limit** token registration endpoints

## Production Deployment

### Using Docker

Add to your `docker-compose.yml`:

```yaml
services:
  main-api:
    environment:
      - FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}
      - FIREBASE_CLIENT_EMAIL=${FIREBASE_CLIENT_EMAIL}
      - FIREBASE_PRIVATE_KEY=${FIREBASE_PRIVATE_KEY}
```

### Using Kubernetes

Create a secret:

```bash
kubectl create secret generic firebase-credentials \
  --from-file=service-account.json=./firebase-service-account.json
```

Mount in deployment:

```yaml
volumeMounts:
  - name: firebase-credentials
    mountPath: /app/secrets
    readOnly: true
volumes:
  - name: firebase-credentials
    secret:
      secretName: firebase-credentials
```

Set environment variable:

```yaml
env:
  - name: FIREBASE_SERVICE_ACCOUNT_PATH
    value: /app/secrets/service-account.json
```

## Troubleshooting

### Issue: "Firebase not initialized"

**Cause:** Missing or incorrect Firebase configuration

**Solution:** Verify environment variables are set correctly. Check logs for initialization errors.

### Issue: Notifications not received on iOS

**Possible causes:**
1. APNs certificates not configured in Firebase
2. Device token format incorrect
3. App not requesting notification permissions

**Solution:** Verify Firebase iOS setup and check device token format.

### Issue: "Invalid registration token"

**Cause:** Token is invalid, expired, or from wrong project

**Solution:** 
1. Ensure the token is from the correct Firebase project
2. Re-register the token from the mobile app
3. Check if token was uninstalled/reinstalled

### Issue: High token invalidation rate

**Cause:** Users uninstalling app or clearing data

**Solution:** This is normal behavior. The system automatically cleans up invalid tokens.

## Migration from Legacy HTTP API

If you're currently using the legacy FCM HTTP API:

1. Set up Firebase Admin SDK configuration as described above
2. Deploy the new code
3. The service will automatically use Firebase Admin SDK
4. Monitor logs to confirm successful migration
5. After confirming, you can remove `FCM_SERVER_KEY` environment variable

The fallback ensures zero downtime during migration.

## Support & References

- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
- [FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
- [Firebase Console](https://console.firebase.google.com/)
- [APNs Configuration](https://firebase.google.com/docs/cloud-messaging/ios/certs)
