"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { VehicleStatistics } from "./VehicleStatistics";
import { DriverStatistics } from "./DriverStatistics";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, LineChart, Line, PieChart, Pie, Cell } from "recharts";

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

const COLORS = ["#0088FE", "#00C49F", "#FFBB28", "#FF8042", "#8884d8"];

export function TransportAnalytics() {
  const { data: vehicles = [], isLoading: vehiclesLoading } = useQuery<any[]>({
    queryKey: ["vehicles"],
    queryFn: () => fetchJSON<any[]>("/api/vehicles"),
  });

  const { data: users = [], isLoading: usersLoading } = useQuery<any[]>({
    queryKey: ["users"],
    queryFn: () => fetchJSON<any[]>("/api/users"),
  });

  const { data: requests = [], isLoading: requestsLoading } = useQuery<any[]>({
    queryKey: ["transport-requests"],
    queryFn: () => fetchJSON<any[]>("/api/transport/requests"),
  });

  const isLoading = vehiclesLoading || usersLoading || requestsLoading;

  const drivers = users.filter((u) => {
    const roles = u.roles && u.roles.length > 0 ? u.roles : (u.role ? [u.role] : []);
    return roles.some((r: string) => r.toLowerCase() === "driver");
  });

  // Fuel consumption analytics
  const fuelData = requests
    .filter((r) => r.totalTripFuelLiters && r.totalTripDistanceKm)
    .slice(0, 20)
    .map((r) => ({
      date: r.tripDate ? new Date(r.tripDate).toLocaleDateString() : "N/A",
      fuel: r.totalTripFuelLiters || 0,
      distance: r.totalTripDistanceKm || 0,
      efficiency: r.totalTripDistanceKm && r.totalTripFuelLiters
        ? (r.totalTripDistanceKm / r.totalTripFuelLiters).toFixed(2)
        : 0,
    }));

  // Trip completion rates
  const totalTrips = requests.length;
  const completedTrips = requests.filter((r) => r.tripCompleted).length;
  const completionRate = totalTrips > 0 ? ((completedTrips / totalTrips) * 100).toFixed(1) : 0;

  const completionData = [
    { name: "Completed", value: completedTrips },
    { name: "In Progress", value: requests.filter((r) => r.tripStarted && !r.tripCompleted).length },
    { name: "Pending", value: requests.filter((r) => !r.tripStarted && !r.tripCompleted).length },
  ];

  // Vehicle utilization by month (simplified)
  const utilizationData = vehicles.slice(0, 10).map((vehicle) => {
    const vehicleRequests = requests.filter(
      (r) => (typeof r.vehicleId === "object" ? r.vehicleId?._id : r.vehicleId) === vehicle._id
    );
    return {
      name: vehicle.plateNumber,
      trips: vehicleRequests.length,
      completed: vehicleRequests.filter((r) => r.tripCompleted).length,
    };
  });

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-64" />
        <div className="grid gap-4 md:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-24" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">Transport Analytics</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Comprehensive transport statistics and insights
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Vehicles</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{vehicles.length}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Drivers</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{drivers.length}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Trips</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{totalTrips}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Completion Rate</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{completionRate}%</div>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Trip Completion Status</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={completionData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, value }) => `${name}: ${value}`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {completionData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

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
                <Bar dataKey="completed" fill="#82ca9d" name="Completed" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {fuelData.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Fuel Consumption Analytics</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={fuelData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" angle={-45} textAnchor="end" height={80} />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="fuel" stroke="#8884d8" name="Fuel (Liters)" />
                <Line type="monotone" dataKey="distance" stroke="#82ca9d" name="Distance (Km)" />
                <Line type="monotone" dataKey="efficiency" stroke="#FF8042" name="Efficiency (Km/L)" />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      <VehicleStatistics />
      <DriverStatistics />
    </div>
  );
}
