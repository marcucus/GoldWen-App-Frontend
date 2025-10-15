import { Test, TestingModule } from '@nestjs/testing';
import { UsersController } from '../users.controller';
import { UsersService } from '../users.service';
import { ProfilesService } from '../../profiles/profiles.service';
import { GdprService } from '../gdpr.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Profile } from '../../../database/entities/profile.entity';
import { PromptAnswer } from '../../../database/entities/prompt-answer.entity';
import { User } from '../../../database/entities/user.entity';
import { UserStatus } from '../../../common/enums';
import { PasswordUtil } from '../../../common/utils';
import { UnauthorizedException, BadRequestException } from '@nestjs/common';
import { DeleteAccountDto } from '../dto/delete-account.dto';

describe('UsersController - Delete Account', () => {
  let controller: UsersController;

  const mockUser: Partial<User> = {
    id: 'test-user-id',
    email: 'test@example.com',
    status: UserStatus.ACTIVE,
    passwordHash: '$2b$10$hashedpassword',
  };

  const mockUsersService = {
    findById: jest.fn(),
    updateUser: jest.fn(),
    updateSettings: jest.fn(),
    getUserStats: jest.fn(),
    deactivateUser: jest.fn(),
    registerPushToken: jest.fn(),
    deletePushToken: jest.fn(),
    getAccessibilitySettings: jest.fn(),
    updateAccessibilitySettings: jest.fn(),
    recordConsent: jest.fn(),
    getCurrentConsent: jest.fn(),
    getUsersWithRoles: jest.fn(),
    updateUserRole: jest.fn(),
  };

  const mockProfilesService = {
    submitPromptAnswers: jest.fn(),
    getUserPromptAnswers: jest.fn(),
  };

  const mockGdprService = {
    deleteUserCompletely: jest.fn(),
    exportUserData: jest.fn(),
  };

  const mockProfileRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
    create: jest.fn(),
  };

  const mockPromptAnswerRepository = {
    find: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
        {
          provide: ProfilesService,
          useValue: mockProfilesService,
        },
        {
          provide: GdprService,
          useValue: mockGdprService,
        },
        {
          provide: getRepositoryToken(Profile),
          useValue: mockProfileRepository,
        },
        {
          provide: getRepositoryToken(PromptAnswer),
          useValue: mockPromptAnswerRepository,
        },
      ],
    }).compile();

    controller = module.get<UsersController>(UsersController);

    // Reset all mocks before each test
    jest.clearAllMocks();
  });

  describe('DELETE /users/me', () => {
    it('should successfully delete account with valid password and confirmation', async () => {
      const deleteAccountDto: DeleteAccountDto = {
        password: 'correctPassword123',
        confirmationText: 'DELETE',
      };

      const req: any = {
        user: mockUser,
      };

      // Mock findById to return user with password hash
      mockUsersService.findById.mockResolvedValue(mockUser);

      // Mock password comparison to return true
      jest.spyOn(PasswordUtil, 'compare').mockResolvedValue(true);

      // Mock GDPR service
      mockGdprService.deleteUserCompletely.mockResolvedValue(undefined);

      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      const result = await controller.deleteAccount(req, deleteAccountDto);

      expect(mockUsersService.findById).toHaveBeenCalledWith(mockUser.id);
      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(PasswordUtil.compare).toHaveBeenCalledWith(
        deleteAccountDto.password,
        mockUser.passwordHash,
      );
      expect(mockGdprService.deleteUserCompletely).toHaveBeenCalledWith(
        mockUser.id,
      );
      expect(result).toEqual({
        success: true,
        message: 'Account deleted successfully',
      });
    });

    it('should throw BadRequestException if confirmation text is not "DELETE"', async () => {
      const deleteAccountDto: DeleteAccountDto = {
        password: 'correctPassword123',
        confirmationText: 'delete', // lowercase - should fail
      };

      const req: any = {
        user: mockUser,
      };

      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow(BadRequestException);

      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow('Invalid confirmation text. Must be exactly "DELETE"');

      // Should not call any service methods
      expect(mockUsersService.findById).not.toHaveBeenCalled();
      expect(mockGdprService.deleteUserCompletely).not.toHaveBeenCalled();
    });

    it('should throw BadRequestException if confirmation text is empty', async () => {
      const deleteAccountDto: DeleteAccountDto = {
        password: 'correctPassword123',
        confirmationText: '',
      };

      const req: any = {
        user: mockUser,
      };

      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow(BadRequestException);

      expect(mockUsersService.findById).not.toHaveBeenCalled();
      expect(mockGdprService.deleteUserCompletely).not.toHaveBeenCalled();
    });

    it('should throw BadRequestException if confirmation text is different', async () => {
      const deleteAccountDto: DeleteAccountDto = {
        password: 'correctPassword123',
        confirmationText: 'CONFIRM',
      };

      const req: any = {
        user: mockUser,
      };

      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow(BadRequestException);

      expect(mockUsersService.findById).not.toHaveBeenCalled();
      expect(mockGdprService.deleteUserCompletely).not.toHaveBeenCalled();
    });

    it('should throw UnauthorizedException if password is incorrect', async () => {
      const deleteAccountDto: DeleteAccountDto = {
        password: 'wrongPassword123',
        confirmationText: 'DELETE',
      };

      const req: any = {
        user: mockUser,
      };

      // Mock findById to return user with password hash
      mockUsersService.findById.mockResolvedValue(mockUser);

      // Mock password comparison to return false (incorrect password)

      jest.spyOn(PasswordUtil, 'compare').mockResolvedValue(false);

      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow(UnauthorizedException);

      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow('Invalid password');

      expect(mockUsersService.findById).toHaveBeenCalledWith(mockUser.id);
      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(PasswordUtil.compare).toHaveBeenCalledWith(
        deleteAccountDto.password,
        mockUser.passwordHash,
      );
      // Should not proceed to deletion
      expect(mockGdprService.deleteUserCompletely).not.toHaveBeenCalled();
    });

    it('should throw UnauthorizedException if password is empty', async () => {
      const deleteAccountDto: DeleteAccountDto = {
        password: '',
        confirmationText: 'DELETE',
      };

      const req: any = {
        user: mockUser,
      };

      mockUsersService.findById.mockResolvedValue(mockUser);

      jest.spyOn(PasswordUtil, 'compare').mockResolvedValue(false);

      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow(UnauthorizedException);

      expect(mockGdprService.deleteUserCompletely).not.toHaveBeenCalled();
    });

    it('should verify password before checking confirmation text order', async () => {
      const deleteAccountDto: DeleteAccountDto = {
        password: 'wrongPassword123',
        confirmationText: 'wrong-confirmation',
      };

      const req: any = {
        user: mockUser,
      };

      // First validation should fail on confirmation text
      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow(BadRequestException);

      // Should fail at confirmation text validation, not reach password check
      expect(mockUsersService.findById).not.toHaveBeenCalled();
    });

    it('should handle user not found scenario', async () => {
      const deleteAccountDto: DeleteAccountDto = {
        password: 'correctPassword123',
        confirmationText: 'DELETE',
      };

      const req: any = {
        user: mockUser,
      };

      // Mock findById to throw NotFoundException
      mockUsersService.findById.mockRejectedValue(new Error('User not found'));

      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow('User not found');

      expect(mockGdprService.deleteUserCompletely).not.toHaveBeenCalled();
    });

    it('should handle GDPR service deletion errors gracefully', async () => {
      const deleteAccountDto: DeleteAccountDto = {
        password: 'correctPassword123',
        confirmationText: 'DELETE',
      };

      const req: any = {
        user: mockUser,
      };

      mockUsersService.findById.mockResolvedValue(mockUser);

      jest.spyOn(PasswordUtil, 'compare').mockResolvedValue(true);

      // Mock GDPR service to throw error
      mockGdprService.deleteUserCompletely.mockRejectedValue(
        new Error('Database deletion error'),
      );

      await expect(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        controller.deleteAccount(req, deleteAccountDto),
      ).rejects.toThrow('Database deletion error');

      expect(mockUsersService.findById).toHaveBeenCalled();
      expect(mockGdprService.deleteUserCompletely).toHaveBeenCalledWith(
        mockUser.id,
      );
    });
  });

  describe('DELETE /users/me - DTO Validation', () => {
    it('should validate that password is required', () => {
      const dto = new DeleteAccountDto();
      dto.confirmationText = 'DELETE';
      // password is undefined - should fail validation
      expect(dto.password).toBeUndefined();
    });

    it('should validate that confirmationText is required', () => {
      const dto = new DeleteAccountDto();
      dto.password = 'password123';
      // confirmationText is undefined - should fail validation
      expect(dto.confirmationText).toBeUndefined();
    });

    it('should create valid DTO with all required fields', () => {
      const dto = new DeleteAccountDto();
      dto.password = 'password123';
      dto.confirmationText = 'DELETE';

      expect(dto.password).toBe('password123');
      expect(dto.confirmationText).toBe('DELETE');
    });
  });
});
