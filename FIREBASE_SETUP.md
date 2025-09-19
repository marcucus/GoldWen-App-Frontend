# Firebase Setup for Push Notifications

This document explains how to configure Firebase for push notifications in the GoldWen app.

## Current State

The app currently uses placeholder Firebase configuration values that allow local notifications to work but not push notifications from Firebase Cloud Messaging (FCM). To enable full push notification functionality, you need to configure a real Firebase project.

## Option 1: Use FlutterFire CLI (Recommended)

1. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Login to Firebase:**
   ```bash
   firebase login
   ```

3. **Configure the project:**
   ```bash
   flutterfire configure
   ```
   
   This will:
   - Create a new Firebase project or select an existing one
   - Generate the proper configuration files
   - Update the Firebase configuration in your Flutter project

4. **Enable Cloud Messaging:**
   - Go to the Firebase Console
   - Select your project
   - Navigate to "Cloud Messaging" in the left sidebar
   - Enable the service if not already enabled

## Option 2: Manual Configuration

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select an existing project
3. Enable Google Analytics (optional)
4. Wait for project creation to complete

### Step 2: Add Android App

1. In Firebase Console, click "Add app" and select Android
2. Enter package name: `com.goldwen.app` (or your chosen package name)
3. Enter app nickname: `GoldWen Android`
4. Enter SHA-1 certificate fingerprint (optional for development)
5. Download `google-services.json`
6. Place the file in `android/app/google-services.json`

### Step 3: Add iOS App

1. In Firebase Console, click "Add app" and select iOS
2. Enter bundle ID: `com.goldwen.app` (or your chosen bundle ID)
3. Enter app nickname: `GoldWen iOS`
4. Download `GoogleService-Info.plist`
5. Place the file in `ios/Runner/GoogleService-Info.plist`
6. Add the file to your Xcode project

### Step 4: Enable Cloud Messaging

1. In Firebase Console, go to "Cloud Messaging"
2. Enable the service
3. Note your Server Key (needed for backend integration)

### Step 5: Update Configuration

Replace the placeholder values in `lib/core/config/firebase_config.dart` with your actual Firebase project values:

```dart
// Replace these with your actual Firebase configuration
static const String _androidApiKey = "YOUR_ANDROID_API_KEY";
static const String _androidAppId = "YOUR_ANDROID_APP_ID";
static const String _androidMessagingSenderId = "YOUR_SENDER_ID";
static const String _androidProjectId = "YOUR_PROJECT_ID";

static const String _iosApiKey = "YOUR_IOS_API_KEY";
static const String _iosAppId = "YOUR_IOS_APP_ID";
static const String _iosMessagingSenderId = "YOUR_SENDER_ID";
static const String _iosProjectId = "YOUR_PROJECT_ID";
static const String _iosBundleId = "YOUR_BUNDLE_ID";
```

## Backend Configuration

For the backend to send push notifications, you'll need to:

1. Add the Firebase Server Key to your backend environment variables
2. Update the notification service to use the correct FCM endpoint
3. Ensure the device token registration endpoint is working

## Testing Push Notifications

1. Run the app in debug mode
2. Go to Notifications page
3. Tap the bug icon (test button) in debug mode
4. Use the Notification Test page to test different notification types
5. Check Firebase Console > Cloud Messaging for message analytics

## Troubleshooting

### Local Notifications Work, Push Notifications Don't
- Check Firebase configuration files are properly placed
- Verify Firebase project has Cloud Messaging enabled
- Check device token is being generated and sent to backend

### Build Errors After Adding Firebase
- Run `flutter clean && flutter pub get`
- For iOS: Update Podfile and run `pod install`
- For Android: Ensure `google-services.json` is in the correct location

### No Notifications in Release Mode
- Check notification permissions are properly requested
- Verify Firebase configuration for release builds
- Check if notifications are being filtered by system settings

## Files Created/Modified

- `lib/core/config/firebase_config.dart` - Firebase configuration
- `lib/core/services/firebase_messaging_service.dart` - FCM service
- `lib/features/notifications/pages/notification_test_page.dart` - Testing UI
- `android/app/google-services.json.example` - Android config example
- `ios/Runner/GoogleService-Info.plist.example` - iOS config example

## Next Steps

1. Configure real Firebase project
2. Replace example configuration files with real ones
3. Update backend with Firebase Server Key
4. Test push notifications end-to-end
5. Configure notification icons and sounds
6. Set up notification analytics and monitoring