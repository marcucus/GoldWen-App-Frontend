import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan, Between } from 'typeorm';
import { ConfigService } from '@nestjs/config';

import { Chat } from '../../database/entities/chat.entity';
import { Message } from '../../database/entities/message.entity';
import { CustomLoggerService } from '../../common/logger';
import { ChatStatus } from '../../common/enums';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ChatScheduler {
  constructor(
    @InjectRepository(Chat)
    private chatRepository: Repository<Chat>,
    @InjectRepository(Message)
    private messageRepository: Repository<Message>,
    private notificationsService: NotificationsService,
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {}

  /**
   * Automatically expire chats every hour
   * Expires chats that have passed their 24-hour limit
   */
  @Cron(CronExpression.EVERY_HOUR, {
    name: 'expire-chats',
  })
  async expireChats() {
    const jobId = `expire-chats-${Date.now()}`;
    const startTime = Date.now();

    this.logger.info('🕐 Starting chat expiration job', {
      jobId,
      scheduledTime: new Date().toISOString(),
    });

    try {
      const now = new Date();

      // Find all active chats that have expired
      const expiredChats = await this.chatRepository.find({
        where: {
          status: ChatStatus.ACTIVE,
          expiresAt: LessThan(now),
        },
        relations: ['match', 'match.user1', 'match.user2'],
      });

      this.logger.info('Found chats to expire', {
        jobId,
        count: expiredChats.length,
      });

      let successCount = 0;
      let errorCount = 0;
      const errors: Array<{ chatId: string; error: string }> = [];

      // Expire each chat
      for (const chat of expiredChats) {
        try {
          chat.status = ChatStatus.EXPIRED;
          await this.chatRepository.save(chat);
          successCount++;

          this.logger.debug(
            `Chat ${chat.id} expired successfully (users: ${chat.match.user1Id}, ${chat.match.user2Id})`,
            'ChatScheduler',
          );
        } catch (error) {
          errorCount++;
          errors.push({
            chatId: chat.id,
            error: error.message || 'Unknown error',
          });

          this.logger.error(
            `Failed to expire chat ${chat.id}`,
            error.stack,
            'ChatScheduler',
          );
        }
      }

      const executionTime = Date.now() - startTime;

      this.logger.info('✅ Chat expiration job completed', {
        jobId,
        totalChats: expiredChats.length,
        successCount,
        errorCount,
        executionTimeMs: executionTime,
      });

      // Alert if there are errors
      if (errorCount > 0) {
        this.logger.warn(
          `Chat expiration had ${errorCount} errors. Sample errors: ${JSON.stringify(errors.slice(0, 5))}`,
          'ChatScheduler',
        );
      }
    } catch (error) {
      const executionTime = Date.now() - startTime;

      this.logger.error(
        `Chat expiration job failed after ${executionTime}ms: ${error.message}`,
        error.stack,
        'ChatScheduler',
      );

      throw error;
    }
  }

  /**
   * Send expiration warnings every hour
   * Warns users 2 hours before their chat expires
   */
  @Cron(CronExpression.EVERY_HOUR, {
    name: 'warn-expiring-chats',
  })
  async warnAboutExpiringChats() {
    const jobId = `warn-expiring-${Date.now()}`;
    const startTime = Date.now();

    this.logger.info('⏰ Starting chat expiration warning job', {
      jobId,
      scheduledTime: new Date().toISOString(),
    });

    try {
      const now = new Date();
      const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);
      const threeHoursFromNow = new Date(now.getTime() + 3 * 60 * 60 * 1000);

      // Find chats expiring in the next 2-3 hours
      const expiringChats = await this.chatRepository.find({
        where: {
          status: ChatStatus.ACTIVE,
          expiresAt: Between(twoHoursFromNow, threeHoursFromNow),
        },
        relations: [
          'match',
          'match.user1',
          'match.user1.profile',
          'match.user2',
          'match.user2.profile',
        ],
      });

      this.logger.info('Found chats expiring soon', {
        jobId,
        count: expiringChats.length,
      });

      let successCount = 0;
      let errorCount = 0;
      const errors: Array<{ chatId: string; error: string }> = [];

      // Send warnings for each chat
      for (const chat of expiringChats) {
        try {
          const hoursLeft = Math.ceil(
            (chat.expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60),
          );

          // Send notification to both users
          const user1 = chat.match.user1;
          const user2 = chat.match.user2;

          try {
            await this.notificationsService.sendChatExpiringNotification(
              user1.id,
              user2.profile?.firstName || 'votre match',
              hoursLeft,
            );
          } catch (notifError) {
            this.logger.warn(
              `Failed to send expiration warning to user ${user1.id}: ${notifError.message}`,
              'ChatScheduler',
            );
          }

          try {
            await this.notificationsService.sendChatExpiringNotification(
              user2.id,
              user1.profile?.firstName || 'votre match',
              hoursLeft,
            );
          } catch (notifError) {
            this.logger.warn(
              `Failed to send expiration warning to user ${user2.id}: ${notifError.message}`,
              'ChatScheduler',
            );
          }

          successCount++;

          this.logger.debug(
            `Expiration warnings sent for chat ${chat.id} to users ${user1.id} and ${user2.id}, ${hoursLeft} hours left`,
            'ChatScheduler',
          );
        } catch (error) {
          errorCount++;
          errors.push({
            chatId: chat.id,
            error: error.message || 'Unknown error',
          });

          this.logger.error(
            `Failed to send expiration warnings for chat ${chat.id}`,
            error.stack,
            'ChatScheduler',
          );
        }
      }

      const executionTime = Date.now() - startTime;

      this.logger.info('✅ Chat expiration warning job completed', {
        jobId,
        totalChats: expiringChats.length,
        successCount,
        errorCount,
        executionTimeMs: executionTime,
      });

      // Alert if there are errors
      if (errorCount > 0) {
        this.logger.warn(
          `Chat expiration warnings had ${errorCount} errors. Sample errors: ${JSON.stringify(errors.slice(0, 5))}`,
          'ChatScheduler',
        );
      }
    } catch (error) {
      const executionTime = Date.now() - startTime;

      this.logger.error(
        `Chat expiration warning job failed after ${executionTime}ms: ${error.message}`,
        error.stack,
        'ChatScheduler',
      );

      throw error;
    }
  }

  /**
   * Clean up old expired chats and messages at midnight
   * Keeps chat records for 90 days, then archives/deletes them
   */
  @Cron('0 0 * * *', {
    name: 'cleanup-old-chats',
    timeZone: 'Europe/Paris',
  })
  async cleanupOldChats() {
    const jobId = `cleanup-chats-${Date.now()}`;
    const startTime = Date.now();

    this.logger.info('🧹 Starting old chats cleanup job', {
      jobId,
      scheduledTime: new Date().toISOString(),
    });

    try {
      // Delete expired chats older than 90 days
      const ninetyDaysAgo = new Date();
      ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

      // First, get IDs of chats to delete
      const chatsToDelete = await this.chatRepository
        .createQueryBuilder('chat')
        .select('chat.id')
        .where('chat.status = :status', { status: ChatStatus.EXPIRED })
        .andWhere('chat.updatedAt < :date', { date: ninetyDaysAgo })
        .getMany();

      const chatIds = chatsToDelete.map((chat) => chat.id);

      let messagesDeleted = 0;
      let chatsDeleted = 0;

      // Delete messages if there are chats to delete
      if (chatIds.length > 0) {
        const messagesResult = await this.messageRepository
          .createQueryBuilder()
          .delete()
          .where('chatId IN (:...chatIds)', { chatIds })
          .execute();

        messagesDeleted = messagesResult.affected || 0;

        // Delete old expired chats
        const chatsResult = await this.chatRepository
          .createQueryBuilder()
          .delete()
          .where('id IN (:...chatIds)', { chatIds })
          .execute();

        chatsDeleted = chatsResult.affected || 0;
      }

      const executionTime = Date.now() - startTime;

      this.logger.info('✅ Old chats cleanup completed', {
        jobId,
        deletedChats: chatsDeleted,
        deletedMessages: messagesDeleted,
        cutoffDate: ninetyDaysAgo.toISOString(),
        executionTimeMs: executionTime,
      });
    } catch (error) {
      const executionTime = Date.now() - startTime;

      this.logger.error(
        `Old chats cleanup job failed after ${executionTime}ms: ${error.message}`,
        error.stack,
        'ChatScheduler',
      );

      throw error;
    }
  }

  /**
   * Manual trigger for testing chat expiration
   */
  async triggerChatExpiration() {
    if (this.configService.get('app.environment') === 'production') {
      throw new Error(
        'Manual trigger not allowed in production. Use scheduled jobs.',
      );
    }

    this.logger.info('Manual trigger: Chat expiration', {
      environment: this.configService.get('app.environment'),
    });

    await this.expireChats();
  }

  /**
   * Manual trigger for testing expiration warnings
   */
  async triggerExpirationWarnings() {
    if (this.configService.get('app.environment') === 'production') {
      throw new Error(
        'Manual trigger not allowed in production. Use scheduled jobs.',
      );
    }

    this.logger.info('Manual trigger: Expiration warnings', {
      environment: this.configService.get('app.environment'),
    });

    await this.warnAboutExpiringChats();
  }

  /**
   * Manual trigger for testing cleanup
   */
  async triggerCleanup() {
    if (this.configService.get('app.environment') === 'production') {
      throw new Error(
        'Manual trigger not allowed in production. Use scheduled jobs.',
      );
    }

    this.logger.info('Manual trigger: Old chats cleanup', {
      environment: this.configService.get('app.environment'),
    });

    await this.cleanupOldChats();
  }
}
