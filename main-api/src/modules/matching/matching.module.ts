import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { MatchingController } from './matching.controller';
import { MatchingService } from './matching.service';
import { MatchingIntegrationService } from './matching-integration.service';
import { MatchingScheduler } from './matching.scheduler';
import { QuotaGuard } from './guards/quota.guard';
import { PremiumGuard } from '../auth/guards/premium.guard';
import { ChatModule } from '../chat/chat.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ProfilesModule } from '../profiles/profiles.module';

import { User } from '../../database/entities/user.entity';
import { Profile } from '../../database/entities/profile.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';
import { Match } from '../../database/entities/match.entity';
import { PersonalityAnswer } from '../../database/entities/personality-answer.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { UserChoice } from '../../database/entities/user-choice.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Profile,
      DailySelection,
      Match,
      PersonalityAnswer,
      Subscription,
      UserChoice,
    ]),
    forwardRef(() => ChatModule),
    forwardRef(() => NotificationsModule),
    ProfilesModule,
  ],
  providers: [
    MatchingService,
    MatchingIntegrationService,
    MatchingScheduler,
    QuotaGuard,
    PremiumGuard,
  ],
  controllers: [MatchingController],
  exports: [MatchingService, MatchingIntegrationService, MatchingScheduler],
})
export class MatchingModule {}
