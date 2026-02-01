"use client";

import { useMemo } from "react";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Lightbulb, AlertTriangle, Package, History } from "lucide-react";

export type ICTItemForDetails = {
  _id?: string;
  id?: string;
  name: string;
  description?: string;
  category: string;
  quantity: number;
  isAvailable: boolean;
  brand?: string;
  model?: string;
  sku?: string;
  unit: string;
  location?: string;
  lowStockThreshold: number;
  supplier?: string;
  supplierContact?: string;
  cost?: number;
};

type DepartmentRef = { name: string };
type PerformerRef = { name: string; email?: string; departmentId?: DepartmentRef };
type RequesterRef = { name: string; departmentId?: DepartmentRef };
type RequestRef = { _id?: string; requesterId?: RequesterRef };

export type StockHistoryEntry = {
  _id: string;
  previousQuantity: number;
  newQuantity: number;
  changeAmount: number;
  operation: string;
  reason?: string;
  performedBy: PerformerRef | string;
  requestId?: RequestRef | string;
  createdAt: string;
};

function getPerformerDisplay(performedBy: StockHistoryEntry["performedBy"]): string {
  if (typeof performedBy !== "object" || performedBy === null) return "Unknown";
  const name = performedBy.name || (performedBy as PerformerRef).email || "Unknown";
  const dept = (performedBy as PerformerRef).departmentId?.name;
  return dept ? `${name} (${dept})` : name;
}

function getReasonDisplay(entry: StockHistoryEntry): string {
  if (entry.operation === "FULFILLMENT" && entry.requestId && typeof entry.requestId === "object") {
    const req = entry.requestId as RequestRef;
    const requester = req?.requesterId;
    if (requester?.name) {
      const dept = requester.departmentId?.name;
      return dept
        ? `Fulfilled request by ${requester.name} (${dept})`
        : `Fulfilled request by ${requester.name}`;
    }
  }
  return entry.reason || "-";
}

type ItemDetailsContentProps = {
  item: ICTItemForDetails | null | undefined;
  historyRaw: StockHistoryEntry[];
  isLoadingItem: boolean;
  isLoadingHistory: boolean;
};

function formatRelativeTime(dateString: string) {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  if (diffMins < 1) return "Just now";
  if (diffMins < 60) return `${diffMins} min ago`;
  if (diffHours < 24) return `${diffHours} hr ago`;
  if (diffDays < 7) return `${diffDays} days ago`;
  return date.toLocaleDateString();
}

