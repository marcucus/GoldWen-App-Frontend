import { ConfigService } from '@nestjs/config';
import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ThrottlerException, ThrottlerStorage } from '@nestjs/throttler';
import { BruteForceGuard } from './brute-force.guard';
import { CustomLoggerService } from '../logger';
import { AlertingService } from '../monitoring';

describe('BruteForceGuard', () => {
  let guard: BruteForceGuard;
  let mockConfigService: jest.Mocked<ConfigService>;
  let mockLogger: jest.Mocked<CustomLoggerService>;
  let mockAlerting: jest.Mocked<AlertingService>;
  let mockStorage: jest.Mocked<ThrottlerStorage>;
  let mockReflector: jest.Mocked<Reflector>;
  let mockContext: ExecutionContext;
  let mockRequest: any;
  let mockResponse: any;

  beforeEach(() => {
    mockConfigService = {
      get: jest.fn((key: string) => {
        const config = {
          'throttler.auth.ttl': 900000, // 15 minutes
          'throttler.auth.limit': 5,
        };
        return config[key];
      }),
    } as any;

    mockLogger = {
      logSecurityEvent: jest.fn(),
      info: jest.fn(),
      warn: jest.fn(),
      error: jest.fn(),
    } as any;

    mockAlerting = {
      sendCriticalAlert: jest.fn(),
      sendWarningAlert: jest.fn(),
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
      path: '/auth/login',
      headers: {
        'user-agent': 'Test Agent',
      },
      body: {
        email: 'test@example.com',
        password: 'wrongpassword',
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
    guard = new BruteForceGuard(
      mockConfigService,
      mockLogger,
      mockAlerting,
      mockStorage,
      mockReflector,
    );
  });

  it('should be defined', () => {
    expect(guard).toBeDefined();
  });

  describe('constructor', () => {
    it('should configure throttler with auth limits from config', () => {
      expect(mockConfigService.get).toHaveBeenCalledWith('throttler.auth.ttl');
      expect(mockConfigService.get).toHaveBeenCalledWith(
        'throttler.auth.limit',
      );
    });
  });

  describe('getTracker', () => {
    it('should return IP:email combination as tracker', async () => {
      const tracker = await guard['getTracker'](mockRequest);
      expect(tracker).toBe('192.168.1.1:test@example.com');
    });

    it('should handle missing email', async () => {
      mockRequest.body = {};
      const tracker = await guard['getTracker'](mockRequest);
      expect(tracker).toBe('192.168.1.1:no-email');
    });

    it('should use connection remote address if IP is not available', async () => {
      mockRequest.ip = undefined;
      const tracker = await guard['getTracker'](mockRequest);
      expect(tracker).toBe('192.168.1.1:test@example.com');
    });

    it('should return "unknown" for IP if no IP information is available', async () => {
      mockRequest.ip = undefined;
      mockRequest.connection = undefined;
      const tracker = await guard['getTracker'](mockRequest);
      expect(tracker).toBe('unknown:test@example.com');
    });
  });

  describe('throwThrottlingException', () => {
    it('should log brute force attempt with redacted email', async () => {
      await expect(
        guard['throwThrottlingException'](mockContext),
      ).rejects.toThrow(ThrottlerException);

      expect(mockLogger.logSecurityEvent).toHaveBeenCalledWith(
        'brute_force_attempt',
        {
          path: '/auth/login',
          ip: '192.168.1.1',
          userAgent: 'Test Agent',
          email: 'tes***', // First 3 chars + ***
        },
        'error',
      );
    });

    it('should send critical alert for brute force attack', async () => {
      await expect(
        guard['throwThrottlingException'](mockContext),
      ).rejects.toThrow(ThrottlerException);

      expect(mockAlerting.sendCriticalAlert).toHaveBeenCalledWith(
        'Brute Force Attack Detected',
        'Multiple failed login attempts detected from IP 192.168.1.1',
        {
          ip: '192.168.1.1',
          path: '/auth/login',
          userAgent: 'Test Agent',
          attempts: 5,
        },
      );
    });

    it('should throw ThrottlerException with appropriate message', async () => {
      await expect(
        guard['throwThrottlingException'](mockContext),
      ).rejects.toThrow(
        'Too many login attempts. Please try again in 15 minutes.',
      );
    });

    it('should handle missing email gracefully', async () => {
      mockRequest.body = {};

      await expect(
        guard['throwThrottlingException'](mockContext),
      ).rejects.toThrow(ThrottlerException);

      expect(mockLogger.logSecurityEvent).toHaveBeenCalledWith(
        'brute_force_attempt',
        expect.objectContaining({
          email: undefined,
        }),
        'error',
      );
    });
  });

  describe('configuration', () => {
    it('should use default values if config is not available', () => {
      const customConfigService = {
        get: jest.fn().mockReturnValue(undefined),
      } as any;

      const guardInstance = new BruteForceGuard(
        customConfigService,
        mockLogger,
        mockAlerting,
        mockStorage,
        mockReflector,
      );

      expect(guardInstance).toBeDefined();
    });
  });

  describe('security integration', () => {
    it('should integrate with security logging and alerting', async () => {
      try {
        await guard['throwThrottlingException'](mockContext);
      } catch (error) {
        // Expected to throw
      }

      expect(mockLogger.logSecurityEvent).toHaveBeenCalledTimes(1);
      expect(mockAlerting.sendCriticalAlert).toHaveBeenCalledTimes(1);
    });
  });
});
