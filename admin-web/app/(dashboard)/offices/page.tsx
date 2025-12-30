"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Plus, Pencil, Trash2 } from "lucide-react";
import { useToast } from "@/components/ui/use-toast";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";
import MapPicker from "@/components/MapPicker";

type Office = { 
  _id: string; 
  name: string; 
  address?: string;
  latitude: number;
  longitude: number;
  description?: string;
  isHeadOffice?: boolean;
};

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed");
  return res.json();
}

export default function OfficesPage() {
  const qc = useQueryClient();
  const { success, error } = useToast();

  const { data: offices = [], isLoading } = useQuery<Office[]>({ queryKey: ["offices"], queryFn: () => fetchJSON<Office[]>("/api/offices") });

  const [showCreate, setShowCreate] = useState(false);
  const [editingOffice, setEditingOffice] = useState<Office | null>(null);
  const [form, setForm] = useState({ 
    name: "", 
    address: "", 
    lat: "", 
    lng: "", 
    description: "",
    isHeadOffice: false
  });

  async function createOffice() {
    if (!form.name || !form.address || !form.lat || !form.lng) {
      error("Please fill all required fields");
      return;
    }
    const res = await fetch("/api/offices", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ 
        name: form.name.trim(), 
        address: form.address.trim(),
        latitude: Number(form.lat),
        longitude: Number(form.lng),
        description: form.description.trim() || undefined,
      }),
    });
    if (res.ok) {
      setShowCreate(false);
      setForm({ name: "", address: "", lat: "", lng: "", description: "", isHeadOffice: false });
      qc.invalidateQueries({ queryKey: ["offices"] });
      success("Office created successfully");
    } else {
      const data = await res.json().catch(() => ({}));
      error(data.message || "Failed to create office");
    }
  }

  async function updateOffice() {
    if (!editingOffice || !form.name || !form.address || !form.lat || !form.lng) {
      error("Please fill all required fields");
      return;
    }
    const res = await fetch(`/api/offices/${editingOffice._id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ 
        name: form.name.trim(), 
        address: form.address.trim(),
        latitude: Number(form.lat),
        longitude: Number(form.lng),
        description: form.description.trim() || undefined,
        isHeadOffice: form.isHeadOffice,
      }),
    });
    if (res.ok) {
      setEditingOffice(null);
      setForm({ name: "", address: "", lat: "", lng: "", description: "", isHeadOffice: false });
      qc.invalidateQueries({ queryKey: ["offices"] });
      success("Office updated successfully");
    } else {
      const data = await res.json().catch(() => ({}));
      error(data.message || "Failed to update office");
    }
  }

  async function deleteOffice(id: string) {
    if (!confirm("Are you sure you want to delete this office?")) {
      return;
    }
    const res = await fetch(`/api/offices/${id}`, {
      method: "DELETE",
    });
    if (res.ok) {
      qc.invalidateQueries({ queryKey: ["offices"] });
      success("Office deleted successfully");
    } else {
      const data = await res.json().catch(() => ({}));
      error(data.message || "Failed to delete office");
    }
  }

  function openEditDialog(office: Office) {
    setEditingOffice(office);
    setForm({
      name: office.name,
      address: office.address || "",
      lat: office.latitude?.toString() || "",
      lng: office.longitude?.toString() || "",
      description: office.description || "",
      isHeadOffice: office.isHeadOffice || false,
    });
  }

  function closeDialog() {
    setShowCreate(false);
    setEditingOffice(null);
    setForm({ name: "", address: "", lat: "", lng: "", description: "", isHeadOffice: false });
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Offices Management</CardTitle>
            <Dialog open={showCreate} onOpenChange={setShowCreate}>
              <DialogTrigger asChild>
                <Button>
                  <Plus className="mr-2 h-4 w-4" />
                  Create Office
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                  <DialogTitle>Create New Office</DialogTitle>
                </DialogHeader>
                <div className="space-y-4 py-4">
                  <div className="space-y-2">
                    <Label htmlFor="name">Office Name *</Label>
                    <Input
                      id="name"
                      placeholder="Main Office"
                      value={form.name}
                      onChange={(e) => setForm({ ...form, name: e.target.value })}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Location *</Label>
                    <p className="text-sm text-muted-foreground mb-2">
                      Search for an address or click on the map to select a location
                    </p>
                    <MapPicker
                      initialLat={form.lat ? parseFloat(form.lat) : undefined}
                      initialLng={form.lng ? parseFloat(form.lng) : undefined}
                      initialAddress={form.address}
                      onLocationSelect={(lat, lng, address) => {
                        setForm({
                          ...form,
                          address,
                          lat: lat.toString(),
                          lng: lng.toString(),
                        });
                      }}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="description">Description (Optional)</Label>
                    <Input
                      id="description"
                      placeholder="Office description or notes"
                      value={form.description}
                      onChange={(e) => setForm({ ...form, description: e.target.value })}
                    />
                  </div>
                  <div className="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      id="isHeadOffice"
                      checked={form.isHeadOffice}
                      onChange={(e) => setForm({ ...form, isHeadOffice: e.target.checked })}
                      className="h-4 w-4 rounded border-gray-300"
                    />
                    <Label htmlFor="isHeadOffice" className="cursor-pointer">
                      Is Head Office (All trip requests start from here, all ICT/Store requests come here)
                    </Label>
                  </div>
                  <div className="flex gap-2 justify-end">
                    <Button variant="outline" onClick={closeDialog}>
                      Cancel
                    </Button>
                    <Button onClick={createOffice}>Create</Button>
                  </div>
                </div>
              </DialogContent>
            </Dialog>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Address</TableHead>
                <TableHead>Coordinates</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <SkeletonTableRows rows={5} cols={5} />
              ) : offices.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center">
                    No offices found
                  </TableCell>
                </TableRow>
              ) : (
                offices.map((o) => {
                  return (
                    <TableRow key={o._id}>
                      <TableCell className="font-medium">{o.name}</TableCell>
                      <TableCell>{o.address ?? "N/A"}</TableCell>
                      <TableCell>
                        {o.latitude && o.longitude ? `${o.latitude.toFixed(6)}, ${o.longitude.toFixed(6)}` : "N/A"}
                      </TableCell>
                      <TableCell>{o.isHeadOffice ? "Head Office" : "Branch"}</TableCell>
                      <TableCell>
                        <div className="flex gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => openEditDialog(o)}
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => deleteOffice(o._id)}
                          >
                            <Trash2 className="h-4 w-4" />
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

      {/* Edit Dialog */}
      <Dialog open={!!editingOffice} onOpenChange={(open) => !open && closeDialog()}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Edit Office</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="edit-name">Office Name *</Label>
              <Input
                id="edit-name"
                placeholder="Main Office"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label>Location *</Label>
              <p className="text-sm text-muted-foreground mb-2">
                Search for an address or click on the map to select a location
              </p>
              <MapPicker
                initialLat={form.lat ? parseFloat(form.lat) : undefined}
                initialLng={form.lng ? parseFloat(form.lng) : undefined}
                initialAddress={form.address}
                onLocationSelect={(lat, lng, address) => {
                  setForm({
                    ...form,
                    address,
                    lat: lat.toString(),
                    lng: lng.toString(),
                  });
                }}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-description">Description (Optional)</Label>
              <Input
                id="edit-description"
                placeholder="Office description or notes"
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
              />
            </div>
            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="edit-isHeadOffice"
                checked={form.isHeadOffice}
                onChange={(e) => setForm({ ...form, isHeadOffice: e.target.checked })}
                className="h-4 w-4 rounded border-gray-300"
              />
              <Label htmlFor="edit-isHeadOffice" className="cursor-pointer">
                Is Head Office (All trip requests start from here, all ICT/Store requests come here)
              </Label>
            </div>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={closeDialog}>
                Cancel
              </Button>
              <Button onClick={updateOffice}>Update</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}


