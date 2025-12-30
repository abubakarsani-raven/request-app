"use client";

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from "recharts";

interface FulfillmentRateChartProps {
  data: any;
}

const COLORS = ["#0088FE", "#00C49F", "#FFBB28", "#FF8042"];

export function FulfillmentRateChart({ data }: FulfillmentRateChartProps) {
  if (!data) return <div className="text-center text-muted-foreground py-8">No data available</div>;

  const chartData = [];
  if (data.byType?.ICT) {
    chartData.push({
      name: "ICT",
      value: parseFloat(data.byType.ICT.rate) || 0,
      total: data.byType.ICT.total || 0,
    });
  }
  if (data.byType?.STORE) {
    chartData.push({
      name: "Store",
      value: parseFloat(data.byType.STORE.rate) || 0,
      total: data.byType.STORE.total || 0,
    });
  }

  if (chartData.length === 0) {
    return <div className="text-center text-muted-foreground py-8">No fulfillment data available</div>;
  }

  return (
    <ResponsiveContainer width="100%" height={300}>
      <PieChart>
        <Pie
          data={chartData}
          cx="50%"
          cy="50%"
          labelLine={false}
          label={({ name, value }) => `${name}: ${value}%`}
          outerRadius={80}
          fill="#8884d8"
          dataKey="value"
        >
          {chartData.map((entry, index) => (
            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
          ))}
        </Pie>
        <Tooltip />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
}
