"use client";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { AlertTriangle } from "lucide-react";
import { Badge } from "@/components/ui/badge";

type ICTItem = {
  _id: string;
  name: string;
  quantity: number;
  lowStockThreshold: number;
  category: string;
};

type LowStockAlertProps = {
  items: ICTItem[];
};

export function LowStockAlert({ items }: LowStockAlertProps) {
  if (items.length === 0) return null;

  return (
    <Alert variant="destructive">
      <AlertTriangle className="h-4 w-4" />
      <AlertTitle>Low Stock Alert</AlertTitle>
      <AlertDescription>
        <p className="mb-2">
          {items.length} item{items.length > 1 ? "s" : ""} {items.length > 1 ? "are" : "is"} running low on stock:
        </p>
        <div className="flex flex-wrap gap-2">
          {items.map((item) => (
            <Badge key={item._id} variant="outline" className="text-destructive">
              {item.name} ({item.quantity}/{item.lowStockThreshold})
            </Badge>
          ))}
        </div>
      </AlertDescription>
    </Alert>
  );
}

