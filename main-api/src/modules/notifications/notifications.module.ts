import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { FcmService } from './fcm.service';
import { ScheduledNotificationsService } from './scheduled-notifications.service';
import { Notification } from '../../database/entities/notification.entity';
import { NotificationPreferences } from '../../database/entities/notification-preferences.entity';
import { User } from '../../database/entities/user.entity';
import { PushToken } from '../../database/entities/push-token.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { Chat } from '../../database/entities/chat.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Notification,
      NotificationPreferences,
      User,
      PushToken,
      DailySelection,
      Chat,
    ]),
  ],
  providers: [NotificationsService, FcmService, ScheduledNotificationsService],
  controllers: [NotificationsController],
  exports: [NotificationsService, FcmService],
})
export class NotificationsModule {}
