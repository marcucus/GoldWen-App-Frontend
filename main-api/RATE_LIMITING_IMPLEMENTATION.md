# Rate Limiting and API Security Implementation

## Overview
This implementation adds comprehensive rate limiting and brute force protection to the GoldWen API, protecting against abuse and denial-of-service attacks.

## Features Implemented

### 1. Global Rate Limiting
- **Configuration**: 100 requests per minute per IP address
- **Scope**: Applied globally to all API endpoints
- **Implementation**: `RateLimitGuard` extends `ThrottlerGuard`
- **Response**: Returns HTTP 429 when limit exceeded

### 2. Brute Force Protection
- **Configuration**: 5 login attempts per 15 minutes per IP+email combination
- **Scope**: Applied specifically to authentication endpoints (`/auth/login`)
- **Implementation**: `BruteForceGuard` extends `ThrottlerGuard`
- **Tracking**: Combines IP address and email for more precise detection
- **Alerting**: Sends critical alerts when brute force attacks are detected

### 3. Rate Limit Headers
All responses include the following headers:
- `X-RateLimit-Limit`: Maximum number of requests allowed
- `X-RateLimit-Remaining`: Number of requests remaining
- `X-RateLimit-Reset`: Timestamp when the rate limit resets
- `Retry-After`: Seconds to wait before retrying (when rate limited)

### 4. Security Logging
- All rate limit violations are logged with security event tracking
- Brute force attempts trigger critical security alerts
- Integration with existing `SecurityLoggingMiddleware`
- Integration with `AlertingService` for notifications

## File Structure

```
main-api/src/
├── common/
│   ├── guards/
│   │   ├── rate-limit.guard.ts           # Global rate limiting guard
│   │   ├── rate-limit.guard.spec.ts      # Unit tests for rate limiting
│   │   ├── brute-force.guard.ts          # Brute force protection guard
│   │   ├── brute-force.guard.spec.ts     # Unit tests for brute force protection
│   │   └── index.ts                      # Barrel export
│   └── interceptors/
│       └── rate-limit-headers.interceptor.ts  # Rate limit headers interceptor
├── config/
│   ├── config.interface.ts               # Added ThrottlerConfig interface
│   └── configuration.ts                  # Added throttlerConfig
├── modules/
│   └── auth/
│       └── auth.controller.ts            # Applied BruteForceGuard to login endpoint
└── app.module.ts                         # Configured ThrottlerModule and global guard
```

## Configuration

### Environment Variables
Add the following to your `.env` file:

```bash
# Global rate limiting (applies to all endpoints)
THROTTLE_TTL=60000           # 60 seconds
THROTTLE_LIMIT=100           # 100 requests per minute

# Sensitive endpoints rate limiting
THROTTLE_SENSITIVE_TTL=60000  # 60 seconds
THROTTLE_SENSITIVE_LIMIT=20   # 20 requests per minute

# Authentication endpoints brute force protection
THROTTLE_AUTH_TTL=900000      # 15 minutes
THROTTLE_AUTH_LIMIT=5         # 5 attempts per 15 minutes
```

### Default Values
If environment variables are not set, the following defaults are used:
- **Global**: 100 requests/minute
- **Sensitive**: 20 requests/minute  
- **Auth**: 5 attempts/15 minutes

## Usage

### Applying to Endpoints

#### Global Rate Limiting
Applied automatically to all endpoints via `APP_GUARD` in `app.module.ts`:
```typescript
{
  provide: APP_GUARD,
  useClass: RateLimitGuard,
}
```

#### Brute Force Protection on Specific Endpoints
```typescript
@UseGuards(BruteForceGuard)
@Post('login')
async login(@Body() loginDto: LoginDto) {
  // Login logic
}
```

## Security Features

### 1. IP-based Tracking
- Uses client IP address for rate limiting
- Falls back to connection remote address if IP is not available
- Handles proxy scenarios

### 2. Email Redaction in Logs
- Email addresses are redacted in security logs (first 3 chars + ***)
- Protects user privacy while maintaining security audit trail

### 3. Integration with Monitoring
- Integrates with `CustomLoggerService` for structured logging
- Sends alerts via `AlertingService` for brute force attacks
- Works with existing `SecurityLoggingMiddleware`

### 4. Proper Error Handling
- Returns standard `ThrottlerException` with HTTP 429
- Includes helpful error messages for clients
- Sets appropriate `Retry-After` headers

## Testing

### Unit Tests
Comprehensive unit tests are provided for both guards:
- `rate-limit.guard.spec.ts`: 8 tests
- `brute-force.guard.spec.ts`: 11 tests

Run tests:
```bash
npm test -- --testPathPatterns="guards"
```

### Test Coverage
Tests cover:
- Guard initialization and configuration
- IP address tracking logic
- Error logging and alerting
- Security event integration
- Email redaction
- Default configuration fallbacks

## Dependencies

- `@nestjs/throttler`: ^6.2.1 (newly added)
- `@nestjs/common`: ^11.0.1
- `@nestjs/config`: ^4.0.2

## API Response Examples

### Successful Request
```http
GET /api/v1/users
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1704123456789

200 OK
```

### Rate Limited Request
```http
POST /api/v1/auth/login
X-RateLimit-Limit: 5
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1704123456789
Retry-After: 900

429 Too Many Requests
{
  "statusCode": 429,
  "message": "Too many login attempts. Please try again in 15 minutes."
}
```

## Security Considerations

1. **Storage**: Uses in-memory storage by default. For production with multiple instances, consider Redis storage.
2. **Proxy Support**: Ensure proper proxy configuration to get correct client IP addresses.
3. **DDoS Protection**: This is application-level protection. Consider additional infrastructure-level DDoS protection.
4. **Monitoring**: Monitor rate limit violations for patterns that might indicate attacks.

## Future Enhancements

1. **Redis Storage**: Implement Redis-based storage for distributed rate limiting
2. **Dynamic Limits**: Per-user or per-tier rate limits based on subscription level
3. **Whitelist/Blacklist**: IP-based whitelist and blacklist functionality
4. **Custom Throttle Points**: Decorator for easy custom rate limiting on any endpoint
5. **Rate Limit Analytics**: Dashboard for monitoring rate limit usage and violations

## Compliance

This implementation helps meet security requirements for:
- OWASP API Security Top 10 (API4:2023 Unrestricted Resource Consumption)
- PCI DSS (Requirement 8.1.6 - Limit repeated access attempts)
- GDPR (Security of processing - Article 32)

## Support

For issues or questions:
1. Check logs in `SecurityLoggingMiddleware`
2. Review rate limit configuration in `.env`
3. Verify `@nestjs/throttler` is properly installed
4. Check Redis connectivity (if using Redis storage)
