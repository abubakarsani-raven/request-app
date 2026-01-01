"use client";

import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Sparkles, TrendingUp, AlertTriangle, Package, ArrowRight } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";

type ICTItem = {
  _id?: string;
  id?: string;
  name: string;
  category: string;
  quantity: number;
  lowStockThreshold: number;
  unit: string;
};

type RestockingAdvice = {
  itemId: string;
  itemName: string;
  category: string;
  currentStock: number;
  threshold: number;
  recommendedQuantity: number;
  urgency: "high" | "medium" | "low";
  reason: string;
  estimatedDaysUntilOutOfStock: number;
  unit: string;
};

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

async function getRestockingAdvice(): Promise<RestockingAdvice[]> {
  const items: ICTItem[] = await fetchJSON<ICTItem[]>("/api/ict/items");
  const lowStockItems: ICTItem[] = await fetchJSON<ICTItem[]>("/api/ict/items/low-stock/all");
  
  // Get request history for demand analysis
  const requests = await fetchJSON<any[]>("/api/ict/requests?pending=false");
  
  // Analyze demand patterns
  const itemDemand: Record<string, number> = {};
  const last30Days = new Date();
  last30Days.setDate(last30Days.getDate() - 30);
  
  requests.forEach((req: any) => {
    if (new Date(req.createdAt) >= last30Days && req.items) {
      req.items.forEach((item: any) => {
        const itemId = item.itemId?._id || item.itemId;
        if (itemId) {
          itemDemand[itemId] = (itemDemand[itemId] || 0) + (item.requestedQuantity || item.quantity || 0);
        }
      });
    }
  });
  
  // Generate AI-powered recommendations
  const advice: RestockingAdvice[] = [];
  
  // Analyze low stock items
  lowStockItems.forEach((item) => {
    const itemId = getItemId(item);
    const demand = itemDemand[itemId] || 0;
    const avgDailyDemand = demand / 30;
    const daysUntilOutOfStock = avgDailyDemand > 0 ? Math.floor(item.quantity / avgDailyDemand) : 999;
    
    // Calculate recommended quantity based on demand and safety stock
    const safetyStock = item.lowStockThreshold * 1.5; // 1.5x threshold as safety stock
    const recommendedQuantity = Math.max(
      item.lowStockThreshold * 2, // At least 2x threshold
      Math.ceil(avgDailyDemand * 30) + safetyStock // 30 days supply + safety stock
    );
    
    let urgency: "high" | "medium" | "low" = "medium";
    let reason = "";
    
    if (item.quantity === 0) {
      urgency = "high";
      reason = "Item is completely out of stock. Immediate restocking required.";
    } else if (daysUntilOutOfStock < 7) {
      urgency = "high";
      reason = `Critical: Estimated to run out in ${daysUntilOutOfStock} days based on recent demand patterns.`;
    } else if (daysUntilOutOfStock < 14) {
      urgency = "medium";
      reason = `Moderate urgency: Estimated to run out in ${daysUntilOutOfStock} days. Consider restocking soon.`;
    } else {
      urgency = "low";
      reason = `Low urgency: Current stock should last ${daysUntilOutOfStock} days. Monitor for changes in demand.`;
    }
    
    if (demand > 0) {
      reason += ` Recent 30-day demand: ${demand} ${item.unit}.`;
    }
    
    advice.push({
      itemId,
      itemName: item.name,
      category: item.category,
      currentStock: item.quantity,
      threshold: item.lowStockThreshold,
      recommendedQuantity,
      urgency,
      reason,
      estimatedDaysUntilOutOfStock: daysUntilOutOfStock,
      unit: item.unit,
    });
  });
  
  // Sort by urgency (high first)
  const urgencyOrder = { high: 0, medium: 1, low: 2 };
  advice.sort((a, b) => urgencyOrder[a.urgency] - urgencyOrder[b.urgency]);
  
  return advice.slice(0, 10); // Return top 10 recommendations
}

function getItemId(item: ICTItem): string {
  return item._id || item.id || '';
}

export function AIRestockingAdvice() {
  const { data: advice, isLoading, error } = useQuery<RestockingAdvice[]>({
    queryKey: ["restocking-advice"],
    queryFn: getRestockingAdvice,
    refetchInterval: 300000, // Refetch every 5 minutes
  });

  if (error) {
    return (
      <Alert variant="destructive">
        <AlertTriangle className="h-4 w-4" />
        <AlertTitle>Error</AlertTitle>
        <AlertDescription>
          Failed to load restocking advice. Please try again later.
        </AlertDescription>
      </Alert>
    );
  }

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Sparkles className="h-5 w-5" />
            AI Restocking Advice
          </CardTitle>
          <CardDescription>
            Smart recommendations based on demand patterns and stock levels
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="space-y-2">
              <Skeleton className="h-4 w-full" />
              <Skeleton className="h-4 w-3/4" />
            </div>
          ))}
        </CardContent>
      </Card>
    );
  }

  if (!advice || advice.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Sparkles className="h-5 w-5" />
            AI Restocking Advice
          </CardTitle>
          <CardDescription>
            Smart recommendations based on demand patterns and stock levels
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            <Package className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>All items are well-stocked. No immediate restocking needed.</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const urgencyColors = {
    high: "destructive",
    medium: "default",
    low: "secondary",
  } as const;

  const urgencyIcons = {
    high: AlertTriangle,
    medium: TrendingUp,
    low: Package,
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Sparkles className="h-5 w-5 text-purple-500" />
          AI Restocking Advice
        </CardTitle>
        <CardDescription>
          Smart recommendations based on demand patterns and stock levels
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {advice.map((item) => {
          const UrgencyIcon = urgencyIcons[item.urgency];
          return (
            <div
              key={item.itemId}
              className="border rounded-lg p-4 space-y-3 hover:bg-accent/50 transition-colors"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                    <h4 className="font-semibold">{item.itemName}</h4>
                    <Badge variant={urgencyColors[item.urgency]}>
                      <UrgencyIcon className="h-3 w-3 mr-1" />
                      {item.urgency.toUpperCase()}
                    </Badge>
                    <Badge variant="outline">{item.category}</Badge>
                  </div>
                  <p className="text-sm text-muted-foreground mb-2">{item.reason}</p>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-3">
                    <div>
                      <p className="text-xs text-muted-foreground">Current Stock</p>
                      <p className="font-semibold">{item.currentStock} {item.unit}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground">Threshold</p>
                      <p className="font-semibold">{item.threshold} {item.unit}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground">Recommended</p>
                      <p className="font-semibold text-primary">{item.recommendedQuantity} {item.unit}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground">Days Until Out</p>
                      <p className="font-semibold">
                        {item.estimatedDaysUntilOutOfStock === 999 ? "N/A" : item.estimatedDaysUntilOutOfStock}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="flex gap-2 pt-2 border-t">
                <Button
                  size="sm"
                  variant="outline"
                  className="flex-1"
                  onClick={() => {
                    // Navigate to inventory page with item selected
                    window.location.href = `/ict-inventory?item=${item.itemId}`;
                  }}
                >
                  View Item
                  <ArrowRight className="h-3 w-3 ml-1" />
                </Button>
              </div>
            </div>
          );
        })}
      </CardContent>
    </Card>
  );
}
