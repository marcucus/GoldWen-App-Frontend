import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { User } from '../../database/entities/user.entity';
import { Match } from '../../database/entities/match.entity';
import { Chat } from '../../database/entities/chat.entity';
import { Message } from '../../database/entities/message.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { Report } from '../../database/entities/report.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { CustomLoggerService } from '../../common/logger';

import {
  UserStatus,
  MatchStatus,
  ChatStatus,
  SubscriptionStatus,
  ReportStatus,
} from '../../common/enums';

import {
  GetActivityStatsDto,
  ExportStatsDto,
  GlobalStatsResponseDto,
  UserStatsResponseDto,
  ActivityStatsResponseDto,
  ExportFormat,
  ActivityPeriod,
} from './dto';

@Injectable()
export class StatsService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Match)
    private matchRepository: Repository<Match>,
    @InjectRepository(Chat)
    private chatRepository: Repository<Chat>,
    @InjectRepository(Message)
    private messageRepository: Repository<Message>,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(Report)
    private reportRepository: Repository<Report>,
    @InjectRepository(DailySelection)
    private dailySelectionRepository: Repository<DailySelection>,
    private logger: CustomLoggerService,
  ) {}

  /**
   * Get global platform statistics
   */
  async getGlobalStats(): Promise<GlobalStatsResponseDto> {
    this.logger.log('Fetching global statistics');

    try {
      const today = new Date();
      const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
      const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);

      // Parallel execution of all queries for better performance
      const [
        totalUsers,
        activeUsers,
        suspendedUsers,
        totalMatches,
        activeChats,
        pendingReports,
        activeSubscriptions,
        newRegistrationsToday,
        newMatchesToday,
        messagesSentToday,
        dailyActiveUsers,
        monthlyActiveUsers,
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
        this.userRepository.count({
          where: {
            createdAt: new Date(startOfToday.getTime()),
          },
        }),
        this.matchRepository.count({
          where: {
            status: MatchStatus.MATCHED,
            createdAt: new Date(startOfToday.getTime()),
          },
        }),
        this.messageRepository.count({
          where: {
            createdAt: new Date(startOfToday.getTime()),
          },
        }),
        this.userRepository.count({
          where: {
            lastActiveAt: new Date(sevenDaysAgo.getTime()),
          },
        }),
        this.userRepository.count({
          where: {
            lastActiveAt: new Date(thirtyDaysAgo.getTime()),
          },
        }),
      ]);

      // Calculate revenue from active subscriptions
      const subscriptions = await this.subscriptionRepository.find({
        where: { status: SubscriptionStatus.ACTIVE },
      });

      const totalRevenue = subscriptions.reduce((sum, sub) => {
        return sum + (sub.price || 0);
      }, 0);

      // Calculate average matches per user
      const avgMatchesPerUser = totalUsers > 0 ? totalMatches / totalUsers : 0;

      const stats: GlobalStatsResponseDto = {
        totalUsers,
        activeUsers,
        suspendedUsers,
        totalMatches,
        activeChats,
        pendingReports,
        totalRevenue,
        activeSubscriptions,
        newRegistrationsToday,
        newMatchesToday,
        messagesSentToday,
        avgMatchesPerUser: Math.round(avgMatchesPerUser * 100) / 100,
        dailyActiveUsers,
        monthlyActiveUsers,
      };

      this.logger.log('Global statistics fetched successfully');
      return stats;
    } catch (error) {
      this.logger.error('Failed to fetch global statistics', error);
      throw error;
    }
  }

  /**
   * Get statistics for a specific user
   */
  async getUserStats(userId: string): Promise<UserStatsResponseDto> {
    this.logger.log(`Fetching statistics for user: ${userId}`);

    try {
      // Check if user exists
      const user = await this.userRepository.findOne({ 
        where: { id: userId },
        relations: ['profile']
      });
      if (!user) {
        throw new NotFoundException('User not found');
      }

      // Get user's matches
      const totalMatches = await this.matchRepository.count({
        where: [
          { user1Id: userId, status: MatchStatus.MATCHED },
          { user2Id: userId, status: MatchStatus.MATCHED },
        ],
      });

      // Get user's active chats (through matches)
      const activeChats = await this.chatRepository
        .createQueryBuilder('chat')
        .innerJoin('chat.match', 'match')
        .where('(match.user1Id = :userId OR match.user2Id = :userId)', { userId })
        .andWhere('chat.status = :status', { status: ChatStatus.ACTIVE })
        .getCount();

      // Get user's sent messages
      const messagesSent = await this.messageRepository.count({
        where: { senderId: userId },
      });

      // Get user's received messages (need to join through chats and matches)
      const messagesReceived = await this.messageRepository
        .createQueryBuilder('message')
        .innerJoin('message.chat', 'chat')
        .innerJoin('chat.match', 'match')
        .where('message.senderId != :userId', { userId })
        .andWhere('(match.user1Id = :userId OR match.user2Id = :userId)', { userId })
        .getCount();

      // Get daily selections for the user
      const dailySelectionsUsed = await this.dailySelectionRepository.count({
        where: { userId },
      });

      const totalChoicesUsed = await this.dailySelectionRepository
        .createQueryBuilder('ds')
        .select('SUM(ds.choicesUsed)', 'total')
        .where('ds.userId = :userId', { userId })
        .getRawOne();

      // Get current subscription
      const currentSubscription = await this.subscriptionRepository.findOne({
        where: {
          userId,
          status: SubscriptionStatus.ACTIVE,
        },
      });

      // Calculate profile completion percentage (basic implementation)
      let profileCompletionPercent = 0;
      const profile = user.profile;
      
      if (profile?.firstName) profileCompletionPercent += 20;
      if (profile?.lastName) profileCompletionPercent += 20;
      if (profile?.birthDate) profileCompletionPercent += 20;
      if (profile?.bio) profileCompletionPercent += 20;
      if (profile?.location) profileCompletionPercent += 20;

      // Calculate average choices per selection
      const averageChoicesPerSelection = dailySelectionsUsed > 0
        ? Math.round(
            (parseInt(totalChoicesUsed?.total || '0') / dailySelectionsUsed) * 100,
          ) / 100
        : 0;

      // Calculate match rate
      const matchRate = dailySelectionsUsed > 0
        ? Math.round((totalMatches / dailySelectionsUsed) * 100) / 100
        : 0;

      const stats: UserStatsResponseDto = {
        userId,
        totalMatches,
        activeChats,
        profileViews: 0, // Would need separate tracking
        loginStreak: 0, // Would need separate tracking
        messagesSent,
        messagesReceived,
        dailySelectionsUsed,
        totalChoicesUsed: parseInt(totalChoicesUsed?.total || '0'),
        averageChoicesPerSelection,
        matchRate,
        createdAt: user.createdAt!,
        lastActiveAt: user.lastActiveAt || user.createdAt!,
        hasActiveSubscription: !!currentSubscription,
        subscriptionPlan: currentSubscription?.plan || null,
        profileCompletionPercent,
      };

      this.logger.log(`User statistics fetched successfully for user: ${userId}`);
      return stats;
    } catch (error) {
      this.logger.error(`Failed to fetch user statistics for user: ${userId}`, error);
      throw error;
    }
  }

  /**
   * Get activity statistics over time
   */
  async getActivityStats(query: GetActivityStatsDto): Promise<ActivityStatsResponseDto> {
    this.logger.log('Fetching activity statistics');

    try {
      // Set default date range (last 30 days)
      const endDate = query.endDate ? new Date(query.endDate) : new Date();
      const startDate = query.startDate 
        ? new Date(query.startDate) 
        : new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000);
      
      const period = query.period || ActivityPeriod.DAILY;

      // Get date format based on period
      const getDateFormat = (period: ActivityPeriod) => {
        switch (period) {
          case ActivityPeriod.DAILY:
            return 'DATE(created_at)';
          case ActivityPeriod.WEEKLY:
            return 'DATE_TRUNC(\'week\', created_at)';
          case ActivityPeriod.MONTHLY:
            return 'DATE_TRUNC(\'month\', created_at)';
          case ActivityPeriod.YEARLY:
            return 'DATE_TRUNC(\'year\', created_at)';
          default:
            return 'DATE(created_at)';
        }
      };

      const dateFormat = getDateFormat(period);

      // User registrations over time
      const userRegistrations = await this.userRepository
        .createQueryBuilder('user')
        .select(`${dateFormat} as date, COUNT(*) as count`)
        .where('user.createdAt BETWEEN :startDate AND :endDate', { startDate, endDate })
        .groupBy('date')
        .orderBy('date', 'ASC')
        .getRawMany();

      // Matches created over time
      const matchesCreated = await this.matchRepository
        .createQueryBuilder('match')
        .select(`${dateFormat.replace('created_at', 'match.createdAt')} as date, COUNT(*) as count`)
        .where('match.createdAt BETWEEN :startDate AND :endDate', { startDate, endDate })
        .andWhere('match.status = :status', { status: MatchStatus.MATCHED })
        .groupBy('date')
        .orderBy('date', 'ASC')
        .getRawMany();

      // Messages sent over time
      const messagesSent = await this.messageRepository
        .createQueryBuilder('message')
        .select(`${dateFormat.replace('created_at', 'message.createdAt')} as date, COUNT(*) as count`)
        .where('message.createdAt BETWEEN :startDate AND :endDate', { startDate, endDate })
        .groupBy('date')
        .orderBy('date', 'ASC')
        .getRawMany();

      // Daily active users (users who were active on each date)
      const dailyActiveUsers = await this.userRepository
        .createQueryBuilder('user')
        .select(`${dateFormat.replace('created_at', 'user.lastActiveAt')} as date, COUNT(DISTINCT user.id) as count`)
        .where('user.lastActiveAt BETWEEN :startDate AND :endDate', { startDate, endDate })
        .groupBy('date')
        .orderBy('date', 'ASC')
        .getRawMany();

      // Subscription conversions over time
      const subscriptionConversions = await this.subscriptionRepository
        .createQueryBuilder('subscription')
        .select(`${dateFormat.replace('created_at', 'subscription.createdAt')} as date, COUNT(*) as count`)
        .where('subscription.createdAt BETWEEN :startDate AND :endDate', { startDate, endDate })
        .andWhere('subscription.status = :status', { status: SubscriptionStatus.ACTIVE })
        .groupBy('date')
        .orderBy('date', 'ASC')
        .getRawMany();

      // Calculate summary statistics
      const totalActivity = userRegistrations.reduce((sum, item) => sum + parseInt(item.count), 0) +
                           matchesCreated.reduce((sum, item) => sum + parseInt(item.count), 0) +
                           messagesSent.reduce((sum, item) => sum + parseInt(item.count), 0);

      const daysDiff = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 3600 * 24));
      const averageDailyActivity = daysDiff > 0 ? totalActivity / daysDiff : 0;

      // Find peak activity
      const allActivityData = [...userRegistrations, ...matchesCreated, ...messagesSent];
      const activityByDate = new Map<string, number>();
      
      allActivityData.forEach(item => {
        const date = new Date(item.date).toISOString().split('T')[0];
        const currentCount = activityByDate.get(date) || 0;
        activityByDate.set(date, currentCount + parseInt(item.count));
      });

      let peakActivityDate = '';
      let peakActivityCount = 0;
      activityByDate.forEach((count, date) => {
        if (count > peakActivityCount) {
          peakActivityCount = count;
          peakActivityDate = date;
        }
      });

      const stats: ActivityStatsResponseDto = {
        dateRange: {
          startDate: startDate.toISOString().split('T')[0],
          endDate: endDate.toISOString().split('T')[0],
        },
        userRegistrations: userRegistrations.map(item => ({
          date: new Date(item.date).toISOString().split('T')[0],
          count: parseInt(item.count),
        })),
        matchesCreated: matchesCreated.map(item => ({
          date: new Date(item.date).toISOString().split('T')[0],
          count: parseInt(item.count),
        })),
        messagesSent: messagesSent.map(item => ({
          date: new Date(item.date).toISOString().split('T')[0],
          count: parseInt(item.count),
        })),
        dailyActiveUsers: dailyActiveUsers.map(item => ({
          date: new Date(item.date).toISOString().split('T')[0],
          count: parseInt(item.count),
        })),
        subscriptionConversions: subscriptionConversions.map(item => ({
          date: new Date(item.date).toISOString().split('T')[0],
          count: parseInt(item.count),
        })),
        summary: {
          totalActivity,
          averageDailyActivity: Math.round(averageDailyActivity * 100) / 100,
          peakActivityDate,
          peakActivityCount,
        },
      };

      this.logger.log('Activity statistics fetched successfully');
      return stats;
    } catch (error) {
      this.logger.error('Failed to fetch activity statistics', error);
      throw error;
    }
  }

  /**
   * Export statistics in various formats
   */
  async exportStats(
    type: 'global' | 'activity',
    query?: GetActivityStatsDto,
    exportOptions?: ExportStatsDto,
  ): Promise<{ data: any; format: ExportFormat; filename: string }> {
    this.logger.log(`Exporting ${type} statistics`);

    try {
      let data: any;
      let filename: string;

      if (type === 'global') {
        data = await this.getGlobalStats();
        filename = `global-stats-${new Date().toISOString().split('T')[0]}`;
      } else {
        data = await this.getActivityStats(query || {});
        filename = `activity-stats-${new Date().toISOString().split('T')[0]}`;
      }

      const format = exportOptions?.format || ExportFormat.JSON;
      filename = `${filename}.${format}`;

      // For now, we'll return the data as-is
      // In a real implementation, you would format the data according to the export format
      // For CSV: convert to CSV format
      // For PDF: generate PDF document
      // For JSON: already in correct format

      this.logger.log(`Statistics exported successfully: ${filename}`);
      return {
        data,
        format,
        filename,
      };
    } catch (error) {
      this.logger.error(`Failed to export ${type} statistics`, error);
      throw error;
    }
  }
}