# ConsentGuard - GDPR Compliance Documentation

## Overview

The `ConsentGuard` is a NestJS guard that enforces GDPR compliance by ensuring users have provided valid consent before accessing protected routes. This implementation complies with **GDPR Article 7** (Conditions for consent).

## How It Works

The guard checks if:
1. The user is authenticated
2. The user has an active consent record
3. The user has agreed to data processing (`dataProcessing: true`)

If any condition fails, access is denied with a `403 Forbidden` response.

## Installation

The guard is already registered globally in the application. No additional setup is required.

## Usage

### Applying the Guard Globally

The ConsentGuard should be applied globally to ensure all routes require consent by default:

```typescript
// In app.module.ts or a specific module
import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConsentGuard } from './modules/auth/guards/consent.guard';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserConsent } from './database/entities/user-consent.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserConsent]),
    // ... other imports
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ConsentGuard,
    },
    // ... other providers
  ],
})
export class AppModule {}
```

### Skipping Consent Check

For routes that should be accessible without consent (e.g., authentication, consent endpoints, legal routes), use the `@SkipConsentCheck()` decorator:

```typescript
import { Controller, Post, Get, Body } from '@nestjs/common';
import { SkipConsentCheck } from '../auth/decorators/skip-consent.decorator';

@Controller('users')
export class UsersController {
  
  // This route requires consent (default behavior)
  @Get('profile')
  async getProfile() {
    // ...
  }

  // This route is exempt from consent check
  @SkipConsentCheck()
  @Post('consent')
  async recordConsent(@Body() consentDto: ConsentDto) {
    // ...
  }

  // This route is also exempt
  @SkipConsentCheck()
  @Get('consent')
  async getCurrentConsent() {
    // ...
  }
}
```

### Routes That Should Skip Consent Check

The following types of routes should use `@SkipConsentCheck()`:

1. **Authentication routes** - Users need to authenticate before they can give consent
2. **Consent management routes** - Users need to access these to provide consent
3. **Legal routes** - Privacy policy, terms of service must be accessible before consent
4. **Public information routes** - Health checks, API info, etc.

Example:

```typescript
// Authentication Controller
@Controller('auth')
export class AuthController {
  @SkipConsentCheck()
  @Post('register')
  async register() { /* ... */ }

  @SkipConsentCheck()
  @Post('login')
  async login() { /* ... */ }
}

// Legal Controller
@Controller('legal')
export class LegalController {
  @SkipConsentCheck()
  @Get('privacy-policy')
  async getPrivacyPolicy() { /* ... */ }
}
```

## Error Response

When a user tries to access a protected route without valid consent, they receive:

```json
{
  "statusCode": 403,
  "message": "Valid consent required. You must accept the privacy policy and data processing terms to use this feature.",
  "code": "CONSENT_REQUIRED",
  "nextStep": "/consent",
  "details": {
    "hasConsent": false,
    "dataProcessingConsent": false
  }
}
```

The client application should:
1. Detect the `CONSENT_REQUIRED` error code
2. Redirect the user to the consent screen
3. Display the privacy policy
4. Collect consent via `POST /users/consent`

## Frontend Integration

### Flow Diagram

```
User Login
    ↓
Check Consent Status (GET /users/consent)
    ↓
    ├─ Has Valid Consent → Continue to App
    └─ No Valid Consent → Show Consent Screen
              ↓
          Display Privacy Policy (GET /legal/privacy-policy)
              ↓
          User Accepts
              ↓
          Record Consent (POST /users/consent)
              ↓
          Continue to App
```

### Example: Checking Consent Status

```typescript
// Check if user has valid consent
const response = await fetch('/api/v1/users/consent', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const { data } = await response.json();

if (!data || !data.dataProcessing) {
  // Redirect to consent screen
  router.push('/consent');
}
```

### Example: Recording Consent

```typescript
// User accepts privacy policy
const response = await fetch('/api/v1/users/consent', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    dataProcessing: true,      // Required
    marketing: false,          // Optional
    analytics: true,           // Optional
    consentedAt: new Date().toISOString()
  })
});

if (response.ok) {
  // Consent recorded successfully
  router.push('/dashboard');
}
```

### Example: Handling Consent Errors

```typescript
try {
  const response = await fetch('/api/v1/users/profile');
  
  if (response.status === 403) {
    const error = await response.json();
    
    if (error.code === 'CONSENT_REQUIRED') {
      // Show consent modal or redirect to consent screen
      showConsentModal();
    }
  }
} catch (error) {
  console.error('Request failed:', error);
}
```

## Testing

The ConsentGuard includes comprehensive unit tests covering all scenarios:

```bash
# Run ConsentGuard tests
npm test -- consent.guard.spec.ts
```

Test coverage includes:
- ✅ Allow access when skip consent check is set
- ✅ Deny access if user is not authenticated
- ✅ Allow access if user has valid consent
- ✅ Deny access if user has no consent
- ✅ Deny access if dataProcessing is false
- ✅ Proper error response format

## GDPR Compliance

This implementation ensures:

1. **Explicit Consent (Art. 7)**: Users must actively consent to data processing
2. **Withdrawal of Consent (Art. 7.3)**: Previous consents are revoked when new consent is recorded
3. **Proof of Consent**: IP address and timestamp are recorded for each consent
4. **Granular Consent**: Separate flags for data processing, marketing, and analytics
5. **Consent Management**: Users can view and update their consent at any time

## Best Practices

1. **Always check consent on app startup** - Verify user has valid consent before showing main UI
2. **Display privacy policy prominently** - Make it easy for users to read before consenting
3. **Handle consent errors gracefully** - Show friendly UI when consent is required
4. **Update consent on policy changes** - Notify users and request new consent when privacy policy updates
5. **Test consent flows thoroughly** - Ensure all edge cases are handled

## Troubleshooting

### Issue: All routes return 403 CONSENT_REQUIRED

**Solution**: Ensure you've added `@SkipConsentCheck()` to authentication and consent routes.

### Issue: User has consent but still gets 403 error

**Solution**: Check that:
- The consent is active (`isActive: true`)
- The `dataProcessing` field is `true`
- The user ID matches the consent record

### Issue: Guard not being applied

**Solution**: Verify the guard is registered globally or applied to the module/controller.

## Related Documentation

- [API Routes Documentation](../API_ROUTES_DOCUMENTATION.md)
- [GDPR Module Documentation](../modules/gdpr/README.md)
- [Privacy Policy Entity](../../database/entities/privacy-policy.entity.ts)
- [User Consent Entity](../../database/entities/user-consent.entity.ts)
