import { Test, TestingModule } from '@nestjs/testing';
import { Request } from 'express';
import { UsersController } from '../users.controller';
import { UsersService } from '../users.service';
import { ProfilesService } from '../../profiles/profiles.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Profile } from '../../../database/entities/profile.entity';
import { PromptAnswer } from '../../../database/entities/prompt-answer.entity';
import { FontSize } from '../../../common/enums';
import { UpdateAccessibilitySettingsDto } from '../dto/accessibility-settings.dto';
import { SuccessResponseDto } from '../../../common/dto/response.dto';

describe('UsersController - Accessibility Settings', () => {
  let controller: UsersController;
  let usersService: UsersService;

  const mockUsersService = {
    getAccessibilitySettings: jest.fn(),
    updateAccessibilitySettings: jest.fn(),
  };

  const mockProfilesService = {};
  const mockProfileRepository = {};
  const mockPromptAnswerRepository = {};

  const mockRequest = {
    user: {
      id: 'user-uuid',
      email: 'test@example.com',
    },
  } as Request;

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
    usersService = module.get<UsersService>(UsersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /users/me/accessibility-settings', () => {
    it('should return accessibility settings for authenticated user', async () => {
      const mockSettings = {
        fontSize: FontSize.MEDIUM,
        highContrast: false,
        reducedMotion: false,
        screenReader: false,
      };

      mockUsersService.getAccessibilitySettings.mockResolvedValue(mockSettings);

      const result = await controller.getAccessibilitySettings(mockRequest);

      expect(result).toEqual({
        success: true,
        data: mockSettings,
      });
      expect(usersService.getAccessibilitySettings).toHaveBeenCalledWith(
        'user-uuid',
      );
    });

    it('should return settings with custom values', async () => {
      const mockSettings = {
        fontSize: FontSize.LARGE,
        highContrast: true,
        reducedMotion: true,
        screenReader: true,
      };

      mockUsersService.getAccessibilitySettings.mockResolvedValue(mockSettings);

      const result = await controller.getAccessibilitySettings(mockRequest);

      expect(result).toEqual({
        success: true,
        data: mockSettings,
      });
      expect(usersService.getAccessibilitySettings).toHaveBeenCalledWith(
        'user-uuid',
      );
    });
  });

  describe('PUT /users/me/accessibility-settings', () => {
    it('should update all accessibility settings', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {
        fontSize: FontSize.LARGE,
        highContrast: true,
        reducedMotion: true,
        screenReader: true,
      };

      mockUsersService.updateAccessibilitySettings.mockResolvedValue(undefined);

      const result = await controller.updateAccessibilitySettings(
        mockRequest,
        updateDto,
      );

      expect(result).toBeInstanceOf(SuccessResponseDto);
      expect(result.message).toBe(
        'Accessibility settings updated successfully',
      );
      expect(usersService.updateAccessibilitySettings).toHaveBeenCalledWith(
        'user-uuid',
        updateDto,
      );
    });

    it('should update only fontSize', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {
        fontSize: FontSize.XLARGE,
      };

      mockUsersService.updateAccessibilitySettings.mockResolvedValue(undefined);

      const result = await controller.updateAccessibilitySettings(
        mockRequest,
        updateDto,
      );

      expect(result).toBeInstanceOf(SuccessResponseDto);
      expect(usersService.updateAccessibilitySettings).toHaveBeenCalledWith(
        'user-uuid',
        updateDto,
      );
    });

    it('should update only boolean settings', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {
        highContrast: true,
        screenReader: false,
      };

      mockUsersService.updateAccessibilitySettings.mockResolvedValue(undefined);

      const result = await controller.updateAccessibilitySettings(
        mockRequest,
        updateDto,
      );

      expect(result).toBeInstanceOf(SuccessResponseDto);
      expect(usersService.updateAccessibilitySettings).toHaveBeenCalledWith(
        'user-uuid',
        updateDto,
      );
    });

    it('should handle empty update request', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {};

      mockUsersService.updateAccessibilitySettings.mockResolvedValue(undefined);

      const result = await controller.updateAccessibilitySettings(
        mockRequest,
        updateDto,
      );

      expect(result).toBeInstanceOf(SuccessResponseDto);
      expect(usersService.updateAccessibilitySettings).toHaveBeenCalledWith(
        'user-uuid',
        updateDto,
      );
    });

    it('should set reduced motion to false explicitly', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {
        reducedMotion: false,
      };

      mockUsersService.updateAccessibilitySettings.mockResolvedValue(undefined);

      const result = await controller.updateAccessibilitySettings(
        mockRequest,
        updateDto,
      );

      expect(result).toBeInstanceOf(SuccessResponseDto);
      expect(usersService.updateAccessibilitySettings).toHaveBeenCalledWith(
        'user-uuid',
        updateDto,
      );
    });
  });

  describe('Error handling', () => {
    it('should propagate service errors for getAccessibilitySettings', async () => {
      const error = new Error('Database connection error');
      mockUsersService.getAccessibilitySettings.mockRejectedValue(error);

      await expect(
        controller.getAccessibilitySettings(mockRequest),
      ).rejects.toThrow(error);
    });

    it('should propagate service errors for updateAccessibilitySettings', async () => {
      const error = new Error('Update failed');
      const updateDto: UpdateAccessibilitySettingsDto = {
        fontSize: FontSize.LARGE,
      };

      mockUsersService.updateAccessibilitySettings.mockRejectedValue(error);

      await expect(
        controller.updateAccessibilitySettings(mockRequest, updateDto),
      ).rejects.toThrow(error);
    });
  });
});
