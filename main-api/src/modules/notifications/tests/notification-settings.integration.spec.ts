import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import request from 'supertest';

import { NotificationsController } from '../notifications.controller';
import { NotificationsService } from '../notifications.service';
import { CustomLoggerService } from '../../../common/logger';
import { ScheduledNotificationsService } from '../scheduled-notifications.service';
import { Notification } from '../../../database/entities/notification.entity';
import { User } from '../../../database/entities/user.entity';
import { NotificationPreferences } from '../../../database/entities/notification-preferences.entity';
import { PushToken } from '../../../database/entities/push-token.entity';
import { FcmService } from '../fcm.service';
import { FirebaseService } from '../firebase.service';
import { ConfigService } from '@nestjs/config';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';

describe('Notification Settings Integration Tests', () => {
  let app: INestApplication;
  let notificationsService: NotificationsService;

  const mockUser = {
    id: 'test-user-123',
    email: 'test@example.com',
  };

  const mockJwtAuthGuard = {
    canActivate: jest.fn((context) => {
      const request = context.switchToHttp().getRequest();
      request.user = mockUser;
      return true;
    }),
  };

  const mockNotificationRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
    findAndCount: jest.fn(),
    count: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockNotificationPreferencesRepository = {
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
  };

  const mockPushTokenRepository = {
    findOne: jest.fn(),
    find: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    delete: jest.fn(),
    createQueryBuilder: jest.fn(),
  };

  const mockLogger = {
    logUserAction: jest.fn(),
    logBusinessEvent: jest.fn(),
    setContext: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  };

  const mockFcmService = {
    sendToDevice: jest.fn(),
  };

  const mockFirebaseService = {
    isInitialized: jest.fn(() => true),
    isInvalidTokenError: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === 'app.environment') return 'test';
      return null;
    }),
  };

  const mockScheduledNotificationsService = {
    triggerDailySelectionNotifications: jest.fn(),
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [NotificationsController],
      providers: [
        NotificationsService,
        {
          provide: getRepositoryToken(Notification),
          useValue: mockNotificationRepository,
        },
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: getRepositoryToken(NotificationPreferences),
          useValue: mockNotificationPreferencesRepository,
        },
        {
          provide: getRepositoryToken(PushToken),
          useValue: mockPushTokenRepository,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
        {
          provide: FcmService,
          useValue: mockFcmService,
        },
        {
          provide: FirebaseService,
          useValue: mockFirebaseService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: ScheduledNotificationsService,
          useValue: mockScheduledNotificationsService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue(mockJwtAuthGuard)
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ transform: true }));
    await app.init();

    notificationsService =
      moduleFixture.get<NotificationsService>(NotificationsService);
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    mockJwtAuthGuard.canActivate.mockImplementation((context) => {
      const request = context.switchToHttp().getRequest();
      request.user = mockUser;
      return true;
    });
  });

  describe('GET /notifications/settings', () => {
    it('should return notification settings for existing user', async () => {
      const mockPreferences = {
        id: 'pref-123',
        userId: mockUser.id,
        dailySelection: true,
        newMatches: true,
        newMessages: false,
        chatExpiring: true,
        subscriptionUpdates: true,
        pushNotifications: true,
        emailNotifications: false,
        marketingEmails: false,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockNotificationPreferencesRepository.findOne.mockResolvedValue(
        mockPreferences,
      );

      const response = await request(app.getHttpServer())
        .get('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(response.body).toEqual({
        success: true,
        settings: {
          dailySelection: true,
          newMatches: true,
          newMessages: false,
          chatExpiring: true,
          subscriptionUpdates: true,
          pushNotifications: true,
          emailNotifications: false,
          marketingEmails: false,
        },
      });

      expect(mockLogger.setContext).toHaveBeenCalledWith({
        userId: mockUser.id,
        userEmail: mockUser.email,
      });
      expect(mockLogger.logUserAction).toHaveBeenCalledWith(
        'get_notification_settings',
        { userId: mockUser.id },
      );
    });

    it('should return default settings for new user without preferences', async () => {
      const defaultPreferences = {
        id: 'pref-456',
        userId: mockUser.id,
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        subscriptionUpdates: true,
        pushNotifications: true,
        emailNotifications: true,
        marketingEmails: false,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockNotificationPreferencesRepository.findOne.mockResolvedValue(null);
      mockNotificationPreferencesRepository.create.mockReturnValue(
        defaultPreferences,
      );
      mockNotificationPreferencesRepository.save.mockResolvedValue(
        defaultPreferences,
      );

      const response = await request(app.getHttpServer())
        .get('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(response.body).toEqual({
        success: true,
        settings: {
          dailySelection: true,
          newMatches: true,
          newMessages: true,
          chatExpiring: true,
          subscriptionUpdates: true,
          pushNotifications: true,
          emailNotifications: true,
          marketingEmails: false,
        },
      });

      expect(mockNotificationPreferencesRepository.create).toHaveBeenCalledWith(
        {
          userId: mockUser.id,
          dailySelection: true,
          newMatches: true,
          newMessages: true,
          chatExpiring: true,
          subscriptionUpdates: true,
          pushNotifications: true,
          emailNotifications: true,
          marketingEmails: false,
        },
      );
      expect(mockNotificationPreferencesRepository.save).toHaveBeenCalled();
    });

    it('should return 404 if user does not exist', async () => {
      mockUserRepository.findOne.mockResolvedValue(null);

      const response = await request(app.getHttpServer())
        .get('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .expect(404);

      expect(response.body.message).toBe('User not found');
    });
  });

  describe('PUT /notifications/settings', () => {
    it('should update notification settings with all four core types', async () => {
      const updateDto = {
        dailySelection: false,
        newMatches: false,
        newMessages: false,
        chatExpiring: false,
      };

      const existingPreferences = {
        id: 'pref-123',
        userId: mockUser.id,
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        subscriptionUpdates: true,
        pushNotifications: true,
        emailNotifications: true,
        marketingEmails: false,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockNotificationPreferencesRepository.findOne.mockResolvedValue(
        existingPreferences,
      );
      mockNotificationPreferencesRepository.save.mockResolvedValue({
        ...existingPreferences,
        ...updateDto,
      });

      const response = await request(app.getHttpServer())
        .put('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .send(updateDto)
        .expect(200);

      expect(response.body).toEqual({
        success: true,
        data: {
          message: 'Notification settings updated successfully',
          settings: updateDto,
        },
      });

      expect(mockNotificationPreferencesRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          dailySelection: false,
          newMatches: false,
          newMessages: false,
          chatExpiring: false,
        }),
      );

      expect(mockLogger.logUserAction).toHaveBeenCalledWith(
        'update_notification_settings',
        expect.objectContaining({
          userId: mockUser.id,
          ...updateDto,
        }),
      );
    });

    it('should update notification settings with partial update (daily selection only)', async () => {
      const updateDto = {
        dailySelection: false,
      };

      const existingPreferences = {
        id: 'pref-123',
        userId: mockUser.id,
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        subscriptionUpdates: true,
        pushNotifications: true,
        emailNotifications: true,
        marketingEmails: false,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockNotificationPreferencesRepository.findOne.mockResolvedValue(
        existingPreferences,
      );
      mockNotificationPreferencesRepository.save.mockResolvedValue({
        ...existingPreferences,
        ...updateDto,
      });

      const response = await request(app.getHttpServer())
        .put('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .send(updateDto)
        .expect(200);

      expect(response.body).toEqual({
        success: true,
        data: {
          message: 'Notification settings updated successfully',
          settings: updateDto,
        },
      });

      // The service uses Object.assign which updates the object in place
      // So we check that save was called with an object containing dailySelection: false
      expect(mockNotificationPreferencesRepository.save).toHaveBeenCalled();
      const savedObject =
        mockNotificationPreferencesRepository.save.mock.calls[0][0];
      expect(savedObject.dailySelection).toBe(false);
      expect(savedObject.userId).toBe(mockUser.id);
    });

    it('should enable all notification types', async () => {
      const updateDto = {
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
      };

      const existingPreferences = {
        id: 'pref-123',
        userId: mockUser.id,
        dailySelection: false,
        newMatches: false,
        newMessages: false,
        chatExpiring: false,
        subscriptionUpdates: true,
        pushNotifications: true,
        emailNotifications: true,
        marketingEmails: false,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockNotificationPreferencesRepository.findOne.mockResolvedValue(
        existingPreferences,
      );
      mockNotificationPreferencesRepository.save.mockResolvedValue({
        ...existingPreferences,
        ...updateDto,
      });

      const response = await request(app.getHttpServer())
        .put('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .send(updateDto)
        .expect(200);

      expect(response.body).toEqual({
        success: true,
        data: {
          message: 'Notification settings updated successfully',
          settings: updateDto,
        },
      });

      expect(mockNotificationPreferencesRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          dailySelection: true,
          newMatches: true,
          newMessages: true,
          chatExpiring: true,
        }),
      );
    });

    it('should create new preferences if none exist', async () => {
      const updateDto = {
        dailySelection: false,
        newMatches: true,
        newMessages: false,
        chatExpiring: true,
      };

      const newPreferences = {
        id: 'pref-456',
        userId: mockUser.id,
        ...updateDto,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockNotificationPreferencesRepository.findOne.mockResolvedValue(null);
      mockNotificationPreferencesRepository.create.mockReturnValue(
        newPreferences,
      );
      mockNotificationPreferencesRepository.save.mockResolvedValue(
        newPreferences,
      );

      const response = await request(app.getHttpServer())
        .put('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .send(updateDto)
        .expect(200);

      expect(response.body).toEqual({
        success: true,
        data: {
          message: 'Notification settings updated successfully',
          settings: updateDto,
        },
      });

      expect(mockNotificationPreferencesRepository.create).toHaveBeenCalledWith(
        {
          userId: mockUser.id,
          ...updateDto,
        },
      );
      expect(mockNotificationPreferencesRepository.save).toHaveBeenCalled();
    });

    it('should return 404 if user does not exist', async () => {
      const updateDto = {
        dailySelection: false,
      };

      mockUserRepository.findOne.mockResolvedValue(null);

      const response = await request(app.getHttpServer())
        .put('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .send(updateDto)
        .expect(404);

      expect(response.body.message).toBe('User not found');
    });

    it('should validate boolean types for settings', async () => {
      const invalidDto = {
        dailySelection: 'not-a-boolean',
        newMatches: 123,
      };

      const response = await request(app.getHttpServer())
        .put('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .send(invalidDto)
        .expect(400);

      // Validation messages are arrays in NestJS
      expect(Array.isArray(response.body.message)).toBe(true);
      expect(response.body.message.length).toBeGreaterThan(0);
    });

    it('should accept empty update (no changes)', async () => {
      const updateDto = {};

      const existingPreferences = {
        id: 'pref-123',
        userId: mockUser.id,
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        subscriptionUpdates: true,
        pushNotifications: true,
        emailNotifications: true,
        marketingEmails: false,
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockNotificationPreferencesRepository.findOne.mockResolvedValue(
        existingPreferences,
      );
      mockNotificationPreferencesRepository.save.mockResolvedValue(
        existingPreferences,
      );

      const response = await request(app.getHttpServer())
        .put('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .send(updateDto)
        .expect(200);

      expect(response.body).toEqual({
        success: true,
        data: {
          message: 'Notification settings updated successfully',
          settings: updateDto,
        },
      });
    });
  });

  describe('Integration: GET and PUT workflow', () => {
    it('should retrieve default settings, update them, and retrieve updated settings', async () => {
      const defaultPreferences = {
        id: 'pref-789',
        userId: mockUser.id,
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        subscriptionUpdates: true,
        pushNotifications: true,
        emailNotifications: true,
        marketingEmails: false,
      };

      // Step 1: GET settings (creates defaults)
      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockNotificationPreferencesRepository.findOne.mockResolvedValue(null);
      mockNotificationPreferencesRepository.create.mockReturnValue(
        defaultPreferences,
      );
      mockNotificationPreferencesRepository.save.mockResolvedValue(
        defaultPreferences,
      );

      const getResponse1 = await request(app.getHttpServer())
        .get('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(getResponse1.body.settings.dailySelection).toBe(true);
      expect(getResponse1.body.settings.newMatches).toBe(true);

      // Step 2: Update settings
      const updateDto = {
        dailySelection: false,
        newMatches: false,
      };

      const updatedPreferences = {
        ...defaultPreferences,
        ...updateDto,
      };

      mockNotificationPreferencesRepository.findOne.mockResolvedValue(
        defaultPreferences,
      );
      mockNotificationPreferencesRepository.save.mockResolvedValue(
        updatedPreferences,
      );

      await request(app.getHttpServer())
        .put('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .send(updateDto)
        .expect(200);

      // Step 3: GET settings again (should reflect updates)
      mockNotificationPreferencesRepository.findOne.mockResolvedValue(
        updatedPreferences,
      );

      const getResponse2 = await request(app.getHttpServer())
        .get('/notifications/settings')
        .set('Authorization', 'Bearer mock-token')
        .expect(200);

      expect(getResponse2.body.settings.dailySelection).toBe(false);
      expect(getResponse2.body.settings.newMatches).toBe(false);
      expect(getResponse2.body.settings.newMessages).toBe(true); // unchanged
      expect(getResponse2.body.settings.chatExpiring).toBe(true); // unchanged
    });
  });
});
