import { Test, TestingModule } from '@nestjs/testing';
import { PreferencesController } from '../preferences.controller';
import { PreferencesService } from '../preferences.service';
import { FontSize, Gender } from '../../../common/enums';

describe('PreferencesController', () => {
  let controller: PreferencesController;
  let service: PreferencesService;

  const mockUser = {
    id: 'user-123',
  };

  const mockPreferences = {
    notifications: {
      dailySelection: true,
      newMatches: true,
      newMessages: true,
      chatExpiring: true,
      subscriptionUpdates: true,
      marketingEmails: false,
      pushNotifications: true,
      emailNotifications: true,
    },
    privacy: {
      analytics: false,
      marketing: false,
      functionalCookies: true,
      dataRetention: undefined,
    },
    accessibility: {
      fontSize: FontSize.MEDIUM,
      highContrast: false,
      reducedMotion: false,
      screenReader: false,
    },
    filters: {
      ageMin: 25,
      ageMax: 35,
      maxDistance: 50,
      preferredGenders: [Gender.WOMAN],
      showMeInDiscovery: true,
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PreferencesController],
      providers: [
        {
          provide: PreferencesService,
          useValue: {
            getUserPreferences: jest.fn(),
            updateUserPreferences: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<PreferencesController>(PreferencesController);
    service = module.get<PreferencesService>(PreferencesService);
  });

  describe('getMyPreferences', () => {
    it('should return user preferences', async () => {
      jest
        .spyOn(service, 'getUserPreferences')
        .mockResolvedValue(mockPreferences);

      const req = { user: mockUser } as any;
      const result = await controller.getMyPreferences(req);

      expect(result).toEqual({
        success: true,
        data: mockPreferences,
      });

      expect(service.getUserPreferences).toHaveBeenCalledWith('user-123');
    });
  });

  describe('updateMyPreferences', () => {
    it('should update user preferences successfully', async () => {
      const updateDto = {
        notifications: {
          dailySelection: false,
        },
      };

      const mockResult = {
        message: 'User preferences updated successfully',
        preferences: mockPreferences,
      };

      jest
        .spyOn(service, 'updateUserPreferences')
        .mockResolvedValue(mockResult);

      const req = { user: mockUser } as any;
      const result = await controller.updateMyPreferences(req, updateDto);

      expect(result).toEqual({
        success: true,
        message: mockResult.message,
        data: mockResult.preferences,
      });

      expect(service.updateUserPreferences).toHaveBeenCalledWith(
        'user-123',
        updateDto,
      );
    });
  });
});
