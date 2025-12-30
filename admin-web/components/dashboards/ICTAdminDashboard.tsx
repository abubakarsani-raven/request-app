"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

async function fetchJSON(url: string) {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function ICTAdminDashboard() {
  const { data: dashboardMetrics, isLoading } = useQuery({
    queryKey: ["dashboard-metrics"],
    queryFn: () => fetchJSON("/api/analytics/dashboard"),
  });

  const { data: pendingIctRequests } = useQuery({
    queryKey: ["pendingIctRequests"],
    queryFn: () => fetchJSON("/api/dashboard/pending-ict-requests"),
  });

  const metrics = dashboardMetrics || {};

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">ICT Admin Dashboard</h1>
        <p className="text-sm text-muted-foreground mt-1">
          ICT requests and inventory management
        </p>
      </div>

      <div className="grid gap-4 md:gap-6 grid-cols-1 md:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Pending ICT Requests</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-3xl font-bold">{pendingIctRequests ?? 0}</div>
            )}
          </CardContent>
        </Card>

        {metrics.ict && (
          <>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Total Items</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold">{metrics.ict.totalItems || 0}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Low Stock Items</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-orange-600">{metrics.ict.lowStockItems || 0}</div>
              </CardContent>
            </Card>
          </>
        )}
      </div>

      {metrics.requests?.byType?.ICT && (
        <Card>
          <CardHeader>
            <CardTitle>Request Statistics</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <div className="text-sm text-muted-foreground">Total Requests</div>
                <div className="text-2xl font-bold">{metrics.requests.byType.ICT.total || 0}</div>
              </div>
              <div>
                <div className="text-sm text-muted-foreground">Pending</div>
                <div className="text-2xl font-bold">{metrics.requests.byType.ICT.pending || 0}</div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
