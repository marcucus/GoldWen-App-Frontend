import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ThrottlerStorageService } from '@nestjs/throttler';

@Injectable()
export class RateLimitHeadersInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const response = context.switchToHttp().getResponse();
    const request = context.switchToHttp().getRequest();

    return next.handle().pipe(
      tap(() => {
        // Add rate limit headers if they exist from throttler
        const rateLimitInfo = request.rateLimit;

        if (rateLimitInfo) {
          response.setHeader('X-RateLimit-Limit', rateLimitInfo.limit || 100);
          response.setHeader(
            'X-RateLimit-Remaining',
            rateLimitInfo.remaining || 0,
          );
          response.setHeader('X-RateLimit-Reset', rateLimitInfo.reset || 0);
        }
      }),
    );
  }
}
