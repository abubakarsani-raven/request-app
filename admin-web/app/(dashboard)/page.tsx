"use client";

import { useAdminPermissions } from "@/hooks/useAdminPermissions";
import { MainAdminDashboard } from "@/components/dashboards/MainAdminDashboard";
import { ICTAdminDashboard } from "@/components/dashboards/ICTAdminDashboard";
import { StoreAdminDashboard } from "@/components/dashboards/StoreAdminDashboard";
import { TransportAdminDashboard } from "@/components/dashboards/TransportAdminDashboard";

export default function Page() {
  const permissions = useAdminPermissions();

  // Render appropriate dashboard based on admin role
  if (permissions.isMainAdmin) {
    return <MainAdminDashboard />;
  }

  if (permissions.isICTAdmin) {
    return <ICTAdminDashboard />;
  }

  if (permissions.isStoreAdmin) {
    return <StoreAdminDashboard />;
  }

  if (permissions.isTransportAdmin) {
    return <TransportAdminDashboard />;
  }

  // Fallback to main admin dashboard if no specific role detected
  return <MainAdminDashboard />;
}


