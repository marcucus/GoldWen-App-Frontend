import { registerAs } from '@nestjs/config';
import {
  DatabaseConfig,
  RedisConfig,
  JwtConfig,
  AppConfig,
  OAuthConfig,
  FileUploadConfig,
  NotificationConfig,
  EmailConfig,
  MatchingServiceConfig,
  RevenueCatConfig,
  MonitoringConfig,
} from './config.interface';

export const databaseConfig = registerAs(
  'database',
  (): DatabaseConfig => ({
    host: process.env.DATABASE_HOST || 'localhost',
    port: parseInt(process.env.DATABASE_PORT || '5432', 10),
    username: process.env.DATABASE_USERNAME || 'goldwen',
    password: process.env.DATABASE_PASSWORD || 'goldwen_password',
    database: process.env.DATABASE_NAME || 'goldwen_db',
  }),
);

export const redisConfig = registerAs(
  'redis',
  (): RedisConfig => ({
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD || undefined,
  }),
);

export const jwtConfig = registerAs(
  'jwt',
  (): JwtConfig => ({
    secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key',
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  }),
);

export const appConfig = registerAs(
  'app',
  (): AppConfig => ({
    port: parseInt(process.env.PORT || '3000', 10),
    environment: process.env.NODE_ENV || 'development',
    apiPrefix: process.env.API_PREFIX || 'api/v1',
    logLevel: process.env.LOG_LEVEL || 'info',
    frontendUrl: process.env.FRONTEND_URL || 'http://localhost:3001',
  }),
);

export const oauthConfig = registerAs(
  'oauth',
  (): OAuthConfig => ({
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID || '',
      clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
    },
    apple: {
      clientId: process.env.APPLE_CLIENT_ID || '',
      teamId: process.env.APPLE_TEAM_ID || '',
      keyId: process.env.APPLE_KEY_ID || '',
      privateKey: process.env.APPLE_PRIVATE_KEY || '',
    },
  }),
);

export const fileUploadConfig = registerAs(
  'fileUpload',
  (): FileUploadConfig => ({
    uploadDir: process.env.UPLOAD_DIR || 'uploads',
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE || '5242880', 10), // 5MB
  }),
);

export const notificationConfig = registerAs(
  'notification',
  (): NotificationConfig => ({
    fcmServerKey: process.env.FCM_SERVER_KEY || '',
  }),
);

export const emailConfig = registerAs(
  'email',
  (): EmailConfig => ({
    from: process.env.EMAIL_FROM || 'noreply@goldwen.com',
    smtp: {
      host: process.env.EMAIL_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.EMAIL_PORT || '587', 10),
      secure: process.env.EMAIL_SECURE === 'true',
      user: process.env.EMAIL_USER || '',
      pass: process.env.EMAIL_PASSWORD || '',
    },
  }),
);

export const matchingServiceConfig = registerAs(
  'matchingService',
  (): MatchingServiceConfig => ({
    url: process.env.MATCHING_SERVICE_URL || 'http://localhost:8000',
  }),
);

export const revenueCatConfig = registerAs(
  'revenueCat',
  (): RevenueCatConfig => ({
    apiKey: process.env.REVENUECAT_API_KEY || '',
  }),
);

export const monitoringConfig = registerAs(
  'monitoring',
  (): MonitoringConfig => ({
    sentry: {
      dsn: process.env.SENTRY_DSN || '',
      environment: process.env.NODE_ENV || 'development',
      tracesSampleRate: parseFloat(
        process.env.SENTRY_TRACES_SAMPLE_RATE || '0.1',
      ),
      profilesSampleRate: parseFloat(
        process.env.SENTRY_PROFILES_SAMPLE_RATE || '0.01',
      ),
    },
    datadog: process.env.DATADOG_API_KEY && process.env.DATADOG_APP_KEY ? {
      apiKey: process.env.DATADOG_API_KEY,
      appKey: process.env.DATADOG_APP_KEY,
    } : undefined,
    alerts: {
      webhookUrl: process.env.ALERTS_WEBHOOK_URL,
      slackWebhookUrl: process.env.SLACK_WEBHOOK_URL,
      emailRecipients: process.env.ALERT_EMAIL_RECIPIENTS
        ? process.env.ALERT_EMAIL_RECIPIENTS.split(',').map((email) =>
            email.trim(),
          )
        : [],
    },
  }),
);
