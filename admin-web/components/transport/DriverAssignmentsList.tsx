"use client";

import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";
import { ExternalLink, Calendar, MapPin, Car, User, Clock } from "lucide-react";

type Assignment = {
  _id: string;
  destination: string;
  purpose: string;
  tripDate: string | Date;
  tripTime: string;
  returnDate: string | Date;
  returnTime: string;
  status: string;
  workflowStage: string;
  requesterId: {
    _id: string;
    name: string;
    email: string;
  } | string;
  vehicleId: {
    _id: string;
    plateNumber: string;
    make: string;
    model: string;
  } | string | null;
  tripStarted: boolean;
  tripCompleted: boolean;
  createdAt: string | Date;
};

interface DriverAssignmentsListProps {
  driverId: string;
  showHistory?: boolean;
}

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) {
    throw new Error(`Failed to fetch: ${res.status}`);
  }
  return res.json();
}

function getStatusVariant(status: string) {
  switch (status?.toUpperCase()) {
    case "PENDING":
      return "default";
    case "APPROVED":
      return "secondary";
    case "ASSIGNED":
      return "outline";
    case "COMPLETED":
      return "default";
    case "REJECTED":
      return "destructive";
    case "CANCELLED":
      return "destructive";
    default:
      return "outline";
  }
}

function getStatusLabel(status: string) {
  switch (status?.toUpperCase()) {
    case "PENDING":
      return "Pending";
    case "APPROVED":
      return "Approved";
    case "ASSIGNED":
      return "Assigned";
    case "COMPLETED":
      return "Completed";
    case "REJECTED":
      return "Rejected";
    case "CANCELLED":
      return "Cancelled";
    default:
      return status;
  }
}

