# Notification Settings Routes Implementation

## Overview
Implementation of notification settings management routes as specified in TACHES_BACKEND.md (Module 8) and TACHES_FRONTEND.md (Module 6).

## Routes Implemented

### GET /notifications/settings
**Description**: Retrieve notification settings for the authenticated user  
**Authentication**: Required (JWT Bearer token)  
**Method**: GET  
**Path**: `/notifications/settings`

**Response Format**:
```json
{
  "success": true,
  "settings": {
    "dailySelection": true,
    "newMatches": true,
    "newMessages": true,
    "chatExpiring": true,
    "subscriptionUpdates": true,
    "pushNotifications": true,
    "emailNotifications": true,
    "marketingEmails": false
  }
}
```

**Behavior**:
- Returns existing notification preferences if they exist
- Creates and returns default preferences for new users
- All notification types are enabled by default except `marketingEmails`
- Returns 404 if user does not exist

**Example Request**:
```bash
curl -X GET http://localhost:3000/notifications/settings \
  -H "Authorization: Bearer <jwt-token>"
```

---

### PUT /notifications/settings
**Description**: Update notification settings for the authenticated user  
**Authentication**: Required (JWT Bearer token)  
**Method**: PUT  
**Path**: `/notifications/settings`

**Request Body** (all fields optional):
```json
{
  "dailySelection": false,
  "newMatches": false,
  "newMessages": false,
  "chatExpiring": false,
  "subscriptionUpdates": false,
  "pushNotifications": false,
  "emailNotifications": false,
  "marketingEmails": false
}
```

**Response Format**:
```json
{
  "success": true,
  "data": {
    "message": "Notification settings updated successfully",
    "settings": {
      "dailySelection": false,
      "newMatches": false
    }
  }
}
```

**Behavior**:
- Supports partial updates (only send fields you want to change)
- Creates new preferences if none exist
- Updates existing preferences with provided values
- All fields are optional boolean values
- Returns 404 if user does not exist
- Returns 400 for validation errors (non-boolean values)

**Example Requests**:

1. Update all four core notification types:
```bash
curl -X PUT http://localhost:3000/notifications/settings \
  -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "dailySelection": false,
    "newMatches": false,
    "newMessages": false,
    "chatExpiring": false
  }'
```

2. Partial update (only daily selection):
```bash
curl -X PUT http://localhost:3000/notifications/settings \
  -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "dailySelection": false
  }'
```

3. Enable all notifications:
```bash
curl -X PUT http://localhost:3000/notifications/settings \
  -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "dailySelection": true,
    "newMatches": true,
    "newMessages": true,
    "chatExpiring": true
  }'
```

---

## Core Notification Types

The four core notification types as specified in requirements:

1. **dailySelection**: Daily selection notifications (sent at noon)
   - "Votre sélection GoldWen du jour est arrivée !"

2. **newMatches**: New match notifications
   - "Félicitations ! Nouveau match avec [Prénom]"

3. **newMessages**: New message notifications
   - "[Prénom] vous a envoyé un message"

4. **chatExpiring**: Chat expiring soon notifications
   - Notify user when a chat is about to expire

## Additional Notification Types

The implementation also supports additional notification preferences:

5. **subscriptionUpdates**: Subscription-related notifications
6. **pushNotifications**: Global push notification toggle
7. **emailNotifications**: Global email notification toggle
8. **marketingEmails**: Marketing emails (disabled by default)

---

## Database Schema

### NotificationPreferences Entity
```typescript
@Entity('notification_preferences')
export class NotificationPreferences {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @Index({ unique: true })
  userId: string;

  @Column({ default: true })
  dailySelection: boolean;

  @Column({ default: true })
  newMatches: boolean;

  @Column({ default: true })
  newMessages: boolean;

  @Column({ default: true })
  chatExpiring: boolean;

  @Column({ default: true })
  subscriptionUpdates: boolean;

  @Column({ default: false })
  marketingEmails: boolean;

  @Column({ default: true })
  pushNotifications: boolean;

  @Column({ default: true })
  emailNotifications: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToOne(() => User, (user) => user.notificationPreferences)
  @JoinColumn()
  user: User;
}
```

---

## Implementation Details

### Service Methods

**getNotificationSettings(userId: string)**
- Validates user exists
- Retrieves existing preferences or creates defaults
- Logs action for audit trail
- Returns all 8 preference fields

**updateNotificationSettings(userId: string, updateDto: UpdateNotificationSettingsDto)**
- Validates user exists
- Creates new preferences if none exist
- Uses `Object.assign()` to update existing preferences
- Saves updated preferences to database
- Logs action for audit trail
- Returns success message and updated fields

### Validation

The `UpdateNotificationSettingsDto` uses class-validator decorators:
```typescript
export class UpdateNotificationSettingsDto {
  @ApiPropertyOptional({ description: 'Enable daily selection notifications' })
  @IsOptional()
  @IsBoolean()
  dailySelection?: boolean;

  // ... similar for all 8 fields
}
```