export function ItemDetailsContent({
  item,
  historyRaw,
  isLoadingItem,
  isLoadingHistory,
}: ItemDetailsContentProps) {
  const history = useMemo(
    () => [...historyRaw].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()),
    [historyRaw]
  );

  function getOperationBadge(operation: string) {
    const variants: Record<string, "default" | "destructive" | "secondary"> = {
      ADD: "default",
      REMOVE: "destructive",
      ADJUST: "secondary",
      FULFILLMENT: "destructive",
      RETURN: "default",
    };
    return <Badge variant={variants[operation] || "secondary"}>{operation}</Badge>;
  }

  function formatDate(dateString: string) {
    return new Date(dateString).toLocaleString();
  }

  if (isLoadingItem) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-32 w-full" />
      </div>
    );
  }

  if (!item) {
    return <p className="text-center text-muted-foreground py-8">Failed to load item details</p>;
  }

  return (
    <div className="space-y-4">
      <div>
        <h3 className="text-lg font-semibold mb-3">Item Information</h3>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div>
            <p className="text-sm text-muted-foreground">Name</p>
            <p className="font-medium">{item.name}</p>
          </div>
          <div>
            <p className="text-sm text-muted-foreground">Category</p>
            <p className="font-medium">{item.category}</p>
          </div>
          <div>
            <p className="text-sm text-muted-foreground">Current Stock</p>
            <p className="font-medium">{item.quantity} {item.unit}</p>
          </div>
          <div>
            <p className="text-sm text-muted-foreground">Low Stock Threshold</p>
            <p className="font-medium">{item.lowStockThreshold} {item.unit}</p>
          </div>
          <div>
            <p className="text-sm text-muted-foreground">Status</p>
            <Badge variant={item.isAvailable ? "default" : "secondary"}>
              {item.isAvailable ? "Available" : "Unavailable"}
            </Badge>
          </div>
          {item.brand && (
            <div>
              <p className="text-sm text-muted-foreground">Brand</p>
              <p className="font-medium">{item.brand}</p>
            </div>
          )}
          {item.model && (
            <div>
              <p className="text-sm text-muted-foreground">Model</p>
              <p className="font-medium">{item.model}</p>
            </div>
          )}
          {item.sku && (
            <div>
              <p className="text-sm text-muted-foreground">SKU</p>
              <p className="font-medium">{item.sku}</p>
            </div>
          )}
          {item.location && (
            <div>
              <p className="text-sm text-muted-foreground">Location</p>
              <p className="font-medium">{item.location}</p>
            </div>
          )}
          {item.supplier && (
            <div>
              <p className="text-sm text-muted-foreground">Supplier</p>
              <p className="font-medium">{item.supplier}</p>
            </div>
          )}
          {item.cost !== undefined && (
            <div>
              <p className="text-sm text-muted-foreground">Cost</p>
              <p className="font-medium">${item.cost.toFixed(2)}</p>
            </div>
          )}
        </div>
        {item.description && (
          <div className="mt-4">
            <p className="text-sm text-muted-foreground">Description</p>
            <p className="font-medium">{item.description}</p>
          </div>
        )}
      </div>

      <div>
        <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
          <Lightbulb className="h-5 w-5 text-amber-500" />
          Recommendations
        </h3>
        <div className="space-y-2">
          {item.quantity <= item.lowStockThreshold ? (
            <Alert variant="destructive">
              <AlertTriangle className="h-4 w-4" />
              <AlertTitle>Low stock</AlertTitle>
              <AlertDescription>
                Current stock ({item.quantity} {item.unit}) is at or below the threshold ({item.lowStockThreshold}{" "}
                {item.unit}). Consider reordering soon. Suggested reorder: bring stock to at least{" "}
                {Math.max(item.lowStockThreshold * 2, item.lowStockThreshold + 10)} {item.unit}.
              </AlertDescription>
            </Alert>
          ) : item.quantity <= item.lowStockThreshold * 1.5 ? (
            <Alert>
              <Package className="h-4 w-4" />
              <AlertTitle>Stock getting low</AlertTitle>
              <AlertDescription>
                You have {item.quantity} {item.unit} left. Plan to reorder before reaching the threshold of{" "}
                {item.lowStockThreshold} {item.unit}.
              </AlertDescription>
            </Alert>
          ) : (
            <Alert>
              <Package className="h-4 w-4" />
              <AlertTitle>Stock level OK</AlertTitle>
              <AlertDescription>
                Current stock is healthy. Low stock threshold: {item.lowStockThreshold} {item.unit}.
              </AlertDescription>
            </Alert>
          )}
          {history.length > 0 && (() => {
            const lastRestock = history.find((e) => e.operation === "ADD" || e.operation === "ADJUST");
            if (lastRestock) {
              return (
                <p className="text-sm text-muted-foreground flex items-center gap-1">
                  <History className="h-4 w-4" />
                  Last restock: {formatRelativeTime(lastRestock.createdAt)} (
                  {lastRestock.changeAmount >= 0 ? "+" : ""}
                  {lastRestock.changeAmount} {item.unit})
                </p>
              );
            }
            return null;
          })()}
        </div>
      </div>

      <Separator />

      <div>
        <h3 className="text-lg font-semibold mb-3">Stock History</h3>
        <p className="text-sm text-muted-foreground mb-2">Newest first</p>
        {isLoadingHistory ? (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Date</TableHead>
                <TableHead>When</TableHead>
                <TableHead>Operation</TableHead>
                <TableHead>Previous</TableHead>
                <TableHead>New</TableHead>
                <TableHead>Change</TableHead>
                <TableHead>Performed By</TableHead>
                <TableHead>Reason</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <SkeletonTableRows rows={5} cols={8} />
            </TableBody>
          </Table>
        ) : history.length === 0 ? (
          <p className="text-center text-muted-foreground py-8">No stock history available</p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Date</TableHead>
                <TableHead>When</TableHead>
                <TableHead>Operation</TableHead>
                <TableHead>Previous</TableHead>
                <TableHead>New</TableHead>
                <TableHead>Change</TableHead>
                <TableHead>Performed By</TableHead>
                <TableHead>Reason</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {history.map((entry) => (
                <TableRow key={entry._id}>
                  <TableCell className="whitespace-nowrap">{formatDate(entry.createdAt)}</TableCell>
                  <TableCell className="text-muted-foreground text-sm">{formatRelativeTime(entry.createdAt)}</TableCell>
                  <TableCell>{getOperationBadge(entry.operation)}</TableCell>
                  <TableCell>{entry.previousQuantity}</TableCell>
                  <TableCell>{entry.newQuantity}</TableCell>
                  <TableCell>
                    <span className={entry.changeAmount >= 0 ? "text-green-600" : "text-red-600"}>
                      {entry.changeAmount >= 0 ? "+" : ""}
                      {entry.changeAmount}
                    </span>
                  </TableCell>
                  <TableCell>{getPerformerDisplay(entry.performedBy)}</TableCell>
                  <TableCell>{getReasonDisplay(entry)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>
    </div>
  );
}
