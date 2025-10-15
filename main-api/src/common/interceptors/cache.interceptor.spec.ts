import { Test } from '@nestjs/testing';
import { ExecutionContext, CallHandler } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { of } from 'rxjs';
import { CacheInterceptor, CACHE_STRATEGY_KEY } from './cache.interceptor';
import { CacheStrategy, CacheHeaders } from '../enums/cache-strategy.enum';

describe('CacheInterceptor', () => {
  let interceptor: CacheInterceptor;
  let reflector: jest.Mocked<Reflector>;

  const mockResponse = {
    setHeader: jest.fn(),
  };

  const mockContext = {
    switchToHttp: () => ({
      getResponse: () => mockResponse,
    }),
    getHandler: jest.fn(),
  } as any as ExecutionContext;

  const mockCallHandler = {
    handle: () => of({ test: 'data' }),
  } as CallHandler;

  beforeEach(async () => {
    reflector = {
      get: jest.fn(),
    } as any;

    const module = await Test.createTestingModule({
      providers: [
        CacheInterceptor,
        {
          provide: Reflector,
          useValue: reflector,
        },
      ],
    }).compile();

    interceptor = module.get<CacheInterceptor>(CacheInterceptor);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Cache header application', () => {
    it('should apply short cache headers when strategy is SHORT_CACHE', (done) => {
      reflector.get.mockReturnValue(CacheStrategy.SHORT_CACHE);

      interceptor
        .intercept(mockContext, mockCallHandler)
        .subscribe((result) => {
          expect(mockResponse.setHeader).toHaveBeenCalledWith(
            'Cache-Control',
            CacheHeaders[CacheStrategy.SHORT_CACHE]['Cache-Control'],
          );
          expect(mockResponse.setHeader).toHaveBeenCalledWith(
            'ETag',
            expect.any(String),
          );
          expect(result.metadata).toEqual(
            expect.objectContaining({
              cacheExpiry: expect.any(String),
            }),
          );
          done();
        });
    });

    it('should apply medium cache headers when strategy is MEDIUM_CACHE', (done) => {
      reflector.get.mockReturnValue(CacheStrategy.MEDIUM_CACHE);

      interceptor
        .intercept(mockContext, mockCallHandler)
        .subscribe((result) => {
          expect(mockResponse.setHeader).toHaveBeenCalledWith(
            'Cache-Control',
            CacheHeaders[CacheStrategy.MEDIUM_CACHE]['Cache-Control'],
          );
          expect(mockResponse.setHeader).toHaveBeenCalledWith(
            'ETag',
            expect.any(String),
          );
          done();
        });
    });

    it('should apply no-cache headers when strategy is NO_CACHE', (done) => {
      reflector.get.mockReturnValue(CacheStrategy.NO_CACHE);

      interceptor
        .intercept(mockContext, mockCallHandler)
        .subscribe((result) => {
          const noCacheHeaders = CacheHeaders[CacheStrategy.NO_CACHE];
          Object.entries(noCacheHeaders).forEach(([key, value]) => {
            expect(mockResponse.setHeader).toHaveBeenCalledWith(key, value);
          });
          expect(mockResponse.setHeader).not.toHaveBeenCalledWith(
            'ETag',
            expect.any(String),
          );
          done();
        });
    });

    it('should not apply cache headers when no strategy is defined', (done) => {
      reflector.get.mockReturnValue(undefined);

      interceptor
        .intercept(mockContext, mockCallHandler)
        .subscribe((result) => {
          expect(mockResponse.setHeader).not.toHaveBeenCalled();
          expect(result).toEqual({ test: 'data' });
          done();
        });
    });
  });

  describe('ETag generation', () => {
    it('should generate consistent ETags for same data', (done) => {
      reflector.get.mockReturnValue(CacheStrategy.MEDIUM_CACHE);

      // First call
      interceptor.intercept(mockContext, mockCallHandler).subscribe(() => {
        const firstETag = mockResponse.setHeader.mock.calls.find(
          (call) => call[0] === 'ETag',
        )?.[1];

        // Reset mock
        mockResponse.setHeader.mockClear();

        // Second call with same data
        interceptor.intercept(mockContext, mockCallHandler).subscribe(() => {
          const secondETag = mockResponse.setHeader.mock.calls.find(
            (call) => call[0] === 'ETag',
          )?.[1];

          expect(firstETag).toBe(secondETag);
          done();
        });
      });
    });

    it('should generate different ETags for different data', (done) => {
      reflector.get.mockReturnValue(CacheStrategy.MEDIUM_CACHE);

      const firstCallHandler = {
        handle: () => of({ data: 'first' }),
      } as CallHandler;

      const secondCallHandler = {
        handle: () => of({ data: 'second' }),
      } as CallHandler;

      // First call
      interceptor.intercept(mockContext, firstCallHandler).subscribe(() => {
        const firstETag = mockResponse.setHeader.mock.calls.find(
          (call) => call[0] === 'ETag',
        )?.[1];

        // Reset mock
        mockResponse.setHeader.mockClear();

        // Second call with different data
        interceptor.intercept(mockContext, secondCallHandler).subscribe(() => {
          const secondETag = mockResponse.setHeader.mock.calls.find(
            (call) => call[0] === 'ETag',
          )?.[1];

          expect(firstETag).not.toBe(secondETag);
          done();
        });
      });
    });
  });

  describe('Cache expiry metadata', () => {
    it('should add cache expiry to response metadata for SHORT_CACHE', (done) => {
      reflector.get.mockReturnValue(CacheStrategy.SHORT_CACHE);

      interceptor
        .intercept(mockContext, mockCallHandler)
        .subscribe((result) => {
          expect(result.metadata.cacheExpiry).toBeDefined();
          const expiry = new Date(result.metadata.cacheExpiry);
          const now = new Date();
          const diffInMinutes =
            (expiry.getTime() - now.getTime()) / (1000 * 60);
          expect(diffInMinutes).toBeCloseTo(5, 0); // 5 minutes ±1
          done();
        });
    });

    it('should add cache expiry to response metadata for LONG_CACHE', (done) => {
      reflector.get.mockReturnValue(CacheStrategy.LONG_CACHE);

      interceptor
        .intercept(mockContext, mockCallHandler)
        .subscribe((result) => {
          expect(result.metadata.cacheExpiry).toBeDefined();
          const expiry = new Date(result.metadata.cacheExpiry);
          const now = new Date();
          const diffInHours =
            (expiry.getTime() - now.getTime()) / (1000 * 60 * 60);
          expect(diffInHours).toBeCloseTo(24, 0); // 24 hours ±1
          done();
        });
    });

    it('should not add cache expiry for NO_CACHE strategy', (done) => {
      reflector.get.mockReturnValue(CacheStrategy.NO_CACHE);

      interceptor
        .intercept(mockContext, mockCallHandler)
        .subscribe((result) => {
          expect(result.metadata?.cacheExpiry).toBeUndefined();
          done();
        });
    });
  });
});
