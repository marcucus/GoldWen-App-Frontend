# Email Module Documentation

## Overview

The Email Module provides transactional email functionality for the GoldWen application. It supports both SMTP (e.g., Gmail) and SendGrid as email providers with comprehensive error handling and logging.

## Features

- **Multiple Provider Support**: Choose between SMTP or SendGrid
- **Transactional Emails**:
  - Welcome email (when user registers)
  - Password reset email
  - Data export ready notification
  - Account deleted confirmation
  - Subscription confirmed notification
- **Robust Error Handling**: Graceful degradation with detailed logging
- **Email Masking**: Privacy-focused logging that masks email addresses
- **Beautiful HTML Templates**: Responsive email templates with GoldWen branding

## Configuration

### Environment Variables

```bash
# Email provider: 'smtp' (default) or 'sendgrid'
EMAIL_PROVIDER=smtp
EMAIL_FROM=noreply@goldwen.com

# Option 1: SMTP Configuration (e.g., Gmail)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-16-character-app-password

# Option 2: SendGrid Configuration (recommended for production)
SENDGRID_API_KEY=SG.your-sendgrid-api-key
```

### Gmail SMTP Setup

For Gmail users:
1. Enable 2-Factor Authentication on your Gmail account
2. Go to https://myaccount.google.com/apppasswords
3. Generate an App Password for "Mail"
4. Use the 16-character App Password as `EMAIL_PASSWORD`

### SendGrid Setup

For SendGrid (recommended for production):
1. Create a SendGrid account at https://sendgrid.com
2. Generate an API key at https://app.sendgrid.com/settings/api_keys
3. Set `EMAIL_PROVIDER=sendgrid`
4. Set `SENDGRID_API_KEY` to your API key

## Usage

### In Your Module

Import the EmailModule in your feature module:

```typescript
import { EmailModule } from '../email/email.module';

@Module({
  imports: [EmailModule],
  // ...
})
export class YourModule {}
```

### In Your Service

Inject the EmailService:

```typescript
import { EmailService } from '../email/email.service';

@Injectable()
export class YourService {
  constructor(private emailService: EmailService) {}

  async sendWelcome() {
    await this.emailService.sendWelcomeEmail(
      'user@example.com',
      'John'
    );
  }

  async sendPasswordReset() {
    await this.emailService.sendPasswordResetEmail(
      'user@example.com',
      'reset-token-123'
    );
  }

  async sendDataExportReady() {
    await this.emailService.sendDataExportReadyEmail(
      'user@example.com',
      'John',
      'https://example.com/download/data.zip'
    );
  }

  async sendAccountDeleted() {
    await this.emailService.sendAccountDeletedEmail(
      'user@example.com',
      'John'
    );
  }

  async sendSubscriptionConfirmed() {
    await this.emailService.sendSubscriptionConfirmedEmail(
      'user@example.com',
      'John',
      'GoldWen Plus',
      new Date('2025-12-31')
    );
  }
}
```

## Email Types

### 1. Welcome Email
- **Method**: `sendWelcomeEmail(email: string, firstName: string)`
- **When**: User completes registration
- **Critical**: No (errors are logged but not thrown)

### 2. Password Reset Email
- **Method**: `sendPasswordResetEmail(email: string, resetToken: string)`
- **When**: User requests password reset
- **Critical**: Yes (errors are thrown)

### 3. Data Export Ready Email
- **Method**: `sendDataExportReadyEmail(email: string, firstName: string, downloadUrl: string)`
- **When**: User's data export is ready for download
- **Critical**: Yes (errors are thrown)

### 4. Account Deleted Email
- **Method**: `sendAccountDeletedEmail(email: string, firstName: string)`
- **When**: User's account has been deleted
- **Critical**: No (errors are logged but not thrown)

### 5. Subscription Confirmed Email
- **Method**: `sendSubscriptionConfirmedEmail(email: string, firstName: string, subscriptionType: string, expiryDate: Date)`
- **When**: User's subscription is confirmed or renewed
- **Critical**: No (errors are logged but not thrown)
- **Subscription Types**: 'GoldWen Plus', 'GoldWen Premium'

## Error Handling

The email service implements different error handling strategies based on email criticality:

- **Critical emails** (password reset, data export): Errors are thrown and must be handled by the caller
- **Non-critical emails** (welcome, account deleted, subscription): Errors are logged but not thrown to prevent blocking user flows

All errors are logged with:
- Masked email addresses for privacy
- Error details and stack traces
- Provider information (SMTP or SendGrid)

## Testing

The module includes comprehensive unit tests:

```bash
# Run email service tests
npm test -- modules/email/email.service.spec.ts

# Run all email-related tests
npm test -- email.service
```

## Architecture

```
src/modules/email/
├── email.module.ts       # NestJS module definition
├── email.service.ts      # Email service with SendGrid/SMTP support
├── email.service.spec.ts # Unit tests
└── index.ts              # Module exports
```

## Migration from Common Email Service

The old `common/email.service.ts` is still available for backward compatibility. New features should use the email module from `modules/email/`.

To migrate:
1. Replace `import { EmailService } from '../../common/email.service';`
2. With `import { EmailService } from '../email/email.service';`
3. Import EmailModule instead of providing EmailService directly

## Best Practices

1. **Use SendGrid in production**: More reliable than SMTP for high-volume emails
2. **Handle critical email failures**: Implement retry logic or alternative notification methods
3. **Monitor email delivery**: Track email sending success/failure in your monitoring system
4. **Test email templates**: Use tools like Litmus or Email on Acid to test across email clients
5. **Respect user preferences**: Check if user has opted out of specific email types

## Troubleshooting

### Gmail SMTP Errors

If you see "Username and Password not accepted":
- Ensure 2FA is enabled
- Use an App Password, not your regular password
- Check that "Less secure app access" is disabled (you should use App Passwords instead)

### SendGrid Errors

If you see SendGrid API errors:
- Verify your API key is correct
- Check your SendGrid account status
- Ensure you have sufficient sending quota
- Verify the sender email is authenticated in SendGrid

### Emails Not Sending

1. Check configuration: `EMAIL_PROVIDER`, `EMAIL_FROM`, and provider-specific settings
2. Review logs for initialization messages
3. Verify network connectivity to email provider
4. Check spam folders for test emails

## License

Copyright © 2025 GoldWen. All rights reserved.
