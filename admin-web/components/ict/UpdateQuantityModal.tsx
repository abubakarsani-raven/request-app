"use client";

import { useState, useEffect } from "react";
import { useQueryClient, useQuery } from "@tanstack/react-query";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/ui/use-toast";
import { Printer } from "lucide-react";

type ICTItem = {
  _id?: string;
  id?: string;
  name: string;
  quantity: number;
};

type Supplier = {
  _id: string;
  referenceNumber: string;
  name: string;
  contactEmail?: string;
  contactPhone?: string;
};

type SupplyCreated = {
  supplyReferenceNumber: string;
  supplyId: string;
  itemName: string;
  quantity: number;
  supplier?: string;
  supplierReferenceNumber?: string;
};

type UpdateQuantityModalProps = {
  open: boolean;
  item: ICTItem;
  onClose: () => void;
};

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to fetch");
  return res.json();
}

export function UpdateQuantityModal({ open, item, onClose }: UpdateQuantityModalProps) {
  const { success, error } = useToast();
  const queryClient = useQueryClient();
  const [operation, setOperation] = useState<"ADD" | "REMOVE" | "ADJUST">("ADD");
  const [quantity, setQuantity] = useState("");
  const [reason, setReason] = useState("");
  const [supplierId, setSupplierId] = useState("");
  const [supplier, setSupplier] = useState("");
  const [supplierContact, setSupplierContact] = useState("");
  const [cost, setCost] = useState("");
  const [reference, setReference] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [createdSupply, setCreatedSupply] = useState<SupplyCreated | null>(null);

  const { data: suppliers = [] } = useQuery<Supplier[]>({
    queryKey: ["ict-suppliers"],
    queryFn: () => fetchJSON<Supplier[]>("/api/ict/suppliers"),
    enabled: open,
  });

  useEffect(() => {
    if (open) {
      setOperation("ADD");
      setQuantity("");
      setReason("");
      setSupplierId("");
      setSupplier("");
      setSupplierContact("");
      setCost("");
      setReference("");
      setCreatedSupply(null);
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
        if (supplierId) payload.supplierId = supplierId;
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

      const data = res.ok
        ? (await res.json()) as { item?: unknown; supply?: SupplyCreated }
        : null;

      if (res.ok) {
        if (operation === "ADD" && data?.supply) {
          setCreatedSupply(data.supply);
          success(`Supply recorded. Reference: ${data.supply.supplyReferenceNumber}`);
        } else {
          success("Quantity updated successfully");
          queryClient.invalidateQueries({ queryKey: ["ict-items"] });
          queryClient.invalidateQueries({ queryKey: ["ict-items-low-stock"] });
          queryClient.invalidateQueries({ queryKey: ["ict-stock-history", item._id] });
          queryClient.invalidateQueries({ queryKey: ["ict-item-supplies", item._id] });
          onClose();
        }
        queryClient.invalidateQueries({ queryKey: ["ict-items"] });
        queryClient.invalidateQueries({ queryKey: ["ict-items-low-stock"] });
        queryClient.invalidateQueries({ queryKey: ["ict-stock-history", item._id] });
        queryClient.invalidateQueries({ queryKey: ["ict-item-supplies", item._id] });
        if (!data?.supply) onClose();
      } else {
        const err = await res.json();
        error(err.message || "Failed to update quantity");
      }
    } catch (err) {
      error("Failed to update quantity");
    } finally {
      setIsSubmitting(false);
    }
  }

  function printSupplyReference() {
    if (!createdSupply) return;
    const w = window.open("", "_blank", "width=400,height=500");
    if (!w) return;
    w.document.write(`
      <!DOCTYPE html><html><head><title>Supply ${createdSupply.supplyReferenceNumber}</title>
      <style>body{font-family:sans-serif;padding:24px;max-width:360px;} .ref{font-size:1.5rem;font-weight:bold;margin:12px 0;} .row{margin:8px 0;} .label{color:#666;font-size:0.85rem;}</style></head><body>
      <h2>Supply Reference</h2>
      <div class="ref">${createdSupply.supplyReferenceNumber}</div>
      <div class="row"><span class="label">Item</span><br/>${createdSupply.itemName}</div>
      <div class="row"><span class="label">Quantity</span><br/>${createdSupply.quantity}</div>
      ${createdSupply.supplier ? `<div class="row"><span class="label">Supplier</span><br/>${createdSupply.supplier}${createdSupply.supplierReferenceNumber ? ` (${createdSupply.supplierReferenceNumber})` : ""}</div>` : ""}
      <div class="row"><span class="label">Date</span><br/>${new Date().toLocaleString()}</div>
      <p style="margin-top:24px;font-size:0.8rem;color:#888;">Use this reference for records and identification.</p>
      </body></html>
    `);
    w.document.close();
    w.focus();
    setTimeout(() => {
      w.print();
      w.close();
    }, 250);
  }

  const showCreatedSupply = createdSupply && operation === "ADD";

  return (
    <Dialog open={open} onOpenChange={(o) => { if (!o) { setCreatedSupply(null); onClose(); } }}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {showCreatedSupply ? "Supply recorded" : `Update Quantity - ${item.name}`}
          </DialogTitle>
        </DialogHeader>
        {showCreatedSupply ? (
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Supply reference number (use for identification and printing):
            </p>
            <div className="rounded-lg border bg-muted/50 p-4 font-mono text-lg font-semibold">
              {createdSupply.supplyReferenceNumber}
            </div>
            <div className="grid gap-2 text-sm">
              <div><span className="text-muted-foreground">Item:</span> {createdSupply.itemName}</div>
              <div><span className="text-muted-foreground">Quantity:</span> +{createdSupply.quantity}</div>
              {createdSupply.supplier && (
                <div>
                  <span className="text-muted-foreground">Supplier:</span> {createdSupply.supplier}
                  {createdSupply.supplierReferenceNumber && (
                    <span className="ml-1 text-muted-foreground">({createdSupply.supplierReferenceNumber})</span>
                  )}
                </div>
              )}
            </div>
            <div className="flex flex-wrap gap-2">
              <Button type="button" onClick={printSupplyReference} variant="default">
                <Printer className="mr-2 h-4 w-4" />
                Print reference
              </Button>
              <Button type="button" variant="outline" onClick={() => { setCreatedSupply(null); onClose(); }}>
                Done
              </Button>
            </div>
          </div>
        ) : (
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
                Record this stock as a supply (optional). Each supplier has a reference number for identification.
              </p>
              <div className="grid gap-2 sm:grid-cols-2">
                <div className="sm:col-span-2">
                  <Label htmlFor="supplierSelect">Supplier (by reference)</Label>
                  <select
                    id="supplierSelect"
                    value={supplierId}
                    onChange={(e) => {
                      const id = e.target.value;
                      setSupplierId(id);
                      if (id) {
                        const s = suppliers.find((x) => x._id === id);
                        if (s) {
                          setSupplier(s.name);
                          setSupplierContact(s.contactEmail || s.contactPhone || "");
                        }
                      } else {
                        setSupplier("");
                        setSupplierContact("");
                      }
                    }}
                    className="w-full h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
                  >
                    <option value="">— Other / type below —</option>
                    {suppliers.map((s) => (
                      <option key={s._id} value={s._id}>
                        {s.referenceNumber} — {s.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <Label htmlFor="supplier">Supplier name</Label>
                  <Input
                    id="supplier"
                    value={supplier}
                    onChange={(e) => setSupplier(e.target.value)}
                    placeholder="Name (or from list above)"
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
        )}
      </DialogContent>
    </Dialog>
  );
}

