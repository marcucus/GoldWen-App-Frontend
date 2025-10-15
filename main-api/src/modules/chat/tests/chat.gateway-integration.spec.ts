import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { forwardRef } from '@nestjs/common';
import { ChatGateway } from '../chat.gateway';
import { ChatService } from '../chat.service';
import { JwtService } from '@nestjs/jwt';
import { CustomLoggerService } from '../../../common/logger';
import { TypingIndicatorService } from '../services/typing-indicator.service';
import { ReadReceiptsService } from '../services/read-receipts.service';
import { PresenceService } from '../services/presence.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { Chat } from '../../../database/entities/chat.entity';
import { Message } from '../../../database/entities/message.entity';
import { Match } from '../../../database/entities/match.entity';
import { User } from '../../../database/entities/user.entity';

describe('ChatGateway - Real-time Features Integration', () => {
  let gateway: ChatGateway;
  let chatService: ChatService;
  let typingIndicatorService: TypingIndicatorService;
  let readReceiptsService: ReadReceiptsService;
  let presenceService: PresenceService;

  const mockChatRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
    create: jest.fn(),
  };

  const mockMessageRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
    count: jest.fn(),
    createQueryBuilder: jest.fn(),
  };

  const mockMatchRepository = {
    findOne: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
    update: jest.fn(),
  };

  const mockJwtService = {
    verify: jest.fn(),
    sign: jest.fn(),
  };

  const mockLogger = {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  };

  const mockNotificationsService = {
    sendChatAcceptedNotification: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChatGateway,
        ChatService,
        TypingIndicatorService,
        ReadReceiptsService,
        PresenceService,
        {
          provide: getRepositoryToken(Chat),
          useValue: mockChatRepository,
        },
        {
          provide: getRepositoryToken(Message),
          useValue: mockMessageRepository,
        },
        {
          provide: getRepositoryToken(Match),
          useValue: mockMatchRepository,
        },
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
        {
          provide: NotificationsService,
          useValue: mockNotificationsService,
        },
      ],
    }).compile();

    gateway = module.get<ChatGateway>(ChatGateway);
    chatService = module.get<ChatService>(ChatService);
    typingIndicatorService = module.get<TypingIndicatorService>(
      TypingIndicatorService,
    );
    readReceiptsService = module.get<ReadReceiptsService>(ReadReceiptsService);
    presenceService = module.get<PresenceService>(PresenceService);

    jest.clearAllMocks();
  });

  describe('Typing Indicators Integration', () => {
    it('should start typing indicator and auto-timeout', (done) => {
      jest.useFakeTimers();
      const userId = 'user-1';
      const conversationId = 'conv-1';

      const mockClient: any = {
        userId,
        to: jest.fn().mockReturnThis(),
        emit: jest.fn(),
      };

      gateway.handleStartTyping({ conversationId }, mockClient);

      expect(typingIndicatorService.isTyping(userId, conversationId)).toBe(
        true,
      );
      expect(mockClient.to).toHaveBeenCalledWith(`chat:${conversationId}`);
      expect(mockClient.emit).toHaveBeenCalledWith('user_typing', {
        conversationId,
        userId,
      });

      // Advance time to trigger timeout
      jest.advanceTimersByTime(5000);

      expect(typingIndicatorService.isTyping(userId, conversationId)).toBe(
        false,
      );

      jest.useRealTimers();
      done();
    });

    it('should stop typing indicator manually', async () => {
      const userId = 'user-1';
      const conversationId = 'conv-1';

      const mockClient: any = {
        userId,
        to: jest.fn().mockReturnThis(),
        emit: jest.fn(),
      };

      await gateway.handleStartTyping({ conversationId }, mockClient);
      expect(typingIndicatorService.isTyping(userId, conversationId)).toBe(
        true,
      );

      await gateway.handleStopTyping({ conversationId }, mockClient);
      expect(typingIndicatorService.isTyping(userId, conversationId)).toBe(
        false,
      );
    });
  });

  describe('Read Receipts Integration', () => {
    it('should mark message as read and emit receipt', async () => {
      const userId = 'user-1';
      const conversationId = 'conv-1';
      const messageId = 'msg-1';
      const readAt = new Date();

      const mockClient: any = {
        userId,
        to: jest.fn().mockReturnThis(),
        emit: jest.fn(),
      };

      const mockMessage = {
        id: messageId,
        chatId: conversationId,
        senderId: 'user-2',
        isRead: false,
        chat: {
          id: conversationId,
          match: {
            user1Id: userId,
            user2Id: 'user-2',
          },
        },
      };

      mockMessageRepository.findOne.mockResolvedValue(mockMessage);
      mockMessageRepository.save.mockResolvedValue({
        ...mockMessage,
        isRead: true,
        readAt,
      });
      mockChatRepository.findOne.mockResolvedValue({
        id: conversationId,
        match: {
          user1Id: userId,
          user2Id: 'user-2',
        },
      });

      await gateway.handleReadMessage(
        { conversationId, messageId },
        mockClient,
      );

      expect(mockClient.to).toHaveBeenCalledWith(`chat:${conversationId}`);
      expect(mockClient.emit).toHaveBeenCalledWith(
        'message_read',
        expect.objectContaining({
          conversationId,
          messageId,
          readBy: userId,
        }),
      );
    });

    it('should mark entire conversation as read', async () => {
      const userId = 'user-1';
      const conversationId = 'conv-1';

      const mockClient: any = {
        userId,
        to: jest.fn().mockReturnThis(),
        emit: jest.fn(),
      };

      mockChatRepository.findOne.mockResolvedValue({
        id: conversationId,
        match: {
          user1Id: userId,
          user2Id: 'user-2',
        },
      });

      const mockQueryBuilder = {
        update: jest.fn().mockReturnThis(),
        set: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        execute: jest.fn().mockResolvedValue({ affected: 5 }),
      };

      mockMessageRepository.createQueryBuilder.mockReturnValue(
        mockQueryBuilder,
      );

      await gateway.handleMarkConversationRead({ conversationId }, mockClient);

      expect(mockClient.to).toHaveBeenCalledWith(`chat:${conversationId}`);
      expect(mockClient.emit).toHaveBeenCalledWith(
        'conversation_read',
        expect.objectContaining({
          conversationId,
          readBy: userId,
          messageCount: 5,
        }),
      );
    });
  });

  describe('Presence Integration', () => {
    it('should mark user online on connection', async () => {
      const userId = 'user-1';
      const token = 'valid-token';

      const mockClient: any = {
        handshake: {
          auth: { token },
        },
        id: 'socket-id',
        join: jest.fn(),
        disconnect: jest.fn(),
      };

      // Mock the server
      gateway.server = {
        emit: jest.fn(),
      } as any;

      mockJwtService.verify.mockReturnValue({ sub: userId });
      mockUserRepository.update.mockResolvedValue({ affected: 1 });

      await gateway.handleConnection(mockClient);

      expect(mockClient.userId).toBe(userId);
      expect(presenceService.isUserOnline(userId)).toBe(true);
      expect(mockUserRepository.update).toHaveBeenCalledWith(
        userId,
        expect.objectContaining({
          lastActiveAt: expect.any(Date),
        }),
      );
    });

    it('should mark user offline on disconnect', async () => {
      const userId = 'user-1';

      // First mark user online
      await presenceService.setUserOnline(userId);
      expect(presenceService.isUserOnline(userId)).toBe(true);

      const mockClient: any = {
        userId,
        to: jest.fn().mockReturnThis(),
        emit: jest.fn(),
      };

      // Mock the server
      gateway.server = {
        emit: jest.fn(),
      } as any;

      mockUserRepository.update.mockResolvedValue({ affected: 1 });

      await gateway.handleDisconnect(mockClient);

      expect(presenceService.isUserOnline(userId)).toBe(false);
    });

    it('should get presence status for multiple users', async () => {
      const userId = 'user-1';
      const userIds = ['user-2', 'user-3'];

      const mockClient: any = {
        userId,
        emit: jest.fn(),
      };

      await presenceService.setUserOnline('user-2');
      mockUserRepository.findOne.mockResolvedValue({
        id: 'user-3',
        lastActiveAt: new Date(Date.now() - 3600000), // 1 hour ago
      });

      await gateway.handleGetPresence({ userIds }, mockClient);

      expect(mockClient.emit).toHaveBeenCalledWith(
        'presence_status',
        expect.objectContaining({
          statuses: expect.arrayContaining([
            expect.objectContaining({
              userId: 'user-2',
              isOnline: true,
            }),
            expect.objectContaining({
              userId: 'user-3',
              isOnline: false,
            }),
          ]),
        }),
      );
    });
  });

  describe('Connection Lifecycle', () => {
    it('should clear typing indicators on disconnect', async () => {
      const userId = 'user-1';
      const conv1 = 'conv-1';
      const conv2 = 'conv-2';

      // Start typing in multiple conversations
      typingIndicatorService.startTyping(userId, conv1);
      typingIndicatorService.startTyping(userId, conv2);

      expect(typingIndicatorService.isTyping(userId, conv1)).toBe(true);
      expect(typingIndicatorService.isTyping(userId, conv2)).toBe(true);

      const mockClient: any = {
        userId,
        to: jest.fn().mockReturnThis(),
        emit: jest.fn(),
      };

      // Mock the server
      gateway.server = {
        emit: jest.fn(),
      } as any;

      mockUserRepository.update.mockResolvedValue({ affected: 1 });

      await gateway.handleDisconnect(mockClient);

      expect(typingIndicatorService.isTyping(userId, conv1)).toBe(false);
      expect(typingIndicatorService.isTyping(userId, conv2)).toBe(false);
      expect(mockClient.emit).toHaveBeenCalledTimes(2); // One for each conversation
    });
  });
});
