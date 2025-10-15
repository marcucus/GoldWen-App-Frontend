# Logout Implementation - Documentation

## Overview
This document describes the complete logout implementation for the GoldWen app, including both frontend and backend changes.

## Problem Statement
The original logout functionality did not properly:
- Call the backend to invalidate tokens
- Clear Redis cache and session data
- Remove FCM (Firebase Cloud Messaging) tokens
- Redirect users to the login screen

## Solution Implemented

### Backend Changes (main-api/)

#### 1. New Logout Endpoint
**File**: `src/modules/auth/auth.controller.ts`
- Added `POST /auth/logout` endpoint
- Requires JWT authentication
- Extracts user ID and token from request
- Calls `AuthService.logout()` to perform cleanup

#### 2. Logout Service Implementation
**File**: `src/modules/auth/auth.service.ts`
- Added `logout(userId: string, token?: string)` method
- Performs the following cleanup operations:
  1. **Token Blacklisting**: Stores JWT token in Redis blacklist with TTL matching JWT expiration
  2. **FCM Token Cleanup**: Removes all push notification tokens for the user
  3. **Cache Cleanup**: Clears all user-specific cache entries (`user:${userId}:*`)
  4. **Session Cleanup**: Removes session data (`session:${userId}`)

#### 3. JWT Strategy Update
**File**: `src/modules/auth/strategies/jwt.strategy.ts`
- Added Redis injection
- Modified `validate()` method to check token blacklist
- Rejects authentication if token is found in Redis blacklist
- Prevents use of invalidated tokens even before expiration

#### 4. Auth Module Update
**File**: `src/modules/auth/auth.module.ts`
- Added `PushToken` entity to TypeORM imports
- Enables push token cleanup during logout

### Frontend Changes (lib/)

The frontend logout implementation was already correct and includes:

#### Auth Provider
**File**: `lib/features/auth/providers/auth_provider.dart`
- `signOut()` method already calls `ApiService.logout()`
- Clears local state (user, token, status)
- Clears API service token
- Removes stored auth data from SharedPreferences

#### Settings Page
**File**: `lib/features/settings/pages/settings_page.dart`
- Shows confirmation dialog before logout
- Calls `authProvider.signOut()`
- Redirects to `/welcome` page using `context.go('/welcome')`

#### API Service
**File**: `lib/core/services/api_service.dart`
- `logout()` method sends POST request to `/auth/logout` endpoint
- Includes JWT token in Authorization header

## Flow Diagram

```
User clicks "Se déconnecter" (Logout)
    ↓
Confirmation dialog shown
    ↓
User confirms
    ↓
Frontend: authProvider.signOut()
    ↓
Frontend: ApiService.logout() → POST /auth/logout
    ↓
Backend: JWT validation
    ↓
Backend: AuthService.logout()
    ├─→ Add token to Redis blacklist
    ├─→ Delete FCM push tokens
    ├─→ Clear user cache entries
    └─→ Delete session data
    ↓
Backend: Return success response
    ↓
Frontend: Clear local state
    ├─→ Set user = null
    ├─→ Set token = null
    ├─→ Clear SharedPreferences
    └─→ Clear ApiService token
    ↓
Frontend: Redirect to /welcome
```

## Redis Keys Used

1. **Token Blacklist**: `blacklist:token:${token}`
   - TTL: Matches JWT expiration time
   - Value: "true"

2. **User Cache**: `user:${userId}:*`
   - All keys matching this pattern are deleted

3. **Session**: `session:${userId}`
   - User session data deleted

## Testing the Implementation

### Manual Testing Steps

1. **Login**:
   - Login to the app with valid credentials
   - Verify authentication works

2. **Verify Token Works**:
   - Navigate through the app
   - Make API calls (e.g., view profile, daily matches)
   - Confirm all authenticated endpoints work

3. **Logout**:
   - Go to Settings page
   - Click on "Se déconnecter"
   - Confirm in dialog
   - Verify redirect to welcome page

4. **Verify Token Invalidation**:
   - Try to use the old token (if you saved it)
   - Should receive 401 Unauthorized error
   - Token should be in Redis blacklist

5. **Verify No Push Notifications**:
   - After logout, no notifications should be received
   - FCM tokens should be removed from database

6. **Re-login**:
   - Login again with same credentials
   - New token should be issued
   - App should work normally

### Backend Testing

```bash
# 1. Start the backend
cd main-api
npm run start:dev

# 2. Login and get token
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Save the returned token

# 3. Verify token works
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"

# 4. Logout
curl -X POST http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN"

# 5. Try to use token again (should fail)
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
# Expected: 401 Unauthorized with "Token has been revoked" message
```

## Security Improvements

1. **Token Blacklisting**: Prevents reuse of tokens after logout
2. **Server-side Cleanup**: Ensures all session data is removed
3. **FCM Token Removal**: Prevents unauthorized notifications
4. **Cache Clearing**: Removes potentially sensitive cached data

## Future Enhancements

1. **Logout All Devices**: Add endpoint to invalidate all tokens for a user
2. **Device Management**: Let users see and manage active sessions
3. **Logout Notifications**: Send notification when account is logged out from another device
4. **Admin Force Logout**: Admin ability to force logout specific users

## Notes

- Logout is designed to always succeed on client side, even if backend call fails
- This ensures users can always logout locally even with network issues
- Backend cleanup is best-effort and errors are logged but not thrown
- Redis TTL ensures blacklisted tokens are automatically cleaned up after expiration
