import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';

import { PreferencesService } from '../preferences.service';
import { User } from '../../../database/entities/user.entity';
import { NotificationPreferences } from '../../../database/entities/notification-preferences.entity';
import { UserConsent } from '../../../database/entities/user-consent.entity';
import { Profile } from '../../../database/entities/profile.entity';
import { CustomLoggerService } from '../../../common/logger';
import { FontSize, Gender } from '../../../common/enums';

describe('PreferencesService', () => {
  let service: PreferencesService;
  let userRepository: Repository<User>;
  let notificationPreferencesRepository: Repository<NotificationPreferences>;
  let userConsentRepository: Repository<UserConsent>;
  let profileRepository: Repository<Profile>;
  let logger: CustomLoggerService;

  const mockUser = {
    id: 'user-123',
    fontSize: FontSize.MEDIUM,
    highContrast: false,
    reducedMotion: false,
    screenReader: false,
  };

  const mockNotificationPreferences = {
    id: 'pref-123',
    userId: 'user-123',
    dailySelection: true,
    newMatches: true,
    newMessages: true,
    chatExpiring: true,
    subscriptionUpdates: true,
    marketingEmails: false,
    pushNotifications: true,
    emailNotifications: true,
  };

  const mockUserConsent = {
    id: 'consent-123',
    userId: 'user-123',
    dataProcessing: true,
    marketing: false,
    analytics: false,
    consentedAt: new Date(),
    isActive: true,
  };

  const mockProfile = {
    id: 'profile-123',
    userId: 'user-123',
    minAge: 25,
    maxAge: 35,
    maxDistance: 50,
    interestedInGenders: [Gender.WOMAN],
    showMeInDiscovery: true,
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PreferencesService,
        {
          provide: getRepositoryToken(User),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(NotificationPreferences),
          useValue: {
            findOne: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(UserConsent),
          useValue: {
            findOne: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Profile),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: CustomLoggerService,
          useValue: {
            logUserAction: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<PreferencesService>(PreferencesService);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    notificationPreferencesRepository = module.get<
      Repository<NotificationPreferences>
    >(getRepositoryToken(NotificationPreferences));
    userConsentRepository = module.get<Repository<UserConsent>>(
      getRepositoryToken(UserConsent),
    );
    profileRepository = module.get<Repository<Profile>>(
      getRepositoryToken(Profile),
    );
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  describe('getUserPreferences', () => {
    it('should return user preferences when user exists', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as User);
      jest
        .spyOn(notificationPreferencesRepository, 'findOne')
        .mockResolvedValue(
          mockNotificationPreferences as NotificationPreferences,
        );
      jest
        .spyOn(userConsentRepository, 'findOne')
        .mockResolvedValue(mockUserConsent as UserConsent);
      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as Profile);

      const result = await service.getUserPreferences('user-123');

      expect(result).toEqual({
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
      });

      expect(logger.logUserAction).toHaveBeenCalledWith(
        'get_user_preferences',
        {
          userId: 'user-123',
        },
      );
    });

    it('should throw NotFoundException when user does not exist', async () => {
      jest.spyN(userRepository, 'findOne').mockResolvedValue(null);

      await expect(
        service.getUserPreferences('nonexistent-user'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should create default preferences when they do not exist', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as User);
      jest
        .spyOn(notificationPreferencesRepository, 'findOne')
        .mockResolvedValue(null);
      jest
        .spyOn(notificationPreferencesRepository, 'create')
        .mockReturnValue(
          mockNotificationPreferences as NotificationPreferences,
        );
      jest
        .spyOn(notificationPreferencesRepository, 'save')
        .mockResolvedValue(
          mockNotificationPreferences as NotificationPreferences,
        );
      jest.spyOn(userConsentRepository, 'findOne').mockResolvedValue(null);
      jest
        .spyOn(userConsentRepository, 'create')
        .mockReturnValue(mockUserConsent as UserConsent);
      jest
        .spyOn(userConsentRepository, 'save')
        .mockResolvedValue(mockUserConsent as UserConsent);
      jest
        .spyOn(profileRepository, 'findOne')
        .mockResolvedValue(mockProfile as Profile);

      const result = await service.getUserPreferences('user-123');

      expect(notificationPreferencesRepository.create).toHaveBeenCalledWith({
        userId: 'user-123',
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        subscriptionUpdates: true,
        marketingEmails: false,
        pushNotifications: true,
        emailNotifications: true,
      });

      expect(userConsentRepository.create).toHaveBeenCalledWith({
        userId: 'user-123',
        dataProcessing: true,
        marketing: false,
        analytics: false,
        consentedAt: expect.any(Date),
        isActive: true,
      });

      expect(result.notifications.dailySelection).toBe(true);
    });
  });

  describe('updateUserPreferences', () => {
    it('should update user preferences successfully', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(mockUser as User);
      jest.spyOn(service, 'getUserPreferences').mockResolvedValue({} as any);

      const updateDto = {
        notifications: {
          dailySelection: false,
        },
        accessibility: {
          fontSize: FontSize.LARGE,
        },
      };

      const result = await service.updateUserPreferences('user-123', updateDto);

      expect(result.message).toBe('User preferences updated successfully');
      expect(logger.logUserAction).toHaveBeenCalledWith(
        'update_user_preferences',
        {
          userId: 'user-123',
        },
      );
    });

    it('should throw NotFoundException when user does not exist', async () => {
      jest.spyOn(userRepository, 'findOne').mockResolvedValue(null);

      const updateDto = {
        notifications: {
          dailySelection: false,
        },
      };

      await expect(
        service.updateUserPreferences('nonexistent-user', updateDto),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
