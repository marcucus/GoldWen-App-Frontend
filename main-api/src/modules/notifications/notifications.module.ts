import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { FcmService } from './fcm.service';
import { Notification } from '../../database/entities/notification.entity';
import { NotificationPreferences } from '../../database/entities/notification-preferences.entity';
import { User } from '../../database/entities/user.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Notification, NotificationPreferences, User]),
  ],
  providers: [NotificationsService, FcmService],
  controllers: [NotificationsController],
  exports: [NotificationsService, FcmService],
})
export class NotificationsModule {}
