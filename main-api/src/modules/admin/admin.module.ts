import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { MonitoringController } from './monitoring.controller';
import { MonitoringService } from './monitoring.service';
import { NotificationsModule } from '../notifications/notifications.module';

import { Admin } from '../../database/entities/admin.entity';
import { User } from '../../database/entities/user.entity';
import { Report } from '../../database/entities/report.entity';
import { Match } from '../../database/entities/match.entity';
import { Chat } from '../../database/entities/chat.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { SupportTicket } from '../../database/entities/support-ticket.entity';
import { Prompt } from '../../database/entities/prompt.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Admin,
      User,
      Report,
      Match,
      Chat,
      Subscription,
      SupportTicket,
      Prompt,
    ]),
    forwardRef(() => NotificationsModule),
  ],
  providers: [AdminService, MonitoringService],
  controllers: [AdminController, MonitoringController],
  exports: [AdminService],
})
export class AdminModule {}
