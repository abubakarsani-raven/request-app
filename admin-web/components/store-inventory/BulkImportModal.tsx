"use client";

import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/components/ui/use-toast";
import { Upload, Download } from "lucide-react";

type BulkImportModalProps = {
  open: boolean;
  onClose: () => void;
};

export function BulkImportModal({ open, onClose }: BulkImportModalProps) {
  const { success, error } = useToast();
  const [file, setFile] = useState<File | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    if (e.target.files && e.target.files[0]) {
      setFile(e.target.files[0]);
    }
  }

  function downloadTemplate() {
    const csv = `name,description,category,quantity,lowStockThreshold,isAvailable
Office Chair,Ergonomic office chair,Furniture,10,5,true
Printer Paper,A4 white paper,Stationery,50,20,true
Cleaning Supplies,General cleaning materials,Cleaning Supplies,30,10,true`;
    
    const blob = new Blob([csv], { type: "text/csv" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "store-items-template.csv";
    a.click();
    window.URL.revokeObjectURL(url);
  }

  async function handleSubmit() {
    if (!file) {
      error("Please select a file");
      return;
    }

    setIsSubmitting(true);
    try {
      // Parse CSV file
      const text = await file.text();
      const lines = text.split("\n").filter((line) => line.trim());
      const headers = lines[0].split(",").map((h) => h.trim());
      const items: any[] = [];

      for (let i = 1; i < lines.length; i++) {
        const values = lines[i].split(",").map((v) => v.trim());
        const item: any = {};
        headers.forEach((header, index) => {
          const value = values[index];
          if (value) {
            if (header === "quantity" || header === "lowStockThreshold") {
              item[header] = Number(value) || 0;
            } else if (header === "isAvailable") {
              item[header] = value.toLowerCase() === "true";
            } else {
              item[header] = value;
            }
          }
        });
        if (item.name && item.category) {
          items.push(item);
        }
      }

      if (items.length === 0) {
        error("No valid items found in file");
        setIsSubmitting(false);
        return;
      }

      const res = await fetch("/api/store-inventory/bulk", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ items }),
      });

      if (res.ok) {
        const data = await res.json();
        success(
          `Successfully imported ${data.created} item${data.created !== 1 ? "s" : ""}. ${
            data.errors?.length > 0 ? `${data.errors.length} error${data.errors.length !== 1 ? "s" : ""} occurred.` : ""
          }`
        );
        onClose();
        setFile(null);
      } else {
        const data = await res.json();
        error(data.message || "Failed to import items");
      }
    } catch (err) {
      error("Failed to import items");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Bulk Import Store Items</DialogTitle>
          <DialogDescription>
            Upload a CSV file to import multiple store items at once. Download the template to see the required format.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <Label>CSV File</Label>
            <Input
              type="file"
              accept=".csv"
              onChange={handleFileChange}
              className="mt-1"
            />
          </div>

          <div className="flex justify-between items-center">
            <Button variant="outline" onClick={downloadTemplate}>
              <Download className="mr-2 h-4 w-4" />
              Download Template
            </Button>
            <div className="flex gap-2">
              <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
                Cancel
              </Button>
              <Button onClick={handleSubmit} disabled={isSubmitting || !file}>
                <Upload className="mr-2 h-4 w-4" />
                {isSubmitting ? "Importing..." : "Import"}
              </Button>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
