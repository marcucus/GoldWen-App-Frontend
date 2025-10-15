import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';

import { UsersService } from './users.service';
import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { Match } from '../../database/entities/match.entity';
import { Message } from '../../database/entities/message.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { PushToken } from '../../database/entities/push-token.entity';
import { UserConsent } from '../../database/entities/user-consent.entity';
import { CustomLoggerService } from '../../common/logger/logger.service';
import { UserRole } from '../../common/enums';
import { UpdateUserRoleDto } from './dto/role-management.dto';

describe('UsersService Role Management', () => {
  let service: UsersService;
  let userRepository: Repository<User>;
  let logger: CustomLoggerService;

  const mockUser = {
    id: '1',
    email: 'test@test.com',
    role: UserRole.USER,
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: getRepositoryToken(User),
          useValue: {
            findOne: jest.fn(),
            findAndCount: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Profile),
          useValue: {},
        },
        {
          provide: getRepositoryToken(Match),
          useValue: {},
        },
        {
          provide: getRepositoryToken(Message),
          useValue: {},
        },
        {
          provide: getRepositoryToken(Subscription),
          useValue: {},
        },
        {
          provide: getRepositoryToken(DailySelection),
          useValue: {},
        },
        {
          provide: getRepositoryToken(PushToken),
          useValue: {},
        },
        {
          provide: getRepositoryToken(UserConsent),
          useValue: {},
        },
        {
          provide: CustomLoggerService,
          useValue: {
            logAuditTrail: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  describe('getUsersWithRoles', () => {
    it('should return paginated list of users with roles', async () => {
      const mockUsers = [mockUser];
      const mockTotal = 1;

      jest
        .spyOn(userRepository, 'findAndCount')
        .mockResolvedValue([mockUsers, mockTotal]);

      const result = await service.getUsersWithRoles(1, 10);

      expect(result).toEqual({
        users: [
          {
            id: mockUser.id,
            email: mockUser.email,
            role: mockUser.role,
            updatedAt: mockUser.updatedAt,
          },
        ],
        total: mockTotal,
        page: 1,
        limit: 10,
      });

      expect(userRepository.findAndCount).toHaveBeenCalledWith({
        select: ['id', 'email', 'role', 'updatedAt'],
        skip: 0,
        take: 10,
        order: { updatedAt: 'DESC' },
      });
    });
  });

  describe('updateUserRole', () => {
    it('should update user role successfully', async () => {
      const updateRoleDto: UpdateUserRoleDto = { role: UserRole.MODERATOR };
      const adminUserId = 'admin-1';
      const userCopy = { ...mockUser };

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(userCopy as User);
      jest.spyOn(userRepository, 'save').mockResolvedValue({
        ...userCopy,
        role: UserRole.MODERATOR,
      } as User);

      const result = await service.updateUserRole(
        mockUser.id,
        updateRoleDto,
        adminUserId,
      );

      expect(result).toEqual({
        id: mockUser.id,
        email: mockUser.email,
        role: UserRole.MODERATOR,
        updatedAt: mockUser.updatedAt,
      });

      expect(logger.logAuditTrail).toHaveBeenCalledWith('role_change', 'user', {
        targetUserId: mockUser.id,
        targetUserEmail: mockUser.email,
        oldRole: UserRole.USER,
        newRole: UserRole.MODERATOR,
        adminUserId,
        timestamp: expect.any(String),
      });
    });

    it('should throw NotFoundException when user not found', async () => {
      const updateRoleDto: UpdateUserRoleDto = { role: UserRole.MODERATOR };
      const adminUserId = 'admin-1';

      jest.spyOn(userRepository, 'findOne').mockResolvedValue(null);

      await expect(
        service.updateUserRole('non-existent', updateRoleDto, adminUserId),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('getUserRole', () => {
    it('should return user role', async () => {
      const userCopy = { ...mockUser };
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(userCopy as User);

      const result = await service.getUserRole(mockUser.id);

      expect(result).toBe(UserRole.USER);
      expect(userRepository.findOne).toHaveBeenCalledWith({
        where: { id: mockUser.id },
        select: ['role'],
      });
    });

    it('should return default role when user has no role', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue({
        ...mockUser,
        role: null,
      } as User);

      const result = await service.getUserRole(mockUser.id);

      expect(result).toBe(UserRole.USER);
    });

    it('should throw NotFoundException when user not found', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(null);

      await expect(service.getUserRole('non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
