import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { CustomLoggerService } from '../logger';
import { SuccessResponseDto, ResponseMetadata } from '../dto/response.dto';

@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  constructor(private readonly logger: CustomLoggerService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const response = context.switchToHttp().getResponse();
    const startTime = Date.now();

    return next.handle().pipe(
      map((data) => {
        const endTime = Date.now();
        const processingTime = endTime - startTime;

        // Add performance headers
        response.setHeader('X-Response-Time', `${processingTime}ms`);
        response.setHeader('X-Request-ID', this.generateRequestId());

        // Optimize response time warning
        if (processingTime > 1000) {
          this.logger.warn(
            `Slow response detected: ${processingTime}ms`,
            'ResponseInterceptor',
          );
        }

        // Log successful responses
        this.logger.info('HTTP Response', {
          method: request.method,
          url: request.url,
          statusCode: response.statusCode,
          duration: `${processingTime}ms`,
          userAgent: request.headers['user-agent'],
          ip: request.ip,
          userId: request.user?.id,
          dataSize: data ? JSON.stringify(data).length : 0,
        });

        // Enhance response with metadata if it's not already structured
        if (data && typeof data === 'object') {
          // If it's already a structured response, enhance metadata
          if ('success' in data || 'message' in data) {
            const metadata: ResponseMetadata = {
              ...data.metadata,
              requestId: this.generateRequestId(),
              processingTime,
              loadingState: 'success',
            };

            return {
              ...data,
              metadata,
            };
          } else {
            // Wrap raw data in success response
            return new SuccessResponseDto(
              'Operation completed successfully',
              data,
              {
                requestId: this.generateRequestId(),
                processingTime,
                loadingState: 'success',
              },
            );
          }
        }

        return data;
      }),
    );
  }

  private generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
