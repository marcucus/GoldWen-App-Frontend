import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Reflector } from '@nestjs/core';
import { Response } from 'express';
import { CacheStrategy, CacheHeaders } from '../enums/cache-strategy.enum';

export const CACHE_STRATEGY_KEY = 'cacheStrategy';

export const CacheControl =
  (strategy: CacheStrategy) =>
  (target: any, key?: string, descriptor?: PropertyDescriptor) => {
    if (descriptor) {
      Reflect.defineMetadata(CACHE_STRATEGY_KEY, strategy, descriptor.value);
      return descriptor;
    }
    Reflect.defineMetadata(CACHE_STRATEGY_KEY, strategy, target);
    return target;
  };

@Injectable()
export class CacheInterceptor implements NestInterceptor {
  constructor(private reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const response = context.switchToHttp().getResponse<Response>();

    // Get cache strategy from decorator
    const cacheStrategy = this.reflector.get<CacheStrategy>(
      CACHE_STRATEGY_KEY,
      context.getHandler(),
    );

    return next.handle().pipe(
      map((data) => {
        // Apply cache headers if strategy is defined
        if (cacheStrategy && CacheHeaders[cacheStrategy]) {
          const headers = CacheHeaders[cacheStrategy];
          Object.entries(headers).forEach(([key, value]) => {
            response.setHeader(key, value);
          });

          // Add ETag for cache validation
          if (cacheStrategy !== CacheStrategy.NO_CACHE) {
            const etag = this.generateETag(data);
            response.setHeader('ETag', etag);
          }

          // Add cache expiry to response metadata
          if (data && typeof data === 'object') {
            const cacheExpiry = this.getCacheExpiry(cacheStrategy);
            if (cacheExpiry) {
              data.metadata = {
                ...data.metadata,
                cacheExpiry: cacheExpiry.toISOString(),
              };
            }
          }
        }

        return data;
      }),
    );
  }

  private generateETag(data: any): string {
    // Simple ETag generation based on data hash
    const content = JSON.stringify(data);
    let hash = 0;
    for (let i = 0; i < content.length; i++) {
      const char = content.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return `"${Math.abs(hash).toString(16)}"`;
  }

  private getCacheExpiry(strategy: CacheStrategy): Date | null {
    const now = new Date();
    switch (strategy) {
      case CacheStrategy.SHORT_CACHE:
        return new Date(now.getTime() + 5 * 60 * 1000); // 5 minutes
      case CacheStrategy.MEDIUM_CACHE:
        return new Date(now.getTime() + 60 * 60 * 1000); // 1 hour
      case CacheStrategy.LONG_CACHE:
        return new Date(now.getTime() + 24 * 60 * 60 * 1000); // 24 hours
      case CacheStrategy.STATIC_CACHE:
        return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // 7 days
      default:
        return null;
    }
  }
}
