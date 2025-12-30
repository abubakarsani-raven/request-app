"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/components/ui/use-toast";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { WorkflowTimeline } from "@/components/admin-approval/WorkflowTimeline";
import { RequestActions } from "@/components/admin-approval/RequestActions";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { ArrowLeft } from "lucide-react";
import { useAdminPermissions } from "@/hooks/useAdminPermissions";

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

interface StoreRequestItem {
  itemId: string | { _id: string; name: string; description?: string; category?: string; quantity?: number };
  quantity: number;
  requestedQuantity?: number;
  fulfilledQuantity?: number;
}

interface Approval {
  approverId: string | { _id: string; name: string; email: string };
  role: string;
  status: 'APPROVED' | 'REJECTED';
  comment?: string;
  timestamp: Date | string;
}

interface StoreRequestDetail {
  _id: string;
  requesterId: string | { _id: string; name: string; email: string };
  items: StoreRequestItem[];
  status: string;
  workflowStage: string;
  comment?: string;
  notes?: string;
  approvals?: Approval[];
  createdAt?: string;
  updatedAt?: string;
}

const storeWorkflowStages = [
  { stage: 'SUBMITTED', role: null, description: 'Request Submitted' },
  { stage: 'SUPERVISOR_REVIEW', role: 'SUPERVISOR', description: 'Supervisor Review' },
  { stage: 'SO_REVIEW', role: 'SO', description: 'Store Officer Review' },
  { stage: 'DGS_REVIEW', role: 'DGS', description: 'DGS Review' },
  { stage: 'FULFILLMENT', role: 'SO', description: 'Fulfillment' },
];

