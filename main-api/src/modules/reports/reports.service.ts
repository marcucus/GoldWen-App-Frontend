import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Report } from '../../database/entities/report.entity';
import { User } from '../../database/entities/user.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateReportDto } from './dto/create-report.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { GetReportsDto } from './dto/get-reports.dto';
import { ReportStatus, NotificationType } from '../../common/enums';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Report)
    private reportRepository: Repository<Report>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private notificationsService: NotificationsService,
  ) {}

  /**
   * Create a new report
   */
  async createReport(
    reporterId: string,
    createReportDto: CreateReportDto,
  ): Promise<Report> {
    const { targetUserId, evidence, messageId, chatId, ...reportData } =
      createReportDto;

    // Validate that target user exists
    const targetUser = await this.userRepository.findOne({
      where: { id: targetUserId },
    });

    if (!targetUser) {
      throw new BadRequestException('Target user not found');
    }

    // Prevent self-reporting
    if (reporterId === targetUserId) {
      throw new BadRequestException('You cannot report yourself');
    }

    // Check for duplicate reports (same reporter, same target, same type, within last 24h)
    const existingReport = await this.reportRepository.findOne({
      where: {
        reporterId,
        reportedUserId: targetUserId,
        type: reportData.type,
        status: ReportStatus.PENDING,
      },
    });

    if (existingReport) {
      throw new BadRequestException(
        'You have already submitted a similar report for this user',
      );
    }

    // Create the report
    const report = this.reportRepository.create({
      reporterId,
      reportedUserId: targetUserId,
      evidence: evidence ? JSON.stringify(evidence) : undefined,
      messageId,
      chatId,
      ...reportData,
    });

    const savedReport = await this.reportRepository.save(report);

    // Send notification to admins/moderators about new report
    try {
      await this.sendReportNotification(savedReport);
    } catch (error) {
      // Log error but don't fail the report creation
      console.error('Failed to send report notification:', error);
    }

    return savedReport;
  }

  /**
   * Get reports for admin/moderator interface
   */
  async getReports(getReportsDto: GetReportsDto) {
    const { page = 1, limit = 10, status, type } = getReportsDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.reportRepository
      .createQueryBuilder('report')
      .leftJoinAndSelect('report.reporter', 'reporter')
      .leftJoinAndSelect('report.reportedUser', 'reportedUser')
      .leftJoinAndSelect('report.reviewedBy', 'reviewedBy')
      .orderBy('report.createdAt', 'DESC');

    if (status) {
      queryBuilder.andWhere('report.status = :status', { status });
    }

    if (type) {
      queryBuilder.andWhere('report.type = :type', { type });
    }

    const [reports, total] = await queryBuilder
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    // Parse evidence JSON for each report
    const reportsWithParsedEvidence = reports.map((report) => ({
      ...report,
      evidence: report.evidence ? JSON.parse(report.evidence) : null,
    }));

    return {
      data: reportsWithParsedEvidence,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }

  /**
   * Get reports submitted by a specific user
   */
  async getUserReports(
    userId: string,
    getReportsDto: GetReportsDto,
  ): Promise<any> {
    const { page = 1, limit = 10, status, type } = getReportsDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.reportRepository
      .createQueryBuilder('report')
      .leftJoinAndSelect('report.reportedUser', 'reportedUser')
      .where('report.reporterId = :userId', { userId })
      .orderBy('report.createdAt', 'DESC');

    if (status) {
      queryBuilder.andWhere('report.status = :status', { status });
    }

    if (type) {
      queryBuilder.andWhere('report.type = :type', { type });
    }

    const [reports, total] = await queryBuilder
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    // Parse evidence and exclude sensitive admin data
    const sanitizedReports = reports.map((report) => ({
      id: report.id,
      type: report.type,
      status: report.status,
      reason: report.reason,
      description: report.description,
      evidence: report.evidence ? JSON.parse(report.evidence) : null,
      createdAt: report.createdAt,
      updatedAt: report.updatedAt,
      reviewedAt: report.reviewedAt,
      reportedUser: {
        id: report.reportedUser.id,
        // Don't expose sensitive user data
      },
    }));

    return {
      data: sanitizedReports,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }

  /**
   * Update report status (admin/moderator only)
   */
  async updateReportStatus(
    reportId: string,
    reviewerId: string,
    updateDto: UpdateReportStatusDto,
  ): Promise<Report> {
    const report = await this.reportRepository.findOne({
      where: { id: reportId },
      relations: ['reporter', 'reportedUser'],
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    // Update report fields
    report.status = updateDto.status;
    report.reviewedById = reviewerId;
    report.reviewedAt = new Date();

    if (updateDto.reviewNotes) {
      report.reviewNotes = updateDto.reviewNotes;
    }

    if (updateDto.resolution) {
      report.resolution = updateDto.resolution;
    }

    const updatedReport = await this.reportRepository.save(report);

    // Notify the reporter about the resolution
    try {
      await this.sendResolutionNotification(updatedReport);
    } catch (error) {
      console.error('Failed to send resolution notification:', error);
    }

    return updatedReport;
  }

  /**
   * Get report by ID (admin/moderator only)
   */
  async getReportById(reportId: string): Promise<Report> {
    const report = await this.reportRepository.findOne({
      where: { id: reportId },
      relations: ['reporter', 'reportedUser', 'reviewedBy'],
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    // Parse evidence JSON
    return {
      ...report,
      evidence: report.evidence ? JSON.parse(report.evidence) : null,
    };
  }

  /**
   * Send notification to admins about new report
   */
  private async sendReportNotification(report: Report): Promise<void> {
    // This would typically send notifications to all admins/moderators
    // For now, we'll just implement the basic structure
    // In a real implementation, you'd query admin users and send notifications

    const message = `New report received: ${report.type} from user ${report.reporterId}`;

    // Implementation would depend on your notification system
    // For example:
    // await this.notificationsService.sendToAdmins({
    //   type: NotificationType.SYSTEM,
    //   title: 'New Report Submitted',
    //   body: message,
    //   data: { reportId: report.id }
    // });
  }

  /**
   * Send notification to reporter about resolution
   */
  private async sendResolutionNotification(report: Report): Promise<void> {
    if (!report.reporter) return;

    try {
      await this.notificationsService.createNotification({
        userId: report.reporter.id,
        type: NotificationType.SYSTEM,
        title: 'Report Update',
        body: `Your report has been ${report.status}`,
        data: {
          reportId: report.id,
          status: report.status,
        },
      });
    } catch (error) {
      console.error('Failed to send resolution notification:', error);
    }
  }

  /**
   * Get report statistics (admin only)
   */
  async getReportStatistics(): Promise<any> {
    const total = await this.reportRepository.count();
    const pending = await this.reportRepository.count({
      where: { status: ReportStatus.PENDING },
    });
    const resolved = await this.reportRepository.count({
      where: { status: ReportStatus.RESOLVED },
    });
    const dismissed = await this.reportRepository.count({
      where: { status: ReportStatus.DISMISSED },
    });

    // Get reports by type
    const reportsByType = await this.reportRepository
      .createQueryBuilder('report')
      .select('report.type', 'type')
      .addSelect('COUNT(*)', 'count')
      .groupBy('report.type')
      .getRawMany();

    return {
      total,
      byStatus: {
        pending,
        resolved,
        dismissed,
        reviewed: await this.reportRepository.count({
          where: { status: ReportStatus.REVIEWED },
        }),
      },
      byType: reportsByType.reduce((acc, item) => {
        acc[item.type] = parseInt(item.count);
        return acc;
      }, {}),
    };
  }
}
