# GDPR Module - Documentation

## Overview

The GDPR module implements complete GDPR compliance for the GoldWen application, covering the three main articles:

- **Article 7**: Consent Management
- **Article 17**: Right to be Forgotten (Account Deletion)
- **Article 20**: Right to Data Portability (Data Export)

## Architecture

### Entities

#### 1. `UserConsent` (existing)
Stores user consent records with full history tracking.

**Fields:**
- `dataProcessing`: Required consent for data processing
- `marketing`: Optional consent for marketing communications
- `analytics`: Optional consent for analytics tracking
- `consentedAt`: Timestamp of consent
- `revokedAt`: Timestamp of revocation (if applicable)
- `isActive`: Whether this is the current active consent

#### 2. `DataExportRequest` (new)
Tracks data export requests per Article 20 RGPD.

**Fields:**
- `userId`: User requesting the export
- `format`: Export format (JSON or PDF)
- `status`: pending | processing | completed | failed
- `fileUrl`: URL to download the exported data
- `completedAt`: When the export was completed
- `expiresAt`: When the export file expires (7 days after completion)

#### 3. `AccountDeletion` (new)
Tracks account deletion requests per Article 17 RGPD.

**Fields:**
- `userId`: User requesting deletion
- `userEmail`: Email stored for audit trail
- `status`: pending | processing | completed | failed
- `reason`: Optional deletion reason
- `metadata`: Statistics about anonymized data
- `requestedAt`: When deletion was requested
- `completedAt`: When deletion was completed

### Services

#### 1. `GdprService`
Main service coordinating all GDPR operations.

**Key Methods:**
- `requestDataExport(userId, format)`: Create export request
- `getExportRequestStatus(userId, requestId)`: Check export status
- `requestAccountDeletion(userId, reason)`: Create deletion request
- `recordConsent(userId, consentData)`: Record new consent
- `getCurrentConsent(userId)`: Get active consent
- `getConsentHistory(userId)`: Get full consent history
- `revokeConsent(userId)`: Revoke active consent

#### 2. `DataExportService`
Handles data collection and export file generation.

**Key Methods:**
- `createExportRequest(userId, format)`: Initiate export
- `processExportRequest(requestId)`: Process export asynchronously
- `getExportRequest(userId, requestId)`: Retrieve request details
- `getUserExportRequests(userId)`: List all user export requests

### Controller

#### `GdprController`
RESTful API endpoints at `/gdpr/*`

## API Endpoints

### Article 20 - Data Portability

#### 1. Request Data Export
```http
POST /gdpr/export-data
Authorization: Bearer <token>
Content-Type: application/json

{
  "format": "json"  // or "pdf"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Data export request created successfully",
  "data": {
    "requestId": "uuid",
    "status": "pending",
    "format": "json",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "expiresAt": "2024-01-22T10:30:00.000Z"
  }
}
```

#### 2. Check Export Status
```http
GET /gdpr/export-data/:requestId
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "requestId": "uuid",
    "status": "completed",
    "format": "json",
    "fileUrl": "https://...",
    "completedAt": "2024-01-15T10:35:00.000Z",
    "expiresAt": "2024-01-22T10:35:00.000Z",
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}
```

#### 3. List All Export Requests
```http
GET /gdpr/export-data
Authorization: Bearer <token>
```

### Article 17 - Right to be Forgotten

#### 1. Request Account Deletion
```http
DELETE /gdpr/delete-account
Authorization: Bearer <token>
Content-Type: application/json

{
  "reason": "No longer using the service"  // optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "Account deletion request created. Your account will be permanently deleted.",
  "data": {
    "requestId": "uuid",
    "status": "pending",
    "requestedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

#### 2. Check Deletion Status
```http
GET /gdpr/delete-account/:requestId
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "requestId": "uuid",
    "status": "completed",
    "requestedAt": "2024-01-15T10:30:00.000Z",
    "completedAt": "2024-01-15T10:35:00.000Z",
    "metadata": {
      "messagesAnonymized": 150,
      "matchesAnonymized": 23,
      "reportsAnonymized": 2,
      "dataExported": false
    }
  }
}
```

### Article 7 - Consent Management

#### 1. Record Consent
```http
POST /gdpr/consent
Authorization: Bearer <token>
Content-Type: application/json

