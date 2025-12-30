import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '../../shared/types';
import { ROLES_KEY } from '../decorators/roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }
    
    const { user } = context.switchToHttp().getRequest();
    
    if (!user || !user.roles || !Array.isArray(user.roles)) {
      throw new ForbiddenException('User roles not found');
    }
    
    // Convert user roles to strings for comparison (handle both enum values and strings)
    const userRoles = user.roles.map((role: any) => 
      typeof role === 'string' ? role.toUpperCase() : String(role).toUpperCase()
    );
    
    // Convert required roles to strings for comparison
    const requiredRolesStrings = requiredRoles.map(role => 
      typeof role === 'string' ? role.toUpperCase() : String(role).toUpperCase()
    );
    
    const hasRequiredRole = requiredRolesStrings.some((requiredRole) => 
      userRoles.includes(requiredRole)
    );
    
    if (!hasRequiredRole) {
      throw new ForbiddenException('Forbidden resource');
    }
    
    return true;
  }
}

