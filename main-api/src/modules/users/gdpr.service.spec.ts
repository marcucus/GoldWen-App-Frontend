import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GdprService } from './gdpr.service';
import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { UserConsent } from '../../database/entities/user-consent.entity';
import { Match } from '../../database/entities/match.entity';
import { Message } from '../../database/entities/message.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { PushToken } from '../../database/entities/push-token.entity';
import { Notification } from '../../database/entities/notification.entity';
import { Report } from '../../database/entities/report.entity';

describe('GdprService', () => {
  let service: GdprService;
  let userRepository: Repository<User>;
  let profileRepository: Repository<Profile>;

  const mockRepositories = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GdprService,
        {
          provide: getRepositoryToken(User),
          useValue: mockRepositories,
        },
        {
          provide: getRepositoryToken(Profile),
          useValue: mockRepositories,
        },
        {
          provide: getRepositoryToken(Match),
          useValue: mockRepositories,
        },
        {
          provide: getRepositoryToken(Message),
          useValue: mockRepositories,
        },
        {
          provide: getRepositoryToken(Subscription),
          useValue: mockRepositories,
        },
        {
          provide: getRepositoryToken(DailySelection),
          useValue: mockRepositories,
        },
        {
          provide: getRepositoryToken(UserConsent),
          useValue: mockRepositories,
        },
        {
          provide: getRepositoryToken(PushToken),
          useValue: mockRepositories,
        },
        {
          provide: getRepositoryToken(Notification),
          useValue: mockRepositories,
        },
        {
          provide: getRepositoryToken(Report),
          useValue: mockRepositories,
        },
      ],
    }).compile();

    service = module.get<GdprService>(GdprService);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    profileRepository = module.get<Repository<Profile>>(
      getRepositoryToken(Profile),
    );
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('exportUserData', () => {
    it('should export user data in JSON format', async () => {
      const userId = 'test-user-id';
      const mockUser = {
        id: userId,
        email: 'test@example.com',
        status: 'ACTIVE',
        createdAt: new Date(),
      };

      mockRepositories.findOne.mockResolvedValue(mockUser);
      mockRepositories.find.mockResolvedValue([]);

      const result = await service.exportUserData(userId, 'json');

      expect(result).toBeDefined();
      expect(result.userId).toBe(userId);
      expect(result.data).toBeDefined();
      expect(result.data.user).toBeDefined();
    });

    it('should handle PDF format request', async () => {
      const userId = 'test-user-id';

      mockRepositories.findOne.mockResolvedValue(null);
      mockRepositories.find.mockResolvedValue([]);

      const result = await service.exportUserData(userId, 'pdf');

      expect(result).toBeDefined();
      expect(result.format).toBe('json'); // Currently returns JSON with note about PDF
      expect(result.note).toContain(
        'PDF export requires additional implementation',
      );
    });
  });

  describe('deleteUserCompletely', () => {
    it('should call all necessary deletion methods', async () => {
      const userId = 'test-user-id';

      await service.deleteUserCompletely(userId);

      expect(mockRepositories.delete).toHaveBeenCalledWith({ userId });
      expect(mockRepositories.update).toHaveBeenCalled();
    });
  });
});
