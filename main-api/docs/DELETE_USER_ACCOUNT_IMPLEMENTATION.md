# DELETE /users/me - Account Deletion Implementation

## Overview
Complete implementation of the GDPR-compliant user account deletion route with password verification and double confirmation.

## Endpoint Details

### Route
```
DELETE /api/v1/users/me
```

### Authentication
- **Required**: Yes (JWT Bearer Token)
- **Type**: Bearer Token

### Request Body
```json
{
  "password": "string",
  "confirmationText": "DELETE"
}
```

### Request Body Validation
- **password**: 
  - Required: Yes
  - Type: string
  - Min length: 1
  - Purpose: User's current password for verification

- **confirmationText**:
  - Required: Yes
  - Type: string
  - Exact value: "DELETE" (case-sensitive)
  - Purpose: Double confirmation to prevent accidental deletion

### Response

#### Success (200)
```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

#### Error: Invalid Confirmation Text (400)
```json
{
  "statusCode": 400,
  "message": "Invalid confirmation text. Must be exactly \"DELETE\"",
  "error": "Bad Request"
}
```

#### Error: Invalid Password (401)
```json
{
  "statusCode": 401,
  "message": "Invalid password",
  "error": "Unauthorized"
}
```

## Implementation Details

### Security Features
1. **Password Verification**: User must provide their current password
2. **Double Confirmation**: Must type exactly "DELETE" (case-sensitive)
3. **JWT Authentication**: Route protected by JWT guard
4. **GDPR Compliance**: Complete anonymization using GdprService

### Deletion Process
When a user deletes their account:
1. Validates confirmation text is exactly "DELETE"
2. Fetches user with password hash from database
3. Verifies the provided password matches
4. Calls `GdprService.deleteUserCompletely()` which:
   - Anonymizes all messages (sender becomes "deleted-user")
   - Anonymizes all matches (user IDs replaced with "deleted-user")
   - Deletes push tokens
   - Deletes user consents
   - Deletes notifications
   - Deletes daily selections
   - Deletes subscriptions
   - Anonymizes reports
   - Deletes profile
   - Deletes user record

### Files Modified
- `src/modules/users/users.controller.ts`: Updated DELETE /users/me endpoint
- `src/modules/users/dto/delete-account.dto.ts`: New DTO for request validation

### Files Created
- `src/modules/users/dto/delete-account.dto.ts`: Request DTO with validation
- `src/modules/users/tests/delete-account.spec.ts`: Comprehensive test suite (12 tests)

## Test Coverage

### Test Suite: `delete-account.spec.ts`
Total tests: 12 (all passing)

#### Success Cases
✅ Should successfully delete account with valid password and confirmation

#### Error Cases - Confirmation Text
✅ Should throw BadRequestException if confirmation text is not "DELETE"
✅ Should throw BadRequestException if confirmation text is empty
✅ Should throw BadRequestException if confirmation text is different

#### Error Cases - Password
✅ Should throw UnauthorizedException if password is incorrect
✅ Should throw UnauthorizedException if password is empty

#### Edge Cases
✅ Should verify password before checking confirmation text order
✅ Should handle user not found scenario
✅ Should handle GDPR service deletion errors gracefully

#### DTO Validation
✅ Should validate that password is required
✅ Should validate that confirmationText is required
✅ Should create valid DTO with all required fields

## Example Usage

### cURL Example
```bash
curl -X DELETE https://api.goldwen.com/api/v1/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "MySecurePassword123",
    "confirmationText": "DELETE"
  }'
```

### JavaScript/TypeScript Example
```typescript
async function deleteAccount(password: string): Promise<void> {
  const response = await fetch('https://api.goldwen.com/api/v1/users/me', {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      password: password,
      confirmationText: 'DELETE'
    })
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }

  const result = await response.json();
  console.log(result.message); // "Account deleted successfully"
}
```

## Frontend Integration

### Expected Flow (from TACHES_FRONTEND.md)
1. ✅ User clicks "Delete Account" button in settings
2. ✅ Warning page displays consequences of deletion
3. ✅ User enters password for verification
4. ✅ User types "DELETE" for double confirmation
5. ✅ Backend validates both password and confirmation text
6. ✅ Complete account deletion with GDPR anonymization
7. ✅ User is automatically logged out and redirected

### UI Recommendations
- Show clear warning about permanent data loss
- Display list of what will be deleted:
  - Profile information
  - All matches and conversations
  - Photos and prompt answers
  - Subscription history
  - Push notification tokens
- Require password entry in a secure input field
- Require typing exactly "DELETE" in a text field
- Disable submit button until both fields are filled
- Show loading indicator during deletion
- Handle errors gracefully (wrong password, network issues)

## RGPD/GDPR Compliance

This implementation satisfies:
- ✅ **Article 17**: Right to erasure ("right to be forgotten")
- ✅ **Complete data deletion**: All personal data removed or anonymized
- ✅ **Irreversible deletion**: No way to recover deleted accounts
- ✅ **System integrity**: Related data anonymized rather than deleted
- ✅ **Audit trail**: Logs track deletion process
- ✅ **User verification**: Password required to prevent unauthorized deletion

## Related Documentation
- [GDPR Module README](../modules/gdpr/README.md)
- [API Routes Documentation](../../API_ROUTES_DOCUMENTATION.md)
- [Frontend Tasks](../../../TACHES_FRONTEND.md) - Module 9.2
