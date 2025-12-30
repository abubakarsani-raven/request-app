"use client";

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";

interface InventoryLevelChartProps {
  data: any;
}

export function InventoryLevelChart({ data }: InventoryLevelChartProps) {
  if (!data) return <div className="text-center text-muted-foreground py-8">No data available</div>;

  const chartData = Object.entries(data.byCategory || {}).map(([category, count]) => ({
    name: category,
    count: count as number,
  }));

  if (chartData.length === 0) {
    return <div className="text-center text-muted-foreground py-8">No inventory data available</div>;
  }

  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={chartData}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} />
        <YAxis />
        <Tooltip />
        <Legend />
        <Bar dataKey="count" fill="#8884d8" name="Items" />
      </BarChart>
    </ResponsiveContainer>
  );
}
