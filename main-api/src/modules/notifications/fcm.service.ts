import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CustomLoggerService } from '../../common/logger';

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, any>;
  imageUrl?: string;
}

export interface FcmResponse {
  success: boolean;
  messageId?: string;
  error?: string;
}

@Injectable()
export class FcmService {
  private readonly serverKey: string;
  private readonly fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  constructor(
    private readonly configService: ConfigService,
    private readonly logger: CustomLoggerService,
  ) {
    this.serverKey = this.configService.get('notification.fcmServerKey') || '';
  }

  async sendToDevice(
    deviceToken: string,
    payload: NotificationPayload,
  ): Promise<FcmResponse> {
    if (!this.serverKey) {
      this.logger.warn(
        'FCM server key not configured, skipping push notification',
      );
      return { success: false, error: 'FCM not configured' };
    }

    if (!deviceToken) {
      this.logger.warn('No device token provided for push notification');
      return { success: false, error: 'No device token' };
    }

    try {
      const message = {
        to: deviceToken,
        notification: {
          title: payload.title,
          body: payload.body,
          image: payload.imageUrl,
        },
        data: payload.data || {},
        android: {
          notification: {
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await fetch(this.fcmUrl, {
        method: 'POST',
        headers: {
          Authorization: `key=${this.serverKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
      });

      const result = await response.json();

      if (response.ok && result.success === 1) {
        this.logger.info('Push notification sent successfully', {
          messageId: result.results?.[0]?.message_id,
          deviceToken: deviceToken.substring(0, 10) + '...',
        });

        return {
          success: true,
          messageId: result.results?.[0]?.message_id,
        };
      } else {
        this.logger.error(
          'Failed to send push notification',
          result.results?.[0]?.error || 'Unknown error',
          'FcmService',
        );

        return {
          success: false,
          error: result.results?.[0]?.error || 'Unknown error',
        };
      }
    } catch (error) {
      this.logger.error(
        'Error sending push notification',
        error.message,
        'FcmService',
      );

      return {
        success: false,
        error: error.message,
      };
    }
  }

  async sendToMultipleDevices(
    deviceTokens: string[],
    payload: NotificationPayload,
  ): Promise<FcmResponse[]> {
    const results: FcmResponse[] = [];

    for (const token of deviceTokens) {
      const result = await this.sendToDevice(token, payload);
      results.push(result);
    }

    const successCount = results.filter((r) => r.success).length;

    this.logger.info('Batch push notifications sent', {
      total: deviceTokens.length,
      successful: successCount,
      failed: deviceTokens.length - successCount,
    });

    return results;
  }

  async sendToTopic(
    topic: string,
    payload: NotificationPayload,
  ): Promise<FcmResponse> {
    if (!this.serverKey) {
      this.logger.warn(
        'FCM server key not configured, skipping topic notification',
      );
      return { success: false, error: 'FCM not configured' };
    }

    try {
      const message = {
        to: `/topics/${topic}`,
        notification: {
          title: payload.title,
          body: payload.body,
          image: payload.imageUrl,
        },
        data: payload.data || {},
      };

      const response = await fetch(this.fcmUrl, {
        method: 'POST',
        headers: {
          Authorization: `key=${this.serverKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
      });

      const result = await response.json();

      if (response.ok && result.success >= 1) {
        this.logger.info('Topic notification sent successfully', {
          topic,
          messageId: result.message_id,
        });

        return {
          success: true,
          messageId: result.message_id,
        };
      } else {
        this.logger.error(
          'Failed to send topic notification',
          result.error || 'Unknown error',
          'FcmService',
        );

        return {
          success: false,
          error: result.error || 'Unknown error',
        };
      }
    } catch (error) {
      this.logger.error(
        'Error sending topic notification',
        error.message,
        'FcmService',
      );

      return {
        success: false,
        error: error.message,
      };
    }
  }

  // Helper methods for specific notification types
  async sendDailySelectionNotification(deviceToken: string) {
    return this.sendToDevice(deviceToken, {
      title: 'Votre sélection du jour est prête !',
      body: 'De nouveaux profils compatibles vous attendent',
      data: {
        type: 'daily_selection',
        action: 'open_daily_selection',
      },
    });
  }

  async sendNewMatchNotification(
    deviceToken: string,
    matchedUserName: string,
    conversationId: string,
    matchedUserId: string,
  ) {
    return this.sendToDevice(deviceToken, {
      title: 'Vous avez un match !',
      body: `${matchedUserName} a aussi flashé sur vous`,
      data: {
        type: 'new_match',
        conversationId,
        matchedUserId,
        action: 'open_chat',
      },
    });
  }

  async sendNewMessageNotification(
    deviceToken: string,
    senderName: string,
    messageContent: string,
    conversationId: string,
    senderId: string,
  ) {
    return this.sendToDevice(deviceToken, {
      title: `Nouveau message de ${senderName}`,
      body: messageContent,
      data: {
        type: 'new_message',
        conversationId,
        senderId,
        action: 'open_chat',
      },
    });
  }

  async sendChatExpiringNotification(
    deviceToken: string,
    otherUserName: string,
    conversationId: string,
    expiresAt: Date,
  ) {
    const hoursLeft = Math.ceil(
      (expiresAt.getTime() - Date.now()) / (1000 * 60 * 60),
    );

    return this.sendToDevice(deviceToken, {
      title: 'Votre conversation expire bientôt',
      body: `Plus que ${hoursLeft}h pour discuter avec ${otherUserName}`,
      data: {
        type: 'chat_expiring',
        conversationId,
        expiresAt: expiresAt.toISOString(),
        action: 'open_chat',
      },
    });
  }
}
