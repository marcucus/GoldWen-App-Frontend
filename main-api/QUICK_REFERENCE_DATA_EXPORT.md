# Quick Reference: RGPD Data Export Routes

## Endpoints

### Request Data Export
```
POST /api/v1/users/me/export-data
Authorization: Bearer <jwt-token>
```

**Response**:
```json
{
  "exportId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "processing",
  "estimatedTime": 300
}
```

### Get Export Status
```
GET /api/v1/users/me/export-data/:exportId
Authorization: Bearer <jwt-token>
```

**Response** (Ready):
```json
{
  "status": "ready",
  "downloadUrl": "https://example.com/export.json",
  "expiresAt": "2024-01-27T12:00:00Z"
}
```

## Status Values
- `processing`: Export is being generated
- `ready`: Export is ready for download
- `failed`: Export generation failed

## Security
- ✅ JWT authentication required
- ✅ User can only access their own exports
- ✅ Exports expire after 7 days
- ✅ Sensitive data sanitized (passwords, tokens)

## Testing
```bash
npm test -- data-export.controller.spec.ts
```

## Implementation Files
- `src/modules/users/users.controller.ts` - Routes
- `src/modules/users/users.module.ts` - Module config
- `src/modules/gdpr/gdpr.service.ts` - GDPR orchestration
- `src/modules/gdpr/data-export.service.ts` - Data collection
- `src/modules/users/tests/data-export.controller.spec.ts` - Tests

## GDPR Compliance
- ✅ Article 20: Right to data portability
- ✅ Article 15: Right of access
- ✅ Complete user data export
- ✅ Machine-readable format (JSON)
- ✅ Provided without undue delay
