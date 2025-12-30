"use client";

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";

interface RequestChartProps {
  data: any;
}

export function RequestChart({ data }: RequestChartProps) {
  if (!data) return <div className="text-center text-muted-foreground py-8">No data available</div>;

  const chartData = [
    {
      name: "By Type",
      Vehicle: data.byType?.VEHICLE || 0,
      ICT: data.byType?.ICT || 0,
      Store: data.byType?.STORE || 0,
    },
    {
      name: "By Status",
      Pending: data.byStatus?.PENDING || 0,
      Approved: data.byStatus?.APPROVED || 0,
      Rejected: data.byStatus?.REJECTED || 0,
      Fulfilled: data.byStatus?.FULFILLED || 0,
    },
  ];

  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={chartData}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="name" />
        <YAxis />
        <Tooltip />
        <Legend />
        <Bar dataKey="Vehicle" fill="#8884d8" />
        <Bar dataKey="ICT" fill="#82ca9d" />
        <Bar dataKey="Store" fill="#ffc658" />
        <Bar dataKey="Pending" fill="#ff7300" />
        <Bar dataKey="Approved" fill="#00ff00" />
        <Bar dataKey="Rejected" fill="#ff0000" />
        <Bar dataKey="Fulfilled" fill="#0088fe" />
      </BarChart>
    </ResponsiveContainer>
  );
}
