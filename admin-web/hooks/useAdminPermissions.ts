"use client";

import { useMemo } from 'react';
import { useAuth } from './useAuth';
import { UserRole } from '@/types/user';

export function useAdminPermissions() {
  const { user } = useAuth();

  const permissions = useMemo(() => {
    if (!user) {
      return {
        isMainAdmin: false,
        isICTAdmin: false,
        isStoreAdmin: false,
        isTransportAdmin: false,
        canManageICT: false,
        canManageStore: false,
        canManageTransport: false,
        canManageUsers: false,
        canViewAll: false,
        canApproveAll: false,
      };
    }

    // Support both single role and roles array
    const userRoles: UserRole[] = user.roles || (user.role ? [user.role] : []);

    const isMainAdmin = userRoles.includes(UserRole.ADMIN);
    const isICTAdmin = userRoles.includes(UserRole.ICT_ADMIN);
    const isStoreAdmin = userRoles.includes(UserRole.STORE_ADMIN);
    const isTransportAdmin = userRoles.includes(UserRole.TRANSPORT_ADMIN);

    return {
      isMainAdmin,
      isICTAdmin,
      isStoreAdmin,
      isTransportAdmin,
      canManageICT: isMainAdmin || isICTAdmin,
      canManageStore: isMainAdmin || isStoreAdmin,
      canManageTransport: isMainAdmin || isTransportAdmin,
      canManageUsers: isMainAdmin,
      canViewAll: isMainAdmin,
      canApproveAll: isMainAdmin || isICTAdmin || isStoreAdmin || isTransportAdmin,
    };
  }, [user]);

  return permissions;
}
