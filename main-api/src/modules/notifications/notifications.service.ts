import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';

import { Notification } from '../../database/entities/notification.entity';
import { User } from '../../database/entities/user.entity';
import { NotificationPreferences } from '../../database/entities/notification-preferences.entity';
import { NotificationType } from '../../common/enums';
import { CustomLoggerService } from '../../common/logger';

import {
  GetNotificationsDto,
  CreateNotificationDto,
  UpdateNotificationSettingsDto,
  TestNotificationDto,
} from './dto/notifications.dto';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private notificationRepository: Repository<Notification>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(NotificationPreferences)
    private notificationPreferencesRepository: Repository<NotificationPreferences>,
    private configService: ConfigService,
    private logger: CustomLoggerService,
  ) {}

  async getNotifications(
    userId: string,
    getNotificationsDto: GetNotificationsDto,
  ): Promise<{
    notifications: Notification[];
    total: number;
    page: number;
    limit: number;
    unreadCount: number;
  }> {
    const { page = 1, limit = 20, type, read } = getNotificationsDto;
    const skip = (page - 1) * limit;

    const whereCondition: any = { userId };

    if (type) {
      whereCondition.type = type;
    }

    if (typeof read === 'boolean') {
      whereCondition.isRead = read;
    }

    const [notifications, total] =
      await this.notificationRepository.findAndCount({
        where: whereCondition,
        order: { createdAt: 'DESC' },
        skip,
        take: limit,
      });

    // Get unread count
    const unreadCount = await this.notificationRepository.count({
      where: { userId, isRead: false },
    });

    this.logger.logUserAction('get_notifications', userId, {
      total,
      page,
      limit,
      unreadCount,
      filters: { type, read },
    });

    return { notifications, total, page, limit, unreadCount };
  }

  async markAsRead(
    notificationId: string,
    userId: string,
  ): Promise<Notification> {
    const notification = await this.notificationRepository.findOne({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    if (notification.isRead) {
      return notification; // Already read
    }

    notification.isRead = true;
    notification.readAt = new Date();

    const updatedNotification =
      await this.notificationRepository.save(notification);

    this.logger.logUserAction('mark_notification_read', userId, {
      notificationId,
      type: notification.type,
    });

    return updatedNotification;
  }

  async markAllAsRead(userId: string): Promise<{ affected: number }> {
    const result = await this.notificationRepository.update(
      { userId, isRead: false },
      { isRead: true, readAt: new Date() },
    );

    this.logger.logUserAction('mark_all_notifications_read', userId, {
      affected: result.affected,
    });

    return { affected: result.affected || 0 };
  }

  async deleteNotification(
    notificationId: string,
    userId: string,
  ): Promise<void> {
    const notification = await this.notificationRepository.findOne({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    await this.notificationRepository.delete(notificationId);

    this.logger.logUserAction('delete_notification', userId, {
      notificationId,
      type: notification.type,
    });
  }

  async createNotification(
    createNotificationDto: CreateNotificationDto,
  ): Promise<Notification> {
    const { userId, type, title, body, data, scheduledFor } =
      createNotificationDto;

    // Verify user exists
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const notification = this.notificationRepository.create({
      userId,
      type,
      title,
      body,
      data,
      scheduledFor,
      isSent: !scheduledFor, // If not scheduled, mark as sent immediately
      sentAt: scheduledFor ? undefined : new Date(),
    });

    const savedNotification =
      await this.notificationRepository.save(notification);

    this.logger.logBusinessEvent('notification_created', {
      notificationId: savedNotification.id,
      userId,
      type,
      scheduled: !!scheduledFor,
    });

    // TODO: Integrate with actual push notification service (FCM, etc.)
    if (!scheduledFor) {
      await this.sendPushNotification(savedNotification);
    }

    return savedNotification;
  }

  async sendTestNotification(
    userId: string,
    testNotificationDto: TestNotificationDto,
  ): Promise<Notification> {
    // Only allow in development
    if (this.configService.get('app.environment') === 'production') {
      throw new ForbiddenException(
        'Test notifications are only available in development',
      );
    }

    const { title, body, type } = testNotificationDto;

    const notification = await this.createNotification({
      userId,
      type: type || NotificationType.DAILY_SELECTION,
      title: title || 'Test Notification',
      body: body || 'This is a test notification from GoldWen API',
      data: { test: true, timestamp: new Date().toISOString() },
    });

    this.logger.logUserAction('send_test_notification', userId, {
      notificationId: notification.id,
      type: notification.type,
    });

    return notification;
  }

  async updateNotificationSettings(
    userId: string,
    updateSettingsDto: UpdateNotificationSettingsDto,
  ): Promise<{ message: string; settings: UpdateNotificationSettingsDto }> {
    // Verify user exists
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Find or create notification preferences
    let preferences = await this.notificationPreferencesRepository.findOne({
      where: { userId },
    });

    if (!preferences) {
      preferences = this.notificationPreferencesRepository.create({
        userId,
        ...updateSettingsDto,
      });
    } else {
      // Update existing preferences
      Object.assign(preferences, updateSettingsDto);
    }

    await this.notificationPreferencesRepository.save(preferences);

    this.logger.logUserAction(
      'update_notification_settings',
      userId,
      updateSettingsDto,
    );

    return {
      message: 'Notification settings updated successfully',
      settings: updateSettingsDto,
    };
  }

  // Helper method to send actual push notifications
  private async sendPushNotification(
    notification: Notification,
  ): Promise<void> {
    try {
      // Get user's FCM token and notification preferences
      const user = await this.userRepository.findOne({
        where: { id: notification.userId },
        select: ['id', 'fcmToken', 'notificationsEnabled'],
        relations: ['notificationPreferences'],
      });

      if (!user || !user.notificationsEnabled || !user.fcmToken) {
        this.logger.info(
          'Push notification skipped - user preferences or token unavailable',
          {
            notificationId: notification.id,
            userId: notification.userId,
            hasToken: !!user?.fcmToken,
            notificationsEnabled: user?.notificationsEnabled,
          },
        );
        return;
      }

      // Check specific notification type preferences
      const preferences = user.notificationPreferences;
      if (preferences && !preferences.pushNotifications) {
        this.logger.info(
          'Push notification skipped - user disabled push notifications',
          {
            notificationId: notification.id,
            userId: notification.userId,
            type: notification.type,
          },
        );
        return;
      }

      // Check type-specific preferences
      const typeAllowed = this.checkNotificationTypeAllowed(
        notification.type,
        preferences,
      );
      if (!typeAllowed) {
        this.logger.info(
          'Push notification skipped - notification type disabled',
          {
            notificationId: notification.id,
            userId: notification.userId,
            type: notification.type,
          },
        );
        return;
      }

      const fcmServerKey = this.configService.get('notification.fcmServerKey');

      if (!fcmServerKey) {
        this.logger.warn(
          'FCM server key not configured, skipping push notification',
        );
        return;
      }

      // Prepare FCM payload
      const fcmPayload = {
        to: user.fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
          icon: 'ic_notification',
          sound: 'default',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        data: {
          notificationId: notification.id,
          type: notification.type,
          ...notification.data,
        },
      };

      // Send FCM request
      const response = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          Authorization: `key=${fcmServerKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      });

      if (!response.ok) {
        throw new Error(
          `FCM request failed: ${response.status} ${response.statusText}`,
        );
      }

      const result = await response.json();

      if (result.failure > 0) {
        this.logger.warn(
          'FCM notification partially failed',
          JSON.stringify({
            notificationId: notification.id,
            userId: notification.userId,
            success: result.success,
            failure: result.failure,
            results: result.results,
          }),
        );
      } else {
        this.logger.info('Push notification sent successfully', {
          notificationId: notification.id,
          userId: notification.userId,
          type: notification.type,
          title: notification.title,
        });
      }

      // Update notification as sent
      await this.notificationRepository.update(notification.id, {
        isSent: true,
        sentAt: new Date(),
      });
    } catch (error) {
      this.logger.error(
        'Failed to send push notification',
        error.stack,
        'NotificationsService',
      );

      // Implement simple retry logic
      if (notification.retryCount < 3) {
        setTimeout(
          async () => {
            try {
              await this.notificationRepository.update(notification.id, {
                retryCount: (notification.retryCount || 0) + 1,
              });

              const retryNotification =
                await this.notificationRepository.findOne({
                  where: { id: notification.id },
                });

              if (retryNotification) {
                await this.sendPushNotification(retryNotification);
              }
            } catch (retryError) {
              this.logger.error(
                'Retry push notification failed',
                retryError.stack,
                'NotificationsService',
              );
            }
          },
          Math.pow(2, notification.retryCount || 0) * 1000,
        ); // Exponential backoff
      }
    }
  }

  private checkNotificationTypeAllowed(
    type: NotificationType,
    preferences?: NotificationPreferences,
  ): boolean {
    if (!preferences) return true; // Default to allow if no preferences set

    switch (type) {
      case NotificationType.DAILY_SELECTION:
        return preferences.dailySelection;
      case NotificationType.NEW_MATCH:
        return preferences.newMatches;
      case NotificationType.NEW_MESSAGE:
        return preferences.newMessages;
      case NotificationType.CHAT_EXPIRING:
        return preferences.chatExpiring;
      case NotificationType.SUBSCRIPTION_EXPIRED:
      case NotificationType.SUBSCRIPTION_RENEWED:
        return preferences.subscriptionUpdates;
      default:
        return true; // Allow unknown types by default
    }
  }

  // Business logic methods for creating specific types of notifications

  async sendDailySelectionNotification(userId: string): Promise<Notification> {
    return this.createNotification({
      userId,
      type: NotificationType.DAILY_SELECTION,
      title: 'Votre sélection GoldWen du jour est arrivée !',
      body: 'Découvrez vos nouvelles suggestions de profils compatibles.',
      data: { action: 'view_daily_selection' },
    });
  }

  async sendNewMatchNotification(
    userId: string,
    matchedUserName: string,
  ): Promise<Notification> {
    return this.createNotification({
      userId,
      type: NotificationType.NEW_MATCH,
      title: 'Félicitations ! Vous avez un match !',
      body: `Vous avez un match avec ${matchedUserName}. Commencez à discuter !`,
      data: { action: 'open_chat', matchedUserName },
    });
  }

  async sendNewMessageNotification(
    userId: string,
    senderName: string,
  ): Promise<Notification> {
    return this.createNotification({
      userId,
      type: NotificationType.NEW_MESSAGE,
      title: 'Nouveau message',
      body: `${senderName} vous a envoyé un message.`,
      data: { action: 'open_chat', senderName },
    });
  }

  async sendChatExpiringNotification(
    userId: string,
    partnerName: string,
    hoursLeft: number,
  ): Promise<Notification> {
    return this.createNotification({
      userId,
      type: NotificationType.CHAT_EXPIRING,
      title: 'Votre conversation expire bientôt !',
      body: `Il vous reste ${hoursLeft}h pour discuter avec ${partnerName}.`,
      data: { action: 'open_chat', partnerName, hoursLeft },
    });
  }

  async sendSubscriptionExpiredNotification(
    userId: string,
  ): Promise<Notification> {
    return this.createNotification({
      userId,
      type: NotificationType.SUBSCRIPTION_EXPIRED,
      title: 'Votre abonnement GoldWen Plus a expiré',
      body: 'Renouvelez votre abonnement pour continuer à profiter des fonctionnalités premium.',
      data: { action: 'renew_subscription' },
    });
  }
}
