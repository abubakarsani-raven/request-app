"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

async function fetchJSON(url: string) {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function TransportAdminDashboard() {
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

  const { data: availableVehicles } = useQuery({
    queryKey: ["availableVehicles"],
    queryFn: () => fetchJSON("/api/dashboard/available-vehicles"),
  });

  const metrics = dashboardMetrics || {};

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">Transport Admin Dashboard</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Transport requests, vehicles, and drivers management
        </p>
      </div>

      <div className="grid gap-4 md:gap-6 grid-cols-1 md:grid-cols-3">
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
            <CardTitle className="text-sm font-medium text-muted-foreground">Pending Requests</CardTitle>
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

      {metrics.vehicles && metrics.drivers && (
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
                  <span className="font-medium">{metrics.drivers.total || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Available</span>
                  <span className="font-medium">{metrics.drivers.available || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Active Trips</span>
                  <span className="font-medium">{metrics.drivers.activeTrips || 0}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {metrics.requests?.byType?.VEHICLE && (
        <Card>
          <CardHeader>
            <CardTitle>Request Statistics</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <div className="text-sm text-muted-foreground">Total Requests</div>
                <div className="text-2xl font-bold">{metrics.requests.byType.VEHICLE.total || 0}</div>
              </div>
              <div>
                <div className="text-sm text-muted-foreground">Pending</div>
                <div className="text-2xl font-bold">{metrics.requests.byType.VEHICLE.pending || 0}</div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
