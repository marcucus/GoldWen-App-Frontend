import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DataExportService } from './data-export.service';
import {
  DataExportRequest,
  ExportStatus,
  ExportFormat,
} from '../../database/entities/data-export-request.entity';
import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { Match } from '../../database/entities/match.entity';
import { Message } from '../../database/entities/message.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { UserConsent } from '../../database/entities/user-consent.entity';
import { PushToken } from '../../database/entities/push-token.entity';
import { Notification } from '../../database/entities/notification.entity';
import { Report } from '../../database/entities/report.entity';

describe('DataExportService', () => {
  let service: DataExportService;
  let dataExportRequestRepository: Repository<DataExportRequest>;

  const mockRepositories = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    update: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DataExportService,
        {
          provide: getRepositoryToken(DataExportRequest),
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

    service = module.get<DataExportService>(DataExportService);
    dataExportRequestRepository = module.get<Repository<DataExportRequest>>(
      getRepositoryToken(DataExportRequest),
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createExportRequest', () => {
    it('should create a JSON export request', async () => {
      const userId = 'test-user-id';
      const mockRequest = {
        id: 'request-id',
        userId,
        format: ExportFormat.JSON,
        status: ExportStatus.PENDING,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      };

      mockRepositories.create.mockReturnValue(mockRequest);
      mockRepositories.save.mockResolvedValue(mockRequest);

      const result = await service.createExportRequest(
        userId,
        ExportFormat.JSON,
      );

      expect(dataExportRequestRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          userId,
          format: ExportFormat.JSON,
          status: ExportStatus.PENDING,
        }),
      );
      expect(dataExportRequestRepository.save).toHaveBeenCalled();
      expect(result.userId).toBe(userId);
      expect(result.format).toBe(ExportFormat.JSON);
    });

    it('should create a PDF export request', async () => {
      const userId = 'test-user-id';
      const mockRequest = {
        id: 'request-id',
        userId,
        format: ExportFormat.PDF,
        status: ExportStatus.PENDING,
      };

      mockRepositories.create.mockReturnValue(mockRequest);
      mockRepositories.save.mockResolvedValue(mockRequest);

      const result = await service.createExportRequest(
        userId,
        ExportFormat.PDF,
      );

      expect(result.format).toBe(ExportFormat.PDF);
    });
  });

  describe('getExportRequest', () => {
    it('should retrieve an export request by ID', async () => {
      const userId = 'test-user-id';
      const requestId = 'request-id';
      const mockRequest = {
        id: requestId,
        userId,
        status: ExportStatus.COMPLETED,
      };

      mockRepositories.findOne.mockResolvedValue(mockRequest);

      const result = await service.getExportRequest(userId, requestId);

      expect(dataExportRequestRepository.findOne).toHaveBeenCalledWith({
        where: { id: requestId, userId },
      });
      expect(result).toEqual(mockRequest);
    });

    it('should return null when request not found', async () => {
      mockRepositories.findOne.mockResolvedValue(null);

      const result = await service.getExportRequest('user-id', 'invalid-id');

      expect(result).toBeNull();
    });
  });

  describe('getUserExportRequests', () => {
    it('should retrieve all export requests for a user', async () => {
      const userId = 'test-user-id';
      const mockRequests = [
        {
          id: 'req-1',
          userId,
          status: ExportStatus.COMPLETED,
          createdAt: new Date('2024-01-15'),
        },
        {
          id: 'req-2',
          userId,
          status: ExportStatus.PENDING,
          createdAt: new Date('2024-01-16'),
        },
      ];

      mockRepositories.find.mockResolvedValue(mockRequests);

      const result = await service.getUserExportRequests(userId);

      expect(dataExportRequestRepository.find).toHaveBeenCalledWith({
        where: { userId },
        order: { createdAt: 'DESC' },
      });
      expect(result).toEqual(mockRequests);
      expect(result.length).toBe(2);
    });
  });

  describe('processExportRequest', () => {
    it('should process export request and update status to completed', async () => {
      const requestId = 'request-id';
      const userId = 'test-user-id';
      const mockRequest = {
        id: requestId,
        userId,
        format: ExportFormat.JSON,
        status: ExportStatus.PENDING,
      };

      const mockUser = {
        id: userId,
        email: 'test@example.com',
        status: 'ACTIVE',
        createdAt: new Date(),
      };

      // Mock repository responses
      mockRepositories.findOne
        .mockResolvedValueOnce(mockRequest) // First call for getting the request
        .mockResolvedValueOnce(mockUser) // Second call for getting user
        .mockResolvedValue(null); // Other findOne calls

      mockRepositories.find.mockResolvedValue([]); // Empty arrays for related entities
      mockRepositories.update.mockResolvedValue({ affected: 1 });

      await service.processExportRequest(requestId);

      // Should update status to PROCESSING first
      expect(dataExportRequestRepository.update).toHaveBeenCalledWith(
        requestId,
        { status: ExportStatus.PROCESSING },
      );

      // Should update status to COMPLETED with file URL
      expect(dataExportRequestRepository.update).toHaveBeenCalledWith(
        requestId,
        expect.objectContaining({
          status: ExportStatus.COMPLETED,
          completedAt: expect.any(Date),
          fileUrl: expect.stringContaining('data:application/json;base64'),
        }),
      );
    });

    it('should handle errors and update status to FAILED', async () => {
      const requestId = 'request-id';
      const mockRequest = {
        id: requestId,
        userId: 'test-user-id',
        status: ExportStatus.PENDING,
      };

      mockRepositories.findOne.mockResolvedValue(mockRequest);
      mockRepositories.update
        .mockResolvedValueOnce({ affected: 1 }) // PROCESSING update
        .mockRejectedValueOnce(new Error('Database error')); // Simulate error

      await service.processExportRequest(requestId);

      // Should update to FAILED status
      expect(dataExportRequestRepository.update).toHaveBeenCalledWith(
        requestId,
        expect.objectContaining({
          status: ExportStatus.FAILED,
          errorMessage: expect.any(String),
        }),
      );
    });

    it('should handle missing request gracefully', async () => {
      mockRepositories.findOne.mockResolvedValue(null);

      await service.processExportRequest('invalid-id');

      // Should not throw error, just log
      expect(dataExportRequestRepository.update).not.toHaveBeenCalled();
    });
  });
});
