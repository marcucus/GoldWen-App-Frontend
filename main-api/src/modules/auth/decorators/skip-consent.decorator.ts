import { SetMetadata } from '@nestjs/common';
import { SKIP_CONSENT_CHECK } from '../guards/consent.guard';

/**
 * Decorator to skip consent check for specific routes
 * Use this on routes that should be accessible without consent
 * (e.g., consent recording endpoint, privacy policy, authentication routes)
 */
export const SkipConsentCheck = () => SetMetadata(SKIP_CONSENT_CHECK, true);
