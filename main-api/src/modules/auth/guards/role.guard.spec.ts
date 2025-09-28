import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ForbiddenException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { RoleGuard, Roles } from './role.guard';
import { Reflector } from '@nestjs/core';
import { UserRole } from '../../../common/enums';
import { User } from '../../../database/entities/user.entity';

describe('RoleGuard', () => {
  let guard: RoleGuard;
  let reflector: Reflector;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RoleGuard,
        {
          provide: Reflector,
          useValue: {
            getAllAndOverride: jest.fn(),
          },
        },
      ],
    }).compile();

    guard = module.get<RoleGuard>(RoleGuard);
    reflector = module.get<Reflector>(Reflector);
  });

  it('should be defined', () => {
    expect(guard).toBeDefined();
  });

  describe('canActivate', () => {
    let mockContext: any;
    let mockRequest: any;

    beforeEach(() => {
      mockRequest = {
        user: null,
      };

      mockContext = {
        switchToHttp: () => ({
          getRequest: () => mockRequest,
        }),
        getHandler: jest.fn(),
        getClass: jest.fn(),
      };
    });

    it('should return true when no roles are required', () => {
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(null);

      const result = guard.canActivate(mockContext);

      expect(result).toBe(true);
    });

    it('should throw ForbiddenException when user is not authenticated', () => {
      jest
        .spyOn(reflector, 'getAllAndOverride')
        .mockReturnValue([UserRole.ADMIN]);

      expect(() => guard.canActivate(mockContext)).toThrow(ForbiddenException);
    });

    it('should throw ForbiddenException when user has no role defined', () => {
      mockRequest.user = { id: '1', email: 'test@test.com' } as User;
      jest
        .spyOn(reflector, 'getAllAndOverride')
        .mockReturnValue([UserRole.ADMIN]);

      expect(() => guard.canActivate(mockContext)).toThrow(ForbiddenException);
    });

    it('should return true when user has required role', () => {
      mockRequest.user = {
        id: '1',
        email: 'test@test.com',
        role: UserRole.ADMIN,
      } as User;
      jest
        .spyOn(reflector, 'getAllAndOverride')
        .mockReturnValue([UserRole.ADMIN]);

      const result = guard.canActivate(mockContext);

      expect(result).toBe(true);
    });

    it('should allow admin to access moderator endpoints', () => {
      mockRequest.user = {
        id: '1',
        email: 'test@test.com',
        role: UserRole.ADMIN,
      } as User;
      jest
        .spyOn(reflector, 'getAllAndOverride')
        .mockReturnValue([UserRole.MODERATOR]);

      const result = guard.canActivate(mockContext);

      expect(result).toBe(true);
    });

    it('should throw ForbiddenException when user lacks required role', () => {
      mockRequest.user = {
        id: '1',
        email: 'test@test.com',
        role: UserRole.USER,
      } as User;
      jest
        .spyOn(reflector, 'getAllAndOverride')
        .mockReturnValue([UserRole.ADMIN]);

      expect(() => guard.canActivate(mockContext)).toThrow(ForbiddenException);
    });

    it('should return true when user has one of multiple required roles', () => {
      mockRequest.user = {
        id: '1',
        email: 'test@test.com',
        role: UserRole.MODERATOR,
      } as User;
      jest
        .spyOn(reflector, 'getAllAndOverride')
        .mockReturnValue([UserRole.ADMIN, UserRole.MODERATOR]);

      const result = guard.canActivate(mockContext);

      expect(result).toBe(true);
    });
  });
});
