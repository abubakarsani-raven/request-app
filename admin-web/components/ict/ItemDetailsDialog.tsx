"use client";

import { useQuery } from "@tanstack/react-query";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { ItemDetailsContent, type ICTItemForDetails, type StockHistoryEntry } from "./ItemDetailsContent";

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
  const { data: item, isLoading: isLoadingItem } = useQuery<ICTItemForDetails>({
    queryKey: ["ict-item", itemId],
    queryFn: () => fetchJSON<ICTItemForDetails>(`/api/ict/items/${itemId}`),
    enabled: open && !!itemId,
  });

  const { data: historyRaw = [], isLoading: isLoadingHistory } = useQuery<StockHistoryEntry[]>({
    queryKey: ["ict-stock-history", itemId],
    queryFn: () => fetchJSON<StockHistoryEntry[]>(`/api/ict/items/${itemId}/history`),
    enabled: open && !!itemId,
  });

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-7xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {isLoadingItem ? (
              <Skeleton className="h-6 w-64" />
            ) : (
              `Item Details – ${item?.name || "Loading..."}`
            )}
          </DialogTitle>
        </DialogHeader>
        <ItemDetailsContent
          item={item}
          historyRaw={historyRaw}
          isLoadingItem={isLoadingItem}
          isLoadingHistory={isLoadingHistory}
        />
      </DialogContent>
    </Dialog>
  );
}
