"use client";

import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/ui/use-toast";

type StoreItem = {
  _id?: string;
  id?: string;
  name: string;
  description?: string;
  category: string;
  quantity?: number;
  isAvailable?: boolean;
  lowStockThreshold?: number;
};

type StoreItemFormProps = {
  open: boolean;
  item?: StoreItem | null;
  onClose: () => void;
};

const COMMON_CATEGORIES = [
  "Office Supplies",
  "Cleaning Supplies",
  "Stationery",
  "Furniture",
  "Equipment",
  "Other",
];

export function StoreItemForm({ open, item, onClose }: StoreItemFormProps) {
  const { success, error } = useToast();
  const [form, setForm] = useState({
    name: "",
    description: "",
    category: "",
    quantity: 0,
    isAvailable: true,
    lowStockThreshold: 5,
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (item) {
      setForm({
        name: item.name || "",
        description: item.description || "",
        category: item.category || "",
        quantity: item.quantity || 0,
        isAvailable: item.isAvailable ?? true,
        lowStockThreshold: item.lowStockThreshold || 5,
      });
    } else {
      setForm({
        name: "",
        description: "",
        category: "",
        quantity: 0,
        isAvailable: true,
        lowStockThreshold: 5,
      });
    }
  }, [item, open]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name || !form.category) {
      error("Name and category are required");
      return;
    }

    setIsSubmitting(true);
    try {
      const itemId = item?._id || item?.id;
      const url = itemId ? `/api/store-inventory/${itemId}` : "/api/store-inventory";
      const method = itemId ? "PUT" : "POST";

      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });

      if (res.ok) {
        success(itemId ? "Item updated successfully" : "Item created successfully");
        onClose();
      } else {
        const data = await res.json();
        error(data.message || "Failed to save item");
      }
    } catch (err) {
      error("Failed to save item");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{item ? "Edit Store Item" : "Create Store Item"}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="name">Name *</Label>
            <Input
              id="name"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              required
            />
          </div>

          <div>
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              rows={3}
            />
          </div>

          <div>
            <Label htmlFor="category">Category *</Label>
            <select
              id="category"
              value={form.category}
              onChange={(e) => setForm({ ...form, category: e.target.value })}
              className="w-full px-3 py-2 border rounded-md"
              required
            >
              <option value="">Select category</option>
              {COMMON_CATEGORIES.map((cat) => (
                <option key={cat} value={cat}>
                  {cat}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="quantity">Initial Quantity</Label>
              <Input
                id="quantity"
                type="number"
                min="0"
                value={form.quantity}
                onChange={(e) => setForm({ ...form, quantity: parseInt(e.target.value) || 0 })}
              />
            </div>

            <div>
              <Label htmlFor="lowStockThreshold">Low Stock Threshold</Label>
              <Input
                id="lowStockThreshold"
                type="number"
                min="0"
                value={form.lowStockThreshold}
                onChange={(e) => setForm({ ...form, lowStockThreshold: parseInt(e.target.value) || 5 })}
              />
            </div>
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="isAvailable"
              checked={form.isAvailable}
              onChange={(e) => setForm({ ...form, isAvailable: e.target.checked })}
              className="h-4 w-4"
            />
            <Label htmlFor="isAvailable">Item is available</Label>
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? "Saving..." : item ? "Update" : "Create"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