---

## Test Coverage

### Unit Tests (notifications.service.spec.ts)
- ✅ Get existing notification preferences
- ✅ Create default preferences for new users
- ✅ Update existing notification preferences
- ✅ Create new preferences if none exist
- ✅ Update only the four core notification types
- ✅ Handle partial updates correctly
- ✅ Throw NotFoundException if user does not exist

### Integration Tests (notification-settings.integration.spec.ts)
- ✅ GET /notifications/settings returns existing settings
- ✅ GET /notifications/settings creates defaults for new users
- ✅ GET /notifications/settings returns 404 for non-existent users
- ✅ PUT /notifications/settings updates all four core types
- ✅ PUT /notifications/settings handles partial updates
- ✅ PUT /notifications/settings enables all notification types
- ✅ PUT /notifications/settings creates preferences if none exist
- ✅ PUT /notifications/settings returns 404 for non-existent users
- ✅ PUT /notifications/settings validates boolean types
- ✅ PUT /notifications/settings accepts empty updates
- ✅ Complete GET → PUT → GET workflow validation

**Total Tests**: 25 tests (14 unit + 11 integration)  
**Test Status**: ✅ All passing

---

## Error Handling

### Common Error Responses

**404 Not Found** (User does not exist):
```json
{
  "statusCode": 404,
  "message": "User not found",
  "error": "Not Found"
}
```

**400 Bad Request** (Invalid input):
```json
{
  "statusCode": 400,
  "message": [
    "dailySelection must be a boolean value",
    "newMatches must be a boolean value"
  ],
  "error": "Bad Request"
}
```

**401 Unauthorized** (Missing or invalid token):
```json
{
  "statusCode": 401,
  "message": "Unauthorized"
}
```

---

## Security

- All routes require JWT authentication via `@UseGuards(JwtAuthGuard)`
- User ID is extracted from JWT token, preventing unauthorized access
- Settings can only be viewed/modified by the authenticated user
- All actions are logged for audit trail

---

## Performance Considerations

- Database queries use indexed `userId` field for fast lookups
- Default preferences are created on first access (lazy initialization)
- Updates use `Object.assign()` for efficient partial updates
- No N+1 query issues

---

## Frontend Integration

The routes are ready to be integrated with the frontend as specified in TACHES_FRONTEND.md:

```typescript
// Get notification settings
GET /api/v1/notifications/settings
Authorization: Bearer <token>

// Update notification settings
PUT /api/v1/notifications/settings
Authorization: Bearer <token>
Body: {
  "dailySelection": boolean,
  "newMatches": boolean,
  "newMessages": boolean,
  "chatExpiring": boolean
}
```

---

## Files Modified/Created

### Modified Files:
1. `main-api/src/modules/notifications/notifications.service.spec.ts`
   - Added 5 new unit tests for `updateNotificationSettings`
   - Enhanced test coverage for notification settings

### Created Files:
1. `main-api/src/modules/notifications/tests/notification-settings.integration.spec.ts`
   - 11 comprehensive integration tests
   - Tests all success and error scenarios
   - Validates complete workflow

2. `main-api/docs/NOTIFICATION_SETTINGS_ROUTES.md` (this file)
   - Complete API documentation
   - Usage examples
   - Implementation details

### Existing Files (No Changes Required):
- `main-api/src/modules/notifications/notifications.controller.ts` - Routes already implemented
- `main-api/src/modules/notifications/notifications.service.ts` - Service methods already implemented
- `main-api/src/modules/notifications/dto/notifications.dto.ts` - DTOs already defined
- `main-api/src/database/entities/notification-preferences.entity.ts` - Entity already defined

---

## Acceptance Criteria ✅

All requirements from TACHES_BACKEND.md Module 8 have been met:

- ✅ GET /notifications/settings route implemented
- ✅ PUT /notifications/settings route implemented
- ✅ All four core notification types supported (dailySelection, newMatches, newMessages, chatExpiring)
- ✅ User can enable/disable each notification type individually
- ✅ Paramètres de notifications personnalisables
- ✅ Sauvegarde et récupération fonctionnelles
- ✅ Respect des préférences lors de l'envoi de notifications (implemented in `shouldSendNotification()`)
- ✅ Comprehensive unit and integration tests
- ✅ Clean code following SOLID principles
- ✅ Proper error handling and validation
- ✅ Security with JWT authentication
- ✅ Complete documentation

---

## Next Steps

The notification settings routes are fully implemented and tested. The next steps for the notification system would be:

1. Ensure the notification sending logic respects user preferences (already implemented via `shouldSendNotification()`)
2. Test the integration with the frontend mobile app
3. Monitor and log notification delivery success rates
4. Consider adding analytics to track which notification types users prefer

---

## Support

For questions or issues related to notification settings:
- Check the service logs for detailed error messages
- Verify JWT token is valid and user exists
- Ensure request body contains valid boolean values
- Review test files for usage examples
