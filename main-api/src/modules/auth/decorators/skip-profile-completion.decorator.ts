import { SetMetadata } from '@nestjs/common';
import { SKIP_PROFILE_COMPLETION } from '../guards/profile-completion.guard';

/**
 * Decorator to skip profile completion validation for specific routes
 * Use this for routes that should be accessible even with incomplete profiles
 * (e.g., profile completion endpoints, logout, etc.)
 */
export const SkipProfileCompletion = () =>
  SetMetadata(SKIP_PROFILE_COMPLETION, true);
