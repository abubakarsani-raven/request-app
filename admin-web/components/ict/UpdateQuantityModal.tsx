"use client";

import { useState, useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/ui/use-toast";

type ICTItem = {
  _id?: string;
  id?: string;
  name: string;
  quantity: number;
};

type UpdateQuantityModalProps = {
  open: boolean;
  item: ICTItem;
  onClose: () => void;
};

export function UpdateQuantityModal({ open, item, onClose }: UpdateQuantityModalProps) {
  const { success, error } = useToast();
  const queryClient = useQueryClient();
  const [operation, setOperation] = useState<"ADD" | "REMOVE" | "ADJUST">("ADD");
  const [quantity, setQuantity] = useState("");
  const [reason, setReason] = useState("");
  const [supplier, setSupplier] = useState("");
  const [supplierContact, setSupplierContact] = useState("");
  const [cost, setCost] = useState("");
  const [reference, setReference] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (open) {
      setOperation("ADD");
      setQuantity("");
      setReason("");
      setSupplier("");
      setSupplierContact("");
      setCost("");
      setReference("");
    }
  }, [open]);

  async function handleSubmit() {
    if (!item?._id) {
      error("Item ID is missing");
      return;
    }

    const qty = Number(quantity);
    if (!quantity || isNaN(qty) || qty <= 0) {
      error("Please enter a valid quantity");
      return;
    }

    if (operation === "REMOVE" && qty > item.quantity) {
      error(`Cannot remove more than available quantity (${item.quantity})`);
      return;
    }

    setIsSubmitting(true);
    try {
      const payload: Record<string, unknown> = {
        quantity: qty,
        operation,
        reason: reason || undefined,
      };
      if (operation === "ADD") {
        if (supplier.trim()) payload.supplier = supplier.trim();
        if (supplierContact.trim()) payload.supplierContact = supplierContact.trim();
        const costNum = Number(cost);
        if (cost.trim() && !Number.isNaN(costNum)) payload.cost = costNum;
        if (reference.trim()) payload.reference = reference.trim();
      }

      const res = await fetch(`/api/ict/items/${item._id}/quantity`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        success("Quantity updated successfully");
        // Invalidate queries to refresh the table
        queryClient.invalidateQueries({ queryKey: ["ict-items"] });
        queryClient.invalidateQueries({ queryKey: ["ict-items-low-stock"] });
        queryClient.invalidateQueries({ queryKey: ["ict-stock-history", item._id] });
        queryClient.invalidateQueries({ queryKey: ["ict-item-supplies", item._id] });
        onClose();
      } else {
        const data = await res.json();
        error(data.message || "Failed to update quantity");
      }
    } catch (err) {
      error("Failed to update quantity");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Update Quantity - {item.name}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <Label>Current Quantity</Label>
            <Input value={item.quantity} disabled />
          </div>

          <div>
            <Label>Operation</Label>
            <select
              value={operation}
              onChange={(e) => setOperation(e.target.value as "ADD" | "REMOVE" | "ADJUST")}
              className="w-full h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
            >
              <option value="ADD">Add Stock</option>
              <option value="REMOVE">Remove Stock</option>
              <option value="ADJUST">Adjust to Value</option>
            </select>
          </div>

          <div>
            <Label>
              {operation === "ADJUST" ? "New Quantity" : "Quantity"}
            </Label>
            <Input
              type="number"
              min="0"
              value={quantity}
              onChange={(e) => setQuantity(e.target.value)}
              placeholder={operation === "ADJUST" ? "Enter new quantity" : "Enter quantity"}
            />
            {operation === "ADD" && quantity && (
              <p className="text-sm text-muted-foreground mt-1">
                New quantity will be: {item.quantity + Number(quantity) || 0}
              </p>
            )}
            {operation === "REMOVE" && quantity && (
              <p className="text-sm text-muted-foreground mt-1">
                New quantity will be: {Math.max(0, item.quantity - Number(quantity) || 0)}
              </p>
            )}
          </div>

          {operation === "ADD" && (
            <>
              <p className="text-sm text-muted-foreground">
                Record this stock as a supply (optional). Different suppliers can supply the same item.
              </p>
              <div className="grid gap-2 sm:grid-cols-2">
                <div>
                  <Label htmlFor="supplier">Supplier</Label>
                  <Input
                    id="supplier"
                    value={supplier}
                    onChange={(e) => setSupplier(e.target.value)}
                    placeholder="Supplier name"
                  />
                </div>
                <div>
                  <Label htmlFor="supplierContact">Supplier contact</Label>
                  <Input
                    id="supplierContact"
                    value={supplierContact}
                    onChange={(e) => setSupplierContact(e.target.value)}
                    placeholder="Email or phone"
                  />
                </div>
                <div>
                  <Label htmlFor="cost">Cost (optional)</Label>
                  <Input
                    id="cost"
                    type="number"
                    min="0"
                    step="0.01"
                    value={cost}
                    onChange={(e) => setCost(e.target.value)}
                    placeholder="0.00"
                  />
                </div>
                <div>
                  <Label htmlFor="reference">Reference (e.g. PO number)</Label>
                  <Input
                    id="reference"
                    value={reference}
                    onChange={(e) => setReference(e.target.value)}
                    placeholder="Optional"
                  />
                </div>
              </div>
            </>
          )}

          <div>
            <Label>Reason (Optional)</Label>
            <Textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Reason for this change"
              rows={3}
            />
          </div>

          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
              Cancel
            </Button>
            <Button onClick={handleSubmit} disabled={isSubmitting}>
              {isSubmitting ? "Updating..." : "Update"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

