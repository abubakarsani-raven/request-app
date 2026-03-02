"use client";

import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useToast } from "@/components/ui/use-toast";
import { Building2, Plus, Printer } from "lucide-react";

type Supplier = {
  _id: string;
  referenceNumber: string;
  name: string;
  contactEmail?: string;
  contactPhone?: string;
  address?: string;
};

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to fetch");
  return res.json();
}

export default function SuppliersPage() {
  const { success, error } = useToast();
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [contactEmail, setContactEmail] = useState("");
  const [contactPhone, setContactPhone] = useState("");
  const [address, setAddress] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [createdSupplier, setCreatedSupplier] = useState<Supplier | null>(null);

  const { data: suppliers = [], isLoading } = useQuery<Supplier[]>({
    queryKey: ["ict-suppliers"],
    queryFn: () => fetchJSON<Supplier[]>("/api/ict/suppliers"),
  });

  async function handleCreate() {
    if (!name.trim()) {
      error("Supplier name is required");
      return;
    }
    setIsSubmitting(true);
    try {
      const res = await fetch("/api/ict/suppliers", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: name.trim(),
          contactEmail: contactEmail.trim() || undefined,
          contactPhone: contactPhone.trim() || undefined,
          address: address.trim() || undefined,
        }),
      });
      if (!res.ok) {
        const e = await res.json();
        throw new Error(e.message || "Failed to create supplier");
      }
      const created = await res.json();
      setCreatedSupplier(created);
      success(`Supplier created. Reference: ${created.referenceNumber}`);
      queryClient.invalidateQueries({ queryKey: ["ict-suppliers"] });
    } catch (err: unknown) {
      error(err instanceof Error ? err.message : "Failed to create supplier");
    } finally {
      setIsSubmitting(false);
    }
  }

  function printSupplierRef(supplier: Supplier) {
    const w = window.open("", "_blank", "width=400,height=420");
    if (!w) return;
    w.document.write(`
      <!DOCTYPE html><html><head><title>Supplier ${supplier.referenceNumber}</title>
      <style>body{font-family:sans-serif;padding:24px;max-width:360px;} .ref{font-size:1.5rem;font-weight:bold;margin:12px 0;} .row{margin:8px 0;} .label{color:#666;font-size:0.85rem;}</style></head><body>
      <h2>Supplier Reference</h2>
      <div class="ref">${supplier.referenceNumber}</div>
      <div class="row"><span class="label">Name</span><br/>${supplier.name}</div>
      ${supplier.contactEmail ? `<div class="row"><span class="label">Email</span><br/>${supplier.contactEmail}</div>` : ""}
      ${supplier.contactPhone ? `<div class="row"><span class="label">Phone</span><br/>${supplier.contactPhone}</div>` : ""}
      <p style="margin-top:24px;font-size:0.8rem;color:#888;">Use this reference when recording supplies.</p>
      </body></html>
    `);
    w.document.close();
    w.focus();
    setTimeout(() => { w.print(); w.close(); }, 250);
  }

  const showCreated = createdSupplier && open;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Suppliers</h1>
        <p className="text-muted-foreground">
          Manage suppliers and their reference numbers for identification and printing.
        </p>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Building2 className="h-5 w-5" />
            Supplier list
          </CardTitle>
          <Button onClick={() => { setOpen(true); setCreatedSupplier(null); setName(""); setContactEmail(""); setContactPhone(""); setAddress(""); }}>
            <Plus className="mr-2 h-4 w-4" />
            Add supplier
          </Button>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <p className="text-muted-foreground">Loading...</p>
          ) : suppliers.length === 0 ? (
            <p className="text-muted-foreground">
              No suppliers yet. Add one to get a reference number for use when recording supplies.
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Reference</TableHead>
                  <TableHead>Name</TableHead>
                  <TableHead>Contact</TableHead>
                  <TableHead className="w-[100px]">Print</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {suppliers.map((s) => (
                  <TableRow key={s._id}>
                    <TableCell className="font-mono font-medium">{s.referenceNumber}</TableCell>
                    <TableCell>{s.name}</TableCell>
                    <TableCell className="text-muted-foreground text-sm">
                      {s.contactEmail || s.contactPhone || "—"}
                    </TableCell>
                    <TableCell>
                      <Button variant="ghost" size="sm" onClick={() => printSupplierRef(s)}>
                        <Printer className="h-4 w-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <Dialog open={open} onOpenChange={(o) => { if (!o) { setCreatedSupplier(null); setOpen(false); } }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{showCreated ? "Supplier created" : "Add supplier"}</DialogTitle>
          </DialogHeader>
          {showCreated ? (
            <div className="space-y-4">
              <p className="text-sm text-muted-foreground">Reference number (use when recording supplies):</p>
              <div className="rounded-lg border bg-muted/50 p-4 font-mono text-lg font-semibold">
                {createdSupplier.referenceNumber}
              </div>
              <div className="text-sm">
                <span className="text-muted-foreground">Name:</span> {createdSupplier.name}
              </div>
              <div className="flex gap-2">
                <Button type="button" onClick={() => printSupplierRef(createdSupplier)}>
                  <Printer className="mr-2 h-4 w-4" />
                  Print reference
                </Button>
                <Button type="button" variant="outline" onClick={() => { setCreatedSupplier(null); setOpen(false); }}>
                  Done
                </Button>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <div>
                <Label htmlFor="name">Name *</Label>
                <Input
                  id="name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Supplier name"
                />
              </div>
              <div>
                <Label htmlFor="contactEmail">Email</Label>
                <Input
                  id="contactEmail"
                  type="email"
                  value={contactEmail}
                  onChange={(e) => setContactEmail(e.target.value)}
                  placeholder="Email"
                />
              </div>
              <div>
                <Label htmlFor="contactPhone">Phone</Label>
                <Input
                  id="contactPhone"
                  value={contactPhone}
                  onChange={(e) => setContactPhone(e.target.value)}
                  placeholder="Phone"
                />
              </div>
              <div>
                <Label htmlFor="address">Address</Label>
                <Input
                  id="address"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Optional"
                />
              </div>
              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
                <Button onClick={handleCreate} disabled={isSubmitting}>
                  {isSubmitting ? "Creating..." : "Create"}
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
