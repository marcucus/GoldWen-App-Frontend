# Firebase Cloud Messaging (FCM) Setup Guide

This guide explains how to set up Firebase Cloud Messaging for the GoldWen app to enable push notifications on iOS, Android, and Web platforms.

## Prerequisites

- A Firebase project (create one at https://console.firebase.google.com)
- Access to your Firebase project console
- Platform-specific development tools:
  - Android: Android Studio
  - iOS: Xcode with a valid Apple Developer account
  - Web: Any web server or Firebase Hosting

## 1. Firebase Project Setup

### Create or Select a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project" or select an existing project
3. Follow the setup wizard
4. Enable Google Analytics (optional but recommended)

### Enable Cloud Messaging

1. In your Firebase project console
2. Navigate to **Project Settings** (gear icon)
3. Select the **Cloud Messaging** tab
4. Enable Cloud Messaging API (if not already enabled)

## 2. Android Configuration

### Step 1: Register Your Android App

1. In Firebase Console, click "Add app" → Android (Android icon)
2. Enter your Android package name (found in `android/app/build.gradle`)
   - Example: `com.goldwen.app`
3. (Optional) Enter app nickname and SHA-1 certificate
4. Click "Register app"

### Step 2: Download Configuration File

1. Download the `google-services.json` file
2. Place it in: `android/app/google-services.json`
3. **Important**: Add `google-services.json` to `.gitignore` if not already there

### Step 3: Verify Android Dependencies

The following should already be in `android/build.gradle`:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

And in `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

### Step 4: Test Android Permissions

The AndroidManifest.xml already includes required permissions:
- `INTERNET`
- `RECEIVE_BOOT_COMPLETED`
- `VIBRATE`
- `WAKE_LOCK`
- `POST_NOTIFICATIONS`

## 3. iOS Configuration

### Step 1: Register Your iOS App

1. In Firebase Console, click "Add app" → iOS (Apple icon)
2. Enter your iOS bundle ID (found in Xcode or `ios/Runner.xcodeproj`)
   - Example: `com.goldwen.app`
3. (Optional) Enter App Store ID and app nickname
4. Click "Register app"

### Step 2: Download Configuration File

1. Download the `GoogleService-Info.plist` file
2. Open your iOS project in Xcode: `open ios/Runner.xcworkspace`
3. Drag and drop `GoogleService-Info.plist` into the `Runner` folder in Xcode
4. Ensure "Copy items if needed" is checked
5. Select `Runner` target
6. **Important**: Add `GoogleService-Info.plist` to `.gitignore`

### Step 3: Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the `Runner` target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** (if not already added)
   - Check "Remote notifications"

### Step 4: Upload APNs Authentication Key

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles** → **Keys**
3. Create a new key with **Apple Push Notifications service (APNs)** enabled
4. Download the `.p8` key file
5. In Firebase Console → **Project Settings** → **Cloud Messaging**
6. Under **Apple app configuration**, upload:
   - APNs Authentication Key (.p8 file)
   - Key ID
   - Team ID

### Step 5: Verify iOS Configuration

The Info.plist already includes required background modes:
- `fetch`
- `remote-notification`

## 4. Web Configuration

### Step 1: Register Your Web App

1. In Firebase Console, click "Add app" → Web (</> icon)
2. Enter app nickname (e.g., "GoldWen Web")
3. (Optional) Set up Firebase Hosting
4. Click "Register app"

### Step 2: Get Web App Configuration

Copy the Firebase configuration object. It looks like this:

```javascript
{
  apiKey: "AIza...",
  authDomain: "your-app.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-app.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123",
  measurementId: "G-XXXXXXXXXX"
}
```

### Step 3: Update Web Configuration

1. Open `web/firebase-messaging-sw.js`
2. Replace the placeholder values with your Firebase config:

```javascript
firebase.initializeApp({
  apiKey: "YOUR_ACTUAL_API_KEY",
  authDomain: "YOUR_ACTUAL_AUTH_DOMAIN",
  projectId: "YOUR_ACTUAL_PROJECT_ID",
  storageBucket: "YOUR_ACTUAL_STORAGE_BUCKET",
  messagingSenderId: "YOUR_ACTUAL_SENDER_ID",
  appId: "YOUR_ACTUAL_APP_ID",
  measurementId: "YOUR_ACTUAL_MEASUREMENT_ID"
});
```

3. Update `lib/core/config/firebase_config.dart` with the same values

### Step 4: Generate Web Push Certificate (VAPID Key)

1. In Firebase Console → **Project Settings** → **Cloud Messaging**
2. Scroll to **Web configuration**
3. Under **Web Push certificates**, click **Generate key pair**
4. Copy the generated key pair (starts with "B...")
5. Add this to your app's Firebase configuration

## 5. Testing Push Notifications

### Test on Android

1. Build and run the app on an Android device (not emulator for push notifications)
2. Allow notification permissions when prompted
3. Check logs for device token registration
4. Use Firebase Console → **Cloud Messaging** → **Send your first message** to test

### Test on iOS

1. Build and run on a physical iOS device (simulator doesn't support push)
2. Allow notification permissions
3. Ensure you're using a valid provisioning profile
4. Test with Firebase Console or your backend

### Test on Web

1. Deploy to a web server or use `flutter run -d chrome --web-port=5000`
2. Accept notification permissions in browser
3. Ensure service worker is registered
4. Test with Firebase Console

## 6. Verify Implementation

### Check Device Token Registration

The app automatically registers device tokens with the backend when:
- User logs in
- App starts with valid authentication
- Token is refreshed

Logs will show:
```
FCM Device Token: [token_preview]...
Device token registered with backend successfully
```

### Check Notification Types

The app supports these notification types:
- `daily_selection` - Daily profile selection at 12:00 PM
- `new_match` - When users mutually select each other
- `new_message` - New chat messages
- `chat_expiring` - Chat expiration warnings
- `system` - System updates and announcements

### Verify Deep Linking

Each notification type navigates to the appropriate screen:
- Daily selection → Discover tab
- New match → Matches page
- New message → Chat conversation
- Chat expiring → Chat conversation
- System → Notifications page

## 7. Backend Integration

### API Endpoints Used

The app calls these backend endpoints:

```
POST /users/me/push-tokens
{
  "token": "device_token",
  "platform": "ios|android|web",
  "appVersion": "1.0.0",
  "deviceId": "unique_device_id"
}

DELETE /users/me/push-tokens
{
  "token": "device_token"
}

PUT /notifications/settings
{
  "dailySelection": true,
  "newMatch": true,
  "newMessage": true,
  "chatExpiring": true,
  "subscription": true
}
```

### Backend Notification Format

When sending notifications from backend, use this format:

```json
{
  "to": "device_token",
  "notification": {
    "title": "Notification Title",
    "body": "Notification Body"
  },
  "data": {
    "type": "new_match|new_message|daily_selection|chat_expiring",
    "matchedUserId": "user_id",
    "conversationId": "conversation_id",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

## 8. Troubleshooting

### Android Issues

**Problem**: Notifications not received
- Check `google-services.json` is in correct location
- Verify package name matches Firebase console
- Check device has Google Play Services
- Enable "Unrestricted" battery usage for the app

**Problem**: Background notifications not working
- Verify all permissions in AndroidManifest.xml
- Check Firebase Cloud Messaging is enabled in console

### iOS Issues

**Problem**: Notifications not received
- Ensure using physical device (not simulator)
- Verify APNs certificate is uploaded to Firebase
- Check bundle ID matches Firebase console
- Ensure Push Notifications capability is enabled in Xcode

**Problem**: Background notifications not working
- Verify `remote-notification` in UIBackgroundModes
- Check provisioning profile includes Push Notifications

### Web Issues

**Problem**: Service worker not registered
- Ensure `firebase-messaging-sw.js` is in `web/` folder
- Check browser console for service worker errors
- Verify HTTPS is used (required for service workers)

**Problem**: Notifications not received
- Check notification permissions in browser settings
- Verify VAPID key is correctly configured
- Ensure service worker is active in DevTools → Application

## 9. Security Best Practices

1. **Never commit Firebase configuration files to version control**
   - Add to `.gitignore`:
     ```
     android/app/google-services.json
     ios/Runner/GoogleService-Info.plist
     ```

2. **Use environment-specific configurations**
   - Separate Firebase projects for development, staging, and production

3. **Implement token refresh handling**
   - Already implemented in `FirebaseMessagingService`
   - Tokens are automatically refreshed and re-registered

4. **Validate notification data on backend**
   - Don't trust client-provided notification data
   - Verify user permissions before sending notifications

## 10. Monitoring and Analytics

### Firebase Console Monitoring

Monitor notifications in Firebase Console:
- **Cloud Messaging** → **Reports**: View delivery rates
- **Analytics** → **Events**: Track notification opens
- **Cloud Messaging** → **Diagnostics**: Debug delivery issues

### App-Level Logging

Check app logs for:
```
Firebase Messaging Service initialized successfully
FCM Token refreshed
Device token registered with backend successfully
Notification shown: [type]
```

## Support

For issues specific to:
- Firebase setup: https://firebase.google.com/support
- Flutter Firebase: https://firebase.flutter.dev
- APNs: https://developer.apple.com/documentation/usernotifications

## References

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Android Notification Guide](https://developer.android.com/develop/ui/views/notifications)
