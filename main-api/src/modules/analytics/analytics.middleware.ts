import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { AnalyticsService } from './analytics.service';

/**
 * Middleware to track API requests and user actions
 * This middleware automatically tracks page views and API usage
 */
@Injectable()
export class AnalyticsMiddleware implements NestMiddleware {
  private readonly logger = new Logger(AnalyticsMiddleware.name);

  constructor(private readonly analyticsService: AnalyticsService) {}

  use(req: Request, res: Response, next: NextFunction): void {
    const startTime = Date.now();
    const { method, path, ip } = req;

    // Extract user ID from request if authenticated
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
    const userId = (req as any).user?.id || (req as any).user?.userId;

    // Track API request
    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const { statusCode } = res;

      // Only track successful requests to avoid noise
      if (statusCode < 400) {
        void this.analyticsService
          .trackEvent({
            name: 'api_request',
            userId,
            properties: {
              method,
              path,
              statusCode,
              duration,
              ip,
              userAgent: req.get('user-agent'),
            },
          })
          .catch((error: unknown) => {
            const errorMessage =
              error instanceof Error ? error.stack : String(error);
            this.logger.error('Failed to track API request', errorMessage);
          });
      }
    });

    next();
  }
}
