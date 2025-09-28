import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '../../../common/enums';
import { User } from '../../../database/entities/user.entity';

export const ROLES_KEY = 'roles';
export const Roles =
  (roles: UserRole[]) =>
  (target: any, propertyKey: string, descriptor: PropertyDescriptor) => {
    Reflect.defineMetadata(ROLES_KEY, roles, descriptor.value);
  };

@Injectable()
export class RoleGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user: User = request.user;

    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    if (!user.role) {
      throw new ForbiddenException('User role not defined');
    }

    // Check if user has any of the required roles
    const hasPermission = requiredRoles.includes(user.role);

    // Admin users can access moderator-only endpoints
    if (
      !hasPermission &&
      user.role === UserRole.ADMIN &&
      requiredRoles.includes(UserRole.MODERATOR)
    ) {
      return true;
    }

    if (!hasPermission) {
      throw new ForbiddenException(
        `Access denied. Required roles: ${requiredRoles.join(', ')}`,
      );
    }

    return true;
  }
}
