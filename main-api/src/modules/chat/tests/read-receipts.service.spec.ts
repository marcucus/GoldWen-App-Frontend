import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ReadReceiptsService } from '../services/read-receipts.service';
import { Message } from '../../../database/entities/message.entity';
import { CustomLoggerService } from '../../../common/logger';

describe('ReadReceiptsService', () => {
  let service: ReadReceiptsService;
  let messageRepository: Repository<Message>;
  let logger: CustomLoggerService;

  const mockMessageRepository = {
    find: jest.fn(),
    findOne: jest.fn(),
    save: jest.fn(),
    count: jest.fn(),
    createQueryBuilder: jest.fn(),
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
        ReadReceiptsService,
        {
          provide: getRepositoryToken(Message),
          useValue: mockMessageRepository,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    service = module.get<ReadReceiptsService>(ReadReceiptsService);
    messageRepository = module.get<Repository<Message>>(
      getRepositoryToken(Message),
    );
    logger = module.get<CustomLoggerService>(CustomLoggerService);

    jest.clearAllMocks();
  });

  describe('markMessagesAsRead', () => {
    it('should mark multiple messages as read', async () => {
      const userId = 'user-1';
      const messageIds = ['msg-1', 'msg-2'];
      const mockMessages = [
        { id: 'msg-1', senderId: 'user-2', isRead: false },
        { id: 'msg-2', senderId: 'user-3', isRead: false },
      ];

      mockMessageRepository.find.mockResolvedValue(mockMessages);
      mockMessageRepository.save.mockResolvedValue(mockMessages);

      const result = await service.markMessagesAsRead(messageIds, userId);

      expect(result).toEqual(['msg-1', 'msg-2']);
      expect(mockMessageRepository.save).toHaveBeenCalled();
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Messages marked as read',
        expect.objectContaining({
          userId,
          messageCount: 2,
        }),
      );
    });

    it('should not mark own messages as read', async () => {
      const userId = 'user-1';
      const messageIds = ['msg-1', 'msg-2'];
      const mockMessages = [
        { id: 'msg-1', senderId: 'user-1', isRead: false }, // Own message
        { id: 'msg-2', senderId: 'user-2', isRead: false },
      ];

      mockMessageRepository.find.mockResolvedValue(mockMessages);
      mockMessageRepository.save.mockResolvedValue([mockMessages[1]]);

      const result = await service.markMessagesAsRead(messageIds, userId);

      expect(result).toEqual(['msg-2']);
    });

    it('should return empty array when no messages to mark', async () => {
      const userId = 'user-1';
      const messageIds: string[] = [];

      const result = await service.markMessagesAsRead(messageIds, userId);

      expect(result).toEqual([]);
      expect(mockMessageRepository.find).not.toHaveBeenCalled();
    });

    it('should handle already read messages', async () => {
      const userId = 'user-1';
      const messageIds = ['msg-1'];
      const mockMessages: any[] = []; // All already read

      mockMessageRepository.find.mockResolvedValue(mockMessages);

      const result = await service.markMessagesAsRead(messageIds, userId);

      expect(result).toEqual([]);
      expect(mockMessageRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('getReadReceipts', () => {
    it('should get read receipts for messages', async () => {
      const messageIds = ['msg-1', 'msg-2'];
      const now = new Date();
      const mockMessages = [
        {
          id: 'msg-1',
          senderId: 'user-1',
          readAt: now,
          isRead: true,
        },
        {
          id: 'msg-2',
          senderId: 'user-2',
          readAt: now,
          isRead: true,
        },
      ];

      mockMessageRepository.find.mockResolvedValue(mockMessages);

      const result = await service.getReadReceipts(messageIds);

      expect(result).toHaveLength(2);
      expect(result[0]).toEqual({
        messageId: 'msg-1',
        userId: 'user-1',
        readAt: now,
      });
    });

    it('should return empty array for empty input', async () => {
      const result = await service.getReadReceipts([]);

      expect(result).toEqual([]);
      expect(mockMessageRepository.find).not.toHaveBeenCalled();
    });
  });

  describe('getUnreadCount', () => {
    it('should get unread message count for user in chat', async () => {
      const chatId = 'chat-1';
      const userId = 'user-1';

      mockMessageRepository.count.mockResolvedValue(5);

      const result = await service.getUnreadCount(chatId, userId);

      expect(result).toBe(5);
      expect(mockMessageRepository.count).toHaveBeenCalled();
    });
  });

  describe('markConversationAsRead', () => {
    it('should mark all unread messages in conversation as read', async () => {
      const chatId = 'chat-1';
      const userId = 'user-1';

      const mockQueryBuilder = {
        update: jest.fn().mockReturnThis(),
        set: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({ affected: 3 }),
      };

      mockMessageRepository.createQueryBuilder.mockReturnValue(
        mockQueryBuilder,
      );

      const result = await service.markConversationAsRead(chatId, userId);

      expect(result).toBe(3);
      expect(mockLogger.info).toHaveBeenCalledWith(
        'Conversation marked as read',
        expect.objectContaining({
          chatId,
          userId,
          messagesMarked: 3,
        }),
      );
    });

    it('should handle when no messages to mark', async () => {
      const chatId = 'chat-1';
      const userId = 'user-1';

      const mockQueryBuilder = {
        update: jest.fn().mockReturnThis(),
        set: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({ affected: 0 }),
      };

      mockMessageRepository.createQueryBuilder.mockReturnValue(
        mockQueryBuilder,
      );

      const result = await service.markConversationAsRead(chatId, userId);

      expect(result).toBe(0);
    });
  });

  describe('getMessageReadStatus', () => {
    it('should get read status for a message', async () => {
      const messageId = 'msg-1';
      const readAt = new Date();

      mockMessageRepository.findOne.mockResolvedValue({
        id: messageId,
        isRead: true,
        readAt,
      });

      const result = await service.getMessageReadStatus(messageId);

      expect(result).toEqual({
        isRead: true,
        readAt,
      });
    });

    it('should return null for non-existent message', async () => {
      const messageId = 'msg-1';

      mockMessageRepository.findOne.mockResolvedValue(null);

      const result = await service.getMessageReadStatus(messageId);

      expect(result).toBeNull();
    });

    it('should handle unread messages', async () => {
      const messageId = 'msg-1';

      mockMessageRepository.findOne.mockResolvedValue({
        id: messageId,
        isRead: false,
        readAt: null,
      });

      const result = await service.getMessageReadStatus(messageId);

      expect(result).toEqual({
        isRead: false,
        readAt: null,
      });
    });
  });
});
