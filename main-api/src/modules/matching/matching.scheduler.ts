import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';

import { User } from '../../database/entities/user.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { CustomLoggerService } from '../../common/logger';
import { MatchingService } from './matching.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class MatchingScheduler {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(DailySelection)
    private dailySelectionRepository: Repository<DailySelection>,
    private matchingService: MatchingService,
    private notificationsService: NotificationsService,
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {}

  /**
   * Generate daily selections for all users at 12:00 PM
   * This runs every day at noon
   * TODO: Implement timezone-aware scheduling for multi-region users
   */
  @Cron('0 12 * * *', {
    name: 'daily-selection-generation',
    timeZone: 'Europe/Paris', // Main timezone - adjust based on requirements
  })
  async generateDailySelectionsForAllUsers() {
    const startTime = Date.now();
    const jobId = `daily-selection-${Date.now()}`;

    this.logger.info('🚀 Starting daily selection generation job', {
      jobId,
      scheduledTime: new Date().toISOString(),
      timezone: 'Europe/Paris',
    });

    try {
      // Get all users with completed profiles
      const users = await this.userRepository.find({
        where: { isProfileCompleted: true },
      });

      this.logger.info('Retrieved users for daily selection', {
        jobId,
        totalUsers: users.length,
      });

      let successCount = 0;
      let errorCount = 0;
      let skippedCount = 0;
      const errors: Array<{ userId: string; error: string }> = [];

      // Process each user
      for (const user of users) {
        try {
          // Generate daily selection
          await this.matchingService.generateDailySelection(user.id);

          // Send push notification
          try {
            await this.notificationsService.sendDailySelectionNotification(
              user.id,
            );
          } catch (notifError) {
            // Log notification error but don't fail the whole job
            this.logger.warn(
              `Failed to send daily selection notification for user ${user.id}: ${notifError.message}`,
              'MatchingScheduler',
            );
          }

          successCount++;
        } catch (error) {
          // Check if selection already exists (not an error, just skip)
          if (error.message?.includes('already has a selection')) {
            skippedCount++;
          } else {
            errorCount++;
            errors.push({
              userId: user.id,
              error: error.message || 'Unknown error',
            });

            this.logger.error(
              `Failed to generate daily selection for user ${user.id}`,
              error.stack,
              'MatchingScheduler',
            );
          }
        }
      }

      const executionTime = Date.now() - startTime;

      // Log completion with detailed metrics
      this.logger.info('✅ Daily selection generation completed', {
        jobId,
        totalUsers: users.length,
        successCount,
        errorCount,
        skippedCount,
        executionTimeMs: executionTime,
        executionTimeSec: (executionTime / 1000).toFixed(2),
        successRate: ((successCount / users.length) * 100).toFixed(2) + '%',
      });

      // Alert if there are errors
      if (errorCount > 0) {
        const errorRate = (errorCount / users.length) * 100;
        const alertLevel = errorRate > 10 ? 'CRITICAL' : 'WARNING';

        this.logger.warn(
          `${alertLevel}: Daily selection generation had ${errorCount} errors (${errorRate.toFixed(2)}%). First 5 errors: ${JSON.stringify(errors.slice(0, 5))}`,
          'MatchingScheduler',
        );

        // TODO: Send alert to monitoring system (Sentry, Slack, etc.)
        // if (errorRate > 10) {
        //   await this.sendCriticalAlert('Daily selection generation failure', {
        //     errorCount,
        //     errorRate,
        //   });
        // }
      }
    } catch (error) {
      const executionTime = Date.now() - startTime;

      this.logger.error(
        `Daily selection generation job failed catastrophically after ${executionTime}ms: ${error.message}`,
        error.stack,
        'MatchingScheduler',
      );

      // TODO: Send critical alert
      // await this.sendCriticalAlert('Daily selection generation catastrophic failure', {
      //   error: error.message,
      // });

      throw error; // Re-throw to ensure it's logged by NestJS scheduler
    }
  }

  /**
   * Clean up old daily selections at midnight
   * Keeps only the last 30 days of selections
   */
  @Cron('0 0 * * *', {
    name: 'cleanup-old-daily-selections',
    timeZone: 'Europe/Paris',
  })
  async cleanupOldDailySelections() {
    const jobId = `cleanup-selections-${Date.now()}`;
    const startTime = Date.now();

    this.logger.info('🧹 Starting daily selections cleanup job', {
      jobId,
      scheduledTime: new Date().toISOString(),
    });

    try {
      // Delete selections older than 30 days
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const result = await this.dailySelectionRepository
        .createQueryBuilder()
        .delete()
        .where('createdAt < :date', { date: thirtyDaysAgo })
        .execute();

      const executionTime = Date.now() - startTime;

      this.logger.info('✅ Daily selections cleanup completed', {
        jobId,
        deletedCount: result.affected || 0,
        cutoffDate: thirtyDaysAgo.toISOString(),
        executionTimeMs: executionTime,
      });
    } catch (error) {
      this.logger.error(
        `Daily selections cleanup job failed: ${error.message}`,
        error.stack,
        'MatchingScheduler',
      );

      throw error;
    }
  }

  /**
   * Manual trigger for testing in development
   * Can be called from admin endpoints or for testing
   */
  async triggerDailySelectionGeneration() {
    if (this.configService.get('app.environment') === 'production') {
      throw new Error(
        'Manual trigger not allowed in production. Use scheduled jobs.',
      );
    }

    this.logger.info('Manual trigger: Daily selection generation', {
      environment: this.configService.get('app.environment'),
    });

    await this.generateDailySelectionsForAllUsers();
  }

  /**
   * Manual trigger for cleanup testing
   */
  async triggerCleanup() {
    if (this.configService.get('app.environment') === 'production') {
      throw new Error(
        'Manual trigger not allowed in production. Use scheduled jobs.',
      );
    }

    this.logger.info('Manual trigger: Daily selections cleanup', {
      environment: this.configService.get('app.environment'),
    });

    await this.cleanupOldDailySelections();
  }
}
