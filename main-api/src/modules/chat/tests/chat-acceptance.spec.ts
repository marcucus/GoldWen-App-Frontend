import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { ChatService } from '../chat.service';
import { Chat } from '../../../database/entities/chat.entity';
import { Message } from '../../../database/entities/message.entity';
import { Match } from '../../../database/entities/match.entity';
import { User } from '../../../database/entities/user.entity';
import { NotificationsService } from '../../notifications/notifications.service';
import { MatchStatus, ChatStatus } from '../../../common/enums';

describe('ChatService - Chat Acceptance', () => {
  let service: ChatService;
  let chatRepository: Repository<Chat>;
  let messageRepository: Repository<Message>;
  let matchRepository: Repository<Match>;
  let userRepository: Repository<User>;
  let notificationsService: NotificationsService;

  const mockChatRepository = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const mockMessageRepository = {
    count: jest.fn(),
  };

  const mockMatchRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockNotificationsService = {
    sendChatAcceptedNotification: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChatService,
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
          provide: NotificationsService,
          useValue: mockNotificationsService,
        },
      ],
    }).compile();

    service = module.get<ChatService>(ChatService);
    chatRepository = module.get<Repository<Chat>>(getRepositoryToken(Chat));
    messageRepository = module.get<Repository<Message>>(
      getRepositoryToken(Message),
    );
    matchRepository = module.get<Repository<Match>>(getRepositoryToken(Match));
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    notificationsService =
      module.get<NotificationsService>(NotificationsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('acceptChatRequest', () => {
    const matchId = 'match-1';
    const userId = 'user-2'; // Target user who accepts/rejects
    const initiatorId = 'user-1'; // User who initiated the match

    const mockMatch = {
      id: matchId,
      user1Id: initiatorId,
      user2Id: userId,
      status: MatchStatus.MATCHED,
      matchedAt: new Date(),
      user1: {
        id: initiatorId,
        profile: { firstName: 'John' },
      },
      user2: {
        id: userId,
        profile: { firstName: 'Jane' },
      },
    };

    beforeEach(() => {
      mockMatchRepository.findOne.mockResolvedValue(mockMatch);
    });

    describe('when accepting chat request', () => {
      it('should create chat and send notifications when chat is accepted', async () => {
        // Arrange
        mockChatRepository.findOne.mockResolvedValue(null); // No existing chat

        const newChat = {
          id: 'chat-1',
          matchId,
          status: ChatStatus.ACTIVE,
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours from now
        };
        mockChatRepository.create.mockReturnValue(newChat);
        mockChatRepository.save.mockResolvedValue(newChat);

        // Act
        const result = await service.acceptChatRequest(matchId, userId, true);

        // Assert
        expect(result.success).toBe(true);
        expect(result.data.chatId).toBe('chat-1');
        expect(result.data.match.id).toBe(matchId);
        expect(result.data.expiresAt).toBeDefined();

        expect(mockChatRepository.create).toHaveBeenCalledWith({
          matchId,
          status: ChatStatus.ACTIVE,
          expiresAt: expect.any(Date),
        });

        expect(
          mockNotificationsService.sendChatAcceptedNotification,
        ).toHaveBeenCalledTimes(2);
        expect(
          mockNotificationsService.sendChatAcceptedNotification,
        ).toHaveBeenCalledWith(initiatorId, 'Jane');
        expect(
          mockNotificationsService.sendChatAcceptedNotification,
        ).toHaveBeenCalledWith(userId, 'John');
      });

      it('should throw error if chat already exists and is active', async () => {
        // Arrange
        const existingChat = {
          id: 'chat-1',
          matchId,
          status: ChatStatus.ACTIVE,
        };
        mockChatRepository.findOne.mockResolvedValue(existingChat);

        // Act & Assert
        await expect(
          service.acceptChatRequest(matchId, userId, true),
        ).rejects.toThrow(BadRequestException);
      });
    });

    describe('when declining chat request', () => {
      it('should reject the match when chat is declined', async () => {
        // Arrange
        mockChatRepository.findOne.mockResolvedValue(null); // No existing chat

        // Act
        const result = await service.acceptChatRequest(matchId, userId, false);

        // Assert
        expect(result.success).toBe(true);
        expect(result.data.match.id).toBe(matchId);
        expect(result.data.match.status).toBe('rejected');
        expect(result.data.chatId).toBeUndefined();

        expect(mockMatchRepository.save).toHaveBeenCalledWith(
          expect.objectContaining({
            id: matchId,
            status: MatchStatus.REJECTED,
          }),
        );

        expect(mockChatRepository.create).not.toHaveBeenCalled();
        expect(
          mockNotificationsService.sendChatAcceptedNotification,
        ).not.toHaveBeenCalled();
      });
    });

    describe('error handling', () => {
      it('should throw NotFoundException if match not found', async () => {
        // Arrange
        mockMatchRepository.findOne.mockResolvedValue(null);

        // Act & Assert
        await expect(
          service.acceptChatRequest(matchId, userId, true),
        ).rejects.toThrow(NotFoundException);
      });

      it('should throw NotFoundException if user is not the target of the match', async () => {
        // Arrange
        const differentUserId = 'different-user';
        mockMatchRepository.findOne.mockResolvedValue(null); // Match query will fail for wrong user

        // Act & Assert
        await expect(
          service.acceptChatRequest(matchId, differentUserId, true),
        ).rejects.toThrow(NotFoundException);
      });

      it('should handle notification failures gracefully', async () => {
        // Arrange
        mockChatRepository.findOne.mockResolvedValue(null);

        const newChat = {
          id: 'chat-1',
          matchId,
          status: ChatStatus.ACTIVE,
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
        };
        mockChatRepository.create.mockReturnValue(newChat);
        mockChatRepository.save.mockResolvedValue(newChat);

        // Mock notification failure
        mockNotificationsService.sendChatAcceptedNotification.mockRejectedValue(
          new Error('Notification service error'),
        );

        // Act
        const result = await service.acceptChatRequest(matchId, userId, true);

        // Assert
        expect(result.success).toBe(true);
        expect(result.data.chatId).toBe('chat-1');
        // Should still create chat even if notifications fail
      });
    });
  });
});
