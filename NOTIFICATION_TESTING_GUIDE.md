# Quick Testing Guide - Push Notifications

This guide provides quick steps to test push notifications in the GoldWen app.

## Prerequisites

1. Complete Firebase setup (see `FIREBASE_FCM_SETUP.md`)
2. Physical device (push notifications don't work on emulators/simulators)
3. Valid Firebase configuration files in place
4. Backend API running and accessible

## Quick Setup Checklist

- [ ] `android/app/google-services.json` in place (Android)
- [ ] `ios/Runner/GoogleService-Info.plist` in place (iOS)
- [ ] `web/firebase-messaging-sw.js` updated with your Firebase config (Web)
- [ ] Backend API accessible
- [ ] User account created and logged in

## Testing Daily Selection Notifications

### Automatic Test (Scheduled for 12:00 PM)

1. **Enable daily selection notifications:**
   ```dart
   // In app settings or use the notification test page
   Settings → Notifications → Enable "Daily Selection"
   ```

2. **Wait for 12:00 PM local time**
   - Notification should appear automatically
   - Title: "Votre sélection GoldWen du jour est arrivée !"
   - Body: "Découvrez vos nouveaux profils compatibles"

3. **Verify:**
   - Notification appears at exactly 12:00 PM
   - Tapping notification navigates to Discover tab
   - Notification repeats daily at the same time

### Manual Test (Immediate)

1. **Use the Notification Test Page:**
   ```
   Navigate to: Settings → Developer Options → Test Notifications
   Or use: /test-notifications route
   ```

2. **Trigger test notification:**
   - Tap "Test Daily Selection"
   - Notification appears immediately
   - Verify navigation to Discover tab

### Backend API Test

```bash
# Trigger daily selection notification from backend
curl -X POST http://your-api-url/notifications/trigger-daily-selection \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

## Testing Match Notifications

### Automatic Test (When Match Occurs)

1. **Create a mutual match:**
   - User A selects User B from daily selection
   - User B selects User A from their daily selection
   - Both users receive match notification

2. **Expected notification:**
   - Title: "Nouveau match !"
   - Body: "Félicitations ! Vous avez un match avec [Name]"
   - Tapping navigates to Matches page

### Manual Test

1. **Use test endpoint:**
   ```bash
   curl -X POST http://your-api-url/notifications/test \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "new_match",
       "title": "Nouveau match !",
       "body": "Félicitations ! Vous avez un match avec Sophie"
     }'
   ```

2. **Or use the app test page:**
   - Go to Notification Test Page
   - Enter user name: "Sophie"
   - Tap "Test Match Notification"

## Testing Message Notifications

### Automatic Test (Real-time via WebSocket)

1. **Start a conversation:**
   - Match with another user
   - Wait for other user to send a message
   - Notification appears in real-time

2. **Expected notification:**
   - Title: "Nouveau message"
   - Body: "[SenderName] vous a envoyé un message"
   - Tapping navigates to chat conversation

### Manual Test

```bash
# Send test message notification
curl -X POST http://your-api-url/notifications/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "new_message",
    "title": "Nouveau message",
    "body": "Marc vous a envoyé un message"
  }'
```

## Testing Chat Expiring Notifications

### Automatic Test

1. **Start a conversation with countdown:**
   - Match with user
   - Wait until chat has been active for 20+ hours
   - System sends expiration warning 4 hours before expiry

2. **Expected notification:**
   - Title: "Votre conversation expire bientôt !"
   - Body: "Il vous reste 4h pour discuter avec [Name]"
   - Tapping navigates to chat

### Manual Test

```bash
# Trigger chat expiring notification
curl -X POST http://your-api-url/notifications/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "chat_expiring",
    "title": "Votre conversation expire bientôt !",
    "body": "Il vous reste 4h pour discuter avec Sophie"
  }'
