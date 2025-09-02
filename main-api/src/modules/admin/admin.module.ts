import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { NotificationsModule } from '../notifications/notifications.module';

import { Admin } from '../../database/entities/admin.entity';
import { User } from '../../database/entities/user.entity';
import { Report } from '../../database/entities/report.entity';
import { Match } from '../../database/entities/match.entity';
import { Chat } from '../../database/entities/chat.entity';
import { Subscription } from '../../database/entities/subscription.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Admin, User, Report, Match, Chat, Subscription]),
    forwardRef(() => NotificationsModule),
  ],
  providers: [AdminService],
  controllers: [AdminController],
  exports: [AdminService],
})
export class AdminModule {}
