import { Test, TestingModule } from '@nestjs/testing';
import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConsentGuard, SKIP_CONSENT_CHECK } from './consent.guard';
import { UserConsent } from '../../../database/entities/user-consent.entity';

describe('ConsentGuard', () => {
  let guard: ConsentGuard;
  let repository: Repository<UserConsent>;
  let reflector: Reflector;

  const mockUserConsent: UserConsent = {
    id: '123e4567-e89b-12d3-a456-426614174000',
    userId: 'user-123',
    dataProcessing: true,
    marketing: false,
    analytics: false,
    consentedAt: new Date(),
    ipAddress: '127.0.0.1',
    isActive: true,
    revokedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    user: null,
  };

  const mockRepository = {
    findOne: jest.fn(),
  };

  const mockReflector = {
    getAllAndOverride: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ConsentGuard,
        {
          provide: getRepositoryToken(UserConsent),
          useValue: mockRepository,
        },
        {
          provide: Reflector,
          useValue: mockReflector,
        },
      ],
    }).compile();

    guard = module.get<ConsentGuard>(ConsentGuard);
    repository = module.get<Repository<UserConsent>>(
      getRepositoryToken(UserConsent),
    );
    reflector = module.get<Reflector>(Reflector);

    jest.clearAllMocks();
  });

  const createMockExecutionContext = (
    user: any,
    skipConsent = false,
  ): ExecutionContext => {
    mockReflector.getAllAndOverride.mockReturnValue(skipConsent);

    return {
      switchToHttp: () => ({
        getRequest: () => ({
          user,
        }),
      }),
      getHandler: jest.fn(),
      getClass: jest.fn(),
    } as any;
  };

  it('should be defined', () => {
    expect(guard).toBeDefined();
  });

  describe('canActivate', () => {
    it('should allow access if skip consent check is set', async () => {
      const context = createMockExecutionContext({ id: 'user-123' }, true);

      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockRepository.findOne).not.toHaveBeenCalled();
    });

    it('should deny access if user is not authenticated', async () => {
      const context = createMockExecutionContext(null);

      const result = await guard.canActivate(context);

      expect(result).toBe(false);
      expect(mockRepository.findOne).not.toHaveBeenCalled();
    });

    it('should allow access if user has valid consent', async () => {
      const context = createMockExecutionContext({ id: 'user-123' });
      mockRepository.findOne.mockResolvedValue(mockUserConsent);

      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockRepository.findOne).toHaveBeenCalledWith({
        where: { userId: 'user-123', isActive: true },
        order: { createdAt: 'DESC' },
      });
    });

    it('should deny access if user has no consent', async () => {
      const context = createMockExecutionContext({ id: 'user-123' });
      mockRepository.findOne.mockResolvedValue(null);

      await expect(guard.canActivate(context)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should deny access if user has consent but dataProcessing is false', async () => {
      const context = createMockExecutionContext({ id: 'user-123' });
      mockRepository.findOne.mockResolvedValue({
        ...mockUserConsent,
        dataProcessing: false,
      });

      await expect(guard.canActivate(context)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw ForbiddenException with proper error details', async () => {
      const context = createMockExecutionContext({ id: 'user-123' });
      mockRepository.findOne.mockResolvedValue(null);

      try {
        await guard.canActivate(context);
        fail('Should have thrown ForbiddenException');
      } catch (error) {
        expect(error).toBeInstanceOf(ForbiddenException);
        expect(error.getResponse()).toMatchObject({
          message: expect.stringContaining('consent required'),
          code: 'CONSENT_REQUIRED',
          nextStep: '/consent',
        });
      }
    });
  });
});
