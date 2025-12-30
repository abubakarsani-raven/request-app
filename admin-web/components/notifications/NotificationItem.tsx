"use client";

import { Badge } from "@/components/ui/badge";
import { CheckCircle2, Circle } from "lucide-react";
import { format } from "date-fns";

interface NotificationItemProps {
  notification: {
    _id: string;
    type: string;
    title: string;
    message: string;
    isRead: boolean;
    createdAt: string;
    requestType?: string;
  };
  onMarkAsRead?: () => void;
}

export function NotificationItem({ notification, onMarkAsRead }: NotificationItemProps) {
  const getTypeBadgeVariant = (type: string) => {
    if (type.includes("APPROVED")) return "default";
    if (type.includes("REJECTED")) return "destructive";
    if (type.includes("LOW_STOCK")) return "outline";
    return "secondary";
  };

  return (
    <div
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
            <span>{format(new Date(notification.createdAt), "PPP p")}</span>
            {notification.requestType && (
              <span>Request Type: {notification.requestType}</span>
            )}
          </div>
        </div>
        {!notification.isRead && onMarkAsRead && (
          <button
            onClick={onMarkAsRead}
            className="text-sm text-blue-600 hover:underline"
          >
            Mark as Read
          </button>
        )}
      </div>
    </div>
  );
}
