import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GdprService } from './gdpr.service';
import { DataExportService } from './data-export.service';
import {
  AccountDeletion,
  DeletionStatus,
} from '../../database/entities/account-deletion.entity';
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
import { ExportFormat } from '../../database/entities/data-export-request.entity';

describe('GdprService', () => {
  let service: GdprService;
  let dataExportService: DataExportService;
  let accountDeletionRepository: Repository<AccountDeletion>;
  let userRepository: Repository<User>;
  let userConsentRepository: Repository<UserConsent>;

  const mockRepositories = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  };

  const mockDataExportService = {
    createExportRequest: jest.fn(),
    getExportRequest: jest.fn(),
    getUserExportRequests: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GdprService,
        {
          provide: DataExportService,
          useValue: mockDataExportService,
        },
        {
          provide: getRepositoryToken(AccountDeletion),
          useValue: mockRepositories,
        },
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
    dataExportService = module.get<DataExportService>(DataExportService);
    accountDeletionRepository = module.get<Repository<AccountDeletion>>(
      getRepositoryToken(AccountDeletion),
    );
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    userConsentRepository = module.get<Repository<UserConsent>>(
      getRepositoryToken(UserConsent),
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('Art. 20 RGPD - Data Export', () => {
    describe('requestDataExport', () => {
      it('should create a data export request in JSON format', async () => {
        const userId = 'test-user-id';
        const mockRequest = {
          id: 'request-id',
          userId,
          format: ExportFormat.JSON,
          status: 'pending',
          createdAt: new Date(),
        };

        mockDataExportService.createExportRequest.mockResolvedValue(
          mockRequest,
        );

        const result = await service.requestDataExport(userId, 'json');

        expect(mockDataExportService.createExportRequest).toHaveBeenCalledWith(
          userId,
          ExportFormat.JSON,
        );
        expect(result).toEqual(mockRequest);
      });

      it('should create a data export request in PDF format', async () => {
        const userId = 'test-user-id';
        const mockRequest = {
          id: 'request-id',
          userId,
          format: ExportFormat.PDF,
          status: 'pending',
          createdAt: new Date(),
        };

        mockDataExportService.createExportRequest.mockResolvedValue(
          mockRequest,
        );

        const result = await service.requestDataExport(userId, 'pdf');

        expect(mockDataExportService.createExportRequest).toHaveBeenCalledWith(
          userId,
          ExportFormat.PDF,
        );
        expect(result).toEqual(mockRequest);
      });
    });

    describe('getExportRequestStatus', () => {
      it('should retrieve export request status', async () => {
        const userId = 'test-user-id';
        const requestId = 'request-id';
        const mockRequest = {
          id: requestId,
          userId,
          status: 'completed',
        };

        mockDataExportService.getExportRequest.mockResolvedValue(mockRequest);

        const result = await service.getExportRequestStatus(userId, requestId);

        expect(mockDataExportService.getExportRequest).toHaveBeenCalledWith(
          userId,
          requestId,
        );
        expect(result).toEqual(mockRequest);
      });

      it('should throw NotFoundException when request not found', async () => {
        mockDataExportService.getExportRequest.mockResolvedValue(null);

        await expect(
          service.getExportRequestStatus('user-id', 'request-id'),
        ).rejects.toThrow('Export request not found');
      });
    });

    describe('getUserExportRequests', () => {
      it('should retrieve all export requests for a user', async () => {
        const userId = 'test-user-id';
        const mockRequests = [
          { id: 'req-1', userId, status: 'completed' },
          { id: 'req-2', userId, status: 'pending' },
        ];

        mockDataExportService.getUserExportRequests.mockResolvedValue(
          mockRequests,
        );

        const result = await service.getUserExportRequests(userId);

        expect(
          mockDataExportService.getUserExportRequests,
        ).toHaveBeenCalledWith(userId);
        expect(result).toEqual(mockRequests);
      });
    });
  });

  describe('Art. 17 RGPD - Right to be Forgotten', () => {
    describe('requestAccountDeletion', () => {
      it('should create an account deletion request', async () => {
        const userId = 'test-user-id';
        const reason = 'No longer using the service';
        const mockUser = { id: userId, email: 'test@example.com' };
        const mockDeletionRequest = {
          id: 'deletion-id',
          userId,
          userEmail: mockUser.email,
          status: DeletionStatus.PENDING,
          reason,
          requestedAt: new Date(),
        };

        mockRepositories.findOne.mockResolvedValue(mockUser);
        mockRepositories.create.mockReturnValue(mockDeletionRequest);
        mockRepositories.save.mockResolvedValue(mockDeletionRequest);

        const result = await service.requestAccountDeletion(userId, reason);

        expect(userRepository.findOne).toHaveBeenCalledWith({
          where: { id: userId },
        });
        expect(result.userId).toBe(userId);
        expect(result.status).toBe(DeletionStatus.PENDING);
        expect(result.reason).toBe(reason);
      });

      it('should throw NotFoundException when user not found', async () => {
        mockRepositories.findOne.mockResolvedValue(null);

        await expect(
          service.requestAccountDeletion('invalid-user-id'),
        ).rejects.toThrow('User not found');
      });
    });
  });

  describe('Art. 7 RGPD - Consent Management', () => {
    describe('recordConsent', () => {
      it('should record new consent and deactivate old ones', async () => {
        const userId = 'test-user-id';
        const consentData = {
          dataProcessing: true,
          marketing: false,
          analytics: true,
          consentedAt: '2024-01-15T10:30:00.000Z',
        };

        const mockConsent = {
          id: 'consent-id',
          userId,
          ...consentData,
          isActive: true,
        };

        mockRepositories.update.mockResolvedValue({ affected: 1 });
        mockRepositories.create.mockReturnValue(mockConsent);
        mockRepositories.save.mockResolvedValue(mockConsent);

        const result = await service.recordConsent(userId, consentData);

        // Should deactivate previous consents
        expect(userConsentRepository.update).toHaveBeenCalledWith(
          { userId, isActive: true },
          expect.objectContaining({ isActive: false }),
        );

        expect(result.userId).toBe(userId);
        expect(result.dataProcessing).toBe(true);
        expect(result.isActive).toBe(true);
      });
    });

    describe('getCurrentConsent', () => {
      it('should retrieve current active consent', async () => {
        const userId = 'test-user-id';
        const mockConsent = {
          id: 'consent-id',
          userId,
          dataProcessing: true,
          isActive: true,
        };

        mockRepositories.findOne.mockResolvedValue(mockConsent);

        const result = await service.getCurrentConsent(userId);

        expect(userConsentRepository.findOne).toHaveBeenCalledWith({
          where: { userId, isActive: true },
          order: { createdAt: 'DESC' },
        });
        expect(result).toEqual(mockConsent);
      });

      it('should return null when no active consent exists', async () => {
        mockRepositories.findOne.mockResolvedValue(null);

        const result = await service.getCurrentConsent('user-id');

        expect(result).toBeNull();
      });
    });

    describe('getConsentHistory', () => {
      it('should retrieve all consent records for a user', async () => {
        const userId = 'test-user-id';
        const mockHistory = [
          { id: 'consent-1', userId, isActive: true },
          { id: 'consent-2', userId, isActive: false },
        ];

        mockRepositories.find.mockResolvedValue(mockHistory);

        const result = await service.getConsentHistory(userId);

        expect(userConsentRepository.find).toHaveBeenCalledWith({
          where: { userId },
          order: { createdAt: 'DESC' },
        });
        expect(result).toEqual(mockHistory);
      });
    });

    describe('revokeConsent', () => {
      it('should revoke active consent', async () => {
        const userId = 'test-user-id';

        mockRepositories.update.mockResolvedValue({ affected: 1 });

        await service.revokeConsent(userId);

        expect(userConsentRepository.update).toHaveBeenCalledWith(
          { userId, isActive: true },
          expect.objectContaining({ isActive: false }),
        );
      });
    });
  });
});
