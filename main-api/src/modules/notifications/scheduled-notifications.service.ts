import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';

import { NotificationsService } from './notifications.service';
import { User } from '../../database/entities/user.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { Chat } from '../../database/entities/chat.entity';
import { CustomLoggerService } from '../../common/logger';
import { NotificationType } from '../../common/enums';

@Injectable()
export class ScheduledNotificationsService {
  constructor(
    private notificationsService: NotificationsService,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(DailySelection)
    private dailySelectionRepository: Repository<DailySelection>,
    @InjectRepository(Chat)
    private chatRepository: Repository<Chat>,
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {}

  // Send daily selection notifications at 12:00 PM (local time based approach)
  @Cron('0 12 * * *', {
    name: 'daily-selection-notifications',
    timeZone: 'Europe/Paris', // Adjust based on your main timezone
  })
  async sendDailySelectionNotifications() {
    const isProduction =
      this.configService.get('app.environment') === 'production';

    if (!isProduction) {
      this.logger.info(
        'Skipping daily selection notifications in non-production environment',
      );
      return;
    }

    try {
      this.logger.info('Starting daily selection notifications job');

      // Get users who should receive daily selection notifications
      // This would need to be adjusted based on user timezone preferences
      const users = await this.userRepository
        .createQueryBuilder('user')
        .leftJoinAndSelect('user.notificationPreferences', 'prefs')
        .where('user.status = :status', { status: 'ACTIVE' })
        .andWhere('user.notificationsEnabled = true')
        .andWhere(
          '(prefs.dailySelection IS NULL OR prefs.dailySelection = true)',
        )
        .getMany();

      let successCount = 0;
      let errorCount = 0;

      for (const user of users) {
        try {
          // Check if user has a daily selection for today
          const today = new Date();
          today.setHours(0, 0, 0, 0);

          const hasSelection = await this.dailySelectionRepository
            .createQueryBuilder('selection')
            .where('selection.userId = :userId', { userId: user.id })
            .andWhere('selection.createdAt >= :today', { today })
            .getOne();

          if (hasSelection) {
            await this.notificationsService.sendDailySelectionNotification(
              user.id,
            );
            successCount++;
          }
        } catch (error) {
          this.logger.error(
            `Failed to send daily selection notification to user ${user.id}`,
            error,
          );
          errorCount++;
        }
      }

      this.logger.info(`Daily selection notifications job completed`, {
        totalUsers: users.length,
        successCount,
        errorCount,
      });
    } catch (error) {
      this.logger.error('Daily selection notifications job failed', error);
    }
  }

  // Check for expiring conversations every hour
  @Cron(CronExpression.EVERY_HOUR, {
    name: 'expiring-chat-notifications',
  })
  async sendExpiringChatNotifications() {
    try {
      this.logger.info('Starting expiring chat notifications job');

      // Find conversations that will expire in the next 2 hours
      const twoHoursFromNow = new Date(Date.now() + 2 * 60 * 60 * 1000);
      const fourHoursFromNow = new Date(Date.now() + 4 * 60 * 60 * 1000);

      const expiringChats = await this.chatRepository
        .createQueryBuilder('chat')
        .leftJoinAndSelect('chat.match', 'match')
        .leftJoinAndSelect('match.user1', 'user1')
        .leftJoinAndSelect('match.user2', 'user2')
        .where('chat.expiresAt BETWEEN :twoHours AND :fourHours', {
          twoHours: twoHoursFromNow,
          fourHours: fourHoursFromNow,
        })
        .andWhere('chat.status = :status', { status: 'ACTIVE' })
        .getMany();

      let notificationCount = 0;

      for (const chat of expiringChats) {
        try {
          const match = chat.match;

          // Send notification to both users
          await Promise.all([
            this.notificationsService.createNotification({
              userId: match.user1.id,
              type: NotificationType.CHAT_EXPIRING,
              title: 'Votre conversation expire bientôt !',
              body: 'Il vous reste moins de 2 heures pour continuer votre conversation.',
              data: {
                chatId: chat.id,
                matchId: match.id,
                action: 'open_chat',
              },
            }),
            this.notificationsService.createNotification({
              userId: match.user2.id,
              type: NotificationType.CHAT_EXPIRING,
              title: 'Votre conversation expire bientôt !',
              body: 'Il vous reste moins de 2 heures pour continuer votre conversation.',
              data: {
                chatId: chat.id,
                matchId: match.id,
                action: 'open_chat',
              },
            }),
          ]);

          notificationCount += 2;
        } catch (error) {
          this.logger.error(
            `Failed to send expiring chat notification for chat ${chat.id}`,
            error,
          );
        }
      }

      this.logger.info(`Expiring chat notifications job completed`, {
        chatsFound: expiringChats.length,
        notificationsSent: notificationCount,
      });
    } catch (error) {
      this.logger.error('Expiring chat notifications job failed', error);
    }
  }

  // Manual trigger for testing
  async triggerDailySelectionNotifications() {
    if (this.configService.get('app.environment') !== 'development') {
      throw new Error('Manual trigger only allowed in development');
    }

    await this.sendDailySelectionNotifications();
  }
}
