import { Injectable, ExecutionContext } from '@nestjs/common';
import {
  ThrottlerGuard,
  ThrottlerException,
  ThrottlerStorage,
} from '@nestjs/throttler';
import type { ThrottlerModuleOptions } from '@nestjs/throttler';
import { Reflector } from '@nestjs/core';
import { CustomLoggerService } from '../logger';

@Injectable()
export class RateLimitGuard extends ThrottlerGuard {
  constructor(
    options: ThrottlerModuleOptions,
    storageService: ThrottlerStorage,
    reflector: Reflector,
    private readonly logger: CustomLoggerService,
  ) {
    super(options, storageService, reflector);
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const response = context.switchToHttp().getResponse();

    try {
      const canActivate = await super.canActivate(context);

      // Add rate limit headers on successful request
      const throttlers = Array.isArray(this.options)
        ? this.options
        : this.options.throttlers || [];
      const ttl = Number(throttlers[0]?.ttl) || 60000;
      const limit = Number(throttlers[0]?.limit) || 100;

      response.setHeader('X-RateLimit-Limit', limit);
      response.setHeader('X-RateLimit-Reset', Date.now() + ttl);

      return canActivate;
    } catch (error) {
      if (error instanceof ThrottlerException) {
        // Add rate limit headers on rate limit exceeded
        const throttlers = Array.isArray(this.options)
          ? this.options
          : this.options.throttlers || [];
        const ttl = Number(throttlers[0]?.ttl) || 60000;
        const limit = Number(throttlers[0]?.limit) || 100;

        response.setHeader('X-RateLimit-Limit', limit);
        response.setHeader('X-RateLimit-Remaining', 0);
        response.setHeader('X-RateLimit-Reset', Date.now() + ttl);
        response.setHeader('Retry-After', Math.ceil(ttl / 1000));
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

    // Log rate limit exceeded event
    this.logger.logSecurityEvent(
      'rate_limit_exceeded',
      {
        path,
        ip,
        userAgent,
      },
      'warn',
    );

    throw new ThrottlerException(
      'Too many requests. Please try again in a few minutes.',
    );
  }

  protected async getTracker(req: Record<string, any>): Promise<string> {
    // Track by IP address for rate limiting
    return req.ip || req.connection?.remoteAddress || 'unknown';
  }
}
