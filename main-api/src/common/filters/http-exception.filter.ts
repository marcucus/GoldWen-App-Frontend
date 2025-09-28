import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Inject,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { CustomLoggerService } from '../logger';
import {
  StandardErrorCode,
  ErrorRecoveryActions,
} from '../enums/error-codes.enum';
import { ErrorResponseDto } from '../dto/response.dto';
import { SentryService } from '../monitoring';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  constructor(
    private readonly logger: CustomLoggerService,
    @Inject(SentryService) private readonly sentry: SentryService,
  ) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const startTime = Date.now();

    let status: number;
    let message: string;
    let code: string;
    let errors: any[] = [];
    let recoveryAction: string | undefined;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const responseObj = exceptionResponse as any;
        message = responseObj.message || exception.message;
        code = this.mapToStandardErrorCode(
          status,
          responseObj.error || exception.name,
        );
        errors = Array.isArray(responseObj.message) ? responseObj.message : [];

        // Handle validation errors
        if (Array.isArray(errors) && errors.length > 0) {
          message = 'Validation failed';
          code = StandardErrorCode.VALIDATION_ERROR;
        }
      } else {
        message = exceptionResponse;
        code = this.mapToStandardErrorCode(status, exception.name);
      }
    } else {
      status = HttpStatus.INTERNAL_SERVER_ERROR;
      message = 'Internal server error';
      code = StandardErrorCode.INTERNAL_SERVER_ERROR;

      // Log unexpected errors
      this.logger.error(
        'Unexpected error occurred: ' +
          (exception instanceof Error ? exception.message : 'Unknown error'),
        exception instanceof Error ? exception.stack : undefined,
        'HttpExceptionFilter',
      );

      // Send to Sentry for 5xx errors
      if (exception instanceof Error) {
        this.sentry.captureException(exception, {
          request: {
            method: request.method,
            url: request.url,
            headers: this.filterSensitiveHeaders(request.headers),
            user: (request as any).user,
          },
        });
      }
    }

    // Get recovery action
    recoveryAction = ErrorRecoveryActions[code as StandardErrorCode];

    // Log HTTP exceptions (4xx errors at debug level, 5xx at error level)
    const processingTime = Date.now() - startTime;
    if (status >= 500) {
      this.logger.error(
        `HTTP ${status} Error: ${message}`,
        undefined,
        'HttpExceptionFilter',
      );

      // Also send 5xx errors to Sentry if it's an unexpected error
      if (
        exception instanceof Error &&
        status === HttpStatus.INTERNAL_SERVER_ERROR
      ) {
        this.sentry.captureException(exception, {
          request: {
            method: request.method,
            url: request.url,
            headers: this.filterSensitiveHeaders(request.headers),
            user: (request as any).user,
          },
        });
      }
    } else if (status >= 400) {
      this.logger.debug(
        `HTTP ${status} Client Error: ${message}`,
        'HttpExceptionFilter',
      );
    }

    const errorResponse = new ErrorResponseDto(
      message,
      request.url,
      code,
      errors.length > 0 ? errors : undefined,
      recoveryAction,
      {
        requestId: this.generateRequestId(),
        processingTime,
        loadingState: 'error',
      },
    );

    response.status(status).json(errorResponse);
  }

  private mapToStandardErrorCode(status: number, originalCode: string): string {
    const lowerOriginalCode = originalCode.toLowerCase();

    // Map common HTTP status codes to standardized error codes
    switch (status) {
      case HttpStatus.UNAUTHORIZED:
        if (
          lowerOriginalCode.includes('token_expired') ||
          lowerOriginalCode.includes('tokenexpired')
        ) {
          return StandardErrorCode.TOKEN_EXPIRED;
        }
        if (
          lowerOriginalCode.includes('invalid_credentials') ||
          lowerOriginalCode.includes('invalidcredentials')
        ) {
          return StandardErrorCode.INVALID_CREDENTIALS;
        }
        return StandardErrorCode.UNAUTHORIZED;

      case HttpStatus.FORBIDDEN:
        if (
          lowerOriginalCode.includes('subscription') ||
          lowerOriginalCode.includes('premium')
        ) {
          return StandardErrorCode.SUBSCRIPTION_REQUIRED;
        }
        return StandardErrorCode.FORBIDDEN;

      case HttpStatus.NOT_FOUND:
        if (lowerOriginalCode.includes('user')) {
          return StandardErrorCode.USER_NOT_FOUND;
        }
        if (lowerOriginalCode.includes('profile')) {
          return StandardErrorCode.PROFILE_NOT_FOUND;
        }
        if (lowerOriginalCode.includes('conversation')) {
          return StandardErrorCode.CONVERSATION_NOT_FOUND;
        }
        return StandardErrorCode.RESOURCE_NOT_FOUND;

      case HttpStatus.CONFLICT:
        if (lowerOriginalCode.includes('email')) {
          return StandardErrorCode.EMAIL_ALREADY_EXISTS;
        }
        if (lowerOriginalCode.includes('phone')) {
          return StandardErrorCode.PHONE_ALREADY_EXISTS;
        }
        return StandardErrorCode.RESOURCE_ALREADY_EXISTS;

      case HttpStatus.BAD_REQUEST:
        if (
          lowerOriginalCode.includes('validation') ||
          lowerOriginalCode.includes('validationerror')
        ) {
          return StandardErrorCode.VALIDATION_ERROR;
        }
        if (
          lowerOriginalCode.includes('file_too_large') ||
          lowerOriginalCode.includes('payloadtoolarge')
        ) {
          return StandardErrorCode.FILE_TOO_LARGE;
        }
        return StandardErrorCode.INVALID_INPUT;

      case HttpStatus.TOO_MANY_REQUESTS:
        return StandardErrorCode.RATE_LIMIT_EXCEEDED;

      case HttpStatus.SERVICE_UNAVAILABLE:
        return StandardErrorCode.SERVICE_UNAVAILABLE;

      case HttpStatus.INTERNAL_SERVER_ERROR:
        if (lowerOriginalCode.includes('database')) {
          return StandardErrorCode.DATABASE_ERROR;
        }
        return StandardErrorCode.INTERNAL_SERVER_ERROR;

      default:
        return originalCode || StandardErrorCode.INTERNAL_SERVER_ERROR;
    }
  }

  private generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private filterSensitiveHeaders(headers: any): any {
    const sensitiveHeaders = ['authorization', 'cookie', 'x-api-key'];
    const filtered = { ...headers };

    sensitiveHeaders.forEach((header) => {
      if (filtered[header]) {
        filtered[header] = '[FILTERED]';
      }
    });

    return filtered;
  }
}
