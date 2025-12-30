"use client";

import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/ui/use-toast";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";
import { getUserFromToken } from "@/lib/auth";
import { ArrowLeft, Package, AlertCircle, CheckCircle2 } from "lucide-react";

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

interface ICTRequestItem {
  itemId: string | { _id: string; name: string; description?: string; category?: string; quantity?: number };
  quantity: number;
  requestedQuantity?: number;
  fulfilledQuantity?: number;
  isAvailable?: boolean;
}

interface ICTRequest {
  _id: string;
  requesterId: string | { _id: string; name: string; email: string };
  items: ICTRequestItem[];
  status: string;
  workflowStage: string;
  comment?: string;
  notes?: string;
  createdAt?: string;
  updatedAt?: string;
}

export default function SODashboardPage() {
  const router = useRouter();
  const qc = useQueryClient();
  const { success, error } = useToast();
  const [notifyDialog, setNotifyDialog] = useState<{ open: boolean; id: string | null }>({ open: false, id: null });
  const [notifyMessage, setNotifyMessage] = useState("");

  const user = getUserFromToken();
  const isSO = user?.roles?.includes("SO");

  const { data: requests = [], isLoading } = useQuery<ICTRequest[]>({
    queryKey: ["ict-requests-unfulfilled"],
    queryFn: () => fetchJSON<ICTRequest[]>("/api/ict-requests/unfulfilled"),
    enabled: isSO,
  });

  const handleNotify = async (id: string) => {
    try {
      const res = await fetch(`/api/ict-requests/${id}/notify-requester`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: notifyMessage || undefined }),
      });

      if (res.ok) {
        setNotifyDialog({ open: false, id: null });
        setNotifyMessage("");
        success("Requester notified successfully");
      } else {
        const data = await res.json().catch(() => ({}));
        error(data.message || "Failed to notify requester");
      }
    } catch (err) {
      error("Failed to notify requester");
    }
  };

  // Calculate statistics
  let totalUnfulfilledItems = 0;
  let totalPendingRequests = 0;
  requests.forEach((request) => {
    totalPendingRequests++;
    request.items.forEach((item) => {
      const requested = item.requestedQuantity || item.quantity;
      const fulfilled = item.fulfilledQuantity || 0;
      const remaining = requested - fulfilled;
      if (remaining > 0) {
        totalUnfulfilledItems += remaining;
      }
    });
  });

  const getStatusVariant = (status: string) => {
    const statusUpper = status.toUpperCase();
    if (statusUpper === "APPROVED" || statusUpper === "FULFILLED" || statusUpper === "COMPLETED") return "default";
    if (statusUpper === "PENDING" || statusUpper === "ASSIGNED") return "secondary";
    if (statusUpper === "REJECTED" || statusUpper === "CANCELLED") return "destructive";
    if (statusUpper === "CORRECTED") return "outline";
    return "outline";
  };

  const getStatusLabel = (status: string) => {
    const statusUpper = status.toUpperCase();
    const statusMap: Record<string, string> = {
      "PENDING": "Pending",
      "APPROVED": "Approved",
      "REJECTED": "Rejected",
      "FULFILLED": "Fulfilled",
      "COMPLETED": "Completed",
      "ASSIGNED": "Assigned",
      "CORRECTED": "Needs Correction",
      "CANCELLED": "Cancelled",
    };
    return statusMap[statusUpper] || status;
  };

  const getRequesterName = (requesterId: any) => {
    if (typeof requesterId === "object" && requesterId?.name) {
      return requesterId.name;
    }
    return "Unknown";
  };

  const getItemName = (itemId: any) => {
    if (typeof itemId === "object" && itemId?.name) {
      return itemId.name;
    }
    return "Unknown Item";
  };

  if (!isSO) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" onClick={() => router.back()}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        <Card>
          <CardContent className="py-8 text-center">
            <p className="text-muted-foreground">You do not have permission to view this page</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <Button variant="ghost" onClick={() => router.back()}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        <h1 className="text-2xl font-bold">Fulfillment Queue</h1>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Requests</CardTitle>
            <AlertCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalPendingRequests}</div>
            <p className="text-xs text-muted-foreground">Requests with unfulfilled items</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Unfulfilled Items</CardTitle>
            <Package className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalUnfulfilledItems}</div>
            <p className="text-xs text-muted-foreground">Total items awaiting fulfillment</p>
          </CardContent>
        </Card>
      </div>

      {/* Requests List */}
      <Card>
        <CardHeader>
          <CardTitle>Unfulfilled Requests</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <SkeletonTableRows rows={5} cols={6} />
          ) : requests.length === 0 ? (
            <div className="text-center py-8">
              <CheckCircle2 className="h-16 w-16 mx-auto text-green-500 mb-4" />
              <h3 className="text-lg font-semibold mb-2">All requests fulfilled!</h3>
              <p className="text-muted-foreground">There are no unfulfilled items at this time.</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Request ID</TableHead>
                  <TableHead>Requester</TableHead>
                  <TableHead>Request Date</TableHead>
                  <TableHead>Unfulfilled Items</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {requests.map((request) => {
                  const unfulfilledItems = request.items.filter(
                    (item) => (item.fulfilledQuantity || 0) < (item.requestedQuantity || item.quantity)
                  );

                  return (
                    <TableRow
                      key={request._id}
                      className="cursor-pointer hover:bg-muted/50"
                      onClick={() => router.push(`/ict-requests/${request._id}`)}
                    >
                      <TableCell className="font-medium">
                        #{request._id.substring(0, 8)}...
                      </TableCell>
                      <TableCell>{getRequesterName(request.requesterId)}</TableCell>
                      <TableCell>
                        {request.createdAt
                          ? new Date(request.createdAt).toLocaleDateString("en-US", {
                              year: "numeric",
                              month: "short",
                              day: "numeric",
                            })
                          : "N/A"}
                      </TableCell>
                      <TableCell>
                        <div className="space-y-1">
                          {unfulfilledItems.map((item, idx) => {
                            const itemId = typeof item.itemId === "string" ? item.itemId : item.itemId._id;
                            const itemName = getItemName(item.itemId);
                            const requested = item.requestedQuantity || item.quantity;
                            const fulfilled = item.fulfilledQuantity || 0;
                            const remaining = requested - fulfilled;

                            return (
                              <div key={idx} className="text-sm">
                                <span className="font-medium">{itemName}:</span>{" "}
                                <span className="text-muted-foreground">
                                  Requested: {requested}, Fulfilled: {fulfilled},{" "}
                                </span>
                                <span className="font-semibold text-orange-600">Remaining: {remaining}</span>
                              </div>
                            );
                          })}
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={getStatusVariant(request.status)}>
                          {getStatusLabel(request.status)}
                        </Badge>
                      </TableCell>
                      <TableCell onClick={(e) => e.stopPropagation()}>
                        <div className="flex items-center gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={(e) => {
                              e.stopPropagation();
                              router.push(`/ict-requests/${request._id}`);
                            }}
                          >
                            View Details
                          </Button>
                          {request.workflowStage === "FULFILLMENT" && (
                            <Button
                              variant="default"
                              size="sm"
                              onClick={(e) => {
                                e.stopPropagation();
                                router.push(`/ict-requests/${request._id}`);
                              }}
                            >
                              Fulfill
                            </Button>
                          )}
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={(e) => {
                              e.stopPropagation();
                              setNotifyDialog({ open: true, id: request._id });
                            }}
                          >
                            Notify
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Notify Dialog */}
      <Dialog open={notifyDialog.open} onOpenChange={(open) => setNotifyDialog({ open, id: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Notify Requester</DialogTitle>
            <DialogDescription>
              Send a notification to the requester about item availability
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div>
              <Label htmlFor="notify-message">Message (Optional)</Label>
              <Textarea
                id="notify-message"
                value={notifyMessage}
                onChange={(e) => setNotifyMessage(e.target.value)}
                placeholder="Add a custom message..."
                rows={3}
              />
            </div>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setNotifyDialog({ open: false, id: null })}>
                Cancel
              </Button>
              <Button onClick={() => handleNotify(notifyDialog.id!)}>Send Notification</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

