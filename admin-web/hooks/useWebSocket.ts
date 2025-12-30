"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { io, Socket } from "socket.io-client";

const WS_URL = process.env.NEXT_PUBLIC_WS_URL || "http://localhost:4000";

interface UseWebSocketOptions {
  namespace?: string;
  onConnect?: () => void;
  onDisconnect?: () => void;
  onError?: (error: Error) => void;
  autoConnect?: boolean;
}

export function useWebSocket(options: UseWebSocketOptions = {}) {
  const {
    namespace = "/updates",
    onConnect,
    onDisconnect,
    onError,
    autoConnect = true,
  } = options;

  const [isConnected, setIsConnected] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<"connecting" | "connected" | "disconnected" | "error">("disconnected");
  const socketRef = useRef<Socket | null>(null);
  const listenersRef = useRef<Map<string, Set<Function>>>(new Map());

  const connect = useCallback(() => {
    if (socketRef.current?.connected) {
      return;
    }

    try {
      // Get token from cookie
      const token = document.cookie
        .split("; ")
        .find((row) => row.startsWith("access_token="))
        ?.split("=")[1];

      if (!token) {
        console.warn("No access token found for WebSocket connection");
        setConnectionStatus("error");
        return;
      }

      const socket = io(`${WS_URL}${namespace}`, {
        auth: {
          token,
        },
        transports: ["websocket", "polling"],
        reconnection: true,
        reconnectionDelay: 1000,
        reconnectionAttempts: 5,
      });

      socket.on("connect", () => {
        console.log("WebSocket connected");
        setIsConnected(true);
        setConnectionStatus("connected");
        onConnect?.();
      });

      socket.on("disconnect", (reason) => {
        console.log("WebSocket disconnected:", reason);
        setIsConnected(false);
        setConnectionStatus("disconnected");
        onDisconnect?.();
      });

      socket.on("connect_error", (error) => {
        console.error("WebSocket connection error:", error);
        setConnectionStatus("error");
        onError?.(error);
      });

      socketRef.current = socket;
    } catch (error) {
      console.error("Failed to create WebSocket connection:", error);
      setConnectionStatus("error");
      onError?.(error as Error);
    }
  }, [namespace, onConnect, onDisconnect, onError]);

  const disconnect = useCallback(() => {
    if (socketRef.current) {
      socketRef.current.disconnect();
      socketRef.current = null;
      setIsConnected(false);
      setConnectionStatus("disconnected");
    }
  }, []);

  const emit = useCallback((event: string, data?: any) => {
    if (socketRef.current?.connected) {
      socketRef.current.emit(event, data);
    } else {
      console.warn("WebSocket not connected, cannot emit:", event);
    }
  }, []);

  const on = useCallback((event: string, callback: Function) => {
    if (!socketRef.current) {
      console.warn("WebSocket not initialized, cannot listen to:", event);
      return;
    }

    if (!listenersRef.current.has(event)) {
      listenersRef.current.set(event, new Set());
    }

    listenersRef.current.get(event)!.add(callback);
    socketRef.current.on(event, callback as any);
  }, []);

  const off = useCallback((event: string, callback?: Function) => {
    if (!socketRef.current) {
      return;
    }

    if (callback) {
      listenersRef.current.get(event)?.delete(callback);
      socketRef.current.off(event, callback as any);
    } else {
      listenersRef.current.delete(event);
      socketRef.current.off(event);
    }
  }, []);

  useEffect(() => {
    if (autoConnect) {
      connect();
    }

    return () => {
      // Clean up all listeners
      listenersRef.current.clear();
      disconnect();
    };
  }, [autoConnect, connect, disconnect]);

  return {
    isConnected,
    connectionStatus,
    connect,
    disconnect,
    emit,
    on,
    off,
    socket: socketRef.current,
  };
}
