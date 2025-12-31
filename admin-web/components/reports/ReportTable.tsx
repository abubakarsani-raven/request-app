"use client";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ReportType } from "./ReportsPage";
import { format } from "date-fns";

interface ReportTableProps {
  data: any[];
  reportType: ReportType;
}

export function ReportTable({ data, reportType }: ReportTableProps) {
  if (!data || data.length === 0) {
    return (
      <Card>
        <CardContent className="py-8">
          <div className="text-center text-muted-foreground">No data available for this report.</div>
        </CardContent>
      </Card>
    );
  }

  const getHeaders = () => {
    switch (reportType) {
      case ReportType.REQUESTS:
        return ["ID", "Type", "Requester", "Email", "Department", "Status", "Workflow Stage", "Created At"];
      case ReportType.VEHICLES:
        return ["ID", "Plate Number", "Make", "Model", "Type", "Total Trips", "Active Trips", "Utilization Rate"];
      case ReportType.DRIVERS:
        return ["ID", "Name", "Phone", "License", "Total Trips", "Active Trips", "Performance Rating"];
      case ReportType.FULFILLMENT:
        return ["ID", "Type", "Requester", "Total Items", "Fulfilled Items", "Fulfillment Rate", "Status"];
      case ReportType.APPROVALS:
        return ["ID", "Type", "Workflow Stage", "Approval Status", "Approver Role", "Hours to Approve", "Approved At"];
      case ReportType.INVENTORY:
        return ["ID", "Type", "Name", "Category", "Quantity", "Low Stock Threshold", "Is Low Stock"];
      default:
        return [];
    }
  };

  const headers = getHeaders();

  return (
    <Card>
      <CardHeader>
        <CardTitle>Report Data ({data.length} records)</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                {headers.map((header) => (
                  <TableHead key={header}>{header}</TableHead>
                ))}
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.map((row, index) => (
                <TableRow key={row.id || index}>
                  {headers.map((header) => {
                    let value = "";
                    
                    // Map headers to actual data keys
                    if (header === "ID") {
                      value = row.id || row._id || "";
                    } else if (header === "Type") {
                      value = row.type || "";
                    } else if (header === "Requester") {
                      value = row.requester || "";
                    } else if (header === "Email") {
                      value = row.requesterEmail || row.email || "";
                    } else if (header === "Department") {
                      value = row.department || "";
                    } else if (header === "Status") {
                      value = row.status || "";
                    } else if (header === "Workflow Stage") {
                      value = row.workflowStage || "";
                    } else if (header === "Created At") {
                      value = row.createdAt || "";
                    } else {
                      // Fallback to key matching
                      const key = header.toLowerCase().replace(/\s+/g, "");
                      value = row[key] || row[header] || "";
                    }
                    
                    // Format dates
                    if (value && (header.includes("Date") || header.includes("At"))) {
                      try {
                        const dateValue = new Date(value);
                        if (!isNaN(dateValue.getTime())) {
                          value = format(dateValue, "PPP");
                        }
                      } catch {
                        // Keep original value if parsing fails
                      }
                    }

                    return <TableCell key={header}>{String(value || "")}</TableCell>;
                  })}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}
