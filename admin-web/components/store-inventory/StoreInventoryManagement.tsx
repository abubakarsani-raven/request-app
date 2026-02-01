"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Plus, Search, Package, AlertTriangle, History, Edit, Trash2 } from "lucide-react";
import { useToast } from "@/components/ui/use-toast";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";
import { StoreItemForm } from "./StoreItemForm";
import { UpdateQuantityModal } from "./UpdateQuantityModal";
import { StockHistoryModal } from "./StockHistoryModal";
import { LowStockAlert } from "./LowStockAlert";
import { BulkImportModal } from "./BulkImportModal";

type StoreItem = {
  _id?: string;
  id?: string;
  name: string;
  description?: string;
  category: string;
  quantity: number;
  isAvailable: boolean;
  lowStockThreshold?: number;
};

function getItemId(item: StoreItem): string {
  return item._id || item.id || "";
}

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function StoreInventoryManagement() {
  const qc = useQueryClient();
  const { success, error } = useToast();
  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");
  const [lowStockFilter, setLowStockFilter] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [editingItem, setEditingItem] = useState<StoreItem | null>(null);
  const [updatingQuantity, setUpdatingQuantity] = useState<StoreItem | null>(null);
  const [viewingHistory, setViewingHistory] = useState<StoreItem | null>(null);
  const [showBulkImport, setShowBulkImport] = useState(false);

  const { data: items = [], isLoading } = useQuery<StoreItem[]>({
    queryKey: ["store-items"],
    queryFn: () => fetchJSON<StoreItem[]>("/api/store-inventory"),
  });

  const { data: lowStockItems = [] } = useQuery<StoreItem[]>({
    queryKey: ["store-items-low-stock"],
    queryFn: () => fetchJSON<StoreItem[]>("/api/store-inventory/low-stock/all"),
  });

  const categories = Array.from(new Set(items.map((item) => item.category))).sort();

  const filtered = items.filter((item) => {
    const matchesSearch =
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.category.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = categoryFilter === "all" || item.category === categoryFilter;
    const matchesLowStock = !lowStockFilter || item.quantity <= (item.lowStockThreshold || 5);
    return matchesSearch && matchesCategory && matchesLowStock;
  });

  async function handleDelete(id: string) {
    if (!confirm("Are you sure you want to delete this item?")) return;
    try {
      const res = await fetch(`/api/store-inventory/${id}`, { method: "DELETE" });
      if (res.ok) {
        success("Item deleted successfully");
        qc.invalidateQueries({ queryKey: ["store-items"] });
      } else {
        const data = await res.json();
        error(data.message || "Failed to delete item");
      }
    } catch (err) {
      error("Failed to delete item");
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Store Inventory</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Manage store items and stock levels
          </p>
        </div>
        <div className="flex gap-2">
          <Button onClick={() => setShowBulkImport(true)} variant="outline">
            <Package className="mr-2 h-4 w-4" />
            Bulk Import
          </Button>
          <Button onClick={() => setShowCreate(true)}>
            <Plus className="mr-2 h-4 w-4" />
            Add Item
          </Button>
        </div>
      </div>

      {lowStockItems.length > 0 && (
        <LowStockAlert items={lowStockItems} itemType="store" />
      )}

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <CardTitle>Store Items</CardTitle>
            <div className="flex flex-col gap-2 md:flex-row">
              <div className="relative">
                <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search items..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-8 w-full md:w-[250px]"
                />
              </div>
              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="px-3 py-2 border rounded-md"
              >
                <option value="all">All Categories</option>
                {categories.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
              <Button
                variant={lowStockFilter ? "default" : "outline"}
                onClick={() => setLowStockFilter(!lowStockFilter)}
              >
                <AlertTriangle className="mr-2 h-4 w-4" />
                Low Stock
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Quantity</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <SkeletonTableRows rows={5} cols={5} />
              </TableBody>
            </Table>
          ) : filtered.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">No items found</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Quantity</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.map((item) => {
                  const itemId = getItemId(item);
                  const isLowStock = item.quantity <= (item.lowStockThreshold || 5);
                  return (
                    <TableRow key={itemId}>
                      <TableCell className="font-medium">{item.name}</TableCell>
                      <TableCell>{item.category}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          {item.quantity}
                          {isLowStock && (
                            <Badge variant="destructive" className="text-xs">
                              Low Stock
                            </Badge>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={item.isAvailable ? "default" : "secondary"}>
                          {item.isAvailable ? "Available" : "Unavailable"}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setUpdatingQuantity(item)}
                          >
                            Edit Qty
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setViewingHistory(item)}
                          >
                            <History className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setEditingItem(item)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleDelete(itemId)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {showCreate && (
        <StoreItemForm
          open={showCreate}
          onClose={() => {
            setShowCreate(false);
            qc.invalidateQueries({ queryKey: ["store-items"] });
          }}
        />
      )}

      {editingItem && (
        <StoreItemForm
          open={!!editingItem}
          item={editingItem}
          onClose={() => {
            setEditingItem(null);
            qc.invalidateQueries({ queryKey: ["store-items"] });
          }}
        />
      )}

      {updatingQuantity && (
        <UpdateQuantityModal
          open={!!updatingQuantity}
          item={updatingQuantity}
          onClose={() => {
            setUpdatingQuantity(null);
            qc.invalidateQueries({ queryKey: ["store-items"] });
          }}
        />
      )}

      {viewingHistory && (
        <StockHistoryModal
          open={!!viewingHistory}
          itemId={getItemId(viewingHistory)}
          onClose={() => setViewingHistory(null)}
        />
      )}

      {showBulkImport && (
        <BulkImportModal
          open={showBulkImport}
          onClose={() => {
            setShowBulkImport(false);
            qc.invalidateQueries({ queryKey: ["store-items"] });
          }}
        />
      )}
    </div>
  );
}
