import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import { ProfileCompletionGuard } from '../guards/profile-completion.guard';
import { User } from '../../../database/entities/user.entity';

describe('ProfileCompletionGuard', () => {
  let guard: ProfileCompletionGuard;
  let userRepository: Repository<User>;
  let reflector: Reflector;

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockReflector = {
    getAllAndOverride: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProfileCompletionGuard,
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: Reflector,
          useValue: mockReflector,
        },
      ],
    }).compile();

    guard = module.get<ProfileCompletionGuard>(ProfileCompletionGuard);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    reflector = module.get<Reflector>(Reflector);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  const createMockExecutionContext = (user: any = { id: 'user-id' }) => ({
    switchToHttp: () => ({
      getRequest: () => ({ user }),
    }),
    getHandler: jest.fn(),
    getClass: jest.fn(),
  });

  describe('canActivate', () => {
    it('should allow access when skip profile completion is set', async () => {
      mockReflector.getAllAndOverride.mockReturnValue(true);

      const context = createMockExecutionContext();
      const result = await guard.canActivate(context as any);

      expect(result).toBe(true);
      expect(mockUserRepository.findOne).not.toHaveBeenCalled();
    });

    it('should allow access when profile is completed', async () => {
      mockReflector.getAllAndOverride.mockReturnValue(false);
      mockUserRepository.findOne.mockResolvedValue({
        isProfileCompleted: true,
      });

      const context = createMockExecutionContext();
      const result = await guard.canActivate(context as any);

      expect(result).toBe(true);
      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { id: 'user-id' },
        select: ['isProfileCompleted'],
      });
    });

    it('should throw ForbiddenException when profile is incomplete', async () => {
      mockReflector.getAllAndOverride.mockReturnValue(false);
      mockUserRepository.findOne.mockResolvedValue({
        isProfileCompleted: false,
      });

      const context = createMockExecutionContext();

      await expect(guard.canActivate(context as any)).rejects.toThrow(
        new ForbiddenException({
          message: 'Profile must be completed before accessing this feature',
          code: 'PROFILE_INCOMPLETE',
          nextStep: '/profile/completion',
        }),
      );
    });

    it('should throw ForbiddenException when user is not found', async () => {
      mockReflector.getAllAndOverride.mockReturnValue(false);
      mockUserRepository.findOne.mockResolvedValue(null);

      const context = createMockExecutionContext();

      await expect(guard.canActivate(context as any)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should return false when no user in request', async () => {
      mockReflector.getAllAndOverride.mockReturnValue(false);

      const context = createMockExecutionContext(null);
      const result = await guard.canActivate(context as any);

      expect(result).toBe(false);
    });
  });
});
