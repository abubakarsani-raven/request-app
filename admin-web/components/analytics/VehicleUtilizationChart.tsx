"use client";

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";

interface VehicleUtilizationChartProps {
  data: any;
}

export function VehicleUtilizationChart({ data }: VehicleUtilizationChartProps) {
  if (!data || !data.vehicleUtilization || data.vehicleUtilization.length === 0) {
    return <div className="text-center text-muted-foreground py-8">No vehicle data available</div>;
  }

  const chartData = data.vehicleUtilization.slice(0, 10).map((v: any) => ({
    name: v.plateNumber || "Unknown",
    utilization: v.utilizationRate || 0,
    trips: v.totalTrips || 0,
  }));

  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={chartData}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} />
        <YAxis />
        <Tooltip />
        <Legend />
        <Line type="monotone" dataKey="utilization" stroke="#8884d8" name="Utilization %" />
        <Line type="monotone" dataKey="trips" stroke="#82ca9d" name="Total Trips" />
      </LineChart>
    </ResponsiveContainer>
  );
}
