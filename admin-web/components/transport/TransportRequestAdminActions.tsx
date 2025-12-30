"use client";

import { useParams, useRouter } from "next/navigation";
import { useQueryClient } from "@tanstack/react-query";
import { RequestActions } from "@/components/admin-approval/RequestActions";
import { useToast } from "@/components/ui/use-toast";
import { useAdminPermissions } from "@/hooks/useAdminPermissions";

interface TransportRequestAdminActionsProps {
  requestId: string;
  currentStage: string;
  status: string;
}

export function TransportRequestAdminActions({
  requestId,
  currentStage,
  status,
}: TransportRequestAdminActionsProps) {
  const router = useRouter();
  const qc = useQueryClient();
  const { success, error } = useToast();
  const permissions = useAdminPermissions();

  const handleApprove = async (comment: string, isAdminApproval: boolean) => {
    try {
      const res = await fetch(`/api/transport/requests/${requestId}/approve`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          comment: comment || undefined,
          isAdminApproval: isAdminApproval || undefined,
        }),
      });

      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["transport-request", requestId] });
        qc.invalidateQueries({ queryKey: ["transport-requests"] });
        success("Request approved successfully");
        router.refresh();
      } else {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.message || "Failed to approve request");
      }
    } catch (err: any) {
      throw err;
    }
  };

  const handleReject = async (reason: string) => {
    try {
      const res = await fetch(`/api/transport/requests/${requestId}/reject`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ reason }),
      });

      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["transport-request", requestId] });
        qc.invalidateQueries({ queryKey: ["transport-requests"] });
        success("Request rejected successfully");
        router.refresh();
      } else {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.message || "Failed to reject request");
      }
    } catch (err: any) {
      throw err;
    }
  };

  const canApprove = permissions.canManageTransport || permissions.canApproveAll;

  if (!canApprove) return null;

  return (
    <div className="mt-4">
      <RequestActions
        requestId={requestId}
        requestType="VEHICLE"
        currentStage={currentStage}
        status={status}
        onApprove={handleApprove}
        onReject={handleReject}
      />
    </div>
  );
}
