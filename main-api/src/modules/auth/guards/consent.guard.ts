import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserConsent } from '../../../database/entities/user-consent.entity';

export const SKIP_CONSENT_CHECK = 'skipConsentCheck';

/**
 * ConsentGuard - RGPD Compliance Guard
 * Blocks access to protected routes if user has not provided valid consent
 * This ensures compliance with GDPR Article 7 (Conditions for consent)
 */
@Injectable()
export class ConsentGuard implements CanActivate {
  constructor(
    @InjectRepository(UserConsent)
    private userConsentRepository: Repository<UserConsent>,
    private reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Check if the route should skip consent check
    const skipConsent = this.reflector.getAllAndOverride<boolean>(
      SKIP_CONSENT_CHECK,
      [context.getHandler(), context.getClass()],
    );

    if (skipConsent) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      return false;
    }

    // Check if user has valid active consent
    const consent = await this.userConsentRepository.findOne({
      where: { userId: user.id, isActive: true },
      order: { createdAt: 'DESC' },
    });

    if (!consent || !consent.dataProcessing) {
      throw new ForbiddenException({
        message:
          'Valid consent required. You must accept the privacy policy and data processing terms to use this feature.',
        code: 'CONSENT_REQUIRED',
        nextStep: '/consent',
        details: {
          hasConsent: !!consent,
          dataProcessingConsent: consent?.dataProcessing || false,
        },
      });
    }

    return true;
  }
}
