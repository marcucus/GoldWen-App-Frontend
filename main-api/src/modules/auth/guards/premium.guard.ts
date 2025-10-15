import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription } from '../../../database/entities/subscription.entity';
import { SubscriptionStatus, SubscriptionPlan } from '../../../common/enums';

@Injectable()
export class PremiumGuard implements CanActivate {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId = request.user?.id;

    if (!userId) {
      throw new ForbiddenException('User not authenticated');
    }

    const activeSubscription = await this.subscriptionRepository.findOne({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
      },
    });

    const isPremium =
      activeSubscription?.isActive &&
      activeSubscription.plan === SubscriptionPlan.GOLDWEN_PLUS;

    if (!isPremium) {
      throw new ForbiddenException(
        'Cette fonctionnalité est réservée aux abonnés GoldWen Plus',
      );
    }

    return true;
  }
}
