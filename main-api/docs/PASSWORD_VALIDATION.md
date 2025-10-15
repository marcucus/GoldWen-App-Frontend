# Password Strength Validation Implementation

## Overview

This implementation adds password strength validation to the GoldWen backend authentication system to ensure user accounts are secure.

## Password Requirements

All passwords in the system must meet the following criteria:

1. **Minimum length**: 6 characters
2. **At least one uppercase letter** (A-Z)
3. **At least one special character**: `!@#$%^&*()_+-=[]{};':"\\|,.<>/?`

## Affected Routes

The following API endpoints now enforce password strength validation:

### 1. User Registration
- **Endpoint**: `POST /api/v1/auth/register`
- **Field**: `password`
- **Example valid password**: `Password123!`

### 2. Password Reset
- **Endpoint**: `POST /api/v1/auth/reset-password`
- **Field**: `newPassword`
- **Example valid password**: `NewPassword123!`

### 3. Change Password
- **Endpoint**: `PUT /api/v1/auth/change-password` (or similar)
- **Field**: `newPassword`
- **Example valid password**: `NewPassword123!`

## Error Messages

When a password doesn't meet the requirements, users will receive clear error messages:

### Missing Length Requirement
```json
{
  "statusCode": 400,
  "message": ["Password must be at least 6 characters long"],
  "error": "Bad Request"
}
```

### Missing Uppercase or Special Character
```json
{
  "statusCode": 400,
  "message": ["Password must contain at least one uppercase letter and one special character (!@#$%^&*()_+-=[]{};':\"\\|,.<>/?)"],
  "error": "Bad Request"
}
```

### Multiple Validation Errors
```json
{
  "statusCode": 400,
  "message": [
    "Password must be at least 6 characters long",
    "Password must contain at least one uppercase letter and one special character (!@#$%^&*()_+-=[]{};':\"\\|,.<>/?)"
  ],
  "error": "Bad Request"
}
```

## Example Passwords

### ✅ Valid Passwords
- `Password123!`
- `MyP@ss1`
- `SecurePass#1`
- `Test123$`
- `Valid1!`

### ❌ Invalid Passwords
- `password123!` - Missing uppercase letter
- `Password123` - Missing special character
- `PASS123!` - Missing lowercase letter (but this is allowed by current regex)
- `Pass1!` - Exactly 6 characters, meets all requirements ✅
- `short` - Too short, missing uppercase and special character

## Technical Implementation

### Validation Rules

The validation is implemented using class-validator decorators in the DTOs:

```typescript
@MinLength(6, { message: 'Password must be at least 6 characters long' })
@Matches(/^(?=.*[A-Z])(?=.*[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]).*$/, {
  message: 'Password must contain at least one uppercase letter and one special character (!@#$%^&*()_+-=[]{};\':"\\|,.<>/?)',
})
password: string;
```

### Regular Expression Breakdown

The regex pattern `/^(?=.*[A-Z])(?=.*[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]).*$/` works as follows:

- `^` - Start of string
- `(?=.*[A-Z])` - Positive lookahead for at least one uppercase letter
- `(?=.*[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?])` - Positive lookahead for at least one special character
- `.*` - Match any characters
- `$` - End of string

## Testing

Comprehensive unit tests have been added to ensure the validation works correctly:

```bash
npm test -- src/modules/auth/tests/auth.dto.spec.ts
```

The test suite covers:
- Valid passwords with various special characters
- Passwords missing uppercase letters
- Passwords missing special characters
- Passwords that are too short
- Edge cases with minimum length passwords

## Security Considerations

1. **Server-side validation**: All validation is performed server-side to prevent bypass
2. **Clear error messages**: Users receive specific feedback about what's wrong with their password
3. **Consistent enforcement**: The same rules apply to registration, password reset, and password change
4. **No password in logs**: The validation library doesn't log actual password values

## Frontend Integration

When integrating with the frontend, ensure:

1. Display password requirements to users before they submit
2. Implement client-side validation for better UX (but remember server-side is authoritative)
3. Show clear error messages from the API response
4. Consider adding a password strength indicator

## Migration Notes

- **Existing users**: This change only affects new passwords. Existing user passwords are not retroactively validated.
- **Social login**: Social login users (Google, Apple) are not affected as they don't set passwords in the system.
- **Backward compatibility**: The API is backward compatible - it only adds additional validation, doesn't change the endpoint structure.