```

## Testing Notification Settings

### Enable/Disable Notifications

1. **Navigate to Settings → Notifications**

2. **Test each toggle:**
   - Daily Selection: ON/OFF
   - New Matches: ON/OFF
   - New Messages: ON/OFF
   - Chat Expiring: ON/OFF

3. **Verify behavior:**
   - When OFF, notifications of that type should not appear
   - When ON, notifications should work normally
   - Settings persist after app restart

### Test Quiet Hours

1. **Configure quiet hours:**
   ```
   Settings → Notifications → Quiet Hours
   Start: 22:00
   End: 08:00
   ```

2. **Test during quiet hours:**
   - Notifications should still be received (stored)
   - But no sound/vibration
   - Badge count still updates

3. **Test outside quiet hours:**
   - Full notifications with sound/vibration

## Testing Deep Linking

### Verify Navigation from Notifications

| Notification Type | Expected Navigation |
|-------------------|---------------------|
| Daily Selection | `/discover` (Discover tab) |
| New Match | `/matches` (Matches page) |
| New Message | `/chat/:conversationId` (Specific chat) |
| Chat Expiring | `/chat/:conversationId` (Specific chat) |
| System | `/notifications` (Notifications page) |

### Test Steps

1. **Ensure app is closed or in background**

2. **Receive notification** (use manual test method)

3. **Tap notification**

4. **Verify:**
   - App opens to correct screen
   - Correct data is displayed
   - Navigation history is correct

## Testing on Different Platforms

### Android Testing

1. **Check permissions:**
   ```bash
   adb shell dumpsys package com.goldwen.app | grep permission
   ```

2. **View device token:**
   ```bash
   # In app logs
   flutter logs | grep "FCM Device Token"
   ```

3. **Test notification channels:**
   - Settings → Apps → GoldWen → Notifications
   - Verify all channels are present:
     - Daily Selection
     - Matches
     - Messages
     - General

### iOS Testing

1. **Check permissions:**
   - Settings → GoldWen → Notifications
   - Verify permissions are granted

2. **Test background delivery:**
   - Put app in background
   - Send test notification
   - Verify notification appears on lock screen

3. **Check APNs certificate:**
   - Ensure valid certificate in Firebase Console
   - Verify bundle ID matches

### Web Testing

1. **Check service worker:**
   - Open DevTools → Application → Service Workers
   - Verify `firebase-messaging-sw.js` is active

2. **Test browser permissions:**
   - Chrome: chrome://settings/content/notifications
   - Ensure GoldWen app has permission

3. **Test notification click:**
   - Notifications should open app in new tab
   - Correct route should be navigated to

## Debugging Tips

### Check Logs

**Android:**
```bash
adb logcat | grep -E "Firebase|FCM|Notification"
```

**iOS:**
```bash
# In Xcode Console
Filter: "Firebase" or "FCM" or "Notification"
```

**Flutter:**
```bash
flutter logs | grep -E "Firebase|FCM|Notification"
```

### Common Issues

**No notifications received:**
- Check device token is registered with backend
- Verify Firebase configuration files
- Ensure notifications are enabled in app settings
- Check backend is sending to correct token

**Notifications delayed:**
- Check device battery optimization settings
- Ensure app has unrestricted background access
- Verify backend is using high priority messages

**Deep linking not working:**
- Check `NavigationService` is properly initialized
- Verify routes are registered in app router
- Check notification payload has correct data

**Web notifications not working:**
- Ensure HTTPS is used (required for service workers)
- Check service worker is registered and active
- Verify VAPID key is configured correctly

## Performance Testing

### Load Testing

1. **Send multiple notifications:**
   ```bash
   for i in {1..10}; do
     curl -X POST http://your-api-url/notifications/test \
       -H "Authorization: Bearer YOUR_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"type": "new_match", "title": "Test '$i'", "body": "Test"}' &
   done
   ```

2. **Verify:**
   - All notifications received
   - No performance degradation
   - Correct badge count

### Battery Impact

1. **Monitor battery usage:**
   - Android: Settings → Battery → App usage
   - iOS: Settings → Battery

2. **Check over 24 hours:**
   - Should be minimal impact (<5% daily)
   - Background notifications should not drain battery

## Acceptance Criteria Validation

Use this checklist to validate all acceptance criteria from specifications:

### Module 4.2 - Daily Selection
- [ ] Notification sent at 12:00 PM local time daily
- [ ] Title: "Votre sélection GoldWen du jour est arrivée !"
- [ ] Tapping opens Discover tab with 3-5 profiles
- [ ] Notifications repeat daily

### Module 4.3 - Messaging
- [ ] Match notification: "Félicitations! Vous avez un match avec [Name]"
- [ ] Message notification when receiving new messages
- [ ] Chat expiring notification 4 hours before expiry
- [ ] All notifications navigate to correct screens

### Module 4.4 - Settings
- [ ] Settings UI for all notification types
- [ ] Toggle for daily selection notifications
- [ ] Toggle for match notifications
- [ ] Toggle for message notifications
- [ ] Toggle for chat expiring notifications
- [ ] Push enabled/disabled toggle
- [ ] Sound and vibration preferences
- [ ] Quiet hours configuration
- [ ] Settings persist across app restarts
- [ ] Settings sync with backend

### Technical Requirements
- [ ] Works on iOS (physical device)
- [ ] Works on Android (physical device)
- [ ] Works on Web (HTTPS)
- [ ] Device token registered with backend
- [ ] Token refreshed when expired
- [ ] Token removed on logout
- [ ] Deep linking works for all notification types
- [ ] Notifications respect user settings
- [ ] Notifications respect quiet hours
- [ ] Background notifications work when app closed
- [ ] Foreground notifications work when app open

## Success Metrics

**Test is successful if:**
- ✅ All notification types work on all platforms
- ✅ Deep linking navigates to correct screens
- ✅ Settings are respected (no notifications when disabled)
- ✅ Quiet hours work as expected
- ✅ Daily notifications arrive at 12:00 PM
- ✅ Backend token CRUD operations work
- ✅ No crashes or errors in logs
- ✅ Performance impact is minimal
- ✅ Battery usage is reasonable

## Next Steps

After successful testing:
1. Document any platform-specific quirks found
2. Update backend if any API changes needed
3. Create monitoring dashboard for notification delivery rates
4. Set up analytics to track notification engagement
5. Plan for A/B testing different notification copy
6. Consider adding rich notifications (images, actions)
