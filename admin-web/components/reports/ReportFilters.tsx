"use client";

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ReportType, RequestType, RequestStatus } from "./ReportsPage";

interface ReportFiltersProps {
  filters: any;
  onFiltersChange: (filters: any) => void;
  reportType: ReportType;
}

export function ReportFilters({ filters, onFiltersChange, reportType }: ReportFiltersProps) {
  if (reportType !== ReportType.REQUESTS && reportType !== ReportType.FULFILLMENT && reportType !== ReportType.APPROVALS) {
    return null;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {reportType === ReportType.REQUESTS && (
        <div>
          <Label>Request Type</Label>
          <Select
            value={filters.requestType || "__all__"}
            onValueChange={(value) =>
              onFiltersChange({ ...filters, requestType: value === "__all__" ? undefined : value })
            }
          >
            <SelectTrigger>
              <SelectValue placeholder="All Types" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="__all__">All Types</SelectItem>
              <SelectItem value={RequestType.VEHICLE}>Vehicle</SelectItem>
              <SelectItem value={RequestType.ICT}>ICT</SelectItem>
              <SelectItem value={RequestType.STORE}>Store</SelectItem>
            </SelectContent>
          </Select>
        </div>
      )}

      {(reportType === ReportType.REQUESTS || reportType === ReportType.APPROVALS) && (
        <div>
          <Label>Status</Label>
          <Select
            value={filters.status || "__all__"}
            onValueChange={(value) =>
              onFiltersChange({ ...filters, status: value === "__all__" ? undefined : value })
            }
          >
            <SelectTrigger>
              <SelectValue placeholder="All Statuses" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="__all__">All Statuses</SelectItem>
              <SelectItem value={RequestStatus.PENDING}>Pending</SelectItem>
              <SelectItem value={RequestStatus.APPROVED}>Approved</SelectItem>
              <SelectItem value={RequestStatus.REJECTED}>Rejected</SelectItem>
              <SelectItem value={RequestStatus.ASSIGNED}>Assigned</SelectItem>
              <SelectItem value={RequestStatus.FULFILLED}>Fulfilled</SelectItem>
              <SelectItem value={RequestStatus.COMPLETED}>Completed</SelectItem>
            </SelectContent>
          </Select>
        </div>
      )}

      <div>
        <Label>Department ID</Label>
        <Input
          placeholder="Filter by department"
          value={filters.departmentId || ""}
          onChange={(e) =>
            onFiltersChange({ ...filters, departmentId: e.target.value || undefined })
          }
        />
      </div>

      <div>
        <Label>User ID</Label>
        <Input
          placeholder="Filter by user"
          value={filters.userId || ""}
          onChange={(e) =>
            onFiltersChange({ ...filters, userId: e.target.value || undefined })
          }
        />
      </div>
    </div>
  );
}
