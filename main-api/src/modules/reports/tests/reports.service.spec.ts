import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BadRequestException, NotFoundException } from '@nestjs/common';

import { ReportsService } from '../reports.service';
import { Report } from '../../../database/entities/report.entity';
import { User } from '../../../database/entities/user.entity';
import { NotificationsService } from '../../notifications/notifications.service';
import { ReportType, ReportStatus } from '../../../common/enums';
import { CreateReportDto } from '../dto/create-report.dto';

describe('ReportsService', () => {
  let service: ReportsService;
  let reportRepository: Repository<Report>;
  let userRepository: Repository<User>;
  let notificationsService: NotificationsService;

  const mockReportRepository = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
    createQueryBuilder: jest.fn(),
    count: jest.fn(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
  };

  const mockNotificationsService = {
    createNotification: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReportsService,
        {
          provide: getRepositoryToken(Report),
          useValue: mockReportRepository,
        },
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: NotificationsService,
          useValue: mockNotificationsService,
        },
      ],
    }).compile();

    service = module.get<ReportsService>(ReportsService);
    reportRepository = module.get<Repository<Report>>(
      getRepositoryToken(Report),
    );
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    notificationsService =
      module.get<NotificationsService>(NotificationsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createReport', () => {
    const mockCreateReportDto: CreateReportDto = {
      targetUserId: 'target-user-id',
      type: ReportType.INAPPROPRIATE_CONTENT,
      reason: 'This user posted inappropriate content',
      description: 'Additional details about the issue',
    };

    const mockTargetUser = {
      id: 'target-user-id',
      email: 'target@example.com',
    } as User;

    const mockCreatedReport = {
      id: 'report-id',
      reporterId: 'reporter-id',
      reportedUserId: 'target-user-id',
      type: ReportType.INAPPROPRIATE_CONTENT,
      status: ReportStatus.PENDING,
      reason: 'This user posted inappropriate content',
      description: 'Additional details about the issue',
      createdAt: new Date(),
    } as Report;

    it('should create a report successfully', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockTargetUser);
      mockReportRepository.findOne.mockResolvedValue(null); // No existing report
      mockReportRepository.create.mockReturnValue(mockCreatedReport);
      mockReportRepository.save.mockResolvedValue(mockCreatedReport);

      const result = await service.createReport(
        'reporter-id',
        mockCreateReportDto,
      );

      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { id: 'target-user-id' },
      });

      expect(mockReportRepository.findOne).toHaveBeenCalledWith({
        where: {
          reporterId: 'reporter-id',
          reportedUserId: 'target-user-id',
          type: ReportType.INAPPROPRIATE_CONTENT,
          status: ReportStatus.PENDING,
        },
      });

      expect(mockReportRepository.create).toHaveBeenCalledWith({
        reporterId: 'reporter-id',
        reportedUserId: 'target-user-id',
        evidence: undefined,
        messageId: undefined,
        chatId: undefined,
        type: ReportType.INAPPROPRIATE_CONTENT,
        reason: 'This user posted inappropriate content',
        description: 'Additional details about the issue',
      });

      expect(mockReportRepository.save).toHaveBeenCalledWith(mockCreatedReport);
      expect(result).toEqual(mockCreatedReport);
    });

    it('should throw BadRequestException if target user not found', async () => {
      mockUserRepository.findOne.mockResolvedValue(null);

      await expect(
        service.createReport('reporter-id', mockCreateReportDto),
      ).rejects.toThrow(BadRequestException);

      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { id: 'target-user-id' },
      });
    });

    it('should throw BadRequestException for self-reporting', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockTargetUser);

      await expect(
        service.createReport('target-user-id', mockCreateReportDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException for duplicate reports', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockTargetUser);
      mockReportRepository.findOne.mockResolvedValue(mockCreatedReport); // Existing report

      await expect(
        service.createReport('reporter-id', mockCreateReportDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('should handle evidence array properly', async () => {
      const dtoWithEvidence = {
        ...mockCreateReportDto,
        evidence: [
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ],
      };

      mockUserRepository.findOne.mockResolvedValue(mockTargetUser);
      mockReportRepository.findOne.mockResolvedValue(null);
      mockReportRepository.create.mockReturnValue(mockCreatedReport);
      mockReportRepository.save.mockResolvedValue(mockCreatedReport);

      await service.createReport('reporter-id', dtoWithEvidence);

      expect(mockReportRepository.create).toHaveBeenCalledWith({
        reporterId: 'reporter-id',
        reportedUserId: 'target-user-id',
        evidence: JSON.stringify([
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ]),
        messageId: undefined,
        chatId: undefined,
        type: ReportType.INAPPROPRIATE_CONTENT,
        reason: 'This user posted inappropriate content',
        description: 'Additional details about the issue',
      });
    });
  });

  describe('updateReportStatus', () => {
    const mockReport = {
      id: 'report-id',
      reporterId: 'reporter-id',
      reportedUserId: 'target-user-id',
      type: ReportType.HARASSMENT,
      status: ReportStatus.PENDING,
      reason: 'User was harassing other users',
      reporter: { id: 'reporter-id' } as User,
      reportedUser: { id: 'target-user-id' } as User,
    } as Report;

    const mockUpdateDto = {
      status: ReportStatus.RESOLVED,
      reviewNotes: 'Report reviewed and action taken',
      resolution: 'User has been warned',
    };

    it('should update report status successfully', async () => {
      const updatedReport = {
        ...mockReport,
        status: ReportStatus.RESOLVED,
        reviewedById: 'reviewer-id',
        reviewNotes: 'Report reviewed and action taken',
        resolution: 'User has been warned',
        reviewedAt: expect.any(Date),
      };

      mockReportRepository.findOne.mockResolvedValue(mockReport);
      mockReportRepository.save.mockResolvedValue(updatedReport);
      mockNotificationsService.createNotification.mockResolvedValue(undefined);

      const result = await service.updateReportStatus(
        'report-id',
        'reviewer-id',
        mockUpdateDto,
      );

      expect(mockReportRepository.findOne).toHaveBeenCalledWith({
        where: { id: 'report-id' },
        relations: ['reporter', 'reportedUser'],
      });

      expect(mockReportRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          status: ReportStatus.RESOLVED,
          reviewedById: 'reviewer-id',
          reviewNotes: 'Report reviewed and action taken',
          resolution: 'User has been warned',
          reviewedAt: expect.any(Date),
        }),
      );

      expect(result).toEqual(updatedReport);
    });

    it('should throw NotFoundException if report not found', async () => {
      mockReportRepository.findOne.mockResolvedValue(null);

      await expect(
        service.updateReportStatus(
          'non-existent-id',
          'reviewer-id',
          mockUpdateDto,
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('getReportStatistics', () => {
    it('should return correct statistics', async () => {
      mockReportRepository.count
        .mockResolvedValueOnce(100) // total
        .mockResolvedValueOnce(25) // pending
        .mockResolvedValueOnce(60) // resolved
        .mockResolvedValueOnce(10) // dismissed
        .mockResolvedValueOnce(5); // reviewed

      const mockQueryBuilder = {
        select: jest.fn().mockReturnThis(),
        addSelect: jest.fn().mockReturnThis(),
        groupBy: jest.fn().mockReturnThis(),
        getRawMany: jest.fn().mockResolvedValue([
          { type: 'inappropriate_content', count: '40' },
          { type: 'harassment', count: '30' },
          { type: 'spam', count: '20' },
          { type: 'fake_profile', count: '10' },
        ]),
      };

      mockReportRepository.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      const result = await service.getReportStatistics();

      expect(result).toEqual({
        total: 100,
        byStatus: {
          pending: 25,
          resolved: 60,
          dismissed: 10,
          reviewed: 5,
        },
        byType: {
          inappropriate_content: 40,
          harassment: 30,
          spam: 20,
          fake_profile: 10,
        },
      });
    });
  });
});