export function DriverAssignmentsList({ driverId, showHistory = true }: DriverAssignmentsListProps) {
  const { data: assignments = [], isLoading, error } = useQuery<Assignment[]>({
    queryKey: ["driver-assignments", driverId],
    queryFn: () => fetchJSON<Assignment[]>(`/api/drivers/${driverId}/assignments`),
    enabled: !!driverId,
  });

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Assignments</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Request ID</TableHead>
                <TableHead>Destination</TableHead>
                <TableHead>Trip Date</TableHead>
                <TableHead>Vehicle</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <SkeletonTableRows rows={3} cols={6} />
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Assignments</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">Failed to load assignments</p>
        </CardContent>
      </Card>
    );
  }

  const activeAssignments = assignments.filter(
    (a) => !a.tripCompleted && (a.status === "ASSIGNED" || a.status === "APPROVED" || a.tripStarted)
  );
  const completedAssignments = assignments.filter((a) => a.tripCompleted || a.status === "COMPLETED");
  const otherAssignments = assignments.filter(
    (a) => !activeAssignments.includes(a) && !completedAssignments.includes(a)
  );

  const displayAssignments = showHistory ? assignments : activeAssignments;

  if (displayAssignments.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Assignments</CardTitle>
          <CardDescription>No assignments found</CardDescription>
        </CardHeader>
      </Card>
    );
  }

  const formatDate = (date: string | Date) => {
    if (!date) return "N/A";
    const d = typeof date === "string" ? new Date(date) : date;
    return d.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  const getRequesterDisplay = (requester: Assignment["requesterId"]) => {
    if (typeof requester !== "object" || requester === null) return "Unknown";
    const name = requester.name || requester.email || "Unknown";
    const dept = (requester as { departmentId?: { name: string } }).departmentId?.name;
    return dept ? `${name} (${dept})` : name;
  };

  const getVehicleInfo = (vehicle: Assignment["vehicleId"]) => {
    if (!vehicle) return "N/A";
    if (typeof vehicle === "object" && vehicle !== null) {
      return `${vehicle.plateNumber} (${vehicle.make} ${vehicle.model})`;
    }
    return "N/A";
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Assignments</CardTitle>
        <CardDescription>
          {showHistory
            ? `${assignments.length} total assignment(s) - ${activeAssignments.length} active, ${completedAssignments.length} completed`
            : `${activeAssignments.length} active assignment(s)`}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {showHistory && activeAssignments.length > 0 && (
            <div>
              <h4 className="text-sm font-semibold mb-2">Active Assignments</h4>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Requester</TableHead>
                    <TableHead>Destination</TableHead>
                    <TableHead>Trip Date</TableHead>
                    <TableHead>Vehicle</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {activeAssignments.map((assignment) => (
                    <TableRow key={assignment._id}>
                      <TableCell>{getRequesterDisplay(assignment.requesterId)}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <MapPin className="h-4 w-4 text-muted-foreground" />
                          <span className="max-w-[200px] truncate">{assignment.destination}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-muted-foreground" />
                          <span>{formatDate(assignment.tripDate)}</span>
                        </div>
                        <div className="text-xs text-muted-foreground">{assignment.tripTime}</div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Car className="h-4 w-4 text-muted-foreground" />
                          <span>{getVehicleInfo(assignment.vehicleId)}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={getStatusVariant(assignment.status)}>
                          {getStatusLabel(assignment.status)}
                        </Badge>
                        {assignment.tripStarted && (
                          <Badge variant="outline" className="ml-2">
                            In Progress
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <Link
                          href={`/transport/requests/${assignment._id}`}
                          className="text-primary hover:underline flex items-center gap-1"
                        >
                          View <ExternalLink className="h-3 w-3" />
                        </Link>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}

          {showHistory && completedAssignments.length > 0 && (
            <div>
              <h4 className="text-sm font-semibold mb-2">Completed Assignments</h4>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Requester</TableHead>
                    <TableHead>Destination</TableHead>
                    <TableHead>Trip Date</TableHead>
                    <TableHead>Vehicle</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {completedAssignments.map((assignment) => (
                    <TableRow key={assignment._id}>
                      <TableCell>{getRequesterDisplay(assignment.requesterId)}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <MapPin className="h-4 w-4 text-muted-foreground" />
                          <span className="max-w-[200px] truncate">{assignment.destination}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-muted-foreground" />
                          <span>{formatDate(assignment.tripDate)}</span>
                        </div>
                        <div className="text-xs text-muted-foreground">{assignment.tripTime}</div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Car className="h-4 w-4 text-muted-foreground" />
                          <span>{getVehicleInfo(assignment.vehicleId)}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={getStatusVariant(assignment.status)}>
                          {getStatusLabel(assignment.status)}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Link
                          href={`/transport/requests/${assignment._id}`}
                          className="text-primary hover:underline flex items-center gap-1"
                        >
                          View <ExternalLink className="h-3 w-3" />
                        </Link>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}

          {showHistory && otherAssignments.length > 0 && (
            <div>
              <h4 className="text-sm font-semibold mb-2">Other Assignments</h4>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Request ID</TableHead>
                    <TableHead>Destination</TableHead>
                    <TableHead>Trip Date</TableHead>
                    <TableHead>Vehicle</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {otherAssignments.map((assignment) => (
                    <TableRow key={assignment._id}>
                      <TableCell className="font-mono text-xs">{assignment._id.slice(-8)}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <MapPin className="h-4 w-4 text-muted-foreground" />
                          <span className="max-w-[200px] truncate">{assignment.destination}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-muted-foreground" />
                          <span>{formatDate(assignment.tripDate)}</span>
                        </div>
                        <div className="text-xs text-muted-foreground">{assignment.tripTime}</div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Car className="h-4 w-4 text-muted-foreground" />
                          <span>{getVehicleInfo(assignment.vehicleId)}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={getStatusVariant(assignment.status)}>
                          {getStatusLabel(assignment.status)}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Link
                          href={`/transport/requests/${assignment._id}`}
                          className="text-primary hover:underline flex items-center gap-1"
                        >
                          View <ExternalLink className="h-3 w-3" />
                        </Link>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}

          {!showHistory && displayAssignments.length > 0 && (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Request ID</TableHead>
                  <TableHead>Destination</TableHead>
                  <TableHead>Trip Date</TableHead>
                  <TableHead>Vehicle</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {displayAssignments.map((assignment) => (
                  <TableRow key={assignment._id}>
                    <TableCell className="font-mono text-xs">{assignment._id.slice(-8)}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-muted-foreground" />
                        <span className="max-w-[200px] truncate">{assignment.destination}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Calendar className="h-4 w-4 text-muted-foreground" />
                        <span>{formatDate(assignment.tripDate)}</span>
                      </div>
                      <div className="text-xs text-muted-foreground">{assignment.tripTime}</div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Car className="h-4 w-4 text-muted-foreground" />
                        <span>{getVehicleInfo(assignment.vehicleId)}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant={getStatusVariant(assignment.status)}>
                        {getStatusLabel(assignment.status)}
                      </Badge>
                      {assignment.tripStarted && (
                        <Badge variant="outline" className="ml-2">
                          In Progress
                        </Badge>
                      )}
                    </TableCell>
                    <TableCell>
                      <Link
                        href={`/transport/requests/${assignment._id}`}
                        className="text-primary hover:underline flex items-center gap-1"
                      >
                        View <ExternalLink className="h-3 w-3" />
                      </Link>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

