import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { CustomLoggerService } from '../logger';
import { AlertingService } from '../monitoring';

@Injectable()
export class SecurityLoggingMiddleware implements NestMiddleware {
  constructor(
    private readonly logger: CustomLoggerService,
    private readonly alerting: AlertingService,
  ) {}

  use(req: Request, res: Response, next: NextFunction) {
    const startTime = Date.now();
    const userAgent = req.headers['user-agent'] || 'Unknown';
    const ip = req.ip || req.connection.remoteAddress || 'Unknown';

    // Check for suspicious patterns
    this.checkSuspiciousActivity(req);

    // Log authentication attempts
    if (req.path.includes('/auth/')) {
      this.logger.logSecurityEvent('auth_attempt', {
        path: req.path,
        method: req.method,
        ip,
        userAgent,
      });
    }

    // Log admin access
    if (req.path.includes('/admin/')) {
      this.logger.logSecurityEvent('admin_access_attempt', {
        path: req.path,
        method: req.method,
        ip,
        userAgent,
      });
    }

    // Monitor response for security events
    res.on('finish', () => {
      const duration = Date.now() - startTime;

      // Log failed authentication
      if (req.path.includes('/auth/') && res.statusCode === 401) {
        this.logger.logSecurityEvent(
          'auth_failed',
          {
            path: req.path,
            ip,
            userAgent,
            duration,
          },
          'warn',
        );
      }

      // Log unauthorized admin access
      if (req.path.includes('/admin/') && res.statusCode === 403) {
        this.logger.logSecurityEvent(
          'admin_access_denied',
          {
            path: req.path,
            ip,
            userAgent,
            duration,
          },
          'warn',
        );

        // Send alert for critical admin access attempts
        this.alerting.sendWarningAlert(
          'Unauthorized Admin Access Attempt',
          `Attempt to access admin endpoint ${req.path} from IP ${ip}`,
          { path: req.path, ip, userAgent },
        );
      }

      // Log rate limiting hits
      if (res.statusCode === 429) {
        this.logger.logSecurityEvent(
          'rate_limit_exceeded',
          {
            path: req.path,
            ip,
            userAgent,
          },
          'warn',
        );
      }
    });

    next();
  }

  private checkSuspiciousActivity(req: Request) {
    // Skip security checks in development environment
    if (process.env.NODE_ENV === 'development') {
      return;
    }
    
    const suspiciousPatterns = [
      // SQL injection patterns
      /('|(\\x27)|(\\x2D)|(\\x2C)|(\\x23)|(\\x3B))/gi,
      // XSS patterns
      /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
      // Path traversal patterns
      /\.\.[\/\\]/g,
      // Command injection patterns - exclude {} for JSON
      /[;&|`$()[\]]/g,
    ];

    const userInput =
      JSON.stringify(req.body) + req.url + JSON.stringify(req.query);

    for (const pattern of suspiciousPatterns) {
      if (pattern.test(userInput)) {
        this.logger.logSecurityEvent(
          'suspicious_input_detected',
          {
            pattern: pattern.source,
            path: req.path,
            method: req.method,
            ip: req.ip,
            userAgent: req.headers['user-agent'],
            input:
              userInput.length > 1000
                ? userInput.substring(0, 1000) + '...'
                : userInput,
          },
          'error',
        );

        // Send critical alert
        this.alerting.sendCriticalAlert(
          'Suspicious Activity Detected',
          `Potential security threat detected from IP ${req.ip}`,
          {
            pattern: pattern.source,
            path: req.path,
            ip: req.ip,
          },
        );
        break;
      }
    }

    // Check for unusual request patterns
    if (
      req.headers['content-length'] &&
      parseInt(req.headers['content-length']) > 10 * 1024 * 1024
    ) {
      this.logger.logSecurityEvent(
        'large_request_detected',
        {
          path: req.path,
          contentLength: req.headers['content-length'],
          ip: req.ip,
        },
        'warn',
      );
    }
  }
}
