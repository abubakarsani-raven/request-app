"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function DriverStatistics() {
  const { data: users = [], isLoading } = useQuery<any[]>({
    queryKey: ["users"],
    queryFn: () => fetchJSON<any[]>("/api/users"),
  });

  const { data: requests = [] } = useQuery<any[]>({
    queryKey: ["transport-requests"],
    queryFn: () => fetchJSON<any[]>("/api/transport/requests"),
  });

  if (isLoading) {
    return (
      <div className="grid gap-4 md:grid-cols-4">
        {[1, 2, 3, 4].map((i) => (
          <Skeleton key={i} className="h-24" />
        ))}
      </div>
    );
  }

  const drivers = users.filter((u) => {
    const roles = u.roles && u.roles.length > 0 ? u.roles : (u.role ? [u.role] : []);
    return roles.some((r) => r.toLowerCase() === "driver");
  });

  const totalDrivers = drivers.length;
  const activeAssignments = requests.filter(
    (r) => r.status === "ASSIGNED" && r.tripStarted && !r.tripCompleted && r.driverId
  ).length;
  const availableDrivers = totalDrivers - activeAssignments;

  const driverPerformance = drivers.slice(0, 10).map((driver) => {
    const driverRequests = requests.filter((r) => {
      const driverId = typeof r.driverId === "object" ? r.driverId?._id : r.driverId;
      return driverId === driver._id;
    });
    const completedTrips = driverRequests.filter((r) => r.tripCompleted).length;
    const totalTrips = driverRequests.length;
    const performanceRating = totalTrips > 0 ? Math.round((completedTrips / totalTrips) * 100) : 0;

    return {
      name: driver.name,
      trips: completedTrips,
      total: totalTrips,
      performance: performanceRating,
    };
  });

  return (
    <div className="space-y-4">
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Drivers</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{totalDrivers}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Available</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-green-600">{availableDrivers}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Active Assignments</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-blue-600">{activeAssignments}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Avg Performance</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">
              {driverPerformance.length > 0
                ? Math.round(
                    driverPerformance.reduce((sum, d) => sum + d.performance, 0) / driverPerformance.length
                  )
                : 0}
              %
            </div>
          </CardContent>
        </Card>
      </div>

      {driverPerformance.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Driver Performance</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={driverPerformance}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="trips" fill="#8884d8" name="Completed Trips" />
                <Bar dataKey="performance" fill="#82ca9d" name="Performance %" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
