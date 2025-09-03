import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { CustomLoggerService } from '../logger';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  constructor(private readonly logger: CustomLoggerService) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status: number;
    let message: string;
    let code: string;
    let errors: any[] = [];

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const responseObj = exceptionResponse as any;
        message = responseObj.message || exception.message;
        code = responseObj.error || exception.name;
        errors = responseObj.message || [];

        // Handle validation errors
        if (Array.isArray(errors)) {
          message = 'Validation failed';
        }
      } else {
        message = exceptionResponse;
        code = exception.name;
      }
    } else {
      status = HttpStatus.INTERNAL_SERVER_ERROR;
      message = 'Internal server error';
      code = 'INTERNAL_SERVER_ERROR';

      // Log unexpected errors
      this.logger.error(
        'Unexpected error occurred: ' +
          (exception instanceof Error ? exception.message : 'Unknown error'),
        exception instanceof Error ? exception.stack : undefined,
        'HttpExceptionFilter',
      );
    }

    // Log HTTP exceptions (4xx errors at debug level, 5xx at error level)
    if (status >= 500) {
      this.logger.error(
        `HTTP ${status} Error: ${message}`,
        undefined,
        'HttpExceptionFilter',
      );
    } else if (status >= 400) {
      this.logger.debug(
        `HTTP ${status} Client Error: ${message}`,
        'HttpExceptionFilter',
      );
    }

    const errorResponse = {
      success: false,
      message,
      code,
      ...(errors.length > 0 && { errors }),
      timestamp: new Date().toISOString(),
      path: request.url,
    };

    response.status(status).json(errorResponse);
  }
}
