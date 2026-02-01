"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/ui/use-toast";
import { IctRequest, IctRequestStatus, ICT_STATUS_LABELS } from "@/types/ict-request";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load");
  return res.json();
}

export default function IctRequestsPage() {
  const qc = useQueryClient();
  const { success, error } = useToast();
  const [filter, setFilter] = useState<string>("all");
  const [approveDialog, setApproveDialog] = useState<{ open: boolean; id: string | null }>({ open: false, id: null });
  const [rejectDialog, setRejectDialog] = useState<{ open: boolean; id: string | null }>({ open: false, id: null });
  const [sendBackDialog, setSendBackDialog] = useState<{ open: boolean; id: string | null }>({ open: false, id: null });
  const [cancelDialog, setCancelDialog] = useState<{ open: boolean; id: string | null }>({ open: false, id: null });
  const [comments, setComments] = useState("");
  const [rejectionReason, setRejectionReason] = useState("");
  const [correctionReason, setCorrectionReason] = useState("");
  const [cancelReason, setCancelReason] = useState("");

  const { data: requests = [], isLoading } = useQuery<IctRequest[]>({
    queryKey: ["ict-requests"],
    queryFn: () => fetchJSON<IctRequest[]>("/api/ict-requests"),
  });

  const filtered = requests.filter((r) => {
    // Ensure we only show ICT requests (they should have items array)
    if (!r.items || !Array.isArray(r.items)) return false;
    
    if (filter === "all") return true;
    if (filter === "ready-to-fulfill") {
      // Show requests at FULFILLMENT stage with APPROVED or PENDING status
      return r.workflowStage === "FULFILLMENT" && 
             (r.status?.toUpperCase() === "APPROVED" || r.status?.toUpperCase() === "PENDING");
    }
    return r.status?.toUpperCase() === filter.toUpperCase();
  });

  async function approve(id: string) {
    const res = await fetch(`/api/ict-requests/${id}/approve`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ comments: comments || undefined }),
    });
    if (res.ok) {
      qc.invalidateQueries({ queryKey: ["ict-requests"] });
      setApproveDialog({ open: false, id: null });
      setComments("");
      success("Request approved successfully");
    } else {
      const data = await res.json().catch(() => ({}));
      error(data.message || "Failed to approve");
    }
  }

  async function reject(id: string) {
    if (!rejectionReason) {
      error("Please provide a rejection reason");
      return;
    }
    const res = await fetch(`/api/ict-requests/${id}/reject`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ rejectionReason }),
    });
    if (res.ok) {
      qc.invalidateQueries({ queryKey: ["ict-requests"] });
      setRejectDialog({ open: false, id: null });
      setRejectionReason("");
      success("Request rejected successfully");
    } else {
      const data = await res.json().catch(() => ({}));
      error(data.message || "Failed to reject");
    }
  }

  async function sendBack(id: string) {
    if (!correctionReason) {
      error("Please provide a correction reason");
      return;
    }
    const res = await fetch(`/api/ict-requests/${id}/send-back`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ correctionReason, comments: comments || undefined }),
    });
    if (res.ok) {
      qc.invalidateQueries({ queryKey: ["ict-requests"] });
      setSendBackDialog({ open: false, id: null });
      setCorrectionReason("");
      setComments("");
      success("Request sent back for correction successfully");
    } else {
      const data = await res.json().catch(() => ({}));
      error(data.message || "Failed to send back");
    }
  }

  async function cancel(id: string) {
    if (!cancelReason) {
      error("Please provide a cancellation reason");
      return;
    }
    const res = await fetch(`/api/ict-requests/${id}/cancel`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ reason: cancelReason }),
    });
    if (res.ok) {
      qc.invalidateQueries({ queryKey: ["ict-requests"] });
      setCancelDialog({ open: false, id: null });
      setCancelReason("");
      success("Request cancelled successfully");
    } else {
      const data = await res.json().catch(() => ({}));
      error(data.message || "Failed to cancel");
    }
  }

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

  const getRequesterDisplay = (requesterId: any) => {
    if (typeof requesterId !== "object" || !requesterId?.name) return "Unknown";
    const dept = requesterId.departmentId?.name;
    return dept ? `${requesterId.name} (${dept})` : requesterId.name;
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>ICT Requests Management</CardTitle>
            <div className="flex items-center gap-2">
              <span className="text-sm text-muted-foreground">Filter:</span>
              <Select value={filter} onValueChange={setFilter}>
                <SelectTrigger className="w-[200px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All</SelectItem>
                  <SelectItem value="ready-to-fulfill">Ready to Fulfill</SelectItem>
                  <SelectItem value="PENDING">Pending</SelectItem>
                  <SelectItem value="APPROVED">Approved</SelectItem>
                  <SelectItem value="REJECTED">Rejected</SelectItem>
                  <SelectItem value="FULFILLED">Fulfilled</SelectItem>
                  <SelectItem value="COMPLETED">Completed</SelectItem>
                  <SelectItem value="ASSIGNED">Assigned</SelectItem>
                  <SelectItem value="CORRECTED">Needs Correction</SelectItem>
                  <SelectItem value="CANCELLED">Cancelled</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Items</TableHead>
                <TableHead>Notes</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Requester</TableHead>
                <TableHead>Date</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <SkeletonTableRows rows={5} cols={6} />
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center">
                    No requests found
                  </TableCell>
                </TableRow>
              ) : (
                filtered.map((r: any) => {
                  // Get items list
                  const itemsList = Array.isArray(r.items) 
                    ? r.items.map((item: any) => {
                        // itemId should be populated with the full ICTItem object
                        const itemName = item.itemId?.name || (typeof item.itemId === 'string' ? 'Loading...' : 'Unknown Item');
                        const quantity = item.quantity || item.requestedQuantity || 0;
                        return `${itemName} (${quantity})`;
                      }).join(', ')
                    : 'No items';
                  
                  return (
                    <TableRow 
                      key={r._id}
                      className="cursor-pointer hover:bg-muted/50"
                      onClick={() => window.location.href = `/ict-requests/${r._id}`}
                    >
                      <TableCell className="font-medium max-w-xs">
                        <div className="truncate" title={itemsList}>
                          {itemsList}
                        </div>
                      </TableCell>
                      <TableCell className="max-w-xs">
                        <div className="truncate" title={r.comment || r.notes || ''}>
                          {r.comment || r.notes || '-'}
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={getStatusVariant(r.status)}>
                          {getStatusLabel(r.status)}
                        </Badge>
                      </TableCell>
                      <TableCell>{getRequesterDisplay(r.requesterId)}</TableCell>
                      <TableCell>
                        {r.createdAt
                          ? new Date(r.createdAt).toLocaleDateString("en-US", {
                              year: "numeric",
                              month: "short",
                              day: "numeric",
                            })
                          : "N/A"}
                      </TableCell>
                    <TableCell onClick={(e) => e.stopPropagation()}>
                      <div className="flex items-center gap-2">
                        {['PENDING', 'CORRECTED'].includes((r.status as string)?.toUpperCase() || '') && (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={(e) => {
                              e.stopPropagation();
                              setApproveDialog({ open: true, id: r._id });
                            }}
                          >
                            Approve
                          </Button>
                        )}
                        {['PENDING', 'CORRECTED'].includes((r.status as string)?.toUpperCase() || '') && (
                          <Button 
                            variant="outline" 
                            size="sm" 
                            onClick={(e) => {
                              e.stopPropagation();
                              setSendBackDialog({ open: true, id: r._id });
                            }}
                          >
                            Send Back
                          </Button>
                        )}
                        {['PENDING', 'CORRECTED'].includes((r.status as string)?.toUpperCase() || '') && (
                          <Button 
                            variant="outline" 
                            size="sm" 
                            onClick={(e) => {
                              e.stopPropagation();
                              setRejectDialog({ open: true, id: r._id });
                            }}
                          >
                            Reject
                          </Button>
                        )}
                        {['PENDING', 'CORRECTED'].includes((r.status as string)?.toUpperCase() || '') && (
                          <Button 
                            variant="outline" 
                            size="sm" 
                            onClick={(e) => {
                              e.stopPropagation();
                              setCancelDialog({ open: true, id: r._id });
                            }}
                          >
                            Cancel
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={(e) => {
                            e.stopPropagation();
                            window.location.href = `/ict-requests/${r._id}`;
                          }}
                        >
                          View
                        </Button>
                      </div>
                    </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Approve Dialog */}
      <Dialog open={approveDialog.open} onOpenChange={(open) => setApproveDialog({ open, id: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Approve Request</DialogTitle>
            <DialogDescription>Add optional comments for this approval</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="comments">Comments (optional)</Label>
              <Textarea
                id="comments"
                placeholder="Enter comments..."
                value={comments}
                onChange={(e) => setComments(e.target.value)}
              />
            </div>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setApproveDialog({ open: false, id: null })}>
                Cancel
              </Button>
              <Button onClick={() => approve(approveDialog.id!)}>Approve</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Reject Dialog */}
      <Dialog open={rejectDialog.open} onOpenChange={(open) => setRejectDialog({ open, id: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reject Request</DialogTitle>
            <DialogDescription>Please provide a reason for rejection</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="rejectionReason">Rejection Reason *</Label>
              <Textarea
                id="rejectionReason"
                placeholder="Enter rejection reason..."
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                required
              />
            </div>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setRejectDialog({ open: false, id: null })}>
                Cancel
              </Button>
              <Button variant="destructive" onClick={() => reject(rejectDialog.id!)}>
                Reject
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Send Back Dialog */}
      <Dialog open={sendBackDialog.open} onOpenChange={(open) => setSendBackDialog({ open, id: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Send Back for Correction</DialogTitle>
            <DialogDescription>Please provide a reason for sending back</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="correctionReason">Correction Reason *</Label>
              <Textarea
                id="correctionReason"
                placeholder="Enter correction reason..."
                value={correctionReason}
                onChange={(e) => setCorrectionReason(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="comments">Comments (optional)</Label>
              <Textarea
                id="comments"
                placeholder="Enter comments..."
                value={comments}
                onChange={(e) => setComments(e.target.value)}
              />
            </div>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setSendBackDialog({ open: false, id: null })}>
                Cancel
              </Button>
              <Button onClick={() => sendBack(sendBackDialog.id!)}>Send Back</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Cancel Dialog */}
      <Dialog open={cancelDialog.open} onOpenChange={(open) => setCancelDialog({ open, id: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Cancel Request</DialogTitle>
            <DialogDescription>Please provide a reason for cancellation</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="cancelReason">Cancellation Reason *</Label>
              <Textarea
                id="cancelReason"
                placeholder="Enter cancellation reason..."
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                required
              />
            </div>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setCancelDialog({ open: false, id: null })}>
                Cancel
              </Button>
              <Button variant="destructive" onClick={() => cancel(cancelDialog.id!)}>
                Cancel Request
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

