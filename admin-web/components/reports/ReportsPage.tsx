"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { CalendarIcon, Download, FileSpreadsheet, FileText } from "lucide-react";
import { format, subDays, subMonths, startOfDay, endOfDay } from "date-fns";
import { cn } from "@/lib/utils";
import { DateRangePicker } from "./DateRangePicker";
import { ReportFilters } from "./ReportFilters";
import { ReportTable } from "./ReportTable";
import { ReportSummary } from "./ReportSummary";
import { ExportButtons } from "./ExportButtons";

export enum ReportType {
  REQUESTS = "REQUESTS",
  VEHICLES = "VEHICLES",
  DRIVERS = "DRIVERS",
  FULFILLMENT = "FULFILLMENT",
  APPROVALS = "APPROVALS",
  INVENTORY = "INVENTORY",
}

export enum RequestType {
  VEHICLE = "VEHICLE",
  ICT = "ICT",
  STORE = "STORE",
}

export enum RequestStatus {
  PENDING = "PENDING",
  APPROVED = "APPROVED",
  REJECTED = "REJECTED",
  CORRECTED = "CORRECTED",
  ASSIGNED = "ASSIGNED",
  PARTIAL_FULFILLMENT = "PARTIAL_FULFILLMENT",
  FULFILLED = "FULFILLED",
  COMPLETED = "COMPLETED",
}

interface ReportFilters {
  reportType: ReportType;
  startDate?: Date;
  endDate?: Date;
  requestType?: RequestType;
  status?: RequestStatus;
  departmentId?: string;
  userId?: string;
}

async function fetchReport(filters: ReportFilters) {
  const params = new URLSearchParams();
  if (filters.startDate) {
    params.append("startDate", filters.startDate.toISOString());
  }
  if (filters.endDate) {
    params.append("endDate", filters.endDate.toISOString());
  }
  if (filters.requestType) {
    params.append("requestType", filters.requestType);
  }
  if (filters.status) {
    params.append("status", filters.status);
  }
  if (filters.departmentId) {
    params.append("departmentId", filters.departmentId);
  }
  if (filters.userId) {
    params.append("userId", filters.userId);
  }

  const reportTypeMap: { [key: string]: string } = {
    [ReportType.REQUESTS]: "requests",
    [ReportType.VEHICLES]: "vehicles",
    [ReportType.DRIVERS]: "drivers",
    [ReportType.FULFILLMENT]: "fulfillment",
    [ReportType.APPROVALS]: "approvals",
    [ReportType.INVENTORY]: "inventory",
  };

  const url = `/api/reports/${reportTypeMap[filters.reportType]}?${params.toString()}`;
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load report");
  return res.json();
}

export function ReportsPage() {
  const [filters, setFilters] = useState<ReportFilters>({
    reportType: ReportType.REQUESTS,
  });

  const { data: reportData, isLoading, error } = useQuery({
    queryKey: ["report", filters],
    queryFn: () => fetchReport(filters),
    enabled: !!filters.reportType,
  });

  const handleDatePreset = (preset: "1d" | "3d" | "7d" | "1mo" | "custom") => {
    const now = new Date();
    let startDate: Date | undefined;
    let endDate: Date | undefined;

    switch (preset) {
      case "1d":
        startDate = startOfDay(subDays(now, 1));
        endDate = endOfDay(now);
        break;
      case "3d":
        startDate = startOfDay(subDays(now, 3));
        endDate = endOfDay(now);
        break;
      case "7d":
        startDate = startOfDay(subDays(now, 7));
        endDate = endOfDay(now);
        break;
      case "1mo":
        startDate = startOfDay(subMonths(now, 1));
        endDate = endOfDay(now);
        break;
      case "custom":
        // Keep current dates for custom selection
        return;
    }

    setFilters((prev) => ({ ...prev, startDate, endDate }));
  };

  const handleExport = async (format: "excel" | "pdf") => {
    try {
      const params = new URLSearchParams();
      params.append("reportType", filters.reportType);
      params.append("format", format.toUpperCase());
      if (filters.startDate) {
        params.append("startDate", filters.startDate.toISOString());
      }
      if (filters.endDate) {
        params.append("endDate", filters.endDate.toISOString());
      }
      if (filters.requestType) {
        params.append("requestType", filters.requestType);
      }
      if (filters.status) {
        params.append("status", filters.status);
      }
      if (filters.departmentId) {
        params.append("departmentId", filters.departmentId);
      }
      if (filters.userId) {
        params.append("userId", filters.userId);
      }

      const res = await fetch(`/api/reports/export?${params.toString()}`, {
        method: "POST",
      });

      if (!res.ok) {
        const error = await res.json().catch(() => ({ error: "Export failed" }));
        throw new Error(error.error || "Export failed");
      }

      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `report_${filters.reportType}_${new Date().toISOString().split("T")[0]}.${format === "excel" ? "xlsx" : "pdf"}`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (error: any) {
      console.error("Export error:", error);
      alert(error.message || "Failed to export report. Please try again.");
    }
  };

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-semibold">Reports</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Generate and export detailed reports
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Report Configuration</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="text-sm font-medium mb-2 block">Report Type</label>
              <Select
                value={filters.reportType}
                onValueChange={(value) =>
                  setFilters((prev) => ({ ...prev, reportType: value as ReportType }))
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={ReportType.REQUESTS}>Requests</SelectItem>
                  <SelectItem value={ReportType.VEHICLES}>Vehicles</SelectItem>
                  <SelectItem value={ReportType.DRIVERS}>Drivers</SelectItem>
                  <SelectItem value={ReportType.FULFILLMENT}>Fulfillment</SelectItem>
                  <SelectItem value={ReportType.APPROVALS}>Approvals</SelectItem>
                  <SelectItem value={ReportType.INVENTORY}>Inventory</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <DateRangePicker
              startDate={filters.startDate}
              endDate={filters.endDate}
              onStartDateChange={(date) =>
                setFilters((prev) => ({ ...prev, startDate: date }))
              }
              onEndDateChange={(date) =>
                setFilters((prev) => ({ ...prev, endDate: date }))
              }
              onPresetSelect={handleDatePreset}
            />
          </div>

          <ReportFilters
            filters={filters}
            onFiltersChange={setFilters}
            reportType={filters.reportType}
          />

          <div className="flex gap-2">
            <Button onClick={() => handleExport("excel")} disabled={!reportData}>
              <FileSpreadsheet className="mr-2 h-4 w-4" />
              Export Excel
            </Button>
            <Button onClick={() => handleExport("pdf")} disabled={!reportData} variant="outline">
              <FileText className="mr-2 h-4 w-4" />
              Export PDF
            </Button>
          </div>
        </CardContent>
      </Card>

      {reportData && <ReportSummary summary={reportData.summary} />}

      {isLoading && (
        <Card>
          <CardContent className="py-8">
            <div className="text-center text-muted-foreground">Loading report data...</div>
          </CardContent>
        </Card>
      )}

      {error && (
        <Card>
          <CardContent className="py-8">
            <div className="text-center text-destructive">
              Failed to load report. Please try again.
            </div>
          </CardContent>
        </Card>
      )}

      {reportData && !isLoading && !error && (
        <ReportTable data={reportData.data} reportType={filters.reportType} />
      )}
    </div>
  );
}
