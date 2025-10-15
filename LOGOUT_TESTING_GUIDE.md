# Quick Testing Guide - Logout Functionality

## Quick Start

### 1. Start Backend
```bash
cd main-api
npm install  # if not already done
npm run start:dev
```

Backend should be running on: http://localhost:3000

### 2. Verify Backend Endpoint

```bash
# Test health check
curl http://localhost:3000/api/v1/health
```

### 3. Test Logout Flow (Command Line)

```bash
# 1. Login (replace with real credentials)
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  | jq -r '.data.accessToken')

echo "Token: $TOKEN"

# 2. Verify token works
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/auth/me

# 3. Logout
curl -X POST http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer $TOKEN"

# 4. Try to use token again (should fail with 401)
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/auth/me
# Expected: {"statusCode":401,"message":"Token has been revoked"}
```

### 4. Test in Mobile App

1. **Login**
   - Open app
   - Login with credentials
   - Navigate to some screens (profile, matches, etc.)

2. **Logout**
   - Go to Settings (⚙️ icon)
   - Scroll to bottom
   - Tap "Se déconnecter"
   - Confirm in dialog
   - ✅ Should redirect to Welcome page

3. **Verify Logout**
   - Should be on welcome/login screen
   - No user data visible
   - Previous session should be invalid

4. **Re-login**
   - Login again
   - ✅ Should work with new token
   - All features should work normally

## What Gets Cleaned Up

### Backend (Redis)
- ✅ JWT token blacklisted: `blacklist:token:${token}`
- ✅ User cache cleared: `user:${userId}:*`
- ✅ Session deleted: `session:${userId}`
- ✅ FCM tokens removed from database

### Frontend (Local Storage)
- ✅ Auth token cleared
- ✅ User data removed from SharedPreferences
- ✅ API service token cleared
- ✅ Analytics reset (Mixpanel)

## Expected Behavior

### Success Cases
- ✅ User can logout
- ✅ Redirected to welcome screen
- ✅ All local data cleared
- ✅ Old token rejected (401 Unauthorized)
- ✅ Can login again with new token

### Error Handling
- ✅ Logout succeeds even if backend call fails
- ✅ Logout succeeds even with network issues
- ✅ User always sees welcome screen after logout

## Troubleshooting

### Backend not starting
```bash
cd main-api
rm -rf node_modules package-lock.json
npm install
npm run start:dev
```

### Redis not running
```bash
# Check if Redis is running
redis-cli ping
# Should return: PONG

# Start Redis (if using Docker)
docker run -d -p 6379:6379 redis:alpine

# Or install locally and start
# Ubuntu/Debian: sudo systemctl start redis
# macOS: brew services start redis
```

### Token blacklist not working
```bash
# Check Redis
redis-cli

# In Redis CLI:
KEYS blacklist:token:*

# If no keys found, check:
# 1. Is Redis running?
# 2. Is backend connected to Redis?
# 3. Check backend logs for errors
```

### Frontend not clearing data
- Check console logs for errors
- Verify `AnalyticsService.reset()` is called
- Check SharedPreferences data before/after logout

## Verification Checklist

After implementing, verify:

- [ ] Backend builds without errors (`npm run build`)
- [ ] Backend starts without errors (`npm run start:dev`)
- [ ] Health endpoint returns success
- [ ] Login works and returns token
- [ ] Logout endpoint accepts authenticated request
- [ ] Token is blacklisted in Redis
- [ ] FCM tokens removed from database
- [ ] Old token returns 401 after logout
- [ ] Frontend clears all local data
- [ ] Analytics reset is called
- [ ] User redirected to welcome screen
- [ ] Can login again successfully

## Files to Review

### Backend
- `main-api/src/modules/auth/auth.controller.ts` - Logout endpoint
- `main-api/src/modules/auth/auth.service.ts` - Logout logic
- `main-api/src/modules/auth/strategies/jwt.strategy.ts` - Token validation

### Frontend
- `lib/features/auth/providers/auth_provider.dart` - Logout method
- `lib/features/settings/pages/settings_page.dart` - Logout button
- `lib/core/services/api_service.dart` - API logout call

## Need Help?

1. Check logs:
   - Backend: Console output from `npm run start:dev`
   - Frontend: Flutter console / device logs
   - Redis: `redis-cli MONITOR`

2. Review documentation:
   - `LOGOUT_IMPLEMENTATION.md` - Technical details (English)
   - `LOGOUT_RESUME_FR.md` - Summary (French)

3. Test with curl commands above to isolate backend vs frontend issues
