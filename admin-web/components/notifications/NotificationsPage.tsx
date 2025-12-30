"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Bell, CheckCircle2, Circle, Plus } from "lucide-react";
import { NotificationList } from "./NotificationList";
import { CreateNotificationDialog } from "./CreateNotificationDialog";
import { useAdminPermissions } from "@/hooks/useAdminPermissions";
import { useToast } from "@/components/ui/use-toast";

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

interface Notification {
  _id: string;
  userId: string | { _id: string; name: string; email: string };
  type: string;
  title: string;
  message: string;
  isRead: boolean;
  createdAt: string;
  requestId?: string;
  requestType?: string;
}

export function NotificationsPage() {
  const permissions = useAdminPermissions();
  const qc = useQueryClient();
  const { success, error } = useToast();
  const [filter, setFilter] = useState<"all" | "unread" | "read">("all");
  const [typeFilter, setTypeFilter] = useState<string>("all");
  const [createDialogOpen, setCreateDialogOpen] = useState(false);

  const { data: notifications = [], isLoading } = useQuery<Notification[]>({
    queryKey: ["notifications", filter, typeFilter],
    queryFn: () => {
      const params = new URLSearchParams();
      if (filter !== "all") params.append("isRead", filter === "read" ? "true" : "false");
      if (typeFilter !== "all") params.append("type", typeFilter);
      return fetchJSON<Notification[]>(`/api/notifications?${params.toString()}`);
    },
  });

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  const handleMarkAsRead = async (id: string) => {
    try {
      const res = await fetch(`/api/notifications/${id}/read`, {
        method: "PUT",
      });
      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["notifications"] });
        success("Notification marked as read");
      } else {
        error("Failed to mark notification as read");
      }
    } catch (err) {
      error("Failed to mark notification as read");
    }
  };

  const handleMarkAllAsRead = async () => {
    try {
      const res = await fetch("/api/notifications/mark-all-read", {
        method: "PUT",
      });
      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["notifications"] });
        success("All notifications marked as read");
      } else {
        error("Failed to mark all notifications as read");
      }
    } catch (err) {
      error("Failed to mark all notifications as read");
    }
  };

  const notificationTypes = [
    "REQUEST_UPDATED",
    "REQUEST_APPROVED",
    "REQUEST_REJECTED",
    "LOW_STOCK",
    "TRIP_STARTED",
    "TRIP_COMPLETED",
  ];

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Notifications</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Manage and view system notifications
          </p>
        </div>
        <div className="flex gap-2">
          {unreadCount > 0 && (
            <Button variant="outline" onClick={handleMarkAllAsRead}>
              Mark All as Read
            </Button>
          )}
          {permissions.isMainAdmin && (
            <Button onClick={() => setCreateDialogOpen(true)}>
              <Plus className="mr-2 h-4 w-4" />
              Create Notification
            </Button>
          )}
        </div>
      </div>

      {unreadCount > 0 && (
        <Card>
          <CardContent className="py-3">
            <div className="flex items-center gap-2">
              <Bell className="h-5 w-5 text-blue-600" />
              <span className="font-medium">
                You have {unreadCount} unread notification{unreadCount !== 1 ? "s" : ""}
              </span>
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <CardTitle>All Notifications</CardTitle>
            <div className="flex gap-2">
              <Select value={filter} onValueChange={(value: any) => setFilter(value)}>
                <SelectTrigger className="w-[140px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All</SelectItem>
                  <SelectItem value="unread">Unread</SelectItem>
                  <SelectItem value="read">Read</SelectItem>
                </SelectContent>
              </Select>
              <Select value={typeFilter} onValueChange={setTypeFilter}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Types</SelectItem>
                  {notificationTypes.map((type) => (
                    <SelectItem key={type} value={type}>
                      {type.replace(/_/g, " ")}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <NotificationList
            notifications={notifications}
            isLoading={isLoading}
            onMarkAsRead={handleMarkAsRead}
          />
        </CardContent>
      </Card>

      {createDialogOpen && (
        <CreateNotificationDialog
          open={createDialogOpen}
          onClose={() => {
            setCreateDialogOpen(false);
            qc.invalidateQueries({ queryKey: ["notifications"] });
          }}
        />
      )}
    </div>
  );
}
