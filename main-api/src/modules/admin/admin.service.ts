import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';

import { Admin } from '../../database/entities/admin.entity';
import { User } from '../../database/entities/user.entity';
import { Report } from '../../database/entities/report.entity';
import { Match } from '../../database/entities/match.entity';
import { Chat } from '../../database/entities/chat.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { CustomLoggerService } from '../../common/logger';
import { NotificationsService } from '../notifications/notifications.service';

import {
  UserStatus,
  AdminRole,
  ReportStatus,
  MatchStatus,
  ChatStatus,
  SubscriptionStatus,
} from '../../common/enums';

import {
  AdminLoginDto,
  UpdateUserStatusDto,
  HandleReportDto,
  BroadcastNotificationDto,
  GetUsersDto,
  GetReportsDto,
} from './dto/admin.dto';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(Admin)
    private adminRepository: Repository<Admin>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Report)
    private reportRepository: Repository<Report>,
    @InjectRepository(Match)
    private matchRepository: Repository<Match>,
    @InjectRepository(Chat)
    private chatRepository: Repository<Chat>,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @Inject(forwardRef(() => NotificationsService))
    private notificationsService: NotificationsService,
    private logger: CustomLoggerService,
  ) {}

  async authenticateAdmin(adminLoginDto: AdminLoginDto): Promise<Admin | null> {
    const { email, password } = adminLoginDto;

    this.logger.info('Admin login attempt', { email });

    const admin = await this.adminRepository.findOne({
      where: { email, isActive: true },
    });

    if (!admin) {
      this.logger.logSecurityEvent('admin_login_failed', {
        email,
        reason: 'admin_not_found',
      });
      return null;
    }

    // In production, you'd hash and compare passwords properly
    // For MVP, this is simplified
    if (password === 'admin_password_123') {
      this.logger.logSecurityEvent('admin_login_success', {
        email,
        adminId: admin.id,
      });
      return admin;
    }

    this.logger.logSecurityEvent('admin_login_failed', {
      email,
      reason: 'invalid_password',
    });
    return null;
  }

  async getUsers(getUsersDto: GetUsersDto): Promise<{
    users: User[];
    total: number;
    page: number;
    limit: number;
  }> {
    const { page = 1, limit = 20, status, search } = getUsersDto;
    const skip = (page - 1) * limit;

    const whereCondition: any = {};

    if (status) {
      whereCondition.status = status;
    }

    if (search) {
      whereCondition.email = Like(`%${search}%`);
    }

    const [users, total] = await this.userRepository.findAndCount({
      where: whereCondition,
      relations: ['profile', 'subscriptions'],
      skip,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { users, total, page, limit };
  }

  async getUserDetails(userId: string): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: [
        'profile',
        'profile.photos',
        'profile.promptAnswers',
        'personalityAnswers',
        'subscriptions',
        'matchesAsUser1',
        'matchesAsUser2',
        'reportsSubmitted',
        'reportsReceived',
      ],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async updateUserStatus(
    userId: string,
    updateStatusDto: UpdateUserStatusDto,
  ): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const previousStatus = user.status;
    user.status = updateStatusDto.status;

    this.logger.logBusinessEvent('admin_user_status_change', {
      userId,
      previousStatus,
      newStatus: updateStatusDto.status,
      action: 'admin_user_status_update',
    });

    return this.userRepository.save(user);
  }

  async getReports(getReportsDto: GetReportsDto): Promise<{
    reports: Report[];
    total: number;
    page: number;
    limit: number;
  }> {
    const { page = 1, limit = 20, status, type } = getReportsDto;
    const skip = (page - 1) * limit;

    const whereCondition: any = {};

    if (status) {
      whereCondition.status = status;
    }

    if (type) {
      whereCondition.type = type;
    }

    const [reports, total] = await this.reportRepository.findAndCount({
      where: whereCondition,
      relations: ['reporter', 'reportedUser'],
      skip,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { reports, total, page, limit };
  }

  async handleReport(
    reportId: string,
    handleReportDto: HandleReportDto,
  ): Promise<Report> {
    const report = await this.reportRepository.findOne({
      where: { id: reportId },
      relations: ['reporter', 'reportedUser'],
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    report.status = handleReportDto.status;
    report.resolution = handleReportDto.resolution;
    report.reviewedAt = new Date();

    // Take action based on resolution
    if (handleReportDto.status === ReportStatus.RESOLVED) {
      // Could suspend user, delete content, etc.
      if (handleReportDto.suspendUser && report.reportedUser) {
        report.reportedUser.status = UserStatus.SUSPENDED;
        await this.userRepository.save(report.reportedUser);
      }
    }

    return this.reportRepository.save(report);
  }

  async getDashboardStats(): Promise<{
    totalUsers: number;
    activeUsers: number;
    suspendedUsers: number;
    totalMatches: number;
    activeChats: number;
    pendingReports: number;
    totalRevenue: number;
    activeSubscriptions: number;
  }> {
    const [
      totalUsers,
      activeUsers,
      suspendedUsers,
      totalMatches,
      activeChats,
      pendingReports,
      activeSubscriptions,
    ] = await Promise.all([
      this.userRepository.count(),
      this.userRepository.count({ where: { status: UserStatus.ACTIVE } }),
      this.userRepository.count({ where: { status: UserStatus.SUSPENDED } }),
      this.matchRepository.count({ where: { status: MatchStatus.MATCHED } }),
      this.chatRepository.count({ where: { status: ChatStatus.ACTIVE } }),
      this.reportRepository.count({ where: { status: ReportStatus.PENDING } }),
      this.subscriptionRepository.count({
        where: { status: SubscriptionStatus.ACTIVE },
      }),
    ]);

    // Calculate revenue
    const subscriptions = await this.subscriptionRepository.find({
      where: { status: SubscriptionStatus.ACTIVE },
    });

    const totalRevenue = subscriptions.reduce((sum, sub) => {
      return sum + (sub.price || 0);
    }, 0);

    return {
      totalUsers,
      activeUsers,
      suspendedUsers,
      totalMatches,
      activeChats,
      pendingReports,
      totalRevenue,
      activeSubscriptions,
    };
  }

  async broadcastNotification(
    broadcastDto: BroadcastNotificationDto,
  ): Promise<void> {
    this.logger.logBusinessEvent('admin_broadcast_notification', {
      title: broadcastDto.title,
      type: broadcastDto.type,
      action: 'admin_broadcast',
    });

    // Get all active users
    const users = await this.userRepository.find({
      where: { status: UserStatus.ACTIVE },
      select: ['id', 'email'],
      relations: ['profile'],
    });

    this.logger.info('Broadcasting notification to all users', {
      title: broadcastDto.title,
      body: broadcastDto.body,
      type: broadcastDto.type,
      totalUsers: users.length,
    });

    // Create notifications for all users
    const notificationPromises = users.map((user) =>
      this.notificationsService.createNotification({
        userId: user.id,
        type: broadcastDto.type,
        title: broadcastDto.title,
        body: broadcastDto.body,
        data: {
          action: 'admin_broadcast',
          broadcast: true,
        },
      }),
    );

    try {
      await Promise.all(notificationPromises);

      this.logger.logBusinessEvent('admin_broadcast_completed', {
        title: broadcastDto.title,
        totalUsers: users.length,
        status: 'success',
      });
    } catch (error) {
      this.logger.error(
        'Failed to broadcast notifications to all users',
        error.stack,
        'AdminService',
      );
      throw error;
    }
  }

  async deleteUser(userId: string): Promise<void> {
    const user = await this.userRepository.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const previousStatus = user.status;

    // Soft delete by setting status to DELETED
    user.status = UserStatus.DELETED;
    await this.userRepository.save(user);

    this.logger.logBusinessEvent('admin_user_deleted', {
      userId,
      previousStatus,
      userEmail: user.email,
      action: 'admin_user_delete',
    });
  }

  async getUserAnalytics(): Promise<{
    userRegistrationsByMonth: any[];
    usersByStatus: any[];
    usersBySubscription: any[];
    topReportedUsers: any[];
  }> {
    // This would typically use complex queries or analytics tools
    // For MVP, we'll provide basic data

    const usersByStatus = await this.userRepository
      .createQueryBuilder('user')
      .select('user.status, COUNT(*) as count')
      .groupBy('user.status')
      .getRawMany();

    const usersBySubscription = await this.subscriptionRepository
      .createQueryBuilder('subscription')
      .select('subscription.plan, COUNT(*) as count')
      .where('subscription.status = :status', {
        status: SubscriptionStatus.ACTIVE,
      })
      .groupBy('subscription.plan')
      .getRawMany();

    const topReportedUsers = await this.reportRepository
      .createQueryBuilder('report')
      .select('report.reportedUserId, COUNT(*) as reportCount')
      .leftJoin('report.reportedUser', 'user')
      .addSelect('user.email')
      .groupBy('report.reportedUserId, user.email')
      .orderBy('reportCount', 'DESC')
      .limit(10)
      .getRawMany();

    // For user registrations by month, we'd need more complex date queries
    const userRegistrationsByMonth: any[] = [];

    return {
      userRegistrationsByMonth,
      usersByStatus,
      usersBySubscription,
      topReportedUsers,
    };
  }

  async getRecentActivity(): Promise<{
    recentUsers: User[];
    recentReports: Report[];
    recentMatches: Match[];
  }> {
    const [recentUsers, recentReports, recentMatches] = await Promise.all([
      this.userRepository.find({
        relations: ['profile'],
        order: { createdAt: 'DESC' },
        take: 10,
      }),
      this.reportRepository.find({
        relations: ['reporter', 'reportedUser'],
        order: { createdAt: 'DESC' },
        take: 10,
      }),
      this.matchRepository.find({
        relations: ['user1', 'user2'],
        where: { status: MatchStatus.MATCHED },
        order: { matchedAt: 'DESC' },
        take: 10,
      }),
    ]);

    return {
      recentUsers,
      recentReports,
      recentMatches,
    };
  }
}
