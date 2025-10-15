import { Test, TestingModule } from '@nestjs/testing';
import { AnalyticsMiddleware } from './analytics.middleware';
import { AnalyticsService } from './analytics.service';
import { Request, Response, NextFunction } from 'express';

describe('AnalyticsMiddleware', () => {
  let middleware: AnalyticsMiddleware;

  const mockAnalyticsService = {
    trackEvent: jest.fn().mockResolvedValue(undefined),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AnalyticsMiddleware,
        {
          provide: AnalyticsService,
          useValue: mockAnalyticsService,
        },
      ],
    }).compile();

    middleware = module.get<AnalyticsMiddleware>(AnalyticsMiddleware);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(middleware).toBeDefined();
  });

  it('should track API request on response finish', () => {
    const mockRequest = {
      method: 'GET',
      path: '/api/v1/profiles',
      ip: '127.0.0.1',
      get: jest.fn().mockReturnValue('Mozilla/5.0'),
      user: { id: 'user-123' },
    } as unknown as Request;

    const mockResponse = {
      statusCode: 200,

      on: jest.fn((event: string, callback: () => void) => {
        if (event === 'finish') {
          callback();
        }
      }),
    } as unknown as Response;

    const mockNext = jest.fn() as NextFunction;

    middleware.use(mockRequest, mockResponse, mockNext);

    return new Promise((resolve) => setTimeout(resolve, 100)).then(() => {
      expect(mockNext).toHaveBeenCalled();
      expect(mockAnalyticsService.trackEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'api_request',
          userId: 'user-123',
          properties: expect.objectContaining({
            method: 'GET',
            path: '/api/v1/profiles',
            statusCode: 200,
            ip: '127.0.0.1',
          }),
        }),
      );
    });
  });

  it('should not track failed requests (4xx/5xx)', () => {
    const mockRequest = {
      method: 'POST',
      path: '/api/v1/auth/login',
      ip: '127.0.0.1',
      get: jest.fn().mockReturnValue('Mozilla/5.0'),
    } as unknown as Request;

    const mockResponse = {
      statusCode: 401,

      on: jest.fn((event: string, callback: () => void) => {
        if (event === 'finish') {
          callback();
        }
      }),
    } as unknown as Response;

    const mockNext = jest.fn() as NextFunction;

    middleware.use(mockRequest, mockResponse, mockNext);

    return new Promise((resolve) => setTimeout(resolve, 100)).then(() => {
      expect(mockNext).toHaveBeenCalled();
      expect(mockAnalyticsService.trackEvent).not.toHaveBeenCalled();
    });
  });

  it('should work without authenticated user', () => {
    const mockRequest = {
      method: 'GET',
      path: '/api/v1/public',
      ip: '127.0.0.1',
      get: jest.fn().mockReturnValue('Mozilla/5.0'),
    } as unknown as Request;

    const mockResponse = {
      statusCode: 200,

      on: jest.fn((event: string, callback: () => void) => {
        if (event === 'finish') {
          callback();
        }
      }),
    } as unknown as Response;

    const mockNext = jest.fn() as NextFunction;

    middleware.use(mockRequest, mockResponse, mockNext);

    return new Promise((resolve) => setTimeout(resolve, 100)).then(() => {
      expect(mockNext).toHaveBeenCalled();
      expect(mockAnalyticsService.trackEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'api_request',
          userId: undefined,
        }),
      );
    });
  });

  it('should handle errors gracefully', () => {
    mockAnalyticsService.trackEvent.mockRejectedValueOnce(
      new Error('Tracking failed'),
    );

    const mockRequest = {
      method: 'GET',
      path: '/api/v1/profiles',
      ip: '127.0.0.1',
      get: jest.fn().mockReturnValue('Mozilla/5.0'),
      user: { id: 'user-123' },
    } as unknown as Request;

    const mockResponse = {
      statusCode: 200,

      on: jest.fn((event: string, callback: () => void) => {
        if (event === 'finish') {
          callback();
        }
      }),
    } as unknown as Response;

    const mockNext = jest.fn() as NextFunction;

    expect(() =>
      middleware.use(mockRequest, mockResponse, mockNext),
    ).not.toThrow();

    expect(mockNext).toHaveBeenCalled();
  });

  it('should calculate request duration', () => {
    const mockRequest = {
      method: 'GET',
      path: '/api/v1/profiles',
      ip: '127.0.0.1',
      get: jest.fn().mockReturnValue('Mozilla/5.0'),
      user: { id: 'user-123' },
    } as unknown as Request;

    const mockResponse = {
      statusCode: 200,

      on: jest.fn((event: string, callback: () => void) => {
        if (event === 'finish') {
          setTimeout(callback, 50);
        }
      }),
    } as unknown as Response;

    const mockNext = jest.fn() as NextFunction;

    middleware.use(mockRequest, mockResponse, mockNext);

    return new Promise((resolve) => setTimeout(resolve, 150)).then(() => {
      expect(mockAnalyticsService.trackEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          properties: expect.objectContaining({
            duration: expect.any(Number),
          }),
        }),
      );

      const trackedDuration = mockAnalyticsService.trackEvent.mock.calls[0][0]
        .properties.duration as number;
      expect(trackedDuration).toBeGreaterThanOrEqual(50);
    });
  });
});
