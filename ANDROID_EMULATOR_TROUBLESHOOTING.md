# Android Emulator Network Troubleshooting Guide

This guide helps troubleshoot account creation issues on Android emulators.

## Problem Description

When running the GoldWen app on an Android emulator, account creation fails because the emulator cannot access the backend running on the host machine's localhost.

## Solution Implemented

The app now automatically detects when running on Android and uses the correct IP address:

- **Android Emulator**: `10.0.2.2:3000` (special emulator IP to access host)
- **iOS Simulator**: `localhost:3000` (direct host access)
- **Physical Device**: Use your machine's network IP

## Verification Steps

### 1. Check Backend is Running
Ensure your backend is running on the correct ports:
```bash
# Main API should be on port 3000
curl http://localhost:3000/api/v1/health

# Matching service should be on port 8000  
curl http://localhost:8000/api/v1/algorithm/stats
```

### 2. Test Emulator Network Access
From your Android emulator, you can test connectivity:
```bash
# If you have ADB access, run:
adb shell
# Then inside the emulator:
ping 10.0.2.2
```

### 3. Check App Configuration
The app should automatically use the correct URLs. You can verify by checking the debug output when account creation fails. Look for:
- URLs containing `10.0.2.2` on Android
- Clear error messages about server connectivity

### 4. Verify Android Permissions
The app now includes required network permissions in `AndroidManifest.xml`:
- `INTERNET` permission
- `usesCleartextTraffic="true"` for HTTP development connections

## Common Issues and Solutions

### Issue: "Connection refused" or "Network error"
**Solution**: Backend not running or running on wrong port
```bash
# Start your backend on the correct port
npm start  # or your backend start command
# Verify it's listening on port 3000
```

### Issue: "Timeout" errors
**Solution**: Firewall blocking connections
- Check if Windows Defender or other firewall is blocking port 3000
- Add firewall exception for your backend application

### Issue: Still getting localhost errors
**Solution**: The automatic detection might have failed
- Check the debug console output for actual URLs being used
- Ensure the app was built with the latest changes

### Issue: Works on iOS but not Android
**Solution**: This confirms the platform detection is working correctly
- Android should use `10.0.2.2`
- iOS should use `localhost`

## Manual Network Configuration (Alternative)

If automatic detection fails, you can use environment variables:
```bash
flutter run --dart-define=MAIN_API_BASE_URL=http://10.0.2.2:3000/api/v1
```

## Testing the Fix

1. Start your backend on port 3000
2. Launch Android emulator
3. Run the app
4. Try creating an account
5. Check debug output for connection details

If you still have issues, the error messages will now be more descriptive about the specific connection problem.

## Debug Information

When account creation fails, check the console output for:
```
Auth error: [error details]
Status code: [HTTP status code]
Error code: [API error code]
```

This will help identify if it's a network issue, server issue, or API configuration problem.