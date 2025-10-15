# GoldWen Backend - Monitoring, Logging & Alerting Documentation

## Overview

This document describes the comprehensive monitoring, logging, and alerting system implemented for the GoldWen Dating App Backend to ensure GDPR compliance, security monitoring, and operational excellence.

## Architecture

### Components

1. **Structured Logging** - Winston-based logging with correlation IDs
2. **Error Tracking** - Sentry integration for error monitoring and performance tracking
3. **Metrics & Analytics** - DataDog integration for system and business metrics
4. **Health Monitoring** - Real-time health checks for database and Redis
5. **Security Logging** - Comprehensive security event tracking
6. **Alerting System** - Multi-channel alerting (Slack, webhooks, email)
7. **Admin Dashboard** - Web-based monitoring dashboard

## Configuration

### Environment Variables

```bash
# Sentry Configuration
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
SENTRY_TRACES_SAMPLE_RATE=0.1      # 10% of transactions
SENTRY_PROFILES_SAMPLE_RATE=0.01   # 1% profiling

# DataDog Configuration (optional)
DATADOG_API_KEY=your-datadog-api-key
DATADOG_APP_KEY=your-datadog-app-key

# Alerting Channels
ALERTS_WEBHOOK_URL=https://your-webhook-url.com/alerts
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
ALERT_EMAIL_RECIPIENTS=admin@goldwen.com,dev@goldwen.com

# Logging
LOG_LEVEL=info                      # debug, info, warn, error
```

## Logging

### Log Structure

All logs are structured in JSON format with the following fields:

```json
{
  "timestamp": "2025-01-XX:XX:XX.XXX:XX:XXZ",
  "level": "info",
  "message": "Request processed",
  "traceId": "uuid-trace-id",
  "userId": "user-uuid",
  "ipAddress": "xxx.xxx.xxx.xxx",
  "userAgent": "Mozilla/5.0...",
  "action": "http_request",
  "metadata": {
    "method": "POST",
    "url": "/api/v1/auth/login",
    "statusCode": 200,
    "duration": "150ms"
  }
}
```

### Log Categories

#### 1. HTTP Request Logs
- All incoming requests and responses
- Response times and status codes
- User agent and IP address tracking

#### 2. Security Event Logs
```typescript
logger.logSecurityEvent('auth_failed', {
  reason: 'invalid_credentials',
  attempts: 3
}, 'warn');
```

#### 3. Business Event Logs
```typescript
logger.logBusinessEvent('user_registered', {
  userId: 'uuid',
  method: 'email'
});
```

#### 4. Audit Trail Logs (GDPR Compliance)
```typescript
logger.logAuditTrail('user_data_deleted', 'user_profile', {
  userId: 'uuid',
  deletedFields: ['email', 'photos']
});
```

#### 5. Performance Metrics
```typescript
logger.logPerformanceMetric('api_response_time', 150, 'ms', {
  endpoint: '/api/v1/profiles'
});
```

### Log Retention

- **Development**: Console output with readable format
- **Production**: JSON format with file rotation
  - Error logs: 30 days retention
  - Info logs: 7 days retention
  - Audit logs: 5 years retention (GDPR requirement)

## Error Tracking (Sentry)

### Features
- Automatic error capture and reporting
- Performance monitoring with APM
- Release tracking and deployment monitoring
- User context and custom tags
- Sensitive data filtering

### Custom Error Tracking
```typescript
// Capture exceptions
sentry.captureException(error, {
  user: { id: userId },
  extra: { context: 'payment_processing' }
});

// Add breadcrumbs
sentry.addBreadcrumb('User clicked payment button', 'user_action');
```

## Metrics & Analytics (DataDog)

### Features
- System metrics collection (CPU, memory, disk)
- Business metrics tracking (user signups, matches, etc.)
- API performance monitoring
- Custom dashboards and alerting
- Real-time monitoring

### Configuration
DataDog integration is optional and can be enabled by setting:
- `DATADOG_API_KEY`: Your DataDog API key
- `DATADOG_APP_KEY`: Your DataDog application key

### Custom Metrics
```typescript
// Send gauge metrics
await datadog.sendGaugeMetric('goldwen.users.active', activeUserCount);

// Track business events
await datadog.trackBusinessMetrics('user_signup', 1, ['source:mobile']);

// Monitor API performance
await datadog.trackApiMetrics('/api/profiles', 'GET', responseTime, 200);
```

### Available Metrics
1. **System Metrics**
   - `goldwen.system.memory.heap_used`
   - `goldwen.system.memory.heap_total`
   - `goldwen.system.uptime`

2. **API Metrics**
   - `goldwen.api.response_time`
   - `goldwen.api.requests`

3. **Business Metrics**
   - `goldwen.business.user_signup`
   - `goldwen.business.matches_created`
   - `goldwen.business.messages_sent`

## Health Monitoring

### Health Check Endpoint

```
GET /api/v1/health
```

Response includes:
- Overall system status
- Database connectivity and response time
- Redis connectivity and response time
- Memory usage statistics
- System information

