"use client";

import { useQuery } from "@tanstack/react-query";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";

type ICTItem = {
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

type StockHistory = {
  _id: string;
  previousQuantity: number;
  newQuantity: number;
  changeAmount: number;
  operation: string;
  reason?: string;
  performedBy: { name: string; email: string } | string;
  requestId?: string;
  createdAt: string;
};

type ItemDetailsDialogProps = {
  open: boolean;
  itemId: string;
  onClose: () => void;
};

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function ItemDetailsDialog({ open, itemId, onClose }: ItemDetailsDialogProps) {
  const { data: item, isLoading: isLoadingItem } = useQuery<ICTItem>({
    queryKey: ["ict-item", itemId],
    queryFn: () => fetchJSON<ICTItem>(`/api/ict/items/${itemId}`),
    enabled: open && !!itemId,
  });

  const { data: history = [], isLoading: isLoadingHistory } = useQuery<StockHistory[]>({
    queryKey: ["ict-stock-history", itemId],
    queryFn: () => fetchJSON<StockHistory[]>(`/api/ict/items/${itemId}/history`),
    enabled: open && !!itemId,
  });

  function getOperationBadge(operation: string) {
    const variants: Record<string, "default" | "destructive" | "secondary"> = {
      ADD: "default",
      REMOVE: "destructive",
      ADJUST: "secondary",
      FULFILLMENT: "destructive",
      RETURN: "default",
    };
    return (
      <Badge variant={variants[operation] || "secondary"}>{operation}</Badge>
    );
  }

  function formatDate(dateString: string) {
    return new Date(dateString).toLocaleString();
  }

  function getUserName(performedBy: StockHistory["performedBy"]) {
    if (typeof performedBy === "object" && performedBy !== null) {
      return performedBy.name || performedBy.email || "Unknown";
    }
    return "Unknown";
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-7xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {isLoadingItem ? (
              <Skeleton className="h-6 w-64" />
            ) : (
              `Item Details - ${item?.name || "Loading..."}`
            )}
          </DialogTitle>
        </DialogHeader>

        {isLoadingItem ? (
          <div className="space-y-4">
            <Skeleton className="h-32 w-full" />
            <Skeleton className="h-32 w-full" />
          </div>
        ) : item ? (
          <>
            {/* Item Details Section */}
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

              <Separator />

              {/* Stock History Section */}
              <div>
                <h3 className="text-lg font-semibold mb-3">Stock History</h3>
                {isLoadingHistory ? (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Date</TableHead>
                        <TableHead>Operation</TableHead>
                        <TableHead>Previous</TableHead>
                        <TableHead>New</TableHead>
                        <TableHead>Change</TableHead>
                        <TableHead>Performed By</TableHead>
                        <TableHead>Reason</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      <SkeletonTableRows rows={5} cols={7} />
                    </TableBody>
                  </Table>
                ) : history.length === 0 ? (
                  <p className="text-center text-muted-foreground py-8">No stock history available</p>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Date</TableHead>
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
                          <TableCell>{formatDate(entry.createdAt)}</TableCell>
                          <TableCell>{getOperationBadge(entry.operation)}</TableCell>
                          <TableCell>{entry.previousQuantity}</TableCell>
                          <TableCell>{entry.newQuantity}</TableCell>
                          <TableCell>
                            <span className={entry.changeAmount >= 0 ? "text-green-600" : "text-red-600"}>
                              {entry.changeAmount >= 0 ? "+" : ""}
                              {entry.changeAmount}
                            </span>
                          </TableCell>
                          <TableCell>{getUserName(entry.performedBy)}</TableCell>
                          <TableCell>{entry.reason || "-"}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                )}
              </div>
            </div>
          </>
        ) : (
          <p className="text-center text-muted-foreground py-8">Failed to load item details</p>
        )}
      </DialogContent>
    </Dialog>
  );
}
