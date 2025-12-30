"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useAdminPermissions } from "@/hooks/useAdminPermissions";

async function fetchJSON(url: string) {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function MainAdminDashboard() {
  const permissions = useAdminPermissions();

  const { data: dashboardMetrics, isLoading } = useQuery({
    queryKey: ["dashboard-metrics"],
    queryFn: () => fetchJSON("/api/analytics/dashboard"),
  });

  const { data: activeTrips } = useQuery({
    queryKey: ["activeTrips"],
    queryFn: () => fetchJSON("/api/dashboard/active-trips"),
  });

  const { data: pendingTransportRequests } = useQuery({
    queryKey: ["pendingTransportRequests"],
    queryFn: () => fetchJSON("/api/dashboard/pending-transport-requests"),
  });

  const { data: pendingIctRequests } = useQuery({
    queryKey: ["pendingIctRequests"],
    queryFn: () => fetchJSON("/api/dashboard/pending-ict-requests"),
  });

  const { data: pendingStoreRequests } = useQuery({
    queryKey: ["pendingStoreRequests"],
    queryFn: () => fetchJSON("/api/dashboard/pending-store-requests"),
  });

  const { data: availableVehicles } = useQuery({
    queryKey: ["availableVehicles"],
    queryFn: () => fetchJSON("/api/dashboard/available-vehicles"),
  });

  const metrics = dashboardMetrics || {};

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">Main Admin Dashboard</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Complete system overview and management
        </p>
      </div>

      <div className="grid gap-4 md:gap-6 grid-cols-1 md:grid-cols-3 lg:grid-cols-5">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Active Trips</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-3xl font-bold">{activeTrips ?? 0}</div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Pending Transport</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-3xl font-bold">{pendingTransportRequests ?? 0}</div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Pending ICT</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-3xl font-bold">{pendingIctRequests ?? 0}</div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Pending Store</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-3xl font-bold">{pendingStoreRequests ?? 0}</div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Available Vehicles</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-3xl font-bold">{availableVehicles ?? 0}</div>
            )}
          </CardContent>
        </Card>
      </div>

      {metrics.vehicles && (
        <div className="grid gap-4 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Vehicle Statistics</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Total Vehicles</span>
                  <span className="font-medium">{metrics.vehicles.total || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Available</span>
                  <span className="font-medium">{metrics.vehicles.available || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Active Trips</span>
                  <span className="font-medium">{metrics.vehicles.activeTrips || 0}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Driver Statistics</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Total Drivers</span>
                  <span className="font-medium">{metrics.drivers?.total || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Available</span>
                  <span className="font-medium">{metrics.drivers?.available || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Active Trips</span>
                  <span className="font-medium">{metrics.drivers?.activeTrips || 0}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {metrics.ict && (
        <Card>
          <CardHeader>
            <CardTitle>ICT Statistics</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <div className="text-sm text-muted-foreground">Total Items</div>
                <div className="text-2xl font-bold">{metrics.ict.totalItems || 0}</div>
              </div>
              <div>
                <div className="text-sm text-muted-foreground">Pending Requests</div>
                <div className="text-2xl font-bold">{metrics.ict.pendingRequests || 0}</div>
              </div>
              <div>
                <div className="text-sm text-muted-foreground">Low Stock Items</div>
                <div className="text-2xl font-bold">{metrics.ict.lowStockItems || 0}</div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {metrics.store && (
        <Card>
          <CardHeader>
            <CardTitle>Store Statistics</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <div className="text-sm text-muted-foreground">Total Items</div>
                <div className="text-2xl font-bold">{metrics.store.totalItems || 0}</div>
              </div>
              <div>
                <div className="text-sm text-muted-foreground">Pending Requests</div>
                <div className="text-2xl font-bold">{metrics.store.pendingRequests || 0}</div>
              </div>
              <div>
                <div className="text-sm text-muted-foreground">Low Stock Items</div>
                <div className="text-2xl font-bold">{metrics.store.lowStockItems || 0}</div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
