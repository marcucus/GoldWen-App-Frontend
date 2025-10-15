# Data Export Feature - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Flutter)                           │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Settings Page                                               │   │
│  │  ┌─────────────────────────────────────────────────────┐   │   │
│  │  │  [Download My Data Button]                          │   │   │
│  │  └─────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                ↓                                      │
│                    POST /users/me/export-data                        │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         BACKEND (NestJS)                             │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  UsersController                                             │   │
│  │  @Post('me/export-data')                                    │   │
│  │  ┌─────────────────────────────────────────────────────┐   │   │
│  │  │  1. Authenticate user (JWT)                         │   │   │
│  │  │  2. Call gdprService.requestDataExport()            │   │   │
│  │  │  3. Return: { exportId, status: 'processing' }      │   │   │
│  │  └─────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                ↓                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  GdprService (from gdpr module)                              │   │
│  │  - Creates DataExportRequest entity                         │   │
│  │  - Triggers async processing                                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                ↓                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  DataExportService (Background Process)                      │   │
│  │  ┌─────────────────────────────────────────────────────┐   │   │
│  │  │  1. Update status to 'processing'                   │   │   │
│  │  │  2. Collect data from all entities:                 │   │   │
│  │  │     - User, Profile, Matches, Messages              │   │   │
│  │  │     - Subscriptions, DailySelections                │   │   │
│  │  │     - Consents, PushTokens, Notifications           │   │   │
│  │  │     - Reports                                        │   │   │
│  │  │  3. Sanitize sensitive data                         │   │   │
│  │  │  4. Generate JSON file                              │   │   │
│  │  │  5. Store file (base64/URL)                         │   │   │
│  │  │  6. Update status to 'completed'                    │   │   │
│  │  │  7. Set expiration (7 days)                         │   │   │
│  │  └─────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Flutter)                           │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Polling Loop (every 5-10 seconds)                          │   │
│  │  GET /users/me/export-data/:exportId                        │   │
│  │  ┌─────────────────────────────────────────────────────┐   │   │
│  │  │  If status = "processing": Show spinner              │   │   │
│  │  │  If status = "ready": Show download button           │   │   │
│  │  │  If status = "failed": Show error message            │   │   │
│  │  └─────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         BACKEND (NestJS)                             │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  UsersController                                             │   │
│  │  @Get('me/export-data/:exportId')                           │   │
│  │  ┌─────────────────────────────────────────────────────┐   │   │
│  │  │  1. Authenticate user (JWT)                         │   │   │
│  │  │  2. Get export request from DB                      │   │   │
│  │  │  3. Verify user owns this export                    │   │   │
│  │  │  4. Map status: completed → 'ready'                 │   │   │
│  │  │  5. Return: { status, downloadUrl, expiresAt }      │   │   │
│  │  └─────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Flutter)                           │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Download Complete                                           │   │
│  │  ┌─────────────────────────────────────────────────────┐   │   │
│  │  │  User receives JSON file with all personal data     │   │   │
│  │  │  ✅ GDPR Compliant Export                            │   │   │
│  │  └─────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════
                         DATABASE SCHEMA
═══════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  data_export_requests                                            │
├─────────────────────────────────────────────────────────────────┤
│  id              UUID        PRIMARY KEY                         │
│  userId          VARCHAR     FOREIGN KEY → users.id              │
│  format          ENUM        'json' | 'pdf'                      │
│  status          ENUM        'pending' | 'processing' |          │
│                              'completed' | 'failed'              │
│  fileUrl         TEXT        Download URL (nullable)             │
│  errorMessage    TEXT        Error details (nullable)            │
│  completedAt     TIMESTAMP   Completion time (nullable)          │
│  expiresAt       TIMESTAMP   Expiration time (7 days)            │
│  createdAt       TIMESTAMP   Request creation time               │
│  updatedAt       TIMESTAMP   Last update time                    │
└─────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════
                         SECURITY MEASURES
═══════════════════════════════════════════════════════════════════════

✅ JWT Authentication     - All routes require valid JWT token
✅ User Authorization      - Users can only access their own exports
✅ Data Sanitization       - Passwords and tokens excluded from export
✅ Automatic Expiration    - Exports expire after 7 days
✅ Audit Trail            - All requests logged in database
✅ SQL Injection Safe     - TypeORM parameterized queries
✅ Rate Limiting (TODO)   - Consider adding rate limit (1 req/day)

═══════════════════════════════════════════════════════════════════════
                         RGPD COMPLIANCE
═══════════════════════════════════════════════════════════════════════

✅ Art. 20 - Data Portability
   → Complete data export in machine-readable format (JSON)
   → User can transfer data to another service

✅ Art. 15 - Right of Access
   → User can view all their personal data
   → Data categories clearly identified

✅ Art. 5(1)(f) - Security
   → Authentication and authorization enforced
   → Sensitive data sanitized
   → Automatic expiration

✅ Art. 30 - Records of Processing
   → Export requests logged with timestamps
   → Audit trail for compliance reporting
```
