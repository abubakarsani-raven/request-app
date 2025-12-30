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
import { ItemForm } from "@/components/ict/ItemForm";
import { UpdateQuantityModal } from "@/components/ict/UpdateQuantityModal";
import { StockHistoryModal } from "@/components/ict/StockHistoryModal";
import { LowStockAlert } from "@/components/ict/LowStockAlert";
import { BulkImportModal } from "@/components/ict/BulkImportModal";

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

// Helper to get item ID (handles both _id and id)
function getItemId(item: ICTItem): string {
  return item._id || item.id || '';
}

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export default function ICTInventoryPage() {
  const qc = useQueryClient();
  const { success, error } = useToast();
  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");
  const [lowStockFilter, setLowStockFilter] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [editingItem, setEditingItem] = useState<ICTItem | null>(null);
  const [updatingQuantity, setUpdatingQuantity] = useState<ICTItem | null>(null);
  const [viewingHistory, setViewingHistory] = useState<ICTItem | null>(null);
  const [showBulkImport, setShowBulkImport] = useState(false);

  const { data: items = [], isLoading } = useQuery<ICTItem[]>({
    queryKey: ["ict-items"],
    queryFn: () => fetchJSON<ICTItem[]>("/api/ict/items"),
  });

  const { data: lowStockItems = [] } = useQuery<ICTItem[]>({
    queryKey: ["ict-items-low-stock"],
    queryFn: () => fetchJSON<ICTItem[]>("/api/ict/items/low-stock/all"),
  });

  const categories = Array.from(new Set(items.map((item) => item.category))).sort();

  const filtered = items.filter((item) => {
    const matchesSearch =
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.brand?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.sku?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.category.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = categoryFilter === "all" || item.category === categoryFilter;
    const matchesLowStock = !lowStockFilter || item.quantity <= item.lowStockThreshold;
    return matchesSearch && matchesCategory && matchesLowStock;
  });

  async function handleDelete(id: string) {
    if (!confirm("Are you sure you want to delete this item?")) return;
    try {
      const res = await fetch(`/api/ict/items/${id}`, { method: "DELETE" });
      if (res.ok) {
        success("Item deleted successfully");
        qc.invalidateQueries({ queryKey: ["ict-items"] });
      } else {
        const data = await res.json();
        error(data.message || "Failed to delete item");
      }
    } catch (err) {
      error("Failed to delete item");
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">ICT Inventory Management</h1>
          <p className="text-muted-foreground">Manage ICT items, stock levels, and inventory</p>
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
        <LowStockAlert items={lowStockItems} />
      )}

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>ICT Items</CardTitle>
            <div className="flex gap-2">
              <div className="relative">
                <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search items..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-8 w-64"
                />
              </div>
              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
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
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Brand</TableHead>
                <TableHead>SKU</TableHead>
                <TableHead>Quantity</TableHead>
                <TableHead>Unit</TableHead>
                <TableHead>Location</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <SkeletonTableRows rows={5} cols={9} />
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={9} className="text-center text-muted-foreground">
                    No items found
                  </TableCell>
                </TableRow>
              ) : (
                filtered.map((item) => {
                  const isLowStock = item.quantity <= item.lowStockThreshold;
                  const itemId = getItemId(item);
                  return (
                    <TableRow key={itemId}>
                      <TableCell className="font-medium">{item.name}</TableCell>
                      <TableCell>{item.category}</TableCell>
                      <TableCell>{item.brand || "-"}</TableCell>
                      <TableCell>{item.sku || "-"}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <span>{item.quantity}</span>
                          {isLowStock && (
                            <Badge variant="destructive" className="text-xs">
                              Low
                            </Badge>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>{item.unit}</TableCell>
                      <TableCell>{item.location || "-"}</TableCell>
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
                            onClick={() => {
                              if (!itemId) {
                                error("Item ID is missing");
                                return;
                              }
                              setEditingItem({ ...item, _id: itemId });
                            }}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              if (!itemId) {
                                error("Item ID is missing");
                                return;
                              }
                              setUpdatingQuantity({ ...item, _id: itemId });
                            }}
                          >
                            <Package className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              if (!itemId) {
                                error("Item ID is missing");
                                return;
                              }
                              setViewingHistory({ ...item, _id: itemId });
                            }}
                          >
                            <History className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleDelete(itemId)}
                          >
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
            </Table>
        </CardContent>
      </Card>

      {showCreate && (
        <ItemForm
          open={showCreate}
          onClose={() => {
            setShowCreate(false);
            qc.invalidateQueries({ queryKey: ["ict-items"] });
          }}
        />
      )}

      {editingItem && (
        <ItemForm
          open={!!editingItem}
          item={editingItem}
          onClose={() => {
            setEditingItem(null);
            qc.invalidateQueries({ queryKey: ["ict-items"] });
          }}
        />
      )}

      {updatingQuantity && (
        <UpdateQuantityModal
          open={!!updatingQuantity}
          item={updatingQuantity}
          onClose={() => {
            setUpdatingQuantity(null);
            // Queries are already invalidated in the modal after successful update
          }}
        />
      )}

      {viewingHistory && (
        <StockHistoryModal
          open={!!viewingHistory}
          item={viewingHistory}
          onClose={() => setViewingHistory(null)}
        />
      )}

      {showBulkImport && (
        <BulkImportModal
          open={showBulkImport}
          onClose={() => {
            setShowBulkImport(false);
            qc.invalidateQueries({ queryKey: ["ict-items"] });
          }}
        />
      )}
    </div>
  );
}

