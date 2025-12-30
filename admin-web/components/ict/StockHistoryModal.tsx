"use client";

import { useQuery } from "@tanstack/react-query";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";

type ICTItem = {
  _id: string;
  name: string;
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

type StockHistoryModalProps = {
  open: boolean;
  item: ICTItem;
  onClose: () => void;
};

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function StockHistoryModal({ open, item, onClose }: StockHistoryModalProps) {
  const { data: history = [], isLoading } = useQuery<StockHistory[]>({
    queryKey: ["ict-stock-history", item?._id],
    queryFn: () => {
      if (!item?._id) {
        throw new Error("Item ID is required");
      }
      return fetchJSON<StockHistory[]>(`/api/ict/items/${item._id}/history`);
    },
    enabled: open && !!item?._id,
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
          <DialogTitle>Stock History - {item.name}</DialogTitle>
        </DialogHeader>
        {isLoading ? (
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
      </DialogContent>
    </Dialog>
  );
}