### Example Response
```json
{
  "status": "healthy",
  "timestamp": "2025-01-XX:XX:XX.XXX:XX:XXZ",
  "uptime": 3600,
  "services": {
    "database": {
      "status": "healthy",
      "responseTime": 25
    },
    "cache": {
      "status": "healthy", 
      "responseTime": 5
    }
  },
  "memory": {
    "used": 128,
    "total": 512,
    "percentage": 25
  }
}
```

## Security Monitoring

### Monitored Events

1. **Authentication Events**
   - Login attempts (success/failure)
   - Password reset requests
   - Account lockouts

2. **Authorization Events**
   - Admin panel access attempts
   - Unauthorized API calls
   - Role escalation attempts

3. **Suspicious Activity**
   - SQL injection attempts
   - XSS attack patterns
   - Path traversal attempts
   - Unusual request patterns

4. **Data Access Events**
   - Personal data access
   - Profile modifications
   - Data export requests

### Automatic Threat Detection

The security middleware automatically detects:
- Malicious input patterns
- Brute force attacks
- Unusual request sizes
- Suspicious user agents

## Alerting System

### Alert Levels

1. **Critical** - Immediate attention required
   - System down
   - Security breaches
   - Data corruption

2. **Warning** - Attention needed
   - High error rates
   - Performance degradation
   - Suspicious activity

3. **Info** - Informational
   - Deployment notifications
   - Usage milestones

### Alert Channels

#### Slack Integration
Formatted messages with:
- Color-coded severity levels
- Contextual information
- Direct links to logs

#### Webhook Integration
JSON payload sent to configured webhook URL:
```json
{
  "level": "critical",
  "title": "Database Connection Failed",
  "message": "Unable to connect to PostgreSQL database",
  "service": "GoldWen-API",
  "environment": "production",
  "timestamp": "2025-01-XX:XX:XX.XXX:XX:XXZ",
  "metadata": {
    "error": "connection timeout",
    "retries": 3
  }
}
```

## Admin Dashboard

### Endpoints

- `GET /admin/monitoring/dashboard` - Overview dashboard
- `GET /admin/monitoring/metrics` - System metrics
- `GET /admin/monitoring/logs` - Recent logs with filtering
- `GET /admin/monitoring/alerts` - Recent alerts
- `GET /admin/monitoring/performance` - Performance metrics

### Access Control

- Requires admin authentication
- Role-based access (Admin, Moderator)
- All access attempts are logged

## GDPR Compliance

### Data Protection Measures

1. **Data Minimization**
   - Only necessary data is logged
   - Sensitive data is filtered from logs

2. **Access Logging**
   - All personal data access is logged
   - Audit trail for data modifications

3. **Data Retention**
   - Automatic log cleanup based on retention policies
   - Long-term storage for audit logs

4. **Data Export**
   - Audit logs can be exported for compliance
   - User consent tracking

### Sensitive Data Filtering

Automatically filters sensitive fields:
- Passwords and tokens
- Credit card information
- Personal identifiers (SSN, phone numbers)
- Email addresses in error contexts

## Performance Monitoring

### Metrics Tracked

1. **Response Times**
   - API endpoint performance
   - Database query times
   - External service calls

2. **Throughput**
   - Requests per minute
   - Peak load handling
   - Queue processing rates

3. **Resource Usage**
   - Memory consumption
   - CPU utilization
   - Database connections

4. **Business Metrics**
   - User registrations
   - Match success rates
   - Message delivery rates

## Deployment and Maintenance

### Setup Instructions

1. Configure environment variables
2. Set up Sentry project and obtain DSN
3. Configure Slack webhook (optional)
4. Set log retention policies
5. Test alerting channels

### Regular Maintenance

- Monitor log file sizes and cleanup
- Review and update alert thresholds
- Analyze performance trends
- Update security monitoring rules

### Troubleshooting

#### Common Issues

1. **Sentry not receiving errors**
   - Check SENTRY_DSN configuration
   - Verify network connectivity
   - Check sample rates

2. **Alerts not being sent**
   - Verify webhook URLs
   - Check Slack integration
   - Review alert service logs

3. **High log volume**
   - Adjust log levels
   - Implement sampling for high-frequency events
   - Review retention policies

## Security Considerations

1. **Log Security**
   - Logs contain no sensitive data
   - Access to logs is restricted
   - Log integrity monitoring

2. **Monitoring Access**
   - Admin dashboard requires authentication
   - API endpoints are rate-limited
   - All monitoring access is logged

3. **Data Transmission**
   - All alerts use HTTPS
   - Webhook payloads are signed
   - Sentry data is encrypted in transit

## Compliance and Auditing

### GDPR Requirements Met

- ✅ Data processing transparency
- ✅ Audit trail maintenance
- ✅ Data retention policies
- ✅ Incident response logging
- ✅ User consent tracking

### Regular Audits

- Monthly log review
- Quarterly security assessment
- Annual compliance review
- Incident response testing

## Future Enhancements

1. **Advanced Analytics**
   - Machine learning for anomaly detection
   - Predictive alerting
   - User behavior analysis

2. **Integration Improvements**
   - DataDog integration option
   - ELK stack compatibility
   - Grafana dashboard support

3. **Enhanced Security**
   - Real-time threat detection
   - Automated response mechanisms
   - Advanced user behavior analytics