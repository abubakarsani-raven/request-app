"use client";

import { useQuery } from "@tanstack/react-query";
import { Bell } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useRouter } from "next/navigation";
import { useWebSocket } from "@/hooks/useWebSocket";
import { useEffect } from "react";

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export function NotificationBadge() {
  const router = useRouter();
  const { isConnected, on } = useWebSocket({ autoConnect: true });

  const { data: unreadCount = 0, refetch } = useQuery<number>({
    queryKey: ["notifications-unread-count"],
    queryFn: async () => {
      const notifications = await fetchJSON<any[]>("/api/notifications?isRead=false");
      return notifications.length;
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  });

  useEffect(() => {
    if (isConnected) {
      // Listen for new notifications via WebSocket
      on("notification:new", () => {
        refetch();
      });

      on("notification:read", () => {
        refetch();
      });
    }
  }, [isConnected, on, refetch]);

  return (
    <Button
      variant="ghost"
      size="icon"
      className="relative"
      onClick={() => router.push("/notifications")}
    >
      <Bell className="h-5 w-5" />
      {unreadCount > 0 && (
        <Badge
          variant="destructive"
          className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center p-0 text-xs"
        >
          {unreadCount > 99 ? "99+" : unreadCount}
        </Badge>
      )}
    </Button>
  );
}
