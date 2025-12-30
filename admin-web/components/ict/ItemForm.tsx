"use client";

import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/ui/use-toast";

type ICTItem = {
  _id: string;
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

type ItemFormProps = {
  open: boolean;
  item?: ICTItem | null;
  onClose: () => void;
};

const COMMON_CATEGORIES = [
  "Toner/Cartridges",
  "Printers",
  "Cables",
  "Computer Accessories",
  "Network Equipment",
  "Storage Devices",
  "Monitors/Displays",
  "Other",
];

const COMMON_UNITS = ["pieces", "boxes", "packs", "units", "sets"];

export function ItemForm({ open, item, onClose }: ItemFormProps) {
  const { success, error } = useToast();
  const [form, setForm] = useState({
    name: "",
    description: "",
    category: "",
    quantity: 0,
    isAvailable: true,
    brand: "",
    model: "",
    sku: "",
    unit: "pieces",
    location: "",
    lowStockThreshold: 5,
    supplier: "",
    supplierContact: "",
    cost: "",
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
        brand: item.brand || "",
        model: item.model || "",
        sku: item.sku || "",
        unit: item.unit || "pieces",
        location: item.location || "",
        lowStockThreshold: item.lowStockThreshold || 5,
        supplier: item.supplier || "",
        supplierContact: item.supplierContact || "",
        cost: item.cost?.toString() || "",
      });
    } else {
      setForm({
        name: "",
        description: "",
        category: "",
        quantity: 0,
        isAvailable: true,
        brand: "",
        model: "",
        sku: "",
        unit: "pieces",
        location: "",
        lowStockThreshold: 5,
        supplier: "",
        supplierContact: "",
        cost: "",
      });
    }
  }, [item, open]);

  async function handleSubmit() {
    if (!form.name || !form.category) {
      error("Name and category are required");
      return;
    }

    setIsSubmitting(true);
    try {
      const payload: any = {
        name: form.name,
        description: form.description || undefined,
        category: form.category,
        quantity: Number(form.quantity) || 0,
        isAvailable: form.isAvailable,
        brand: form.brand || undefined,
        model: form.model || undefined,
        sku: form.sku || undefined,
        unit: form.unit,
        location: form.location || undefined,
        lowStockThreshold: Number(form.lowStockThreshold) || 5,
        supplier: form.supplier || undefined,
        supplierContact: form.supplierContact || undefined,
        cost: form.cost ? Number(form.cost) : undefined,
      };

      const url = item ? `/api/ict/items/${item._id}` : "/api/ict/items";
      const method = item ? "PUT" : "POST";

      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        success(item ? "Item updated successfully" : "Item created successfully");
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
          <DialogTitle>{item ? "Edit Item" : "Create New Item"}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="name">Name *</Label>
              <Input
                id="name"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="e.g., HP LaserJet Toner"
              />
            </div>
            <div>
              <Label htmlFor="category">Category *</Label>
              <select
                id="category"
                value={form.category}
                onChange={(e) => setForm({ ...form, category: e.target.value })}
                className="w-full h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
              >
                <option value="">Select category</option>
                {COMMON_CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              placeholder="Item description"
              rows={3}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="brand">Brand</Label>
              <Input
                id="brand"
                value={form.brand}
                onChange={(e) => setForm({ ...form, brand: e.target.value })}
                placeholder="e.g., HP, Canon"
              />
            </div>
            <div>
              <Label htmlFor="model">Model</Label>
              <Input
                id="model"
                value={form.model}
                onChange={(e) => setForm({ ...form, model: e.target.value })}
                placeholder="Model number"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="sku">SKU/Item Code</Label>
              <Input
                id="sku"
                value={form.sku}
                onChange={(e) => setForm({ ...form, sku: e.target.value })}
                placeholder="Stock Keeping Unit"
              />
            </div>
            <div>
              <Label htmlFor="unit">Unit</Label>
              <select
                id="unit"
                value={form.unit}
                onChange={(e) => setForm({ ...form, unit: e.target.value })}
                className="w-full h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
              >
                {COMMON_UNITS.map((unit) => (
                  <option key={unit} value={unit}>
                    {unit}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <Label htmlFor="quantity">Quantity</Label>
              <Input
                id="quantity"
                type="number"
                min="0"
                value={form.quantity}
                onChange={(e) => setForm({ ...form, quantity: Number(e.target.value) || 0 })}
              />
            </div>
            <div>
              <Label htmlFor="lowStockThreshold">Low Stock Threshold</Label>
              <Input
                id="lowStockThreshold"
                type="number"
                min="0"
                value={form.lowStockThreshold}
                onChange={(e) => setForm({ ...form, lowStockThreshold: Number(e.target.value) || 5 })}
              />
            </div>
            <div>
              <Label htmlFor="cost">Cost (per unit)</Label>
              <Input
                id="cost"
                type="number"
                min="0"
                step="0.01"
                value={form.cost}
                onChange={(e) => setForm({ ...form, cost: e.target.value })}
                placeholder="0.00"
              />
            </div>
          </div>

          <div>
            <Label htmlFor="location">Storage Location</Label>
            <Input
              id="location"
              value={form.location}
              onChange={(e) => setForm({ ...form, location: e.target.value })}
              placeholder="e.g., Warehouse A, Shelf 3"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="supplier">Supplier/Vendor</Label>
              <Input
                id="supplier"
                value={form.supplier}
                onChange={(e) => setForm({ ...form, supplier: e.target.value })}
                placeholder="Supplier name"
              />
            </div>
            <div>
              <Label htmlFor="supplierContact">Supplier Contact</Label>
              <Input
                id="supplierContact"
                value={form.supplierContact}
                onChange={(e) => setForm({ ...form, supplierContact: e.target.value })}
                placeholder="Phone or email"
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
            <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
              Cancel
            </Button>
            <Button onClick={handleSubmit} disabled={isSubmitting}>
              {isSubmitting ? "Saving..." : item ? "Update" : "Create"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

