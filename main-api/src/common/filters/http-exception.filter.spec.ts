import { Test } from '@nestjs/testing';
import { ArgumentsHost, HttpException, HttpStatus } from '@nestjs/common';
import { HttpExceptionFilter } from './http-exception.filter';
import { CustomLoggerService } from '../logger';
import {
  StandardErrorCode,
  ErrorRecoveryActions,
} from '../enums/error-codes.enum';

describe('HttpExceptionFilter', () => {
  let filter: HttpExceptionFilter;
  let mockLogger: jest.Mocked<CustomLoggerService>;

  const mockResponse = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };

  const mockRequest = {
    url: '/api/v1/test',
    method: 'GET',
    headers: { 'user-agent': 'test-agent' },
    ip: '127.0.0.1',
    user: { id: 'user123' },
  };

  const mockHost = {
    switchToHttp: () => ({
      getResponse: () => mockResponse,
      getRequest: () => mockRequest,
    }),
  } as ArgumentsHost;

  beforeEach(async () => {
    mockLogger = {
      error: jest.fn(),
      debug: jest.fn(),
      info: jest.fn(),
      warn: jest.fn(),
    } as any;

    const module = await Test.createTestingModule({
      providers: [
        HttpExceptionFilter,
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    filter = module.get<HttpExceptionFilter>(HttpExceptionFilter);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('HTTP Exception handling', () => {
    it('should handle validation errors with standardized code', () => {
      const exception = new HttpException(
        {
          message: ['field1 is required', 'field2 must be valid'],
          error: 'Bad Request',
        },
        HttpStatus.BAD_REQUEST,
      );

      filter.catch(exception, mockHost);

      expect(mockResponse.status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Validation failed',
          code: StandardErrorCode.VALIDATION_ERROR,
          errors: ['field1 is required', 'field2 must be valid'],
          recoveryAction:
            ErrorRecoveryActions[StandardErrorCode.VALIDATION_ERROR],
          path: '/api/v1/test',
          metadata: expect.objectContaining({
            requestId: expect.any(String),
            processingTime: expect.any(Number),
            loadingState: 'error',
          }),
        }),
      );
    });

    it('should handle unauthorized errors with proper error code mapping', () => {
      const exception = new HttpException(
        'Unauthorized',
        HttpStatus.UNAUTHORIZED,
      );

      filter.catch(exception, mockHost);

      expect(mockResponse.status).toHaveBeenCalledWith(HttpStatus.UNAUTHORIZED);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Unauthorized',
          code: StandardErrorCode.UNAUTHORIZED,
          recoveryAction: ErrorRecoveryActions[StandardErrorCode.UNAUTHORIZED],
        }),
      );
    });

    it('should handle token expired errors specifically', () => {
      const exception = new HttpException(
        { message: 'Token expired', error: 'TOKEN_EXPIRED' },
        HttpStatus.UNAUTHORIZED,
      );

      filter.catch(exception, mockHost);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          code: StandardErrorCode.TOKEN_EXPIRED,
          recoveryAction: ErrorRecoveryActions[StandardErrorCode.TOKEN_EXPIRED],
        }),
      );
    });

    it('should handle internal server errors', () => {
      const exception = new Error('Unexpected error');

      filter.catch(exception, mockHost);

      expect(mockResponse.status).toHaveBeenCalledWith(
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: StandardErrorCode.INTERNAL_SERVER_ERROR,
          recoveryAction:
            ErrorRecoveryActions[StandardErrorCode.INTERNAL_SERVER_ERROR],
        }),
      );
      expect(mockLogger.error).toHaveBeenCalled();
    });

    it('should log errors appropriately based on status code', () => {
      // Test 4xx error logging
      const clientException = new HttpException(
        'Bad request',
        HttpStatus.BAD_REQUEST,
      );
      filter.catch(clientException, mockHost);
      expect(mockLogger.debug).toHaveBeenCalled();

      // Test 5xx error logging
      const serverException = new HttpException(
        'Server error',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
      filter.catch(serverException, mockHost);
      expect(mockLogger.error).toHaveBeenCalled();
    });
  });

  describe('Error code mapping', () => {
    it('should map user not found errors correctly', () => {
      const exception = new HttpException(
        { message: 'User not found', error: 'UserNotFound' },
        HttpStatus.NOT_FOUND,
      );

      filter.catch(exception, mockHost);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          code: StandardErrorCode.USER_NOT_FOUND,
        }),
      );
    });

    it('should map subscription required errors correctly', () => {
      const exception = new HttpException(
        {
          message: 'Premium subscription required',
          error: 'SubscriptionRequired',
        },
        HttpStatus.FORBIDDEN,
      );

      filter.catch(exception, mockHost);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          code: StandardErrorCode.SUBSCRIPTION_REQUIRED,
        }),
      );
    });

    it('should map email already exists errors correctly', () => {
      const exception = new HttpException(
        { message: 'Email already exists', error: 'EmailAlreadyExists' },
        HttpStatus.CONFLICT,
      );

      filter.catch(exception, mockHost);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          code: StandardErrorCode.EMAIL_ALREADY_EXISTS,
        }),
      );
    });
  });
});
