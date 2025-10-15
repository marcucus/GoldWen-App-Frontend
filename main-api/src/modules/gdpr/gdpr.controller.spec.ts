import { Test, TestingModule } from '@nestjs/testing';
import { GdprController } from './gdpr.controller';
import { GdprService } from './gdpr.service';
import { ExportFormat } from '../../database/entities/data-export-request.entity';
import { DeletionStatus } from '../../database/entities/account-deletion.entity';

describe('GdprController', () => {
  let controller: GdprController;
  let gdprService: GdprService;

  const mockUser = {
    id: 'test-user-id',
    email: 'test@example.com',
  };

  const mockRequest = {
    user: mockUser,
  } as any;

  const mockGdprService = {
    requestDataExport: jest.fn(),
    getExportRequestStatus: jest.fn(),
    getUserExportRequests: jest.fn(),
    requestAccountDeletion: jest.fn(),
    getDeletionRequestStatus: jest.fn(),
    recordConsent: jest.fn(),
    getCurrentConsent: jest.fn(),
    getConsentHistory: jest.fn(),
    revokeConsent: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [GdprController],
      providers: [
        {
          provide: GdprService,
          useValue: mockGdprService,
        },
      ],
    }).compile();

    controller = module.get<GdprController>(GdprController);
    gdprService = module.get<GdprService>(GdprService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('requestDataExport', () => {
    it('should request data export in JSON format', async () => {
      const exportDto = { format: 'json' as const };
      const mockExportRequest = {
        id: 'request-id',
        userId: mockUser.id,
        format: ExportFormat.JSON,
        status: 'pending',
        createdAt: new Date(),
        expiresAt: new Date(),
      };

      mockGdprService.requestDataExport.mockResolvedValue(mockExportRequest);

      const result = await controller.requestDataExport(mockRequest, exportDto);

      expect(gdprService.requestDataExport).toHaveBeenCalledWith(
        mockUser.id,
        'json',
      );
      expect(result.success).toBe(true);
      expect(result.data.requestId).toBe(mockExportRequest.id);
    });

    it('should request data export in PDF format', async () => {
      const exportDto = { format: 'pdf' as const };
      const mockExportRequest = {
        id: 'request-id',
        userId: mockUser.id,
        format: ExportFormat.PDF,
        status: 'pending',
        createdAt: new Date(),
        expiresAt: new Date(),
      };

      mockGdprService.requestDataExport.mockResolvedValue(mockExportRequest);

      const result = await controller.requestDataExport(mockRequest, exportDto);

      expect(gdprService.requestDataExport).toHaveBeenCalledWith(
        mockUser.id,
        'pdf',
      );
      expect(result.data.format).toBe(ExportFormat.PDF);
    });
  });

  describe('getExportRequestStatus', () => {
    it('should return export request status', async () => {
      const requestId = 'request-id';
      const mockExportRequest = {
        id: requestId,
        userId: mockUser.id,
        format: ExportFormat.JSON,
        status: 'completed',
        fileUrl: 'https://example.com/export.json',
        completedAt: new Date(),
        expiresAt: new Date(),
        createdAt: new Date(),
      };

      mockGdprService.getExportRequestStatus.mockResolvedValue(
        mockExportRequest,
      );

      const result = await controller.getExportRequestStatus(
        mockRequest,
        requestId,
      );

      expect(gdprService.getExportRequestStatus).toHaveBeenCalledWith(
        mockUser.id,
        requestId,
      );
      expect(result.success).toBe(true);
      expect(result.data.requestId).toBe(requestId);
      expect(result.data.status).toBe('completed');
    });
  });

  describe('getUserExportRequests', () => {
    it('should return all user export requests', async () => {
      const mockRequests = [
        {
          id: 'req-1',
          userId: mockUser.id,
          format: ExportFormat.JSON,
          status: 'completed',
          fileUrl: 'url-1',
          completedAt: new Date(),
          expiresAt: new Date(),
          createdAt: new Date(),
        },
        {
          id: 'req-2',
          userId: mockUser.id,
          format: ExportFormat.PDF,
          status: 'pending',
          fileUrl: null,
          completedAt: null,
          expiresAt: new Date(),
          createdAt: new Date(),
        },
      ];

      mockGdprService.getUserExportRequests.mockResolvedValue(mockRequests);

      const result = await controller.getUserExportRequests(mockRequest);

      expect(gdprService.getUserExportRequests).toHaveBeenCalledWith(
        mockUser.id,
      );
      expect(result.success).toBe(true);
      expect(result.data.length).toBe(2);
    });
  });

  describe('requestAccountDeletion', () => {
    it('should create account deletion request', async () => {
      const reason = 'No longer needed';
      const mockDeletionRequest = {
        id: 'deletion-id',
        userId: mockUser.id,
        status: DeletionStatus.PENDING,
        requestedAt: new Date(),
      };

      mockGdprService.requestAccountDeletion.mockResolvedValue(
        mockDeletionRequest,
      );

      const result = await controller.requestAccountDeletion(mockRequest, {
        reason,
      });

      expect(gdprService.requestAccountDeletion).toHaveBeenCalledWith(
        mockUser.id,
        reason,
      );
      expect(result.success).toBe(true);
      expect(result.data.requestId).toBe(mockDeletionRequest.id);
      expect(result.data.status).toBe(DeletionStatus.PENDING);
    });

    it('should create deletion request without reason', async () => {
      const mockDeletionRequest = {
        id: 'deletion-id',
        userId: mockUser.id,
        status: DeletionStatus.PENDING,
        requestedAt: new Date(),
      };

      mockGdprService.requestAccountDeletion.mockResolvedValue(
        mockDeletionRequest,
      );

      const result = await controller.requestAccountDeletion(mockRequest, {});

      expect(gdprService.requestAccountDeletion).toHaveBeenCalledWith(
        mockUser.id,
        undefined,
      );
      expect(result.success).toBe(true);
    });
  });

  describe('recordConsent', () => {
    it('should record user consent', async () => {
      const consentDto = {
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: '2024-01-15T10:30:00.000Z',
      };

      const mockConsent = {
        id: 'consent-id',
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: new Date(consentDto.consentedAt),
        isActive: true,
        createdAt: new Date(),
      };

      mockGdprService.recordConsent.mockResolvedValue(mockConsent);

      const result = await controller.recordConsent(mockRequest, consentDto);

      expect(gdprService.recordConsent).toHaveBeenCalledWith(mockUser.id, {
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: consentDto.consentedAt,
      });
      expect(result.success).toBe(true);
      expect(result.data.dataProcessing).toBe(true);
      expect(result.data.isActive).toBe(true);
    });
  });

  describe('getCurrentConsent', () => {
    it('should return current consent', async () => {
      const mockConsent = {
        id: 'consent-id',
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: new Date(),
        isActive: true,
        createdAt: new Date(),
      };

      mockGdprService.getCurrentConsent.mockResolvedValue(mockConsent);

      const result = await controller.getCurrentConsent(mockRequest);

      expect(gdprService.getCurrentConsent).toHaveBeenCalledWith(mockUser.id);
      expect(result.success).toBe(true);
      expect(result.data).toBeTruthy();
      expect(result.data.id).toBe(mockConsent.id);
    });

    it('should return null when no consent exists', async () => {
      mockGdprService.getCurrentConsent.mockResolvedValue(null);

      const result = await controller.getCurrentConsent(mockRequest);

      expect(result.success).toBe(true);
      expect(result.data).toBeNull();
    });
  });

  describe('getConsentHistory', () => {
    it('should return consent history', async () => {
      const mockHistory = [
        {
          id: 'consent-1',
          dataProcessing: true,
          marketing: false,
          analytics: true,
          consentedAt: new Date(),
          revokedAt: null,
          isActive: true,
          createdAt: new Date(),
        },
        {
          id: 'consent-2',
          dataProcessing: true,
          marketing: true,
          analytics: false,
          consentedAt: new Date(),
          revokedAt: new Date(),
          isActive: false,
          createdAt: new Date(),
        },
      ];

      mockGdprService.getConsentHistory.mockResolvedValue(mockHistory);

      const result = await controller.getConsentHistory(mockRequest);

      expect(gdprService.getConsentHistory).toHaveBeenCalledWith(mockUser.id);
      expect(result.success).toBe(true);
      expect(result.data.length).toBe(2);
    });
  });

  describe('revokeConsent', () => {
    it('should revoke consent', async () => {
      mockGdprService.revokeConsent.mockResolvedValue(undefined);

      const result = await controller.revokeConsent(mockRequest);

      expect(gdprService.revokeConsent).toHaveBeenCalledWith(mockUser.id);
      expect(result.success).toBe(true);
      expect(result.message).toBe('Consent revoked successfully');
    });
  });
});
