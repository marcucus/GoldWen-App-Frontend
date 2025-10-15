import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UserConsent } from '../../database/entities/user-consent.entity';
import { ConsentDto } from './dto/consent.dto';

describe('UsersService GDPR Features', () => {
  let service: UsersService;
  let userConsentRepository: any;

  const mockRepository = {
    findOne: jest.fn(),
    find: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: getRepositoryToken('UserRepository'),
          useValue: mockRepository,
        },
        {
          provide: getRepositoryToken('ProfileRepository'),
          useValue: mockRepository,
        },
        {
          provide: getRepositoryToken('MatchRepository'),
          useValue: mockRepository,
        },
        {
          provide: getRepositoryToken('MessageRepository'),
          useValue: mockRepository,
        },
        {
          provide: getRepositoryToken('SubscriptionRepository'),
          useValue: mockRepository,
        },
        {
          provide: getRepositoryToken('DailySelectionRepository'),
          useValue: mockRepository,
        },
        {
          provide: getRepositoryToken('PushTokenRepository'),
          useValue: mockRepository,
        },
        {
          provide: getRepositoryToken(UserConsent),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    userConsentRepository = module.get(getRepositoryToken(UserConsent));
  });

  describe('recordConsent', () => {
    it('should record new consent and deactivate previous ones', async () => {
      const userId = 'test-user-id';
      const consentDto: ConsentDto = {
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: '2024-01-15T10:30:00.000Z',
      };

      const mockConsent = {
        id: 'consent-id',
        userId,
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: new Date(consentDto.consentedAt),
        isActive: true,
        createdAt: new Date(),
      };

      mockRepository.create.mockReturnValue(mockConsent);
      mockRepository.save.mockResolvedValue(mockConsent);

      const result = await service.recordConsent(userId, consentDto);

      expect(mockRepository.update).toHaveBeenCalledWith(
        { userId, isActive: true },
        { isActive: false, revokedAt: expect.any(Date) },
      );
      expect(mockRepository.create).toHaveBeenCalledWith({
        userId,
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: expect.any(Date),
        isActive: true,
      });
      expect(result).toEqual(mockConsent);
    });
  });

  describe('getCurrentConsent', () => {
    it('should return current active consent', async () => {
      const userId = 'test-user-id';
      const mockConsent = {
        id: 'consent-id',
        userId,
        dataProcessing: true,
        marketing: true,
        analytics: false,
        isActive: true,
      };

      mockRepository.findOne.mockResolvedValue(mockConsent);

      const result = await service.getCurrentConsent(userId);

      expect(mockRepository.findOne).toHaveBeenCalledWith({
        where: { userId, isActive: true },
        order: { createdAt: 'DESC' },
      });
      expect(result).toEqual(mockConsent);
    });

    it('should return null if no active consent found', async () => {
      const userId = 'test-user-id';

      mockRepository.findOne.mockResolvedValue(null);

      const result = await service.getCurrentConsent(userId);

      expect(result).toBeNull();
    });
  });
});
