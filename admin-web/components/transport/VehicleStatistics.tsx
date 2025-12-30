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

export function VehicleStatistics() {
  const { data: vehicles = [], isLoading } = useQuery<any[]>({
    queryKey: ["vehicles"],
    queryFn: () => fetchJSON<any[]>("/api/vehicles"),
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

  const totalVehicles = vehicles.length;
  const availableVehicles = vehicles.filter((v) => v.status === "available" || v.isAvailable).length;
  const activeTrips = requests.filter((r) => r.status === "ASSIGNED" && r.tripStarted && !r.tripCompleted).length;
  const maintenanceDue = vehicles.filter((v) => {
    // Check if vehicle has maintenance records with due dates
    return false; // Placeholder - implement based on your maintenance schema
  }).length;

  const utilizationData = vehicles.slice(0, 10).map((vehicle) => {
    const vehicleRequests = requests.filter(
      (r) => (typeof r.vehicleId === "object" ? r.vehicleId?._id : r.vehicleId) === vehicle._id
    );
    const completedTrips = vehicleRequests.filter((r) => r.tripCompleted).length;
    const utilizationRate = totalVehicles > 0 ? (completedTrips / totalVehicles) * 100 : 0;

    return {
      name: vehicle.plateNumber,
      trips: completedTrips,
      utilization: Math.round(utilizationRate),
    };
  });

  return (
    <div className="space-y-4">
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Vehicles</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{totalVehicles}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Available</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-green-600">{availableVehicles}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Active Trips</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-blue-600">{activeTrips}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Maintenance Due</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-orange-600">{maintenanceDue}</div>
          </CardContent>
        </Card>
      </div>

      {utilizationData.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Vehicle Utilization</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={utilizationData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="trips" fill="#8884d8" name="Total Trips" />
                <Bar dataKey="utilization" fill="#82ca9d" name="Utilization %" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
