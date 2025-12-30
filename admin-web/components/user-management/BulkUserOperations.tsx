"use client";

import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useToast } from "@/components/ui/use-toast";

interface BulkUserOperationsProps {
  open: boolean;
  selectedUserIds: string[];
  onClose: () => void;
  onSuccess?: () => void;
}

export function BulkUserOperations({
  open,
  selectedUserIds,
  onClose,
  onSuccess,
}: BulkUserOperationsProps) {
  const { success, error } = useToast();
  const [operation, setOperation] = useState<"DELETE" | "DEACTIVATE" | "ACTIVATE">("DEACTIVATE");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async () => {
    if (selectedUserIds.length === 0) {
      error("No users selected");
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await fetch("/api/users/bulk-operations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userIds: selectedUserIds,
          operation,
        }),
      });

      if (res.ok) {
        const data = await res.json();
        success(data.message || "Operation completed successfully");
        onSuccess?.();
        onClose();
      } else {
        const data = await res.json().catch(() => ({}));
        error(data.message || "Failed to perform bulk operation");
      }
    } catch (err) {
      error("Failed to perform bulk operation");
    } finally {
      setIsSubmitting(false);
    }
  };

  const getOperationLabel = () => {
    switch (operation) {
      case "DELETE":
        return "delete";
      case "DEACTIVATE":
        return "deactivate";
      case "ACTIVATE":
        return "activate";
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Bulk User Operations</DialogTitle>
          <DialogDescription>
            Perform bulk operation on {selectedUserIds.length} selected user{selectedUserIds.length !== 1 ? "s" : ""}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div>
            <Label>Operation</Label>
            <Select value={operation} onValueChange={(value: any) => setOperation(value)}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="ACTIVATE">Activate Users</SelectItem>
                <SelectItem value="DEACTIVATE">Deactivate Users</SelectItem>
                <SelectItem value="DELETE">Delete Users</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {operation === "DELETE" && (
            <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-md">
              <p className="text-sm text-destructive">
                ⚠️ Warning: This will permanently delete {selectedUserIds.length} user{selectedUserIds.length !== 1 ? "s" : ""}. This action cannot be undone.
              </p>
            </div>
          )}

          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
              Cancel
            </Button>
            <Button
              variant={operation === "DELETE" ? "destructive" : "default"}
              onClick={handleSubmit}
              disabled={isSubmitting}
            >
              {isSubmitting ? "Processing..." : `${operation === "DELETE" ? "Delete" : "Deactivate"} ${selectedUserIds.length} User${selectedUserIds.length !== 1 ? "s" : ""}`}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
