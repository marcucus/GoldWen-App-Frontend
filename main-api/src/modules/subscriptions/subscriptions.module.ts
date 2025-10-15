import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { SubscriptionsController } from './subscriptions.controller';
import { SubscriptionsService } from './subscriptions.service';
import { RevenueCatController } from './revenuecat.controller';
import { RevenueCatService } from './revenuecat.service';

import { Subscription } from '../../database/entities/subscription.entity';
import { User } from '../../database/entities/user.entity';
import { DailySelection } from '../../database/entities/daily-selection.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Subscription, User, DailySelection])],
  providers: [SubscriptionsService, RevenueCatService],
  controllers: [SubscriptionsController, RevenueCatController],
  exports: [SubscriptionsService, RevenueCatService],
})
export class SubscriptionsModule {}
