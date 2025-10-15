import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { FcmService } from './fcm.service';
import { FirebaseService } from './firebase.service';
import { CustomLoggerService } from '../../common/logger';

describe('FcmService', () => {
  let service: FcmService;
  let configService: ConfigService;
  let firebaseService: FirebaseService;
  let loggerService: CustomLoggerService;

  const mockConfigService = {
    get: jest.fn(),
  };

  const mockFirebaseService = {
    isInitialized: jest.fn(),
    sendToDevice: jest.fn(),
    sendToMultipleDevices: jest.fn(),
    sendToTopic: jest.fn(),
  };

  const mockLoggerService = {
    warn: jest.fn(),
    info: jest.fn(),
    error: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FcmService,
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: FirebaseService,
          useValue: mockFirebaseService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLoggerService,
        },
      ],
    }).compile();

    service = module.get<FcmService>(FcmService);
    configService = module.get<ConfigService>(ConfigService);
    firebaseService = module.get<FirebaseService>(FirebaseService);
    loggerService = module.get<CustomLoggerService>(CustomLoggerService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('sendToDevice', () => {
    it('should use Firebase service when initialized', async () => {
      mockFirebaseService.isInitialized.mockReturnValue(true);
      mockFirebaseService.sendToDevice.mockResolvedValue({
        success: true,
        messageId: 'test-message-id',
      });

      const payload = {
        title: 'Test Notification',
        body: 'Test body',
        data: { key: 'value' },
      };

      const result = await service.sendToDevice('test-token', payload);

      expect(firebaseService.sendToDevice).toHaveBeenCalledWith(
        'test-token',
        payload,
      );
      expect(result.success).toBe(true);
      expect(result.messageId).toBe('test-message-id');
    });

    it('should fall back to HTTP API when Firebase is not initialized', async () => {
      mockFirebaseService.isInitialized.mockReturnValue(false);
      mockConfigService.get.mockReturnValue('');

      const result = await service.sendToDevice('test-token', {
        title: 'Test',
        body: 'Test body',
      });

      expect(firebaseService.sendToDevice).not.toHaveBeenCalled();
      expect(result.success).toBe(false);
    });
  });

  describe('sendToMultipleDevices', () => {
    it('should use Firebase service when initialized', async () => {
      mockFirebaseService.isInitialized.mockReturnValue(true);
      mockFirebaseService.sendToMultipleDevices.mockResolvedValue([
        { success: true, messageId: 'msg-1' },
        { success: true, messageId: 'msg-2' },
      ]);

      const payload = {
        title: 'Test Notification',
        body: 'Test body',
      };
      const tokens = ['token1', 'token2'];

      const results = await service.sendToMultipleDevices(tokens, payload);

      expect(firebaseService.sendToMultipleDevices).toHaveBeenCalledWith(
        tokens,
        payload,
      );
      expect(results).toHaveLength(2);
      expect(results[0].success).toBe(true);
    });
  });

  describe('sendToTopic', () => {
    it('should use Firebase service when initialized', async () => {
      mockFirebaseService.isInitialized.mockReturnValue(true);
      mockFirebaseService.sendToTopic.mockResolvedValue({
        success: true,
        messageId: 'topic-msg-id',
      });

      const payload = {
        title: 'Test Topic Notification',
        body: 'Test body',
      };

      const result = await service.sendToTopic('test-topic', payload);

      expect(firebaseService.sendToTopic).toHaveBeenCalledWith(
        'test-topic',
        payload,
      );
      expect(result.success).toBe(true);
    });
  });

  describe('notification helper methods', () => {
    it('should send daily selection notification', async () => {
      mockFirebaseService.isInitialized.mockReturnValue(true);
      mockFirebaseService.sendToDevice.mockResolvedValue({
        success: true,
        messageId: 'daily-selection-msg',
      });

      const result = await service.sendDailySelectionNotification('test-token');

      expect(firebaseService.sendToDevice).toHaveBeenCalledWith(
        'test-token',
        expect.objectContaining({
          title: 'Votre sélection du jour est prête !',
          data: expect.objectContaining({
            type: 'daily_selection',
            action: 'open_daily_selection',
          }),
        }),
      );
      expect(result.success).toBe(true);
    });

    it('should send new match notification', async () => {
      mockFirebaseService.isInitialized.mockReturnValue(true);
      mockFirebaseService.sendToDevice.mockResolvedValue({
        success: true,
        messageId: 'match-msg',
      });

      const result = await service.sendNewMatchNotification(
        'test-token',
        'Sophie',
        'conv-123',
        'user-456',
      );

      expect(firebaseService.sendToDevice).toHaveBeenCalledWith(
        'test-token',
        expect.objectContaining({
          title: 'Vous avez un match !',
          body: 'Sophie a aussi flashé sur vous',
          data: expect.objectContaining({
            type: 'new_match',
            conversationId: 'conv-123',
            matchedUserId: 'user-456',
            action: 'open_chat',
          }),
        }),
      );
      expect(result.success).toBe(true);
    });

    it('should send new message notification', async () => {
      mockFirebaseService.isInitialized.mockReturnValue(true);
      mockFirebaseService.sendToDevice.mockResolvedValue({
        success: true,
        messageId: 'message-msg',
      });

      const result = await service.sendNewMessageNotification(
        'test-token',
        'Marc',
        'Salut !',
        'conv-123',
        'user-789',
      );

      expect(firebaseService.sendToDevice).toHaveBeenCalledWith(
        'test-token',
        expect.objectContaining({
          title: 'Nouveau message de Marc',
          body: 'Salut !',
          data: expect.objectContaining({
            type: 'new_message',
            conversationId: 'conv-123',
            senderId: 'user-789',
            action: 'open_chat',
          }),
        }),
      );
      expect(result.success).toBe(true);
    });

    it('should send chat expiring notification', async () => {
      mockFirebaseService.isInitialized.mockReturnValue(true);
      mockFirebaseService.sendToDevice.mockResolvedValue({
        success: true,
        messageId: 'expiring-msg',
      });

      const expiresAt = new Date(Date.now() + 3 * 60 * 60 * 1000); // 3 hours from now

      const result = await service.sendChatExpiringNotification(
        'test-token',
        'Sophie',
        'conv-123',
        expiresAt,
      );

      expect(firebaseService.sendToDevice).toHaveBeenCalledWith(
        'test-token',
        expect.objectContaining({
          title: 'Votre conversation expire bientôt',
          body: expect.stringContaining('pour discuter avec Sophie'),
          data: expect.objectContaining({
            type: 'chat_expiring',
            conversationId: 'conv-123',
            action: 'open_chat',
          }),
        }),
      );
      expect(result.success).toBe(true);
    });

    it('should send chat accepted notification', async () => {
      mockFirebaseService.isInitialized.mockReturnValue(true);
      mockFirebaseService.sendToDevice.mockResolvedValue({
        success: true,
        messageId: 'accepted-msg',
      });

      const result = await service.sendChatAcceptedNotification(
        'test-token',
        'Marc',
        'conv-123',
        'user-456',
      );

      expect(firebaseService.sendToDevice).toHaveBeenCalledWith(
        'test-token',
        expect.objectContaining({
          title: 'Chat accepté !',
          body: 'Marc a accepté votre demande de chat',
          data: expect.objectContaining({
            type: 'chat_accepted',
            conversationId: 'conv-123',
            accepterId: 'user-456',
            action: 'open_chat',
          }),
        }),
      );
      expect(result.success).toBe(true);
    });
  });
});
