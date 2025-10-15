import { Test, TestingModule } from '@nestjs/testing';
import { Request } from 'express';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { UsersController } from '../users.controller';
import { UsersService } from '../users.service';
import { ProfilesService } from '../../profiles/profiles.service';
import { GdprService as UsersGdprService } from '../gdpr.service';
import { GdprService as GdprModuleService } from '../../gdpr/gdpr.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Profile } from '../../../database/entities/profile.entity';
import { PromptAnswer } from '../../../database/entities/prompt-answer.entity';
import {
  ExportStatus,
  ExportFormat,
} from '../../../database/entities/data-export-request.entity';

describe('UsersController - Data Export (RGPD)', () => {
  let controller: UsersController;
  let gdprModuleService: GdprModuleService;

  const mockUsersService = {};
  const mockProfilesService = {};
  const mockUsersGdprService = {};
  const mockGdprModuleService = {
    requestDataExport: jest.fn(),
    getExportRequestStatus: jest.fn(),
  };
  const mockProfileRepository = {};
  const mockPromptAnswerRepository = {};

  const mockRequest = {
    user: {
      id: 'user-uuid-123',
      email: 'test@example.com',
    },
  } as Request;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
        {
          provide: ProfilesService,
          useValue: mockProfilesService,
        },
        {
          provide: UsersGdprService,
          useValue: mockUsersGdprService,
        },
        {
          provide: GdprModuleService,
          useValue: mockGdprModuleService,
        },
        {
          provide: getRepositoryToken(Profile),
          useValue: mockProfileRepository,
        },
        {
          provide: getRepositoryToken(PromptAnswer),
          useValue: mockPromptAnswerRepository,
        },
      ],
    }).compile();

    controller = module.get<UsersController>(UsersController);
    gdprModuleService = module.get<GdprModuleService>(GdprModuleService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /users/me/export-data', () => {
    it('should create a data export request successfully', async () => {
      const mockExportRequest = {
        id: 'export-uuid-456',
        userId: 'user-uuid-123',
        format: ExportFormat.JSON,
        status: ExportStatus.PENDING,
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      };

      mockGdprModuleService.requestDataExport.mockResolvedValue(
        mockExportRequest,
      );

      const result = await controller.requestDataExport(mockRequest);

      expect(result).toEqual({
        exportId: 'export-uuid-456',
        status: ExportStatus.PENDING,
        estimatedTime: 300,
      });
      expect(gdprModuleService.requestDataExport).toHaveBeenCalledWith(
        'user-uuid-123',
        'json',
      );
    });

    it('should handle export request with processing status', async () => {
      const mockExportRequest = {
        id: 'export-uuid-789',
        userId: 'user-uuid-123',
        format: ExportFormat.JSON,
        status: ExportStatus.PROCESSING,
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      };

      mockGdprModuleService.requestDataExport.mockResolvedValue(
        mockExportRequest,
      );

      const result = await controller.requestDataExport(mockRequest);

      expect(result).toEqual({
        exportId: 'export-uuid-789',
        status: ExportStatus.PROCESSING,
        estimatedTime: 300,
      });
    });

    it('should propagate service errors', async () => {
      const error = new Error('Database error');
      mockGdprModuleService.requestDataExport.mockRejectedValue(error);

      await expect(controller.requestDataExport(mockRequest)).rejects.toThrow(
        error,
      );
    });
  });

  describe('GET /users/me/export-data/:exportId', () => {
    it('should return export status as "processing" for pending request', async () => {
      const mockExportData = {
        id: 'export-uuid-456',
        userId: 'user-uuid-123',
        format: ExportFormat.JSON,
        status: ExportStatus.PENDING,
        fileUrl: null,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      };

      mockGdprModuleService.getExportRequestStatus.mockResolvedValue(
        mockExportData,
      );

      const result = await controller.getDataExport(
        'export-uuid-456',
        mockRequest,
      );

      expect(result).toEqual({
        status: 'processing',
        downloadUrl: null,
        expiresAt: mockExportData.expiresAt,
      });
      expect(gdprModuleService.getExportRequestStatus).toHaveBeenCalledWith(
        'user-uuid-123',
        'export-uuid-456',
      );
    });

    it('should return export status as "ready" for completed request', async () => {
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
      const mockExportData = {
        id: 'export-uuid-456',
        userId: 'user-uuid-123',
        format: ExportFormat.JSON,
        status: ExportStatus.COMPLETED,
        fileUrl: 'https://example.com/exports/user-data.json',
        expiresAt,
        completedAt: new Date(),
      };

      mockGdprModuleService.getExportRequestStatus.mockResolvedValue(
        mockExportData,
      );

      const result = await controller.getDataExport(
        'export-uuid-456',
        mockRequest,
      );

      expect(result).toEqual({
        status: 'ready',
        downloadUrl: 'https://example.com/exports/user-data.json',
        expiresAt,
      });
    });

    it('should return export status as "processing" for processing request', async () => {
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
      const mockExportData = {
        id: 'export-uuid-456',
        userId: 'user-uuid-123',
        format: ExportFormat.JSON,
        status: ExportStatus.PROCESSING,
        fileUrl: null,
        expiresAt,
      };

      mockGdprModuleService.getExportRequestStatus.mockResolvedValue(
        mockExportData,
      );

      const result = await controller.getDataExport(
        'export-uuid-456',
        mockRequest,
      );

      expect(result).toEqual({
        status: 'processing',
        downloadUrl: null,
        expiresAt,
      });
    });

    it('should return export status as "failed" for failed request', async () => {
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
      const mockExportData = {
        id: 'export-uuid-456',
        userId: 'user-uuid-123',
        format: ExportFormat.JSON,
        status: ExportStatus.FAILED,
        fileUrl: null,
        errorMessage: 'Processing error',
        expiresAt,
      };

      mockGdprModuleService.getExportRequestStatus.mockResolvedValue(
        mockExportData,
      );

      const result = await controller.getDataExport(
        'export-uuid-456',
        mockRequest,
      );

      expect(result).toEqual({
        status: 'failed',
        downloadUrl: null,
        expiresAt,
      });
    });

    it('should throw ForbiddenException when user tries to access another user export', async () => {
      const mockExportData = {
        id: 'export-uuid-456',
        userId: 'other-user-uuid',
        format: ExportFormat.JSON,
        status: ExportStatus.COMPLETED,
        fileUrl: 'https://example.com/exports/user-data.json',
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      };

      mockGdprModuleService.getExportRequestStatus.mockResolvedValue(
        mockExportData,
      );

      await expect(
        controller.getDataExport('export-uuid-456', mockRequest),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should propagate NotFoundException from service', async () => {
      const error = new NotFoundException('Export request not found');
      mockGdprModuleService.getExportRequestStatus.mockRejectedValue(error);

      await expect(
        controller.getDataExport('invalid-uuid', mockRequest),
      ).rejects.toThrow(NotFoundException);
    });

    it('should propagate other service errors', async () => {
      const error = new Error('Database error');
      mockGdprModuleService.getExportRequestStatus.mockRejectedValue(error);

      await expect(
        controller.getDataExport('export-uuid-456', mockRequest),
      ).rejects.toThrow(error);
    });
  });

  describe('Edge cases', () => {
    it('should handle export with expired download URL', async () => {
      const expiresAt = new Date(Date.now() - 1000); // Expired
      const mockExportData = {
        id: 'export-uuid-456',
        userId: 'user-uuid-123',
        format: ExportFormat.JSON,
        status: ExportStatus.COMPLETED,
        fileUrl: 'https://example.com/exports/user-data.json',
        expiresAt,
        completedAt: new Date(),
      };

      mockGdprModuleService.getExportRequestStatus.mockResolvedValue(
        mockExportData,
      );

      const result = await controller.getDataExport(
        'export-uuid-456',
        mockRequest,
      );

      // Should still return ready status, expiration is checked by the service
      expect(result.status).toBe('ready');
      expect(result.expiresAt).toEqual(expiresAt);
    });

    it('should handle export with null expiresAt', async () => {
      const mockExportData = {
        id: 'export-uuid-456',
        userId: 'user-uuid-123',
        format: ExportFormat.JSON,
        status: ExportStatus.PENDING,
        fileUrl: null,
        expiresAt: null,
      };

      mockGdprModuleService.getExportRequestStatus.mockResolvedValue(
        mockExportData,
      );

      const result = await controller.getDataExport(
        'export-uuid-456',
        mockRequest,
      );

      expect(result).toEqual({
        status: 'processing',
        downloadUrl: null,
        expiresAt: null,
      });
    });
  });
});
