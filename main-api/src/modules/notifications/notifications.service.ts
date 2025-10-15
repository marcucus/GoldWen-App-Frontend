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
import { PushToken } from '../../database/entities/push-token.entity';
import { NotificationType } from '../../common/enums';
import { CustomLoggerService } from '../../common/logger';
import { FcmService } from './fcm.service';
import { FirebaseService } from './firebase.service';

import {
  GetNotificationsDto,
  CreateNotificationDto,
  UpdateNotificationSettingsDto,
  TestNotificationDto,
  SendGroupNotificationDto,
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
    @InjectRepository(PushToken)
    private pushTokenRepository: Repository<PushToken>,
    private configService: ConfigService,
    private logger: CustomLoggerService,
    private fcmService: FcmService,
    private firebaseService: FirebaseService,
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

    this.logger.logUserAction('get_notifications', {
      userId,
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

    this.logger.logUserAction('mark_notification_read', {
      userId,
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

    this.logger.logUserAction('mark_all_notifications_read', {
      userId,
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

    this.logger.logUserAction('delete_notification', {
      userId,
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

    // Check user notification preferences before creating notification
    const shouldCreateNotification = await this.shouldSendNotification(
      userId,
      type,
    );
    if (!shouldCreateNotification) {
      this.logger.logBusinessEvent('notification_skipped_preferences', {
        userId,
        type,
        reason: 'user_preferences',
      });
      throw new ForbiddenException(
        'Notification creation skipped due to user preferences',
      );
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

    this.logger.logUserAction('send_test_notification', {
      userId,
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

    this.logger.logUserAction('update_notification_settings', {
      userId,
      ...updateSettingsDto,
    });

    return {
      message: 'Notification settings updated successfully',
      settings: updateSettingsDto,
    };
  }

  /**
   * Get notification settings for a user
   */
  async getNotificationSettings(userId: string): Promise<{
    dailySelection: boolean;
    newMatches: boolean;
    newMessages: boolean;
    chatExpiring: boolean;
    subscriptionUpdates: boolean;
    pushNotifications: boolean;
    emailNotifications: boolean;
    marketingEmails: boolean;
  }> {
    // Verify user exists
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Find notification preferences, or return defaults
    let preferences = await this.notificationPreferencesRepository.findOne({
      where: { userId },
    });

    if (!preferences) {
      // Create default preferences for new users
      preferences = this.notificationPreferencesRepository.create({
        userId,
        dailySelection: true,
        newMatches: true,
        newMessages: true,
        chatExpiring: true,
        subscriptionUpdates: true,
        pushNotifications: true,
        emailNotifications: true,
        marketingEmails: false,
      });
      await this.notificationPreferencesRepository.save(preferences);
    }

    this.logger.logUserAction('get_notification_settings', { userId });

    return {
      dailySelection: preferences.dailySelection,
      newMatches: preferences.newMatches,
      newMessages: preferences.newMessages,
      chatExpiring: preferences.chatExpiring,
      subscriptionUpdates: preferences.subscriptionUpdates,
      pushNotifications: preferences.pushNotifications,
      emailNotifications: preferences.emailNotifications,
      marketingEmails: preferences.marketingEmails,
    };
  }

  /**
   * Check if a notification should be sent based on user preferences
   */
  private async shouldSendNotification(
    userId: string,
    type: NotificationType,
  ): Promise<boolean> {
    // Get user's notification preferences
    const preferences = await this.notificationPreferencesRepository.findOne({
      where: { userId },
    });

    // If no preferences exist, use defaults (allow all notifications)
    if (!preferences) {
      return true;
    }

    // Check specific preference based on notification type
    switch (type) {
      case NotificationType.DAILY_SELECTION:
        return preferences.dailySelection && preferences.pushNotifications;
      case NotificationType.NEW_MATCH:
        return preferences.newMatches && preferences.pushNotifications;
      case NotificationType.NEW_MESSAGE:
        return preferences.newMessages && preferences.pushNotifications;
      case NotificationType.CHAT_EXPIRING:
        return preferences.chatExpiring && preferences.pushNotifications;
      case NotificationType.SUBSCRIPTION_EXPIRED:
      case NotificationType.SUBSCRIPTION_RENEWED:
        return preferences.subscriptionUpdates && preferences.pushNotifications;
      case NotificationType.SYSTEM:
        // System notifications are always sent (important updates)
        return true;
      default:
        // Default to checking general push notification preference
        return preferences.pushNotifications;
    }
  }

  /**
   * Check if email notifications should be sent based on user preferences
   * Public method for external services to use
   */
  async shouldSendEmailNotification(
    userId: string,
    type: NotificationType,
  ): Promise<boolean> {
    const preferences = await this.notificationPreferencesRepository.findOne({
      where: { userId },
    });

    if (!preferences) {
      return true; // Default to allowing email notifications
    }

    // Check if email notifications are enabled and specific type is enabled
    if (!preferences.emailNotifications) {
      return false;
    }

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
      case NotificationType.SYSTEM:
        return true; // System emails are always sent
      default:
        return preferences.emailNotifications;
    }
  }

  /**
   * Check marketing email preferences - public method for marketing services
   */
  async shouldSendMarketingEmail(userId: string): Promise<boolean> {
    const preferences = await this.notificationPreferencesRepository.findOne({
      where: { userId },
    });

    return preferences?.marketingEmails ?? false; // Default to false for marketing
  }

  // Helper method to send actual push notifications
  private async sendPushNotification(
    notification: Notification,
  ): Promise<void> {
    try {
      // Get user and their push tokens
      const user = await this.userRepository.findOne({
        where: { id: notification.userId },
        select: ['id', 'notificationsEnabled'],
        relations: ['notificationPreferences'],
      });

      if (!user || !user.notificationsEnabled) {
        this.logger.info(
          'Push notification skipped - user preferences unavailable',
          {
            notificationId: notification.id,
            userId: notification.userId,
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

      // Get active push tokens for the user
      const pushTokens = await this.pushTokenRepository.find({
        where: { userId: notification.userId, isActive: true },
      });

      if (!pushTokens || pushTokens.length === 0) {
        this.logger.info('Push notification skipped - no active push tokens', {
          notificationId: notification.id,
          userId: notification.userId,
        });
        return;
      }

      // Send to all active push tokens
      const sendPromises = pushTokens.map(async (pushToken) => {
        try {
          const payload = {
            title: notification.title,
            body: notification.body,
            data: {
              notificationId: notification.id,
              type: notification.type,
              ...notification.data,
            },
          };

          const result = await this.fcmService.sendToDevice(
            pushToken.token,
            payload,
          );

          if (!result.success) {
            this.logger.warn(
              `Failed to send to push token ${pushToken.id}: ${result.error}`,
              'NotificationsService',
            );

            // Deactivate invalid tokens using Firebase error codes
            if (
              result.errorCode &&
              this.firebaseService.isInvalidTokenError(result.errorCode)
            ) {
              this.logger.info(
                `Deactivating invalid token ${pushToken.id} - Error: ${result.errorCode}`,
                'NotificationsService',
              );
              await this.pushTokenRepository.update(pushToken.id, {
                isActive: false,
              });
            } else if (
              result.error?.includes('InvalidRegistration') ||
              result.error?.includes('NotRegistered')
            ) {
              // Fallback for legacy HTTP API errors
              this.logger.info(
                `Deactivating invalid token ${pushToken.id} - Legacy error`,
                'NotificationsService',
              );
              await this.pushTokenRepository.update(pushToken.id, {
                isActive: false,
              });
            }
          } else {
            // Update last used time for successful sends
            await this.pushTokenRepository.update(pushToken.id, {
              lastUsedAt: new Date(),
            });
          }

          return result;
        } catch (error) {
          this.logger.error(
            `Error sending to push token ${pushToken.id}: ${error.message}`,
            'NotificationsService',
          );
          return { success: false, error: error.message };
        }
      });

      const results = await Promise.all(sendPromises);
      const successCount = results.filter((r) => r.success).length;

      this.logger.info('Push notification batch completed', {
        notificationId: notification.id,
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        totalTokens: pushTokens.length,
        successCount,
      });

      // Update notification as sent if at least one succeeded
      if (successCount > 0) {
        await this.notificationRepository.update(notification.id, {
          isSent: true,
          sentAt: new Date(),
        });
      }
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

  async sendChatAcceptedNotification(
    userId: string,
    accepterName: string,
  ): Promise<Notification> {
    return this.createNotification({
      userId,
      type: NotificationType.NEW_MATCH, // Using NEW_MATCH type for now, could create a specific type
      title: 'Votre demande de chat a été acceptée !',
      body: `${accepterName} a accepté votre demande de chat. Vous pouvez maintenant discuter !`,
      data: { action: 'open_chat', accepterName },
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

  async sendGroupNotification(
    sendGroupNotificationDto: SendGroupNotificationDto,
  ): Promise<Notification[]> {
    const { userIds, type, title, body, data } = sendGroupNotificationDto;

    const notifications = await Promise.all(
      userIds.map((userId) =>
        this.createNotification({
          userId,
          type,
          title,
          body,
          data,
        }),
      ),
    );

    this.logger.info('Group notification sent', {
      type,
      title,
      userCount: userIds.length,
      notificationIds: notifications.map((n) => n.id),
    });

    return notifications;
  }

  /**
   * Register a new push token for a user
   */
  async registerPushToken(
    userId: string,
    token: string,
    platform: string,
    appVersion?: string,
    deviceId?: string,
  ): Promise<PushToken> {
    // Check if token already exists
    const existingToken = await this.pushTokenRepository.findOne({
      where: { token },
    });

    if (existingToken) {
      // Update existing token
      existingToken.userId = userId;
      existingToken.platform = platform as any;
      existingToken.appVersion = appVersion;
      existingToken.deviceId = deviceId;
      existingToken.isActive = true;
      existingToken.lastUsedAt = new Date();

      const updated = await this.pushTokenRepository.save(existingToken);

      this.logger.logUserAction('update_push_token', {
        userId,
        tokenId: updated.id,
        platform,
      });

      return updated;
    }

    // Create new token
    const pushToken = this.pushTokenRepository.create({
      userId,
      token,
      platform: platform as any,
      appVersion,
      deviceId,
      isActive: true,
      lastUsedAt: new Date(),
    });

    const saved = await this.pushTokenRepository.save(pushToken);

    this.logger.logUserAction('register_push_token', {
      userId,
      tokenId: saved.id,
      platform,
    });

    return saved;
  }

  /**
   * Delete a push token
   */
  async deletePushToken(userId: string, token: string): Promise<void> {
    const pushToken = await this.pushTokenRepository.findOne({
      where: { token, userId },
    });

    if (!pushToken) {
      throw new NotFoundException('Push token not found');
    }

    await this.pushTokenRepository.delete(pushToken.id);

    this.logger.logUserAction('delete_push_token', {
      userId,
      tokenId: pushToken.id,
    });
  }

  /**
   * Get all push tokens for a user
   */
  async getUserPushTokens(userId: string): Promise<PushToken[]> {
    return this.pushTokenRepository.find({
      where: { userId, isActive: true },
      order: { lastUsedAt: 'DESC' },
    });
  }

  /**
   * Deactivate inactive push tokens (older than 90 days)
   */
  async deactivateInactivePushTokens(): Promise<number> {
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    const result = await this.pushTokenRepository
      .createQueryBuilder()
      .update(PushToken)
      .set({ isActive: false })
      .where('isActive = :isActive', { isActive: true })
      .andWhere('lastUsedAt < :date', { date: ninetyDaysAgo })
      .execute();

    const affected = result.affected || 0;

    this.logger.info('Deactivated inactive push tokens', {
      affected,
      threshold: '90 days',
    });

    return affected;
  }
}
