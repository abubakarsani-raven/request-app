"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { AdminApprovalDialog } from "./AdminApprovalDialog";
import { useAdminPermissions } from "@/hooks/useAdminPermissions";
import { CheckCircle2, XCircle, Send, History } from "lucide-react";

interface RequestActionsProps {
  requestId: string;
  requestType: "ICT" | "STORE" | "VEHICLE";
  currentStage: string;
  status: string;
  onApprove: (comment: string, isAdminApproval: boolean) => Promise<void>;
  onReject?: (reason: string) => Promise<void>;
  onSendBack?: (reason: string) => Promise<void>;
  onNotify?: (message: string) => Promise<void>;
  showHistory?: () => void;
}

export function RequestActions({
  requestId,
  requestType,
  currentStage,
  status,
  onApprove,
  onReject,
  onSendBack,
  onNotify,
  showHistory,
}: RequestActionsProps) {
  const permissions = useAdminPermissions();
  const [approveDialogOpen, setApproveDialogOpen] = useState(false);
  const [notifyDialogOpen, setNotifyDialogOpen] = useState(false);
  const [notifyMessage, setNotifyMessage] = useState("");

  const canApprove = permissions.canApproveAll || 
    (requestType === "ICT" && permissions.canManageICT) ||
    (requestType === "STORE" && permissions.canManageStore) ||
    (requestType === "VEHICLE" && permissions.canManageTransport);

  const isPending = status === "PENDING" || status === "CORRECTED";
  const isApproved = status === "APPROVED";
  const canNotify = isApproved && onNotify;

  return (
    <>
      <div className="flex flex-wrap gap-2">
        {canApprove && isPending && (
          <Button
            onClick={() => setApproveDialogOpen(true)}
            className="gap-2"
          >
            <CheckCircle2 className="h-4 w-4" />
            Approve
          </Button>
        )}

        {canApprove && isPending && onReject && (
          <Button
            variant="outline"
            onClick={() => {
              // Open reject dialog through approve dialog
              setApproveDialogOpen(true);
            }}
            className="gap-2"
          >
            <XCircle className="h-4 w-4" />
            Reject
          </Button>
        )}

        {canApprove && isPending && onSendBack && (
          <Button
            variant="outline"
            onClick={async () => {
              const reason = prompt("Reason for sending back:");
              if (reason) {
                try {
                  await onSendBack(reason);
                } catch (error) {
                  console.error("Failed to send back:", error);
                }
              }
            }}
            className="gap-2"
          >
            <Send className="h-4 w-4" />
            Send Back
          </Button>
        )}

        {canNotify && (
          <Button
            variant="outline"
            onClick={() => setNotifyDialogOpen(true)}
            className="gap-2"
          >
            <Send className="h-4 w-4" />
            Notify Requester
          </Button>
        )}

        {showHistory && (
          <Button
            variant="outline"
            onClick={showHistory}
            className="gap-2"
          >
            <History className="h-4 w-4" />
            View History
          </Button>
        )}
      </div>

      {approveDialogOpen && (
        <AdminApprovalDialog
          open={approveDialogOpen}
          onClose={() => setApproveDialogOpen(false)}
          onApprove={onApprove}
          onReject={onReject}
          requestType={requestType}
          currentStage={currentStage}
          canApproveAll={permissions.canApproveAll}
        />
      )}

      {notifyDialogOpen && onNotify && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-background p-6 rounded-lg max-w-md w-full space-y-4">
            <h3 className="text-lg font-semibold">Notify Requester</h3>
            <textarea
              value={notifyMessage}
              onChange={(e) => setNotifyMessage(e.target.value)}
              placeholder="Enter notification message..."
              className="w-full p-2 border rounded-md"
              rows={4}
            />
            <div className="flex justify-end gap-2">
              <Button
                variant="outline"
                onClick={() => {
                  setNotifyDialogOpen(false);
                  setNotifyMessage("");
                }}
              >
                Cancel
              </Button>
              <Button
                onClick={async () => {
                  try {
                    await onNotify(notifyMessage);
                    setNotifyDialogOpen(false);
                    setNotifyMessage("");
                  } catch (error) {
                    console.error("Failed to notify:", error);
                  }
                }}
                disabled={!notifyMessage.trim()}
              >
                Send
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
