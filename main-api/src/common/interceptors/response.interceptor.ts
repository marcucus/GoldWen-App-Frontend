import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { CustomLoggerService } from '../logger';

@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  constructor(private readonly logger: CustomLoggerService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const response = context.switchToHttp().getResponse();
    const startTime = Date.now();

    return next.handle().pipe(
      tap((data) => {
        const endTime = Date.now();
        const duration = endTime - startTime;

        // Log successful responses
        this.logger.info('HTTP Response', {
          method: request.method,
          url: request.url,
          statusCode: response.statusCode,
          duration: `${duration}ms`,
          userAgent: request.headers['user-agent'],
          ip: request.ip,
          userId: request.user?.id,
          dataSize: JSON.stringify(data).length,
        });
      }),
    );
  }
}
