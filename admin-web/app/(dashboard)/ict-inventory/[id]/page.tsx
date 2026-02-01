"use client";

import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { useParams } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft } from "lucide-react";
import { ItemDetailsContent, type ICTItemForDetails, type StockHistoryEntry } from "@/components/ict/ItemDetailsContent";

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export default function ICTItemDetailsPage() {
  const params = useParams();
  const id = typeof params.id === "string" ? params.id : "";

  const { data: item, isLoading: isLoadingItem } = useQuery<ICTItemForDetails>({
    queryKey: ["ict-item", id],
    queryFn: () => fetchJSON<ICTItemForDetails>(`/api/ict/items/${id}`),
    enabled: !!id,
  });

  const { data: historyRaw = [], isLoading: isLoadingHistory } = useQuery<StockHistoryEntry[]>({
    queryKey: ["ict-stock-history", id],
    queryFn: () => fetchJSON<StockHistoryEntry[]>(`/api/ict/items/${id}/history`),
    enabled: !!id,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/ict-inventory">
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back to ICT Inventory
          </Link>
        </Button>
      </div>
      <div>
        <h1 className="text-2xl font-semibold">
          {isLoadingItem ? (
            <Skeleton className="h-8 w-64" />
          ) : (
            `Item Details – ${item?.name ?? "Not found"}`
          )}
        </h1>
      </div>
      <ItemDetailsContent
        item={item}
        historyRaw={historyRaw}
        isLoadingItem={isLoadingItem}
        isLoadingHistory={isLoadingHistory}
      />
    </div>
  );
}
