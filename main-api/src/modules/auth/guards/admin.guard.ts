import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    // Check if user has admin role
    // This assumes the JWT token contains role information
    // In a more sophisticated setup, you might query the database
    if (user.role !== 'admin' && !user.isAdmin) {
      throw new ForbiddenException('Admin access required');
    }

    return true;
  }
}
