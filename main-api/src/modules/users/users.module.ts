import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { UserGdprController } from './user-gdpr.controller';
import { ProfilesModule } from '../profiles/profiles.module';
import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { Match } from '../../database/entities/match.entity';
import { Message } from '../../database/entities/message.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { PromptAnswer } from '../../database/entities/prompt-answer.entity';
import { Prompt } from '../../database/entities/prompt.entity';
import { PushToken } from '../../database/entities/push-token.entity';
import { UserConsent } from '../../database/entities/user-consent.entity';
import { Notification } from '../../database/entities/notification.entity';
import { Report } from '../../database/entities/report.entity';
import { GdprService } from './gdpr.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Profile,
      Match,
      Message,
      Subscription,
      DailySelection,
      PromptAnswer,
      Prompt,
      PushToken,
      UserConsent,
      Notification,
      Report,
    ]),
    ProfilesModule,
  ],
  providers: [UsersService, GdprService],
  controllers: [UsersController, UserGdprController],
  exports: [UsersService],
})
export class UsersModule {}
