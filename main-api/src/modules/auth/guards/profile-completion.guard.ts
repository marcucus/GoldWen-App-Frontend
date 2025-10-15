import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../../database/entities/user.entity';

export const SKIP_PROFILE_COMPLETION = 'skipProfileCompletion';

@Injectable()
export class ProfileCompletionGuard implements CanActivate {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Check if the route should skip profile completion check
    const skipCompletion = this.reflector.getAllAndOverride<boolean>(
      SKIP_PROFILE_COMPLETION,
      [context.getHandler(), context.getClass()],
    );

    if (skipCompletion) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      return false;
    }

    // Get fresh user data to check completion status
    const userEntity = await this.userRepository.findOne({
      where: { id: user.id },
      select: ['isProfileCompleted'],
    });

    if (!userEntity?.isProfileCompleted) {
      throw new ForbiddenException({
        message: 'Profile must be completed before accessing this feature',
        code: 'PROFILE_INCOMPLETE',
        nextStep: '/profile/completion',
      });
    }

    return true;
  }
}
