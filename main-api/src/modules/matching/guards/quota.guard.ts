import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DailySelection } from '../../../database/entities/daily-selection.entity';
import { Subscription } from '../../../database/entities/subscription.entity';
import { SubscriptionPlan, SubscriptionStatus } from '../../../common/enums';
import { CustomLoggerService } from '../../../common/logger';

@Injectable()
export class QuotaGuard implements CanActivate {
  constructor(
    @InjectRepository(DailySelection)
    private dailySelectionRepository: Repository<DailySelection>,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    private logger: CustomLoggerService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId = request.user?.id;

    if (!userId) {
      throw new ForbiddenException('User not authenticated');
    }

    // Get today's date at midnight
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Get or create today's daily selection
    const dailySelection = await this.dailySelectionRepository.findOne({
      where: {
        userId,
        selectionDate: today,
      },
    });

    if (!dailySelection) {
      // No daily selection for today - user hasn't generated their selection yet
      throw new ForbiddenException(
        "Vous devez d'abord consulter votre sélection quotidienne",
      );
    }

    // Check if user has exceeded their daily quota
    if (dailySelection.choicesUsed >= dailySelection.maxChoicesAllowed) {
      const maxChoices = dailySelection.maxChoicesAllowed;
      const isPremium = maxChoices > 1;

      // Calculate reset time (next day at noon Paris time)
      const resetTime = new Date();
      resetTime.setDate(resetTime.getDate() + 1);
      resetTime.setHours(12, 0, 0, 0);

      this.logger.logBusinessEvent('daily_quota_exceeded', {
        userId,
        choicesUsed: dailySelection.choicesUsed,
        maxChoices: dailySelection.maxChoicesAllowed,
        resetTime: resetTime.toISOString(),
      });

      if (isPremium) {
        throw new ForbiddenException(
          `Vous avez utilisé vos ${maxChoices} choix quotidiens. Revenez demain pour de nouveaux profils !`,
        );
      } else {
        throw new ForbiddenException(
          'Votre choix quotidien a été utilisé. Passez à GoldWen Plus pour 3 choix par jour ou revenez demain !',
        );
      }
    }

    // Attach quota info to request for use in controllers/services
    request.quotaInfo = {
      choicesUsed: dailySelection.choicesUsed,
      maxChoices: dailySelection.maxChoicesAllowed,
      choicesRemaining:
        dailySelection.maxChoicesAllowed - dailySelection.choicesUsed,
    };

    return true;
  }
}