export default function StoreRequestDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const qc = useQueryClient();
  const { success, error } = useToast();
  const permissions = useAdminPermissions();
  const [fulfillDialog, setFulfillDialog] = useState(false);
  const [fulfillmentItems, setFulfillmentItems] = useState<Record<string, number>>({});

  const requestId = params.id as string;

  const { data: request, isLoading } = useQuery<StoreRequestDetail>({
    queryKey: ["store-request", requestId],
    queryFn: () => fetchJSON<StoreRequestDetail>(`/api/store-requests/${requestId}`),
    enabled: !!requestId,
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

  const handleFulfill = async () => {
    if (!request) return;

    const items = Object.entries(fulfillmentItems)
      .filter(([_, qty]) => qty > 0)
      .map(([itemId, quantityFulfilled]) => ({
        itemId,
        quantityFulfilled,
      }));

    if (items.length === 0) {
      error("Please specify quantities to fulfill");
      return;
    }

    try {
      const res = await fetch(`/api/store-requests/${requestId}/fulfill`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ items }),
      });

      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["store-request", requestId] });
        qc.invalidateQueries({ queryKey: ["store-requests"] });
        setFulfillDialog(false);
        setFulfillmentItems({});
        success("Request fulfilled successfully");
      } else {
        const data = await res.json().catch(() => ({}));
        error(data.message || "Failed to fulfill request");
      }
    } catch (err) {
      error("Failed to fulfill request");
    }
  };

  const handleApprove = async (comment: string, isAdminApproval: boolean) => {
    if (!request) return;

    try {
      const res = await fetch(`/api/store-requests/${requestId}/approve`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          comment: comment || undefined,
          isAdminApproval: isAdminApproval || undefined,
        }),
      });

      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["store-request", requestId] });
        qc.invalidateQueries({ queryKey: ["store-requests"] });
        success("Request approved successfully");
      } else {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.message || "Failed to approve request");
      }
    } catch (err: any) {
      throw err;
    }
  };

  const handleReject = async (reason: string) => {
    if (!request) return;

    try {
      const res = await fetch(`/api/store-requests/${requestId}/reject`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ reason }),
      });

      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["store-request", requestId] });
        qc.invalidateQueries({ queryKey: ["store-requests"] });
        success("Request rejected successfully");
      } else {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.message || "Failed to reject request");
      }
    } catch (err: any) {
      throw err;
    }
  };

  const handleSendBack = async (reason: string) => {
    if (!request) return;

    try {
      const res = await fetch(`/api/store-requests/${requestId}/send-back`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ reason }),
      });

      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["store-request", requestId] });
        qc.invalidateQueries({ queryKey: ["store-requests"] });
        success("Request sent back successfully");
      } else {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.message || "Failed to send back request");
      }
    } catch (err: any) {
      throw err;
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="h-8 bg-muted animate-pulse rounded" />
        <div className="h-64 bg-muted animate-pulse rounded" />
      </div>
    );
  }

  if (!request) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" onClick={() => router.back()}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        <Card>
          <CardContent className="py-8 text-center">
            <p className="text-muted-foreground">Request not found</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Initialize fulfillment items
  if (request.items && Object.keys(fulfillmentItems).length === 0) {
    const initial: Record<string, number> = {};
    request.items.forEach((item) => {
      const itemId = typeof item.itemId === "string" ? item.itemId : item.itemId._id;
      const remaining = (item.requestedQuantity || item.quantity) - (item.fulfilledQuantity || 0);
      initial[itemId] = remaining > 0 ? remaining : 0;
    });
    setFulfillmentItems(initial);
  }

  const workflowStage = request.workflowStage || "SUBMITTED";
  const canFulfill = permissions.canManageStore && 
    workflowStage === "FULFILLMENT" &&
    (request.status === "APPROVED" || request.status === "PENDING");
  
  const canApprove = permissions.canManageStore || permissions.canApproveAll;

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <Button variant="ghost" onClick={() => router.back()}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        <h1 className="text-2xl font-bold">Store Request Details</h1>
      </div>

      <Tabs defaultValue="details" className="space-y-4">
        <TabsList>
          <TabsTrigger value="details">Details</TabsTrigger>
          <TabsTrigger value="workflow">Workflow</TabsTrigger>
        </TabsList>

        <TabsContent value="details" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Request Information</CardTitle>
                <Badge variant={getStatusVariant(request.status)}>
                  {getStatusLabel(request.status)}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label className="text-muted-foreground">Requester</Label>
                  <div className="font-medium">{getRequesterName(request.requesterId)}</div>
                </div>
                <div>
                  <Label className="text-muted-foreground">Request Date</Label>
                  <div className="font-medium">
                    {request.createdAt
                      ? new Date(request.createdAt).toLocaleDateString("en-US", {
                          year: "numeric",
                          month: "short",
                          day: "numeric",
                          hour: "2-digit",
                          minute: "2-digit",
                        })
                      : "N/A"}
                  </div>
                </div>
                {request.comment || request.notes ? (
                  <div className="col-span-2">
                    <Label className="text-muted-foreground">Notes</Label>
                    <div className="font-medium">{request.comment || request.notes || "-"}</div>
                  </div>
                ) : null}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Requested Items</CardTitle>
                <div className="flex gap-2">
                  {canFulfill && (
                    <Button onClick={() => setFulfillDialog(true)}>Fulfill Request</Button>
                  )}
                  {canApprove && (
                    <RequestActions
                      requestId={requestId}
                      requestType="STORE"
                      currentStage={workflowStage}
                      status={request.status}
                      onApprove={handleApprove}
                      onReject={handleReject}
                      onSendBack={handleSendBack}
                    />
                  )}
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Item</TableHead>
                    <TableHead>Requested</TableHead>
                    <TableHead>Fulfilled</TableHead>
                    <TableHead>Remaining</TableHead>
                    <TableHead>Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {request.items?.map((item, index) => {
                    const itemId = typeof item.itemId === "string" ? item.itemId : item.itemId._id;
                    const itemName = getItemName(item.itemId);
                    const requested = item.requestedQuantity || item.quantity;
                    const fulfilled = item.fulfilledQuantity || 0;
                    const remaining = requested - fulfilled;
                    const isFulfilled = remaining === 0;

                    return (
                      <TableRow key={index}>
                        <TableCell className="font-medium">{itemName}</TableCell>
                        <TableCell>{requested}</TableCell>
                        <TableCell>{fulfilled}</TableCell>
                        <TableCell>{remaining}</TableCell>
                        <TableCell>
                          <Badge variant={isFulfilled ? "default" : "secondary"}>
                            {isFulfilled ? "Fulfilled" : "Pending"}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="workflow" className="space-y-4">
          <WorkflowTimeline
            stages={storeWorkflowStages.map((s) => ({
              stage: s.stage,
              role: s.role,
              description: s.description,
            }))}
            currentStage={workflowStage}
            approvals={request.approvals || []}
          />
          {request.approvals && request.approvals.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Approval History</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {request.approvals.map((approval, index) => (
                    <div key={index} className="p-3 border rounded-md">
                      <div className="flex items-center justify-between mb-2">
                        <div>
                          <span className="font-medium">
                            {typeof approval.approverId === "object"
                              ? approval.approverId.name
                              : "Approver"}
                          </span>
                          {" - "}
                          <span className="text-sm text-muted-foreground">
                            {approval.role}
                          </span>
                        </div>
                        <Badge
                          variant={
                            approval.status === "APPROVED" ? "default" : "destructive"
                          }
                        >
                          {approval.status}
                        </Badge>
                      </div>
                      {approval.comment && (
                        <p className="text-sm text-muted-foreground mb-2">
                          {approval.comment}
                        </p>
                      )}
                      <p className="text-xs text-muted-foreground">
                        {new Date(approval.timestamp).toLocaleString()}
                      </p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>
      </Tabs>

      {/* Fulfill Dialog */}
      <Dialog open={fulfillDialog} onOpenChange={setFulfillDialog}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Fulfill Request</DialogTitle>
            <DialogDescription>
              Specify the quantities to fulfill for each item
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Item</TableHead>
                  <TableHead>Requested</TableHead>
                  <TableHead>Fulfilled</TableHead>
                  <TableHead>Remaining</TableHead>
                  <TableHead>Fulfill Quantity</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {request.items?.map((item, index) => {
                  const itemId = typeof item.itemId === "string" ? item.itemId : item.itemId._id;
                  const itemName = getItemName(item.itemId);
                  const requested = item.requestedQuantity || item.quantity;
                  const fulfilled = item.fulfilledQuantity || 0;
                  const remaining = requested - fulfilled;
                  const maxFulfill = remaining;

                  return (
                    <TableRow key={index}>
                      <TableCell className="font-medium">{itemName}</TableCell>
                      <TableCell>{requested}</TableCell>
                      <TableCell>{fulfilled}</TableCell>
                      <TableCell>{remaining}</TableCell>
                      <TableCell>
                        <Input
                          type="number"
                          min="0"
                          max={maxFulfill}
                          value={fulfillmentItems[itemId] || 0}
                          onChange={(e) => {
                            const value = Math.max(0, Math.min(maxFulfill, parseInt(e.target.value) || 0));
                            setFulfillmentItems({ ...fulfillmentItems, [itemId]: value });
                          }}
                          className="w-20"
                          disabled={maxFulfill === 0}
                        />
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setFulfillDialog(false)}>
                Cancel
              </Button>
              <Button onClick={handleFulfill}>Fulfill</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