{
  "dataProcessing": true,
  "marketing": false,
  "analytics": true,
  "consentedAt": "2024-01-15T10:30:00.000Z"
}
```

#### 2. Get Current Consent
```http
GET /gdpr/consent
Authorization: Bearer <token>
```

#### 3. Get Consent History
```http
GET /gdpr/consent/history
Authorization: Bearer <token>
```

#### 4. Revoke Consent
```http
DELETE /gdpr/consent
Authorization: Bearer <token>
```

## Data Anonymization

When a user account is deleted, the following data is anonymized instead of deleted to preserve system integrity:

1. **Messages**: `senderId` is replaced with `"deleted-user"`
2. **Matches**: `user1Id` and `user2Id` are replaced with `"deleted-user"`
3. **Reports**: `reportedUserId` is replaced with `"deleted-user"`

The following data is permanently deleted:
- User profile
- Push tokens
- Notifications
- Daily selections
- Subscriptions
- User consents
- User record itself

## Export Data Format

The exported data includes:

```json
{
  "exportMetadata": {
    "exportedAt": "ISO date",
    "userId": "uuid",
    "dataCategories": [...]
  },
  "user": { /* sanitized user data */ },
  "profile": { /* profile data */ },
  "matches": [ /* match history */ ],
  "messages": [ /* sent messages */ ],
  "subscriptions": [ /* subscription history */ ],
  "dailySelections": [ /* selection history */ ],
  "consents": [ /* consent history */ ],
  "pushTokens": [ /* registered devices */ ],
  "notifications": [ /* notification history */ ],
  "reports": [ /* reports made by user */ ]
}
```

**Note:** Sensitive data like passwords, tokens, and private keys are excluded from exports.

## Security Considerations

1. **Authentication Required**: All endpoints require JWT authentication
2. **User Isolation**: Users can only access their own data
3. **File Expiration**: Export files expire after 7 days
4. **Asynchronous Processing**: Large data exports are processed asynchronously
5. **Audit Trail**: All GDPR operations are logged for compliance
6. **Data Sanitization**: Sensitive fields are removed before export

## Database Migrations

Two migrations are included:

1. `1700000000001-CreateDataExportRequestsTable.ts`
2. `1700000000002-CreateAccountDeletionsTable.ts`

Run migrations with:
```bash
npm run migration:run
```

## Testing

Comprehensive test suite included:

- **GdprService**: 20+ tests covering all GDPR operations
- **DataExportService**: 10+ tests for export functionality
- **GdprController**: 15+ tests for API endpoints

Run tests with:
```bash
npm test -- --testPathPatterns=gdpr
```

## Production Considerations

For production deployment, consider:

1. **File Storage**: Implement S3 or similar cloud storage for export files
2. **Queue System**: Use Bull/Redis for asynchronous processing
3. **Email Notifications**: Notify users when exports are ready
4. **Rate Limiting**: Limit export requests per user per day
5. **Monitoring**: Track GDPR request volumes and processing times
6. **Backup**: Maintain secure backups of deletion audit trails
7. **PDF Generation**: Implement PDF export using libraries like PDFKit

## Compliance Checklist

- [x] Article 7 - Consent Management with full history
- [x] Article 17 - Account deletion with anonymization
- [x] Article 20 - Complete data export in portable format
- [x] Audit trail for all GDPR operations
- [x] Secure data handling and sanitization
- [x] User authentication and authorization
- [x] Comprehensive test coverage
- [x] Database migrations for new entities
- [x] API documentation

## Future Enhancements

1. **PDF Export**: Implement proper PDF generation for export requests
2. **Automated Cleanup**: Scheduled job to delete expired export files
3. **Multi-language Support**: Localized consent forms and emails
4. **Consent UI**: Admin panel for reviewing consent statistics
5. **Data Retention Policies**: Configurable data retention periods
6. **Batch Operations**: Admin tools for bulk GDPR operations
