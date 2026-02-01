"use client";

import { useQuery } from "@tanstack/react-query";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";

type DepartmentRef = { name: string };
type PerformerRef = { name: string; email?: string; departmentId?: DepartmentRef };
type RequesterRef = { name: string; departmentId?: DepartmentRef };
type RequestRef = { _id?: string; requesterId?: RequesterRef };

type StockHistory = {
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

function getPerformerDisplay(performedBy: StockHistory["performedBy"]): string {
  if (typeof performedBy !== "object" || performedBy === null) return "Unknown";
  const name = performedBy.name || (performedBy as PerformerRef).email || "Unknown";
  const dept = (performedBy as PerformerRef).departmentId?.name;
  return dept ? `${name} (${dept})` : name;
}

function getReasonDisplay(entry: StockHistory): string {
  if (entry.operation === "FULFILLMENT" && entry.requestId && typeof entry.requestId === "object") {
    const req = entry.requestId as RequestRef;
    const requester = req?.requesterId;
    if (requester?.name) {
      const dept = requester.departmentId?.name;
      return dept ? `Fulfilled request by ${requester.name} (${dept})` : `Fulfilled request by ${requester.name}`;
    }
  }
  return entry.reason || "-";
}

type StockHistoryModalProps = {
  open: boolean;
  itemId: string;
  onClose: () => void;
};

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function StockHistoryModal({ open, itemId, onClose }: StockHistoryModalProps) {
  const { data: history = [], isLoading } = useQuery<StockHistory[]>({
    queryKey: ["store-stock-history", itemId],
    queryFn: () => fetchJSON<StockHistory[]>(`/api/store-inventory/${itemId}/history`),
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

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-7xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Stock History</DialogTitle>
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
                <TableHead>Reason</TableHead>
                <TableHead>Performed By</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <SkeletonTableRows rows={5} cols={7} />
            </TableBody>
          </Table>
        ) : history.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">No history available</div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Date</TableHead>
                <TableHead>Operation</TableHead>
                <TableHead>Previous</TableHead>
                <TableHead>New</TableHead>
                <TableHead>Change</TableHead>
                <TableHead>Reason</TableHead>
                <TableHead>Performed By</TableHead>
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
                      {entry.changeAmount >= 0 ? "+" : ""}{entry.changeAmount}
                    </span>
                  </TableCell>
                  <TableCell>{getReasonDisplay(entry)}</TableCell>
                  <TableCell>{getPerformerDisplay(entry.performedBy)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </DialogContent>
    </Dialog>
  );
}
