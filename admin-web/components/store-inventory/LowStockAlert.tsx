"use client";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { AlertTriangle } from "lucide-react";
import { Badge } from "@/components/ui/badge";

type StoreItem = {
  _id?: string;
  id?: string;
  name: string;
  quantity: number;
  lowStockThreshold?: number;
  category: string;
};

type LowStockAlertProps = {
  items: StoreItem[];
  itemType?: "store" | "ict";
};

export function LowStockAlert({ items, itemType = "store" }: LowStockAlertProps) {
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
          {items.map((item) => {
            const itemId = item._id || item.id || "";
            return (
              <Badge key={itemId} variant="outline" className="text-destructive">
                {item.name} ({item.quantity}/{item.lowStockThreshold || 5})
              </Badge>
            );
          })}
        </div>
      </AlertDescription>
    </Alert>
  );
}
