"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatCard } from "./StatCard";
import { RequestChart } from "./RequestChart";
import { VehicleUtilizationChart } from "./VehicleUtilizationChart";
import { FulfillmentRateChart } from "./FulfillmentRateChart";
import { InventoryLevelChart } from "./InventoryLevelChart";
import { useAdminPermissions } from "@/hooks/useAdminPermissions";

async function fetchJSON(url: string) {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function AnalyticsDashboard() {
  const permissions = useAdminPermissions();

  const { data: dashboardMetrics, isLoading } = useQuery({
    queryKey: ["dashboard-metrics"],
    queryFn: () => fetchJSON("/api/analytics/dashboard"),
  });

  const { data: requestStats } = useQuery({
    queryKey: ["request-statistics"],
    queryFn: () => fetchJSON("/api/analytics/requests"),
  });

  const { data: vehicleStats } = useQuery({
    queryKey: ["vehicle-statistics"],
    queryFn: () => fetchJSON("/api/analytics/vehicles"),
    enabled: permissions.canManageTransport,
  });

  const { data: driverStats } = useQuery({
    queryKey: ["driver-statistics"],
    queryFn: () => fetchJSON("/api/analytics/drivers"),
    enabled: permissions.canManageTransport,
  });

  const { data: inventoryStats } = useQuery({
    queryKey: ["inventory-statistics"],
    queryFn: () => fetchJSON("/api/analytics/inventory"),
    enabled: permissions.canManageICT || permissions.canManageStore,
  });

  const { data: fulfillmentStats } = useQuery({
    queryKey: ["fulfillment-statistics"],
    queryFn: () => fetchJSON("/api/analytics/fulfillment"),
  });

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">Analytics Dashboard</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Real-time statistics and insights
        </p>
      </div>

      {/* Request Statistics */}
      {requestStats && (
        <div className="grid gap-4 md:grid-cols-4">
          <StatCard
            title="Total Requests"
            value={requestStats.total || 0}
            isLoading={isLoading}
          />
          <StatCard
            title="Pending"
            value={requestStats.pending || 0}
            isLoading={isLoading}
            variant="warning"
          />
          <StatCard
            title="Approved"
            value={requestStats.approved || 0}
            isLoading={isLoading}
            variant="success"
          />
          <StatCard
            title="Fulfilled"
            value={requestStats.fulfilled || 0}
            isLoading={isLoading}
            variant="success"
          />
        </div>
      )}

      {/* Charts */}
      <div className="grid gap-4 md:grid-cols-2">
        {requestStats && (
          <Card>
            <CardHeader>
              <CardTitle>Request Statistics</CardTitle>
            </CardHeader>
            <CardContent>
              <RequestChart data={requestStats} />
            </CardContent>
          </Card>
        )}

        {fulfillmentStats && (
          <Card>
            <CardHeader>
              <CardTitle>Fulfillment Rates</CardTitle>
            </CardHeader>
            <CardContent>
              <FulfillmentRateChart data={fulfillmentStats} />
            </CardContent>
          </Card>
        )}
      </div>

      {/* Vehicle & Driver Statistics (Transport Admin only) */}
      {permissions.canManageTransport && (
        <>
          {vehicleStats && (
            <Card>
              <CardHeader>
                <CardTitle>Vehicle Utilization</CardTitle>
              </CardHeader>
              <CardContent>
                <VehicleUtilizationChart data={vehicleStats} />
              </CardContent>
            </Card>
          )}

          {driverStats && (
            <Card>
              <CardHeader>
                <CardTitle>Driver Performance</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-sm text-muted-foreground">Total Drivers</span>
                    <span className="font-medium">{driverStats.totalDrivers || 0}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-muted-foreground">Available</span>
                    <span className="font-medium">{driverStats.availableDrivers || 0}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-muted-foreground">Average Performance</span>
                    <span className="font-medium">{driverStats.averagePerformance || "0%"}%</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </>
      )}

      {/* Inventory Statistics (ICT/Store Admin only) */}
      {(permissions.canManageICT || permissions.canManageStore) && inventoryStats && (
        <Card>
          <CardHeader>
            <CardTitle>Inventory Levels</CardTitle>
          </CardHeader>
          <CardContent>
            <InventoryLevelChart data={inventoryStats} />
          </CardContent>
        </Card>
      )}
    </div>
  );
}
