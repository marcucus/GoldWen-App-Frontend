import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { ConversationsController } from './conversations.controller';
import { ChatService } from '../chat/chat.service';
import { MatchingService } from '../matching/matching.service';
import { MatchStatus, ChatStatus } from '../../common/enums';

describe('ConversationsController', () => {
  let controller: ConversationsController;
  let chatService: jest.Mocked<ChatService>;
  let matchingService: jest.Mocked<MatchingService>;

  beforeEach(async () => {
    const mockChatService = {
      createChatForMatch: jest.fn(),
      getUserChats: jest.fn(),
      getChatMessages: jest.fn(),
      sendMessage: jest.fn(),
      markMessagesAsRead: jest.fn(),
      deleteMessage: jest.fn(),
    };

    const mockMatchingService = {
      getMutualMatch: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [ConversationsController],
      providers: [
        {
          provide: ChatService,
          useValue: mockChatService,
        },
        {
          provide: MatchingService,
          useValue: mockMatchingService,
        },
      ],
    }).compile();

    controller = module.get<ConversationsController>(ConversationsController);
    chatService = module.get(ChatService);
    matchingService = module.get(MatchingService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('createConversation', () => {
    it('should create conversation for mutual match', async () => {
      const mockUser = { id: 'user1' };
      const mockMatch = {
        id: 'match1',
        user1Id: 'user1',
        user2Id: 'user2',
        status: MatchStatus.MATCHED,
      };
      const mockChat = {
        id: 'chat1',
        matchId: 'match1',
        status: ChatStatus.ACTIVE,
        expiresAt: new Date(),
        timeRemaining: 86400000, // 24 hours
      };

      matchingService.getMutualMatch.mockResolvedValue(mockMatch as any);
      chatService.createChatForMatch.mockResolvedValue(mockChat as any);

      const result = await controller.createConversation(
        { user: mockUser },
        { matchId: 'match1' },
      );

      expect(result).toEqual({
        conversationId: 'chat1',
        matchId: 'match1',
        expiresAt: mockChat.expiresAt,
        timeRemaining: mockChat.timeRemaining,
        status: ChatStatus.ACTIVE,
      });

      expect(matchingService.getMutualMatch).toHaveBeenCalledWith(
        'user1',
        'match1',
      );
      expect(chatService.createChatForMatch).toHaveBeenCalledWith('match1');
    });

    it('should throw BadRequestException when no mutual match found', async () => {
      const mockUser = { id: 'user1' };

      matchingService.getMutualMatch.mockResolvedValue(null);

      await expect(
        controller.createConversation(
          { user: mockUser },
          { matchId: 'match1' },
        ),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
