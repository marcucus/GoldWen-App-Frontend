import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UsersService } from '../users.service';
import { User } from '../../../database/entities/user.entity';
import { Profile } from '../../../database/entities/profile.entity';
import { Match } from '../../../database/entities/match.entity';
import { Message } from '../../../database/entities/message.entity';
import { Subscription } from '../../../database/entities/subscription.entity';
import { DailySelection } from '../../../database/entities/daily-selection.entity';
import { PushToken } from '../../../database/entities/push-token.entity';
import { FontSize, UserStatus } from '../../../common/enums';
import { UpdateAccessibilitySettingsDto } from '../dto/accessibility-settings.dto';
import { NotFoundException } from '@nestjs/common';

describe('UsersService - Accessibility Settings', () => {
  let service: UsersService;

  const mockUser: Partial<User> = {
    id: 'user-uuid',
    email: 'test@example.com',
    status: UserStatus.ACTIVE,
    fontSize: FontSize.MEDIUM,
    highContrast: false,
    reducedMotion: false,
    screenReader: false,
  };

  const mockUserRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: getRepositoryToken(Profile),
          useValue: { findOne: jest.fn(), save: jest.fn() },
        },
        {
          provide: getRepositoryToken(Match),
          useValue: { count: jest.fn(), createQueryBuilder: jest.fn() },
        },
        {
          provide: getRepositoryToken(Message),
          useValue: { count: jest.fn() },
        },
        {
          provide: getRepositoryToken(Subscription),
          useValue: { findOne: jest.fn() },
        },
        {
          provide: getRepositoryToken(DailySelection),
          useValue: { createQueryBuilder: jest.fn() },
        },
        {
          provide: getRepositoryToken(PushToken),
          useValue: {
            find: jest.fn(),
            findOne: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
            remove: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getAccessibilitySettings', () => {
    it('should return accessibility settings for a user', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockUser);

      const result = await service.getAccessibilitySettings('user-uuid');

      expect(result).toEqual({
        fontSize: FontSize.MEDIUM,
        highContrast: false,
        reducedMotion: false,
        screenReader: false,
      });
      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { id: 'user-uuid' },
        relations: ['profile', 'profile.photos', 'profile.promptAnswers'],
      });
    });

    it('should throw NotFoundException if user does not exist', async () => {
      mockUserRepository.findOne.mockResolvedValue(null);

      await expect(
        service.getAccessibilitySettings('non-existent-uuid'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('updateAccessibilitySettings', () => {
    it('should update all accessibility settings when provided', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {
        fontSize: FontSize.LARGE,
        highContrast: true,
        reducedMotion: true,
        screenReader: true,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockUserRepository.save.mockResolvedValue({ ...mockUser, ...updateDto });

      await service.updateAccessibilitySettings('user-uuid', updateDto);

      expect(mockUserRepository.save).toHaveBeenCalledWith({
        ...mockUser,
        fontSize: FontSize.LARGE,
        highContrast: true,
        reducedMotion: true,
        screenReader: true,
      });
    });

    it('should update only fontSize when only fontSize is provided', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {
        fontSize: FontSize.XLARGE,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockUserRepository.save.mockResolvedValue({
        ...mockUser,
        fontSize: FontSize.XLARGE,
      });

      await service.updateAccessibilitySettings('user-uuid', updateDto);

      expect(mockUserRepository.save).toHaveBeenCalledWith({
        ...mockUser,
        fontSize: FontSize.XLARGE,
      });
    });

    it('should update only boolean settings when provided', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {
        highContrast: true,
        screenReader: true,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockUserRepository.save.mockResolvedValue({
        ...mockUser,
        highContrast: true,
        screenReader: true,
      });

      await service.updateAccessibilitySettings('user-uuid', updateDto);

      expect(mockUserRepository.save).toHaveBeenCalledWith({
        ...mockUser,
        highContrast: true,
        screenReader: true,
      });
    });

    it('should not modify settings that are not provided', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {
        fontSize: FontSize.SMALL,
      };

      const userWithExistingSettings = {
        ...mockUser,
        highContrast: true,
        reducedMotion: true,
        screenReader: true,
      };

      mockUserRepository.findOne.mockResolvedValue(userWithExistingSettings);
      mockUserRepository.save.mockResolvedValue({
        ...userWithExistingSettings,
        fontSize: FontSize.SMALL,
      });

      await service.updateAccessibilitySettings('user-uuid', updateDto);

      expect(mockUserRepository.save).toHaveBeenCalledWith({
        ...userWithExistingSettings,
        fontSize: FontSize.SMALL,
        // Other settings should remain unchanged
        highContrast: true,
        reducedMotion: true,
        screenReader: true,
      });
    });

    it('should handle empty update dto without errors', async () => {
      const updateDto: UpdateAccessibilitySettingsDto = {};

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockUserRepository.save.mockResolvedValue(mockUser);

      await service.updateAccessibilitySettings('user-uuid', updateDto);

      // Should save user without any changes
      expect(mockUserRepository.save).toHaveBeenCalledWith(mockUser);
    });

    it('should throw NotFoundException if user does not exist', async () => {
      mockUserRepository.findOne.mockResolvedValue(null);

      const updateDto: UpdateAccessibilitySettingsDto = {
        fontSize: FontSize.LARGE,
      };

      await expect(
        service.updateAccessibilitySettings('non-existent-uuid', updateDto),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
