"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { CheckCircle2, Clock, XCircle, Circle } from "lucide-react";
import { cn } from "@/lib/utils";

interface WorkflowStage {
  stage: string;
  role: string | null;
  description: string;
  timestamp?: string;
  approver?: string;
  status?: "completed" | "current" | "pending" | "rejected";
  comment?: string;
}

interface WorkflowTimelineProps {
  stages: WorkflowStage[];
  currentStage: string;
  approvals?: Array<{
    approverId: string | { _id: string; name: string; email: string };
    role: string;
    status: "APPROVED" | "REJECTED";
    comment?: string;
    timestamp: Date | string;
  }>;
}

export function WorkflowTimeline({ stages, currentStage, approvals = [] }: WorkflowTimelineProps) {
  const getStageStatus = (stage: WorkflowStage): "completed" | "current" | "pending" | "rejected" => {
    const stageIndex = stages.findIndex((s) => s.stage === stage.stage);
    const currentIndex = stages.findIndex((s) => s.stage === currentStage);

    if (stageIndex < currentIndex) {
      // Check if this stage was rejected
      const stageApproval = approvals.find(
        (a) => a.role === stage.role && a.status === "REJECTED"
      );
      if (stageApproval) return "rejected";
      return "completed";
    }
    if (stageIndex === currentIndex) {
      return "current";
    }
    return "pending";
  };

  const getStageIcon = (status: string) => {
    switch (status) {
      case "completed":
        return <CheckCircle2 className="h-5 w-5 text-green-600" />;
      case "current":
        return <Clock className="h-5 w-5 text-blue-600" />;
      case "rejected":
        return <XCircle className="h-5 w-5 text-red-600" />;
      default:
        return <Circle className="h-5 w-5 text-gray-400" />;
    }
  };

  const getApprovalForStage = (stage: WorkflowStage) => {
    return approvals.find((a) => a.role === stage.role);
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Workflow Timeline</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {stages.map((stage, index) => {
            const status = getStageStatus(stage);
            const approval = getApprovalForStage(stage);
            const isLast = index === stages.length - 1;

            return (
              <div key={stage.stage} className="relative">
                {!isLast && (
                  <div
                    className={cn(
                      "absolute left-[11px] top-8 w-0.5 h-full",
                      status === "completed" ? "bg-green-600" : "bg-gray-300"
                    )}
                  />
                )}
                <div className="flex items-start gap-4">
                  <div className="relative z-10 mt-0.5">
                    {getStageIcon(status)}
                  </div>
                  <div className="flex-1 space-y-1">
                    <div className="flex items-center gap-2">
                      <h4 className="font-medium">{stage.description}</h4>
                      <Badge
                        variant={
                          status === "completed"
                            ? "default"
                            : status === "current"
                            ? "secondary"
                            : status === "rejected"
                            ? "destructive"
                            : "outline"
                        }
                      >
                        {status === "completed"
                          ? "Completed"
                          : status === "current"
                          ? "Current"
                          : status === "rejected"
                          ? "Rejected"
                          : "Pending"}
                      </Badge>
                    </div>
                    {stage.role && (
                      <p className="text-sm text-muted-foreground">
                        Required Role: {stage.role}
                      </p>
                    )}
                    {approval && (
                      <div className="mt-2 p-2 bg-muted rounded-md">
                        <p className="text-sm">
                          <span className="font-medium">
                            {typeof approval.approverId === "object"
                              ? approval.approverId.name
                              : "Approver"}
                          </span>
                          {" - "}
                          <span
                            className={
                              approval.status === "APPROVED"
                                ? "text-green-600"
                                : "text-red-600"
                            }
                          >
                            {approval.status}
                          </span>
                        </p>
                        {approval.comment && (
                          <p className="text-sm text-muted-foreground mt-1">
                            {approval.comment}
                          </p>
                        )}
                        {approval.timestamp && (
                          <p className="text-xs text-muted-foreground mt-1">
                            {new Date(approval.timestamp).toLocaleString()}
                          </p>
                        )}
                      </div>
                    )}
                    {stage.timestamp && (
                      <p className="text-xs text-muted-foreground">
                        {new Date(stage.timestamp).toLocaleString()}
                      </p>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
