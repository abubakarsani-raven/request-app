"use client";

import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { useToast } from "@/components/ui/use-toast";

interface AdminApprovalDialogProps {
  open: boolean;
  onClose: () => void;
  onApprove: (comment: string, isAdminApproval: boolean) => Promise<void>;
  onReject?: (reason: string) => Promise<void>;
  requestType: "ICT" | "STORE" | "VEHICLE";
  currentStage: string;
  canApproveAll: boolean;
}

export function AdminApprovalDialog({
  open,
  onClose,
  onApprove,
  onReject,
  requestType,
  currentStage,
  canApproveAll,
}: AdminApprovalDialogProps) {
  const { success, error } = useToast();
  const [comment, setComment] = useState("");
  const [isAdminApproval, setIsAdminApproval] = useState(false);
  const [rejectionReason, setRejectionReason] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showReject, setShowReject] = useState(false);

  const handleApprove = async () => {
    if (!canApproveAll && isAdminApproval) {
      error("You do not have permission to use admin approval override");
      return;
    }

    setIsSubmitting(true);
    try {
      await onApprove(comment, isAdminApproval);
      success("Request approved successfully");
      setComment("");
      setIsAdminApproval(false);
      onClose();
    } catch (err: any) {
      error(err.message || "Failed to approve request");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleReject = async () => {
    if (!rejectionReason.trim()) {
      error("Please provide a rejection reason");
      return;
    }

    if (!onReject) {
      error("Rejection is not available for this request");
      return;
    }

    setIsSubmitting(true);
    try {
      await onReject(rejectionReason);
      success("Request rejected successfully");
      setRejectionReason("");
      setShowReject(false);
      onClose();
    } catch (err: any) {
      error(err.message || "Failed to reject request");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {showReject ? "Reject Request" : "Approve Request"}
          </DialogTitle>
          <DialogDescription>
            {showReject
              ? "Provide a reason for rejecting this request"
              : canApproveAll
              ? "You can approve this request at any stage using admin override"
              : `Approve this ${requestType} request at ${currentStage} stage`}
          </DialogDescription>
        </DialogHeader>

        {showReject ? (
          <div className="space-y-4">
            <div>
              <Label htmlFor="rejectionReason">Rejection Reason *</Label>
              <Textarea
                id="rejectionReason"
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                placeholder="Explain why this request is being rejected..."
                rows={4}
                required
              />
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setShowReject(false)}>
                Cancel
              </Button>
              <Button
                variant="destructive"
                onClick={handleReject}
                disabled={isSubmitting || !rejectionReason.trim()}
              >
                {isSubmitting ? "Rejecting..." : "Reject Request"}
              </Button>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div>
              <Label htmlFor="comment">Comment (Optional)</Label>
              <Textarea
                id="comment"
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                placeholder="Add any comments about this approval..."
                rows={4}
              />
            </div>

            {canApproveAll && (
              <div className="flex items-center gap-2">
                <Checkbox
                  id="adminApproval"
                  checked={isAdminApproval}
                  onCheckedChange={(checked) =>
                    setIsAdminApproval(checked === true)
                  }
                />
                <Label
                  htmlFor="adminApproval"
                  className="text-sm font-normal cursor-pointer"
                >
                  Use Admin Override (approve at any stage)
                </Label>
              </div>
            )}

            <div className="flex justify-between">
              {onReject && (
                <Button
                  variant="outline"
                  onClick={() => setShowReject(true)}
                  disabled={isSubmitting}
                >
                  Reject Instead
                </Button>
              )}
              <div className="flex gap-2 ml-auto">
                <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
                  Cancel
                </Button>
                <Button onClick={handleApprove} disabled={isSubmitting}>
                  {isSubmitting ? "Approving..." : "Approve Request"}
                </Button>
              </div>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
