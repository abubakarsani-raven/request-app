"use client";

import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { useToast } from "@/components/ui/use-toast";

interface CreateNotificationDialogProps {
  open: boolean;
  onClose: () => void;
}

const notificationTypes = [
  "REQUEST_UPDATED",
  "REQUEST_APPROVED",
  "REQUEST_REJECTED",
  "LOW_STOCK",
  "TRIP_STARTED",
  "TRIP_COMPLETED",
  "SYSTEM",
];

export function CreateNotificationDialog({ open, onClose }: CreateNotificationDialogProps) {
  const { success, error } = useToast();
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [type, setType] = useState("SYSTEM");
  const [targetType, setTargetType] = useState<"all" | "users" | "roles">("all");
  const [userIds, setUserIds] = useState("");
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const roles = ["ADMIN", "DGS", "DDGS", "ADGS", "TO", "DDICT", "SO", "SUPERVISOR", "DRIVER"];

  const handleSubmit = async () => {
    if (!title.trim() || !message.trim()) {
      error("Title and message are required");
      return;
    }

    setIsSubmitting(true);
    try {
      let res;
      if (targetType === "all") {
        res = await fetch("/api/notifications/broadcast", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title, message, type }),
        });
      } else if (targetType === "users") {
        const userIdsArray = userIds.split(",").map((id) => id.trim()).filter(Boolean);
        if (userIdsArray.length === 0) {
          error("Please provide at least one user ID");
          setIsSubmitting(false);
          return;
        }
        res = await fetch("/api/notifications/targeted", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title, message, type, userIds: userIdsArray }),
        });
      } else {
        if (selectedRoles.length === 0) {
          error("Please select at least one role");
          setIsSubmitting(false);
          return;
        }
        res = await fetch("/api/notifications/targeted", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title, message, type, roles: selectedRoles }),
        });
      }

      if (res.ok) {
        success("Notification sent successfully");
        setTitle("");
        setMessage("");
        setType("SYSTEM");
        setTargetType("all");
        setUserIds("");
        setSelectedRoles([]);
        onClose();
      } else {
        const data = await res.json().catch(() => ({}));
        error(data.message || "Failed to send notification");
      }
    } catch (err) {
      error("Failed to send notification");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Create Notification</DialogTitle>
          <DialogDescription>
            Send a notification to users. You can broadcast to all users, target specific users, or target by role.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div>
            <Label htmlFor="title">Title *</Label>
            <Input
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Notification title"
              required
            />
          </div>

          <div>
            <Label htmlFor="message">Message *</Label>
            <Textarea
              id="message"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Notification message"
              rows={4}
              required
            />
          </div>

          <div>
            <Label htmlFor="type">Type</Label>
            <Select value={type} onValueChange={setType}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {notificationTypes.map((nt) => (
                  <SelectItem key={nt} value={nt}>
                    {nt.replace(/_/g, " ")}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label>Target</Label>
            <Select value={targetType} onValueChange={(value: any) => setTargetType(value)}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Users</SelectItem>
                <SelectItem value="users">Specific Users</SelectItem>
                <SelectItem value="roles">By Role</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {targetType === "users" && (
            <div>
              <Label htmlFor="userIds">User IDs (comma-separated)</Label>
              <Input
                id="userIds"
                value={userIds}
                onChange={(e) => setUserIds(e.target.value)}
                placeholder="user1, user2, user3"
              />
            </div>
          )}

          {targetType === "roles" && (
            <div>
              <Label>Select Roles</Label>
              <div className="grid grid-cols-2 gap-2 mt-2">
                {roles.map((role) => (
                  <div key={role} className="flex items-center gap-2">
                    <Checkbox
                      checked={selectedRoles.includes(role)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          setSelectedRoles([...selectedRoles, role]);
                        } else {
                          setSelectedRoles(selectedRoles.filter((r) => r !== role));
                        }
                      }}
                    />
                    <Label className="text-sm font-normal">{role}</Label>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
              Cancel
            </Button>
            <Button onClick={handleSubmit} disabled={isSubmitting}>
              {isSubmitting ? "Sending..." : "Send Notification"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
