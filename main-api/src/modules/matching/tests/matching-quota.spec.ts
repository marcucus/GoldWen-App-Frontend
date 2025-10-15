import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BadRequestException } from '@nestjs/common';
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

describe('MatchingService - Quota Enforcement', () => {
  let service: MatchingService;
  let dailySelectionRepository: Repository<DailySelection>;
  let matchRepository: Repository<Match>;
  let userRepository: Repository<User>;

  const mockDailySelectionRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
  };

  const mockMatchRepository = {
    findOne: jest.fn(),
    find: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockProfileRepository = {
    find: jest.fn(),
  };

  const mockPersonalityAnswerRepository = {
    find: jest.fn(),
  };

  const mockSubscriptionRepository = {
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const mockUserChoiceRepository = {
    create: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
  };

  const mockChatService = {
    createChat: jest.fn(),
  };

  const mockNotificationsService = {
    sendNewMatchNotification: jest.fn(),
  };

  const mockMatchingIntegrationService = {
    generateDailySelection: jest.fn(),
  };

  const mockLogger = {
    logBusinessEvent: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MatchingService,
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
          provide: getRepositoryToken(Match),
          useValue: mockMatchRepository,
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
    dailySelectionRepository = module.get<Repository<DailySelection>>(
      getRepositoryToken(DailySelection),
    );
    matchRepository = module.get<Repository<Match>>(getRepositoryToken(Match));
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('chooseProfile - Quota Validation', () => {
    it('should throw BadRequestException if target user not in daily selection', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-456';

      const dailySelection = {
        id: 'selection-123',
        userId,
        selectedProfileIds: ['other-user-1', 'other-user-2'],
        chosenProfileIds: [],
        choicesUsed: 0,
        maxChoicesAllowed: 1,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow('Target user not in your daily selection');
    });

    it('should throw BadRequestException if no daily selection exists', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-456';

      mockDailySelectionRepository.findOne.mockResolvedValue(null);

      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow('Target user not in your daily selection');
    });

    it('should throw BadRequestException if daily quota is exceeded for free user', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-456';

      const dailySelection = {
        id: 'selection-123',
        userId,
        selectedProfileIds: [targetUserId, 'other-user-1'],
        chosenProfileIds: ['other-user-1'],
        choicesUsed: 1,
        maxChoicesAllowed: 1,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow('You have reached your daily limit of 1 choices');
    });

    it('should throw BadRequestException if daily quota is exceeded for premium user', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-456';

      const dailySelection = {
        id: 'selection-123',
        userId,
        selectedProfileIds: [
          targetUserId,
          'other-user-1',
          'other-user-2',
          'other-user-3',
        ],
        chosenProfileIds: ['other-user-1', 'other-user-2', 'other-user-3'],
        choicesUsed: 3,
        maxChoicesAllowed: 3,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow('You have reached your daily limit of 3 choices');
    });

    it('should throw BadRequestException if profile already chosen', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-456';

      const dailySelection = {
        id: 'selection-123',
        userId,
        selectedProfileIds: [targetUserId, 'other-user-1'],
        chosenProfileIds: [targetUserId],
        choicesUsed: 1,
        maxChoicesAllowed: 3,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.chooseProfile(userId, targetUserId, 'like'),
      ).rejects.toThrow('You have already chosen this profile');
    });

    it('should increment choicesUsed when choice is made', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-456';

      const dailySelection = {
        id: 'selection-123',
        userId,
        selectedProfileIds: [targetUserId, 'other-user-1'],
        chosenProfileIds: [],
        choicesUsed: 0,
        maxChoicesAllowed: 1,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);
      mockDailySelectionRepository.save.mockResolvedValue({
        ...dailySelection,
        choicesUsed: 1,
        chosenProfileIds: [targetUserId],
      });
      mockMatchRepository.findOne.mockResolvedValue(null);
      mockMatchRepository.create.mockReturnValue({
        id: 'match-123',
        user1Id: userId,
        user2Id: targetUserId,
      });
      mockMatchRepository.save.mockResolvedValue({
        id: 'match-123',
        user1Id: userId,
        user2Id: targetUserId,
      });
      mockUserRepository.findOne.mockResolvedValue({
        id: userId,
        profile: { firstName: 'John' },
      });

      const result = await service.chooseProfile(userId, targetUserId, 'like');

      expect(dailySelection.choicesUsed).toBe(1);
      expect(dailySelection.chosenProfileIds).toContain(targetUserId);
      expect(mockDailySelectionRepository.save).toHaveBeenCalledWith(
        dailySelection,
      );
      expect(result.success).toBe(true);
    });

    it('should return correct choicesRemaining after choice', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-456';

      const dailySelection = {
        id: 'selection-123',
        userId,
        selectedProfileIds: [targetUserId, 'other-user-1', 'other-user-2'],
        chosenProfileIds: [],
        choicesUsed: 0,
        maxChoicesAllowed: 3,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);
      mockDailySelectionRepository.save.mockResolvedValue({
        ...dailySelection,
        choicesUsed: 1,
      });
      mockMatchRepository.findOne.mockResolvedValue(null);
      mockMatchRepository.create.mockReturnValue({});
      mockMatchRepository.save.mockResolvedValue({});
      mockUserRepository.findOne.mockResolvedValue({
        id: userId,
        profile: { firstName: 'John' },
      });

      const result = await service.chooseProfile(userId, targetUserId, 'pass');

      expect(result.data.choicesRemaining).toBe(2);
      expect(result.data.canContinue).toBe(true);
    });

    it('should set canContinue to false when quota exhausted', async () => {
      const userId = 'user-123';
      const targetUserId = 'target-456';

      const dailySelection = {
        id: 'selection-123',
        userId,
        selectedProfileIds: [targetUserId],
        chosenProfileIds: [],
        choicesUsed: 0,
        maxChoicesAllowed: 1,
        selectionDate: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);
      mockDailySelectionRepository.save.mockResolvedValue({
        ...dailySelection,
        choicesUsed: 1,
      });
      mockMatchRepository.findOne.mockResolvedValue(null);
      mockMatchRepository.create.mockReturnValue({});
      mockMatchRepository.save.mockResolvedValue({});
      mockUserRepository.findOne.mockResolvedValue({
        id: userId,
        profile: { firstName: 'John' },
      });

      const result = await service.chooseProfile(userId, targetUserId, 'pass');

      expect(result.data.choicesRemaining).toBe(0);
      expect(result.data.canContinue).toBe(false);
    });
  });

  describe('getUserChoices', () => {
    it('should return default values when no daily selection exists', async () => {
      const userId = 'user-123';

      mockDailySelectionRepository.findOne.mockResolvedValue(null);

      const result = await service.getUserChoices(userId);

      expect(result.choicesRemaining).toBe(1);
      expect(result.choicesMade).toBe(0);
    });

    it('should return correct quota information for free user', async () => {
      const userId = 'user-123';
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const dailySelection = {
        id: 'selection-123',
        userId,
        selectedProfileIds: ['user-1', 'user-2'],
        chosenProfileIds: ['user-1'],
        choicesUsed: 1,
        maxChoicesAllowed: 1,
        selectionDate: today,
        updatedAt: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      const result = await service.getUserChoices(userId);

      expect(result.choicesRemaining).toBe(0);
      expect(result.choicesMade).toBe(1);
      expect(result.maxChoices).toBe(1);
    });

    it('should return correct quota information for premium user', async () => {
      const userId = 'user-123';
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const dailySelection = {
        id: 'selection-123',
        userId,
        selectedProfileIds: ['user-1', 'user-2', 'user-3'],
        chosenProfileIds: ['user-1'],
        choicesUsed: 1,
        maxChoicesAllowed: 3,
        selectionDate: today,
        updatedAt: new Date(),
      };

      mockDailySelectionRepository.findOne.mockResolvedValue(dailySelection);

      const result = await service.getUserChoices(userId);

      expect(result.choicesRemaining).toBe(2);
      expect(result.choicesMade).toBe(1);
      expect(result.maxChoices).toBe(3);
    });
  });
});
