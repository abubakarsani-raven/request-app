"use client";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { CheckCircle2, Circle } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { format } from "date-fns";

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

interface NotificationListProps {
  notifications: Notification[];
  isLoading: boolean;
  onMarkAsRead: (id: string) => void;
}

export function NotificationList({
  notifications,
  isLoading,
  onMarkAsRead,
}: NotificationListProps) {
  if (isLoading) {
    return (
      <div className="space-y-2">
        {[1, 2, 3, 4, 5].map((i) => (
          <Skeleton key={i} className="h-20 w-full" />
        ))}
      </div>
    );
  }

  if (notifications.length === 0) {
    return (
      <div className="text-center py-8 text-muted-foreground">
        No notifications found
      </div>
    );
  }

  const getTypeBadgeVariant = (type: string) => {
    if (type.includes("APPROVED")) return "default";
    if (type.includes("REJECTED")) return "destructive";
    if (type.includes("LOW_STOCK")) return "outline";
    return "secondary";
  };

  return (
    <div className="space-y-2">
      {notifications.map((notification) => (
        <div
          key={notification._id}
          className={`p-4 border rounded-lg ${
            !notification.isRead ? "bg-blue-50 dark:bg-blue-950" : ""
          }`}
        >
          <div className="flex items-start justify-between gap-4">
            <div className="flex-1 space-y-2">
              <div className="flex items-center gap-2">
                {notification.isRead ? (
                  <CheckCircle2 className="h-4 w-4 text-muted-foreground" />
                ) : (
                  <Circle className="h-4 w-4 text-blue-600" />
                )}
                <h4 className="font-medium">{notification.title}</h4>
                <Badge variant={getTypeBadgeVariant(notification.type)}>
                  {notification.type.replace(/_/g, " ")}
                </Badge>
              </div>
              <p className="text-sm text-muted-foreground">{notification.message}</p>
              <div className="flex items-center gap-4 text-xs text-muted-foreground">
                <span>
                  {format(new Date(notification.createdAt), "PPP p")}
                </span>
                {notification.requestType && (
                  <span>Request Type: {notification.requestType}</span>
                )}
              </div>
            </div>
            {!notification.isRead && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => onMarkAsRead(notification._id)}
              >
                Mark as Read
              </Button>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}
