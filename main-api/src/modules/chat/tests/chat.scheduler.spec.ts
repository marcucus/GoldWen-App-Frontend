import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';

import { ChatScheduler } from '../chat.scheduler';
import { NotificationsService } from '../../notifications/notifications.service';
import { Chat } from '../../../database/entities/chat.entity';
import { Message } from '../../../database/entities/message.entity';
import { CustomLoggerService } from '../../../common/logger';
import { ChatStatus } from '../../../common/enums';

describe('ChatScheduler', () => {
  let scheduler: ChatScheduler;
  let notificationsService: NotificationsService;
  let chatRepository: Repository<Chat>;
  let messageRepository: Repository<Message>;
  let configService: ConfigService;
  let logger: CustomLoggerService;

  const mockChatRepository = {
    find: jest.fn(),
    save: jest.fn(),
    createQueryBuilder: jest.fn(() => ({
      select: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue([]),
      delete: jest.fn().mockReturnThis(),
      execute: jest.fn().mockResolvedValue({ affected: 5 }),
    })),
  };

  const mockMessageRepository = {
    createQueryBuilder: jest.fn(() => ({
      delete: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      execute: jest.fn().mockResolvedValue({ affected: 20 }),
    })),
  };

  const mockNotificationsService = {
    sendChatExpiringNotification: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === 'app.environment') return 'development';
      return undefined;
    }),
  };

  const mockLogger = {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChatScheduler,
        {
          provide: getRepositoryToken(Chat),
          useValue: mockChatRepository,
        },
        {
          provide: getRepositoryToken(Message),
          useValue: mockMessageRepository,
        },
        {
          provide: NotificationsService,
          useValue: mockNotificationsService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    scheduler = module.get<ChatScheduler>(ChatScheduler);
    notificationsService =
      module.get<NotificationsService>(NotificationsService);
    chatRepository = module.get<Repository<Chat>>(getRepositoryToken(Chat));
    messageRepository = module.get<Repository<Message>>(
      getRepositoryToken(Message),
    );
    configService = module.get<ConfigService>(ConfigService);
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('expireChats', () => {
    it('should expire chats that have passed their expiration time', async () => {
      const now = new Date();
      const expiredChat1 = {
        id: 'chat1',
        status: ChatStatus.ACTIVE,
        expiresAt: new Date(now.getTime() - 60000), // 1 minute ago
        match: {
          user1Id: 'user1',
          user2Id: 'user2',
        },
      };
      const expiredChat2 = {
        id: 'chat2',
        status: ChatStatus.ACTIVE,
        expiresAt: new Date(now.getTime() - 120000), // 2 minutes ago
        match: {
          user1Id: 'user3',
          user2Id: 'user4',
        },
      };

      mockChatRepository.find.mockResolvedValue([expiredChat1, expiredChat2]);
      mockChatRepository.save.mockImplementation((chat) =>
        Promise.resolve(chat),
      );

      await scheduler.expireChats();

      expect(mockChatRepository.find).toHaveBeenCalledWith({
        where: {
          status: ChatStatus.ACTIVE,
          expiresAt: expect.any(Object),
        },
        relations: ['match', 'match.user1', 'match.user2'],
      });
      expect(mockChatRepository.save).toHaveBeenCalledTimes(2);
      expect(mockChatRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'chat1',
          status: ChatStatus.EXPIRED,
        }),
      );
      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('Starting chat expiration'),
        expect.any(Object),
      );
      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('completed'),
        expect.objectContaining({
          successCount: 2,
          errorCount: 0,
        }),
      );
    });

    it('should handle errors when expiring individual chats', async () => {
      const expiredChats = [
        {
          id: 'chat1',
          status: ChatStatus.ACTIVE,
          expiresAt: new Date(Date.now() - 60000),
          match: { user1Id: 'user1', user2Id: 'user2' },
        },
        {
          id: 'chat2',
          status: ChatStatus.ACTIVE,
          expiresAt: new Date(Date.now() - 120000),
          match: { user1Id: 'user3', user2Id: 'user4' },
        },
      ];

      mockChatRepository.find.mockResolvedValue(expiredChats);
      mockChatRepository.save
        .mockResolvedValueOnce(expiredChats[0])
        .mockRejectedValueOnce(new Error('Database error'));

      await scheduler.expireChats();

      expect(mockChatRepository.save).toHaveBeenCalledTimes(2);
      expect(mockLogger.error).toHaveBeenCalledWith(
        expect.stringContaining('Failed to expire chat'),
        expect.any(String),
        'ChatScheduler',
      );
      expect(mockLogger.warn).toHaveBeenCalledWith(
        expect.stringContaining('Chat expiration had'),
        'ChatScheduler',
      );
      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('completed'),
        expect.objectContaining({
          successCount: 1,
          errorCount: 1,
        }),
      );
    });

    it('should handle catastrophic failure', async () => {
      mockChatRepository.find.mockRejectedValue(
        new Error('Database connection lost'),
      );

      await expect(scheduler.expireChats()).rejects.toThrow(
        'Database connection lost',
      );

      expect(mockLogger.error).toHaveBeenCalledWith(
        expect.stringContaining('Chat expiration job failed'),
        expect.any(String),
        'ChatScheduler',
      );
    });
  });

  describe('warnAboutExpiringChats', () => {
    it('should send expiration warnings for chats expiring soon', async () => {
      const now = new Date();
      const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);

      const expiringChats = [
        {
          id: 'chat1',
          status: ChatStatus.ACTIVE,
          expiresAt: new Date(twoHoursFromNow.getTime() + 30 * 60 * 1000), // 2.5 hours from now
          match: {
            user1: {
              id: 'user1',
              profile: { firstName: 'Alice' },
            },
            user2: {
              id: 'user2',
              profile: { firstName: 'Bob' },
            },
          },
        },
      ];

      mockChatRepository.find.mockResolvedValue(expiringChats);
      mockNotificationsService.sendChatExpiringNotification.mockResolvedValue(
        true,
      );

      await scheduler.warnAboutExpiringChats();

      expect(mockChatRepository.find).toHaveBeenCalledWith({
        where: {
          status: ChatStatus.ACTIVE,
          expiresAt: expect.any(Object),
        },
        relations: [
          'match',
          'match.user1',
          'match.user1.profile',
          'match.user2',
          'match.user2.profile',
        ],
      });
      expect(
        mockNotificationsService.sendChatExpiringNotification,
      ).toHaveBeenCalledTimes(2);
      expect(
        mockNotificationsService.sendChatExpiringNotification,
      ).toHaveBeenCalledWith('user1', 'Bob', expect.any(Number));
      expect(
        mockNotificationsService.sendChatExpiringNotification,
      ).toHaveBeenCalledWith('user2', 'Alice', expect.any(Number));
      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('completed'),
        expect.objectContaining({
          successCount: 1,
          errorCount: 0,
        }),
      );
    });

    it('should handle notification failures gracefully', async () => {
      const now = new Date();
      const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);

      const expiringChats = [
        {
          id: 'chat1',
          status: ChatStatus.ACTIVE,
          expiresAt: new Date(twoHoursFromNow.getTime() + 30 * 60 * 1000),
          match: {
            user1: {
              id: 'user1',
              profile: { firstName: 'Alice' },
            },
            user2: {
              id: 'user2',
              profile: { firstName: 'Bob' },
            },
          },
        },
      ];

      mockChatRepository.find.mockResolvedValue(expiringChats);
      mockNotificationsService.sendChatExpiringNotification
        .mockRejectedValueOnce(new Error('Notification service unavailable'))
        .mockResolvedValueOnce(true);

      await scheduler.warnAboutExpiringChats();

      expect(
        mockNotificationsService.sendChatExpiringNotification,
      ).toHaveBeenCalledTimes(2);
      expect(mockLogger.warn).toHaveBeenCalledWith(
        expect.stringContaining('Failed to send expiration warning'),
        'ChatScheduler',
      );
      // Should still count as success if at least one notification was attempted
      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('completed'),
        expect.any(Object),
      );
    });

    it('should handle missing profile names', async () => {
      const now = new Date();
      const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);

      const expiringChats = [
        {
          id: 'chat1',
          status: ChatStatus.ACTIVE,
          expiresAt: new Date(twoHoursFromNow.getTime() + 30 * 60 * 1000),
          match: {
            user1: {
              id: 'user1',
              profile: null, // No profile
            },
            user2: {
              id: 'user2',
              profile: { firstName: null }, // No first name
            },
          },
        },
      ];

      mockChatRepository.find.mockResolvedValue(expiringChats);
      mockNotificationsService.sendChatExpiringNotification.mockResolvedValue(
        true,
      );

      await scheduler.warnAboutExpiringChats();

      expect(
        mockNotificationsService.sendChatExpiringNotification,
      ).toHaveBeenCalledWith('user1', 'votre match', expect.any(Number));
      expect(
        mockNotificationsService.sendChatExpiringNotification,
      ).toHaveBeenCalledWith('user2', 'votre match', expect.any(Number));
    });
  });

  describe('cleanupOldChats', () => {
    it('should clean up expired chats and messages older than 90 days', async () => {
      const chatsToDelete = [{ id: 'chat1' }, { id: 'chat2' }, { id: 'chat3' }];

      mockChatRepository.createQueryBuilder.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue(chatsToDelete),
        delete: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({ affected: 3 }),
      });

      mockMessageRepository.createQueryBuilder.mockReturnValue({
        delete: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({ affected: 15 }),
      });

      await scheduler.cleanupOldChats();

      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('Starting old chats cleanup'),
        expect.any(Object),
      );
      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('cleanup completed'),
        expect.objectContaining({
          deletedChats: 3,
          deletedMessages: 15,
        }),
      );
    });

    it('should handle case when no chats need cleanup', async () => {
      mockChatRepository.createQueryBuilder.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
        delete: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({ affected: 0 }),
      });

      await scheduler.cleanupOldChats();

      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('cleanup completed'),
        expect.objectContaining({
          deletedChats: 0,
          deletedMessages: 0,
        }),
      );
    });

    it('should handle cleanup errors', async () => {
      mockChatRepository.createQueryBuilder.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockRejectedValue(new Error('Database error')),
      });

      await expect(scheduler.cleanupOldChats()).rejects.toThrow(
        'Database error',
      );

      expect(mockLogger.error).toHaveBeenCalledWith(
        expect.stringContaining('Old chats cleanup job failed'),
        expect.any(String),
        'ChatScheduler',
      );
    });
  });

  describe('Manual triggers', () => {
    it('should allow manual chat expiration trigger in development', async () => {
      mockChatRepository.find.mockResolvedValue([]);

      await scheduler.triggerChatExpiration();

      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('Manual trigger'),
        expect.any(Object),
      );
    });

    it('should prevent manual trigger in production', async () => {
      mockConfigService.get.mockReturnValue('production');

      await expect(scheduler.triggerChatExpiration()).rejects.toThrow(
        'Manual trigger not allowed in production',
      );
    });

    it('should allow manual expiration warnings trigger in development', async () => {
      mockConfigService.get.mockReturnValue('development');
      mockChatRepository.find.mockResolvedValue([]);

      await scheduler.triggerExpirationWarnings();

      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('Manual trigger'),
        expect.any(Object),
      );
    });

    it('should allow manual cleanup trigger in development', async () => {
      mockConfigService.get.mockReturnValue('development');
      mockChatRepository.createQueryBuilder.mockReturnValue({
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
        delete: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({ affected: 0 }),
      });

      await scheduler.triggerCleanup();

      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining('Manual trigger'),
        expect.any(Object),
      );
    });
  });
});
