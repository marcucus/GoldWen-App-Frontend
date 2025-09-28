import { Injectable, LoggerService } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createLogger, Logger, transports, format } from 'winston';
import { v4 as uuidv4 } from 'uuid';

export interface LogContext {
  traceId?: string;
  userId?: string;
  userEmail?: string;
  action?: string;
  resource?: string;
  ipAddress?: string;
  userAgent?: string;
  method?: string;
  url?: string;
  statusCode?: number;
  responseTime?: number;
  error?: Error;
}

@Injectable()
export class CustomLoggerService implements LoggerService {
  private logger: Logger;
  private context: LogContext = {};

  constructor(private configService: ConfigService) {
    this.createLogger();
  }

  private createLogger() {
    const env = this.configService.get('app.environment') || 'development';
    const logLevel = this.configService.get('app.logLevel') || 'info';

    const isProduction = env === 'production';

    // Production format: structured JSON
    const productionFormat = format.combine(
      format.timestamp(),
      format.errors({ stack: true }),
      format.json(),
      format.printf(({ timestamp, level, message, ...meta }) => {
        return JSON.stringify({
          timestamp,
          level,
          message,
          service: 'goldwen-api',
          environment: env,
          ...this.context,
          ...meta,
        });
      }),
    );

    // Development format: readable console output
    const developmentFormat = format.combine(
      format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
      format.errors({ stack: true }),
      format.colorize(),
      format.printf(({ timestamp, level, message, ...meta }) => {
        const traceId = this.context.traceId ? `[${this.context.traceId}]` : '';
        const contextStr = this.context.userId
          ? `[User: ${this.context.userId}]`
          : '';
        const metaStr = Object.keys(meta).length
          ? JSON.stringify(meta, null, 2)
          : '';

        return `${timestamp} ${level} ${traceId}${contextStr}: ${message} ${metaStr}`;
      }),
    );

    this.logger = createLogger({
      level: logLevel,
      format: isProduction ? productionFormat : developmentFormat,
      transports: [
        new transports.Console(),
        // In production, you might want to add file transports or external services
        ...(isProduction
          ? [
              new transports.File({
                filename: 'logs/error.log',
                level: 'error',
                maxsize: 5242880, // 5MB
                maxFiles: 5,
              }),
              new transports.File({
                filename: 'logs/combined.log',
                maxsize: 5242880, // 5MB
                maxFiles: 5,
              }),
            ]
          : []),
      ],
    });
  }

  // Set context for correlation
  setContext(context: Partial<LogContext>) {
    this.context = { ...this.context, ...context };
  }

  // Generate and set trace ID
  generateTraceId(): string {
    const traceId = uuidv4();
    this.setContext({ traceId });
    return traceId;
  }

  // Clear context (useful for request cleanup)
  clearContext() {
    this.context = {};
  }

  // Standard NestJS logger interface
  log(message: string, context?: string) {
    this.info(message, { context });
  }

  error(message: string, trace?: string, context?: string) {
    this.logger.error(message, {
      context,
      stack: trace,
      ...this.context,
    });
  }

  warn(message: string, context?: string) {
    this.logger.warn(message, {
      context,
      ...this.context,
    });
  }

  debug(message: string, context?: string) {
    this.logger.debug(message, {
      context,
      ...this.context,
    });
  }

  verbose(message: string, context?: string) {
    this.logger.verbose(message, {
      context,
      ...this.context,
    });
  }

  // Custom methods for structured logging
  info(message: string, meta?: any) {
    this.logger.info(message, {
      ...meta,
      ...this.context,
    });
  }

  // HTTP request logging
  logRequest(req: any, res: any, responseTime?: number) {
    const { method, originalUrl, ip, headers } = req;
    const { statusCode } = res;

    this.info('HTTP Request', {
      method,
      url: originalUrl,
      statusCode,
      responseTime: responseTime ? `${responseTime}ms` : undefined,
      ipAddress: ip,
      userAgent: headers['user-agent'],
      action: 'http_request',
    });
  }

  // Business logic logging
  logBusinessEvent(event: string, details: any) {
    this.info(`Business event: ${event}`, {
      action: 'business_event',
      event,
      ...details,
    });
  }

  // Database operation logging
  logDatabaseOperation(operation: string, table: string, meta?: any) {
    this.debug(`Database ${operation} on ${table}`, {
      action: 'database_operation',
      operation,
      table,
      ...meta,
    });
  }

  // External API call logging
  logExternalApiCall(
    service: string,
    endpoint: string,
    method: string,
    responseTime?: number,
    statusCode?: number,
  ) {
    this.info(`External API call to ${service}`, {
      action: 'external_api_call',
      service,
      endpoint,
      method,
      responseTime: responseTime ? `${responseTime}ms` : undefined,
      statusCode,
    });
  }

  // Security event logging
  logSecurityEvent(
    event: string,
    details: any,
    level: 'info' | 'warn' | 'error' = 'warn',
  ) {
    const logData = {
      action: 'security_event',
      event,
      timestamp: new Date().toISOString(),
      traceId: this.context.traceId,
      userId: this.context.userId,
      ipAddress: this.context.ipAddress,
      userAgent: this.context.userAgent,
      ...details,
    };

    switch (level) {
      case 'error':
        this.error(`Security event: ${event}`, undefined, 'SecurityLogger');
        this.info('Security event details', logData);
        break;
      case 'warn':
        this.warn(`Security event: ${event}`, 'SecurityLogger');
        this.info('Security event details', logData);
        break;
      default:
        this.info(`Security event: ${event}`, logData);
    }
  }

  // Audit trail logging for GDPR compliance
  logAuditTrail(action: string, resource: string, details: any) {
    this.info(`Audit: ${action} on ${resource}`, {
      action: 'audit_trail',
      auditAction: action,
      resource,
      timestamp: new Date().toISOString(),
      userId: this.context.userId,
      traceId: this.context.traceId,
      ...details,
    });
  }

  // Performance monitoring
  logPerformanceMetric(
    metric: string,
    value: number,
    unit: string,
    metadata?: any,
  ) {
    this.info(`Performance metric: ${metric}`, {
      action: 'performance_metric',
      metric,
      value,
      unit,
      timestamp: new Date().toISOString(),
      ...metadata,
    });
  }

  // User action logging for analytics
  logUserAction(action: string, details: any) {
    this.info(`User action: ${action}`, {
      action: 'user_action',
      userAction: action,
      userId: this.context.userId,
      timestamp: new Date().toISOString(),
      traceId: this.context.traceId,
      ...details,
    });
  }
}
