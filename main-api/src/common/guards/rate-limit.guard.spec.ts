import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ThrottlerException, ThrottlerStorage } from '@nestjs/throttler';
import { RateLimitGuard } from './rate-limit.guard';
import { CustomLoggerService } from '../logger';

describe('RateLimitGuard', () => {
  let guard: RateLimitGuard;
  let mockLogger: jest.Mocked<CustomLoggerService>;
  let mockStorage: jest.Mocked<ThrottlerStorage>;
  let mockReflector: jest.Mocked<Reflector>;
  let mockContext: ExecutionContext;
  let mockRequest: any;
  let mockResponse: any;

  beforeEach(() => {
    mockLogger = {
      logSecurityEvent: jest.fn(),
      info: jest.fn(),
      warn: jest.fn(),
      error: jest.fn(),
    } as any;

    mockStorage = {
      increment: jest.fn(),
      decrement: jest.fn(),
      reset: jest.fn(),
    } as any;

    mockReflector = {
      getAllAndOverride: jest.fn(),
    } as any;

    mockRequest = {
      ip: '192.168.1.1',
      path: '/api/v1/test',
      headers: {
        'user-agent': 'Test Agent',
      },
      connection: {
        remoteAddress: '192.168.1.1',
      },
    };

    mockResponse = {
      setHeader: jest.fn(),
    };

    mockContext = {
      switchToHttp: () => ({
        getRequest: () => mockRequest,
        getResponse: () => mockResponse,
      }),
      getHandler: jest.fn(),
      getClass: jest.fn(),
    } as any;

    // Create guard instance directly with mocked dependencies
    const options = {
      throttlers: [
        {
          name: 'default',
          ttl: 60000,
          limit: 100,
        },
      ],
    };
    guard = new RateLimitGuard(options, mockStorage, mockReflector, mockLogger);
  });

  it('should be defined', () => {
    expect(guard).toBeDefined();
  });

  describe('getTracker', () => {
    it('should return IP address as tracker', async () => {
      const tracker = await guard['getTracker'](mockRequest);
      expect(tracker).toBe('192.168.1.1');
    });

    it('should return connection remote address if IP is not available', async () => {
      mockRequest.ip = undefined;
      const tracker = await guard['getTracker'](mockRequest);
      expect(tracker).toBe('192.168.1.1');
    });

    it('should return "unknown" if no IP information is available', async () => {
      mockRequest.ip = undefined;
      mockRequest.connection = undefined;
      const tracker = await guard['getTracker'](mockRequest);
      expect(tracker).toBe('unknown');
    });
  });

  describe('throwThrottlingException', () => {
    it('should log rate limit exceeded event', async () => {
      await expect(
        guard['throwThrottlingException'](mockContext),
      ).rejects.toThrow(ThrottlerException);

      expect(mockLogger.logSecurityEvent).toHaveBeenCalledWith(
        'rate_limit_exceeded',
        {
          path: '/api/v1/test',
          ip: '192.168.1.1',
          userAgent: 'Test Agent',
        },
        'warn',
      );
    });

    it('should throw ThrottlerException with appropriate message', async () => {
      await expect(
        guard['throwThrottlingException'](mockContext),
      ).rejects.toThrow(
        'Too many requests. Please try again in a few minutes.',
      );
    });
  });

  describe('security logging integration', () => {
    it('should log security events with correct parameters', async () => {
      try {
        await guard['throwThrottlingException'](mockContext);
      } catch (error) {
        // Expected to throw
      }

      expect(mockLogger.logSecurityEvent).toHaveBeenCalledTimes(1);
      expect(mockLogger.logSecurityEvent).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          path: expect.any(String),
          ip: expect.any(String),
        }),
        expect.any(String),
      );
    });
  });
});
