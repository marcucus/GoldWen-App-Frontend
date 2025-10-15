import { Injectable, ExecutionContext, Inject } from '@nestjs/common';
import * as throttler from '@nestjs/throttler';
import { ThrottlerOptions } from '@nestjs/throttler';
import { Reflector } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { CustomLoggerService } from '../logger';
import { AlertingService } from '../monitoring';

@Injectable()
export class BruteForceGuard extends throttler.ThrottlerGuard {
  private readonly authTtl: number;
  private readonly authLimit: number;

  constructor(
    options: throttler.ThrottlerModuleOptions,
    storageService: throttler.ThrottlerStorage,
    reflector: Reflector,
    private readonly configService: ConfigService,
    private readonly logger: CustomLoggerService,
    private readonly alerting: AlertingService,
  ) {
    const authTtl = configService.get<number>('throttler.auth.ttl') || 900000;
    const authLimit = configService.get<number>('throttler.auth.limit') || 5;

    // Override the options with brute-force specific settings
    const bruteForceOptions = {
      ...options,
      throttlers: [
        {
          name: 'brute-force',
          ttl: authTtl,
          limit: authLimit,
        },
      ],
    };

    super(bruteForceOptions, storageService, reflector);

    this.authTtl = authTtl;
    this.authLimit = authLimit;
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const response = context.switchToHttp().getResponse();

    try {
      const canActivate = await super.canActivate(context);

      // Add rate limit headers on successful request
      response.setHeader('X-RateLimit-Limit', this.authLimit);
      response.setHeader('X-RateLimit-Reset', Date.now() + this.authTtl);

      return canActivate;
    } catch (error) {
      if (error instanceof throttler.ThrottlerException) {
        // Add rate limit headers on rate limit exceeded
        response.setHeader('X-RateLimit-Limit', this.authLimit);
        response.setHeader('X-RateLimit-Remaining', 0);
        response.setHeader('X-RateLimit-Reset', Date.now() + this.authTtl);
        response.setHeader('Retry-After', Math.ceil(this.authTtl / 1000));
      }
      throw error;
    }
  }

  protected async throwThrottlingException(
    context: ExecutionContext,
  ): Promise<void> {
    const request = context.switchToHttp().getRequest();
    const ip = request.ip || request.connection?.remoteAddress;
    const path = request.path;
    const userAgent = request.headers['user-agent'];
    const email = request.body?.email;

    // Log brute force attempt
    this.logger.logSecurityEvent(
      'brute_force_attempt',
      {
        path,
        ip,
        userAgent,
        email: email ? `${email.substring(0, 3)}***` : undefined, // Redact email for privacy
      },
      'error',
    );

    // Send critical alert for brute force attacks
    this.alerting.sendCriticalAlert(
      'Brute Force Attack Detected',
      `Multiple failed login attempts detected from IP ${ip}`,
      {
        ip,
        path,
        userAgent,
        attempts: this.authLimit,
      },
    );

    throw new throttler.ThrottlerException(
      'Too many login attempts. Please try again in 15 minutes.',
    );
  }

  protected async getTracker(req: Record<string, any>): Promise<string> {
    // Track by IP + email combination for more precise brute force detection
    const ip = req.ip || req.connection?.remoteAddress || 'unknown';
    const email = req.body?.email || 'no-email';
    return `${ip}:${email}`;
  }
}
