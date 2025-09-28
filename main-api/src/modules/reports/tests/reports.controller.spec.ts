import { Test, TestingModule } from '@nestjs/testing';
import { ExecutionContext } from '@nestjs/common';

import { ReportsController } from '../reports.controller';
import { ReportsService } from '../reports.service';
import { AdminGuard } from '../../auth/guards/admin.guard';
import { ReportType, ReportStatus } from '../../../common/enums';
import { CreateReportDto } from '../dto/create-report.dto';
import { UpdateReportStatusDto } from '../dto/update-report-status.dto';

describe('ReportsController', () => {
  let controller: ReportsController;
  let service: ReportsService;

  const mockReportsService = {
    createReport: jest.fn(),
    getUserReports: jest.fn(),
    getReports: jest.fn(),
    updateReportStatus: jest.fn(),
    getReportById: jest.fn(),
    getReportStatistics: jest.fn(),
  };

  const mockAdminGuard = {
    canActivate: jest.fn((context: ExecutionContext) => {
      const request = context.switchToHttp().getRequest();
      // Mock admin user
      request.user = { id: 'admin-id', email: 'admin@example.com' };
      return true;
    }),
  };

  const mockUser = {
    id: 'user-id',
    email: 'user@example.com',
  };

  const mockRequest = {
    user: mockUser,
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ReportsController],
      providers: [
        {
          provide: ReportsService,
          useValue: mockReportsService,
        },
      ],
    })
      .overrideGuard(AdminGuard)
      .useValue(mockAdminGuard)
      .compile();

    controller = module.get<ReportsController>(ReportsController);
    service = module.get<ReportsService>(ReportsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createReport', () => {
    const createReportDto: CreateReportDto = {
      targetUserId: 'target-user-id',
      type: ReportType.INAPPROPRIATE_CONTENT,
      reason: 'This user posted inappropriate content',
      description: 'Additional details',
    };

    const mockCreatedReport = {
      id: 'report-id',
      type: ReportType.INAPPROPRIATE_CONTENT,
      status: ReportStatus.PENDING,
      reason: 'This user posted inappropriate content',
      description: 'Additional details',
      createdAt: new Date(),
    };

    it('should create a report successfully', async () => {
      mockReportsService.createReport.mockResolvedValue(mockCreatedReport);

      const result = await controller.createReport(
        mockRequest as any,
        createReportDto,
      );

      expect(mockReportsService.createReport).toHaveBeenCalledWith(
        'user-id',
        createReportDto,
      );

      expect(result).toEqual({
        success: true,
        message: 'Report submitted successfully',
        data: {
          id: 'report-id',
          type: ReportType.INAPPROPRIATE_CONTENT,
          status: ReportStatus.PENDING,
          reason: 'This user posted inappropriate content',
          description: 'Additional details',
          createdAt: mockCreatedReport.createdAt,
        },
      });
    });
  });

  describe('getUserReports', () => {
    const mockReportsResult = {
      data: [
        {
          id: 'report-id',
          type: ReportType.HARASSMENT,
          status: ReportStatus.RESOLVED,
          reason: 'User was sending inappropriate messages',
          createdAt: new Date(),
        },
      ],
      pagination: {
        page: 1,
        limit: 10,
        total: 1,
        pages: 1,
        hasNext: false,
        hasPrev: false,
      },
    };

    it('should return user reports', async () => {
      mockReportsService.getUserReports.mockResolvedValue(mockReportsResult);

      const result = await controller.getUserReports(mockRequest as any, {
        page: 1,
        limit: 10,
      });

      expect(mockReportsService.getUserReports).toHaveBeenCalledWith(
        'user-id',
        {
          page: 1,
          limit: 10,
        },
      );

      expect(result).toEqual({
        success: true,
        data: mockReportsResult.data,
        pagination: mockReportsResult.pagination,
      });
    });
  });

  describe('getReports (Admin only)', () => {
    const mockAllReportsResult = {
      data: [
        {
          id: 'report-id',
          type: ReportType.SPAM,
          status: ReportStatus.PENDING,
          reason: 'User is sending spam messages',
          reporter: { id: 'reporter-id', email: 'reporter@example.com' },
          reportedUser: { id: 'reported-id', email: 'reported@example.com' },
          createdAt: new Date(),
        },
      ],
      pagination: {
        page: 1,
        limit: 10,
        total: 1,
        pages: 1,
        hasNext: false,
        hasPrev: false,
      },
    };

    it('should return all reports for admin', async () => {
      mockReportsService.getReports.mockResolvedValue(mockAllReportsResult);

      const result = await controller.getReports({
        page: 1,
        limit: 10,
      });

      expect(mockReportsService.getReports).toHaveBeenCalledWith({
        page: 1,
        limit: 10,
      });

      expect(result).toEqual({
        success: true,
        data: mockAllReportsResult.data,
        pagination: mockAllReportsResult.pagination,
      });
    });
  });

  describe('updateReportStatus (Admin only)', () => {
    const updateStatusDto: UpdateReportStatusDto = {
      status: ReportStatus.RESOLVED,
      reviewNotes: 'Report reviewed and action taken',
      resolution: 'User has been warned',
    };

    const mockUpdatedReport = {
      id: 'report-id',
      status: ReportStatus.RESOLVED,
      reviewNotes: 'Report reviewed and action taken',
      resolution: 'User has been warned',
      reviewedAt: new Date(),
      reviewedBy: { id: 'admin-id' },
    };

    it('should update report status successfully', async () => {
      const adminRequest = {
        user: { id: 'admin-id', email: 'admin@example.com' },
      };

      mockReportsService.updateReportStatus.mockResolvedValue(
        mockUpdatedReport,
      );

      const result = await controller.updateReportStatus(
        'report-id',
        adminRequest as any,
        updateStatusDto,
      );

      expect(mockReportsService.updateReportStatus).toHaveBeenCalledWith(
        'report-id',
        'admin-id',
        updateStatusDto,
      );

      expect(result).toEqual({
        success: true,
        message: 'Report status updated successfully',
        data: {
          id: 'report-id',
          status: ReportStatus.RESOLVED,
          reviewNotes: 'Report reviewed and action taken',
          resolution: 'User has been warned',
          reviewedAt: mockUpdatedReport.reviewedAt,
          reviewedBy: 'admin-id',
        },
      });
    });
  });

  describe('getReportStatistics (Admin only)', () => {
    const mockStatistics = {
      total: 150,
      byStatus: {
        pending: 25,
        reviewed: 50,
        resolved: 60,
        dismissed: 15,
      },
      byType: {
        inappropriate_content: 45,
        harassment: 30,
        fake_profile: 25,
        spam: 35,
        other: 15,
      },
    };

    it('should return report statistics', async () => {
      mockReportsService.getReportStatistics.mockResolvedValue(mockStatistics);

      const result = await controller.getReportStatistics();

      expect(mockReportsService.getReportStatistics).toHaveBeenCalled();

      expect(result).toEqual({
        success: true,
        data: mockStatistics,
      });
    });
  });
});
