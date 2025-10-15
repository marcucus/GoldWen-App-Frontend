import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { ConfigService } from '@nestjs/config';

import { CustomLoggerService } from '../../../common/logger';
import { Notification } from '../../../database/entities/notification.entity';

@Injectable()
export class CleanupScheduler {
  constructor(
    @InjectRepository(Notification)
    private notificationRepository: Repository<Notification>,
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {}

  /**
   * Clean up old data at 3:00 AM daily
   * This includes notifications, sessions, and exported data
   */
  @Cron('0 3 * * *', {
    name: 'cleanup-old-data',
    timeZone: 'Europe/Paris',
  })
  async cleanupOldData() {
    const jobId = `cleanup-data-${Date.now()}`;
    const startTime = Date.now();

    this.logger.info('🧹 Starting general data cleanup job', {
      jobId,
      scheduledTime: new Date().toISOString(),
    });

    try {
      const results = {
        notifications: 0,
      };

      // Clean up old notifications (>30 days)
      results.notifications = await this.cleanupOldNotifications();

      const executionTime = Date.now() - startTime;

      this.logger.info('✅ General data cleanup completed', {
        jobId,
        results,
        executionTimeMs: executionTime,
        executionTimeSec: (executionTime / 1000).toFixed(2),
      });
    } catch (error) {
      const executionTime = Date.now() - startTime;

      this.logger.error(
        `General data cleanup job failed after ${executionTime}ms: ${error.message}`,
        error.stack,
        'CleanupScheduler',
      );

      throw error;
    }
  }

  /**
   * Clean up notifications older than 30 days
   */
  private async cleanupOldNotifications(): Promise<number> {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const result = await this.notificationRepository
      .createQueryBuilder()
      .delete()
      .where('createdAt < :date', { date: thirtyDaysAgo })
      .execute();

    const deletedCount = result.affected || 0;

    this.logger.debug(
      `Deleted ${deletedCount} old notifications (older than ${thirtyDaysAgo.toISOString()})`,
      'CleanupScheduler',
    );

    return deletedCount;
  }

  /**
   * Manual trigger for testing in development
   */
  async triggerCleanup() {
    if (this.configService.get('app.environment') === 'production') {
      throw new Error(
        'Manual trigger not allowed in production. Use scheduled jobs.',
      );
    }

    this.logger.info('Manual trigger: General data cleanup', {
      environment: this.configService.get('app.environment'),
    });

    await this.cleanupOldData();
  }
}
