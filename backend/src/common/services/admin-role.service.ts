import { Injectable } from '@nestjs/common';
import { UserRole } from '../../shared/types';
import { User, UserDocument } from '../../users/schemas/user.schema';

// Type that accepts both User and UserDocument
type UserLike = User | UserDocument;

@Injectable()
export class AdminRoleService {
  /**
   * Check if user is Main Admin (ADMIN role)
   */
  isMainAdmin(userRoles: UserRole[]): boolean {
    return userRoles.includes(UserRole.ADMIN);
  }

  /**
   * Check if user is ICT Admin
   */
  isICTAdmin(userRoles: UserRole[]): boolean {
    return userRoles.includes(UserRole.ICT_ADMIN);
  }

  /**
   * Check if user is Store Admin
   */
  isStoreAdmin(userRoles: UserRole[]): boolean {
    return userRoles.includes(UserRole.STORE_ADMIN);
  }

  /**
   * Check if user is Transport Admin
   */
  isTransportAdmin(userRoles: UserRole[]): boolean {
    return userRoles.includes(UserRole.TRANSPORT_ADMIN);
  }

  /**
   * Check if user is any type of admin
   */
  isAnyAdmin(userRoles: UserRole[]): boolean {
    return (
      this.isMainAdmin(userRoles) ||
      this.isICTAdmin(userRoles) ||
      this.isStoreAdmin(userRoles) ||
      this.isTransportAdmin(userRoles)
    );
  }

  /**
   * Check if user can manage ICT (Main Admin or ICT Admin)
   */
  canManageICT(userRoles: UserRole[]): boolean {
    return this.isMainAdmin(userRoles) || this.isICTAdmin(userRoles);
  }

  /**
   * Check if user can manage Store (Main Admin or Store Admin)
   */
  canManageStore(userRoles: UserRole[]): boolean {
    return this.isMainAdmin(userRoles) || this.isStoreAdmin(userRoles);
  }

  /**
   * Check if user can manage Transport (Main Admin or Transport Admin)
   */
  canManageTransport(userRoles: UserRole[]): boolean {
    return this.isMainAdmin(userRoles) || this.isTransportAdmin(userRoles);
  }

  /**
   * Check if user can manage other users (Main Admin only)
   */
  canManageUsers(userRoles: UserRole[]): boolean {
    return this.isMainAdmin(userRoles);
  }

  /**
   * Check if user can view all data (Main Admin only)
   */
  canViewAll(userRoles: UserRole[]): boolean {
    return this.isMainAdmin(userRoles);
  }

  /**
   * Check if user can approve at any workflow stage (any admin)
   */
  canApproveAll(userRoles: UserRole[]): boolean {
    return this.isAnyAdmin(userRoles);
  }

  /**
   * Get admin role type for a user
   */
  getAdminRoleType(userRoles: UserRole[]): 'MAIN' | 'ICT' | 'STORE' | 'TRANSPORT' | null {
    if (this.isMainAdmin(userRoles)) return 'MAIN';
    if (this.isICTAdmin(userRoles)) return 'ICT';
    if (this.isStoreAdmin(userRoles)) return 'STORE';
    if (this.isTransportAdmin(userRoles)) return 'TRANSPORT';
    return null;
  }

  /**
   * Check if user has permission for a specific admin area
   */
  hasPermission(userRoles: UserRole[], area: 'ict' | 'store' | 'transport' | 'users'): boolean {
    switch (area) {
      case 'ict':
        return this.canManageICT(userRoles);
      case 'store':
        return this.canManageStore(userRoles);
      case 'transport':
        return this.canManageTransport(userRoles);
      case 'users':
        return this.canManageUsers(userRoles);
      default:
        return false;
    }
  }
}
