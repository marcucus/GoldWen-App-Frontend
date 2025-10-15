import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MatchingService } from '../matching.service';
import { Match } from '../../../database/entities/match.entity';
import { User } from '../../../database/entities/user.entity';
import { Profile } from '../../../database/entities/profile.entity';
import { DailySelection } from '../../../database/entities/daily-selection.entity';
import { PersonalityAnswer } from '../../../database/entities/personality-answer.entity';
import { Subscription } from '../../../database/entities/subscription.entity';
import { UserChoice } from '../../../database/entities/user-choice.entity';
import { ChatService } from '../../chat/chat.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { MatchingIntegrationService } from '../matching-integration.service';
import { CustomLoggerService } from '../../../common/logger';
import { MatchStatus } from '../../../common/enums';

describe('MatchingService - Unidirectional Matching', () => {
  let service: MatchingService;
  let matchRepository: Repository<Match>;
  let userRepository: Repository<User>;
  let profileRepository: Repository<Profile>;
  let dailySelectionRepository: Repository<DailySelection>;
  let personalityAnswerRepository: Repository<PersonalityAnswer>;
  let subscriptionRepository: Repository<Subscription>;
  let chatService: ChatService;
  let notificationsService: NotificationsService;
  let matchingIntegrationService: MatchingIntegrationService;
  let logger: CustomLoggerService;

  const mockMatchRepository = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockProfileRepository = {
    find: jest.fn(),
  };

  const mockDailySelectionRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
  };

  const mockPersonalityAnswerRepository = {
    find: jest.fn(),
  };

  const mockSubscriptionRepository = {
    findOne: jest.fn(),
  };

  const mockUserChoiceRepository = {
    create: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
  };

  const mockChatService = {
    createChatForMatch: jest.fn(),
  };

  const mockNotificationsService = {
    sendNewMatchNotification: jest.fn(),
  };

  const mockMatchingIntegrationService = {};

  const mockLogger = {
    logBusinessEvent: jest.fn(),
    error: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MatchingService,
        {
          provide: getRepositoryToken(Match),
          useValue: mockMatchRepository,
        },
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: getRepositoryToken(Profile),
          useValue: mockProfileRepository,
        },
        {
          provide: getRepositoryToken(DailySelection),
          useValue: mockDailySelectionRepository,
        },
        {
          provide: getRepositoryToken(PersonalityAnswer),
          useValue: mockPersonalityAnswerRepository,
        },
        {
          provide: getRepositoryToken(Subscription),
          useValue: mockSubscriptionRepository,
        },
        {
          provide: getRepositoryToken(UserChoice),
          useValue: mockUserChoiceRepository,
        },
        {
          provide: ChatService,
          useValue: mockChatService,
        },
        {
          provide: NotificationsService,
          useValue: mockNotificationsService,
        },
        {
          provide: MatchingIntegrationService,
          useValue: mockMatchingIntegrationService,
        },
        {
          provide: CustomLoggerService,
          useValue: mockLogger,
        },
      ],
    }).compile();

    service = module.get<MatchingService>(MatchingService);
    matchRepository = module.get<Repository<Match>>(getRepositoryToken(Match));
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    profileRepository = module.get<Repository<Profile>>(
      getRepositoryToken(Profile),
    );
    dailySelectionRepository = module.get<Repository<DailySelection>>(
      getRepositoryToken(DailySelection),
    );
    personalityAnswerRepository = module.get<Repository<PersonalityAnswer>>(
      getRepositoryToken(PersonalityAnswer),
    );
    subscriptionRepository = module.get<Repository<Subscription>>(
      getRepositoryToken(Subscription),
    );
    chatService = module.get<ChatService>(ChatService);
    notificationsService =
      module.get<NotificationsService>(NotificationsService);
    matchingIntegrationService = module.get<MatchingIntegrationService>(
      MatchingIntegrationService,
    );
    logger = module.get<CustomLoggerService>(CustomLoggerService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('chooseProfile - Unidirectional Matching', () => {
    const userId = 'user-1';
    const targetUserId = 'user-2';
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const mockDailySelection = {
      id: 'selection-1',
      userId,
      selectionDate: today,
      selectedProfileIds: [targetUserId],
      chosenProfileIds: [],
      choicesUsed: 0,
      maxChoicesAllowed: 1,
    };

    const mockUser1 = {
      id: userId,
      profile: { firstName: 'John' },
    };

    const mockUser2 = {
      id: targetUserId,
      profile: { firstName: 'Jane' },
    };

    beforeEach(() => {
      const freshDailySelection = {
        ...mockDailySelection,
        chosenProfileIds: [],
        choicesUsed: 0,
      };
      mockDailySelectionRepository.findOne.mockResolvedValue(
        freshDailySelection,
      );
      mockDailySelectionRepository.save.mockResolvedValue({
        ...freshDailySelection,
        chosenProfileIds: [targetUserId],
        choicesUsed: 1,
      });
      mockUserRepository.findOne
        .mockResolvedValueOnce(mockUser1)
        .mockResolvedValueOnce(mockUser2);
    });

    it('should create unidirectional match immediately when user likes someone', async () => {
      // Arrange
      mockMatchRepository.findOne.mockResolvedValue(null); // No existing match
      const newMatch = {
        id: 'match-1',
        user1Id: userId,
        user2Id: targetUserId,
        status: MatchStatus.MATCHED,
        matchedAt: new Date(),
      };
      mockMatchRepository.create.mockReturnValue(newMatch);
      mockMatchRepository.save.mockResolvedValue(newMatch);

      // Act
      const result = await service.chooseProfile(userId, targetUserId, 'like');

      // Assert
      expect(result.success).toBe(true);
      expect(result.data.isMatch).toBe(true);
      expect(result.data.matchId).toBe('match-1');
      expect(result.data.message).toBe('Félicitations ! Vous avez un match !');

      expect(mockMatchRepository.create).toHaveBeenCalledWith({
        user1Id: userId,
        user2Id: targetUserId,
        status: MatchStatus.MATCHED,
        matchedAt: expect.any(Date),
      });

      expect(mockLogger.logBusinessEvent).toHaveBeenCalledWith(
        'unidirectional_match_created',
        {
          matchId: 'match-1',
          initiatorId: userId,
          targetId: targetUserId,
        },
      );

      expect(
        mockNotificationsService.sendNewMatchNotification,
      ).toHaveBeenCalledTimes(2);
      expect(
        mockNotificationsService.sendNewMatchNotification,
      ).toHaveBeenCalledWith(targetUserId, 'John');
      expect(
        mockNotificationsService.sendNewMatchNotification,
      ).toHaveBeenCalledWith(userId, 'Jane');
    });

    it('should not create match for pass choice', async () => {
      // Act
      const result = await service.chooseProfile(userId, targetUserId, 'pass');

      // Assert
      expect(result.success).toBe(true);
      expect(result.data.isMatch).toBe(false);
      expect(result.data.matchId).toBeUndefined();
      expect(mockMatchRepository.create).not.toHaveBeenCalled();
      expect(
        mockNotificationsService.sendNewMatchNotification,
      ).not.toHaveBeenCalled();
    });

    it('should handle existing match gracefully', async () => {
      // Arrange
      const existingMatch = {
        id: 'existing-match-1',
        user1Id: userId,
        user2Id: targetUserId,
        status: MatchStatus.MATCHED,
        matchedAt: new Date(),
      };
      mockMatchRepository.findOne.mockResolvedValue(existingMatch);

      // Act
      const result = await service.chooseProfile(userId, targetUserId, 'like');

      // Assert
      expect(result.success).toBe(true);
      expect(result.data.isMatch).toBe(true);
      expect(result.data.matchId).toBe('existing-match-1');
      expect(result.data.message).toBe(
        'Vous avez déjà un match avec ce profil !',
      );
    });
  });

  describe('getPendingMatches', () => {
    const userId = 'user-1';
    const targetUserId = 'user-2';

    it('should return matches where user is the target and chat is not accepted yet', async () => {
      // Arrange
      const mockMatches = [
        {
          id: 'match-1',
          user1Id: targetUserId,
          user2Id: userId,
          status: MatchStatus.MATCHED,
          matchedAt: new Date(),
          createdAt: new Date(),
          user1: {
            id: targetUserId,
            profile: { firstName: 'Jane' },
          },
          user2: {
            id: userId,
            profile: { firstName: 'John' },
          },
          chat: null, // No chat yet
        },
      ];

      mockMatchRepository.find.mockResolvedValue(mockMatches);

      // Act
      const result = await service.getPendingMatches(userId);

      // Assert
      expect(result).toHaveLength(1);
      expect(result[0]).toEqual({
        matchId: 'match-1',
        targetUser: {
          id: targetUserId,
          profile: { firstName: 'Jane' },
        },
        status: 'pending',
        matchedAt: expect.any(String),
        canInitiateChat: true,
      });
    });

    it('should filter out matches with active chats', async () => {
      // Arrange
      const mockMatches = [
        {
          id: 'match-1',
          user1Id: targetUserId,
          user2Id: userId,
          status: MatchStatus.MATCHED,
          matchedAt: new Date(),
          createdAt: new Date(),
          user1: {
            id: targetUserId,
            profile: { firstName: 'Jane' },
          },
          user2: {
            id: userId,
            profile: { firstName: 'John' },
          },
          chat: {
            id: 'chat-1',
            status: 'active',
          },
        },
      ];

      mockMatchRepository.find.mockResolvedValue(mockMatches);

      // Act
      const result = await service.getPendingMatches(userId);

      // Assert
      expect(result).toHaveLength(0);
    });
  });
});
