"use client";

import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { useToast } from "@/components/ui/use-toast";

interface RoleAssignmentDialogProps {
  open: boolean;
  userId: string;
  userName: string;
  currentRoles: string[];
  onClose: () => void;
  onSuccess?: () => void;
}

const allRoles = [
  "ADMIN",
  "DGS",
  "DDGS",
  "ADGS",
  "TO",
  "DDICT",
  "SO",
  "SUPERVISOR",
  "DRIVER",
  "ICT_ADMIN",
  "STORE_ADMIN",
  "TRANSPORT_ADMIN",
];

export function RoleAssignmentDialog({
  open,
  userId,
  userName,
  currentRoles,
  onClose,
  onSuccess,
}: RoleAssignmentDialogProps) {
  const { success, error } = useToast();
  const [selectedRoles, setSelectedRoles] = useState<string[]>(currentRoles || []);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (open) {
      setSelectedRoles(currentRoles || []);
    }
  }, [open, currentRoles]);

  const handleRoleToggle = (role: string) => {
    if (selectedRoles.includes(role)) {
      setSelectedRoles(selectedRoles.filter((r) => r !== role));
    } else {
      setSelectedRoles([...selectedRoles, role]);
    }
  };

  const handleSubmit = async () => {
    if (selectedRoles.length === 0) {
      error("At least one role must be selected");
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/users/${userId}/roles`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ roles: selectedRoles }),
      });

      if (res.ok) {
        success("Roles updated successfully");
        onSuccess?.();
        onClose();
      } else {
        const data = await res.json().catch(() => ({}));
        error(data.message || "Failed to update roles");
      }
    } catch (err) {
      error("Failed to update roles");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Assign Roles</DialogTitle>
          <DialogDescription>
            Assign roles to {userName}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div className="grid grid-cols-2 gap-2 max-h-64 overflow-y-auto">
            {allRoles.map((role) => (
              <div key={role} className="flex items-center gap-2">
                <Checkbox
                  id={`role-${role}`}
                  checked={selectedRoles.includes(role)}
                  onCheckedChange={() => handleRoleToggle(role)}
                />
                <Label
                  htmlFor={`role-${role}`}
                  className="text-sm font-normal cursor-pointer"
                >
                  {role.replace(/_/g, " ")}
                </Label>
              </div>
            ))}
          </div>
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
              Cancel
            </Button>
            <Button onClick={handleSubmit} disabled={isSubmitting}>
              {isSubmitting ? "Updating..." : "Update Roles"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
