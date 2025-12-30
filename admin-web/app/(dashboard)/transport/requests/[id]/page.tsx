import { notFound } from "next/navigation";
import { cookies } from "next/headers";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import { 
  MapPin, 
  Calendar, 
  Clock, 
  User, 
  Car, 
  Navigation, 
  Fuel, 
  Route,
  CheckCircle2,
  XCircle,
  AlertCircle,
  FileText,
  Building
} from "lucide-react";
import { TransportRequestAdminActions } from "@/components/transport/TransportRequestAdminActions";
import { WorkflowTimeline } from "@/components/admin-approval/WorkflowTimeline";

type RequestDetails = {
  _id: string;
  destination?: string;
  purpose?: string;
  tripDate?: string | Date;
  tripTime?: string;
  returnDate?: string | Date;
  returnTime?: string;
  status: string;
  workflowStage?: string;
  priority?: boolean;
  requesterId?: {
    _id?: string;
    name?: string;
    email?: string;
    departmentId?: {
      name?: string;
    } | string;
  } | string;
  driverId?: {
    _id?: string;
    name?: string;
    email?: string;
    phone?: string;
  } | string | null;
  vehicleId?: {
    _id?: string;
    plateNumber?: string;
    make?: string;
    model?: string;
    capacity?: number;
  } | string | null;
  approvals?: Array<{
    approverId?: {
      name?: string;
    } | string;
    role?: string;
    status?: string;
    comment?: string;
    timestamp?: string | Date;
  }>;
  corrections?: Array<{
    comment?: string;
    timestamp?: string | Date;
    resolved?: boolean;
  }>;
  officeLocation?: {
    latitude?: number;
    longitude?: number;
  } | null;
  startLocation?: {
    latitude?: number;
    longitude?: number;
  } | null;
  destinationLocation?: {
    latitude?: number;
    longitude?: number;
  } | null;
  requestedDestinationLocation?: {
    latitude?: number;
    longitude?: number;
  } | null;
  returnLocation?: {
    latitude?: number;
    longitude?: number;
  } | null;
  dropOffLocation?: {
    latitude?: number;
    longitude?: number;
  } | null;
  waypoints?: Array<{
    name?: string;
    latitude?: number;
    longitude?: number;
    order?: number;
    reached?: boolean;
    reachedTime?: string | Date | null;
    distanceFromPrevious?: number | null;
    fuelFromPrevious?: number | null;
  }>;
  outboundDistanceKm?: number | null;
  returnDistanceKm?: number | null;
  totalDistanceKm?: number | null;
  totalTripDistanceKm?: number | null;
  outboundFuelLiters?: number | null;
  returnFuelLiters?: number | null;
  totalFuelLiters?: number | null;
  totalTripFuelLiters?: number | null;
  tripStarted?: boolean;
  destinationReached?: boolean;
  tripCompleted?: boolean;
  actualDepartureTime?: string | Date | null;
  destinationReachedTime?: string | Date | null;
  actualReturnTime?: string | Date | null;
  createdAt?: string | Date;
  updatedAt?: string | Date;
};

async function fetchRequest(id: string): Promise<RequestDetails | null> {
  try {
    const cookieStore = await cookies();
    const token = cookieStore.get("access_token")?.value;
    
    const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:4000";
    const res = await fetch(`${apiBase}/vehicles/requests/${id}`, {
      cache: "no-store",
      headers: token ? {
        Authorization: `Bearer ${token}`,
      } : {},
    });

    if (res.status === 404) return null;
    if (!res.ok) {
      console.error("Failed to load request details", res.status);
      return null;
    }

    return res.json();
  } catch (error) {
    console.error("Error fetching request:", error);
    return null;
  }
}

function formatStatus(status: string) {
  if (!status) return "Unknown";
  return status
    .split("_")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join(" ");
}

function formatDate(value?: string | Date | null) {
  if (!value) return "N/A";
  const d = typeof value === "string" ? new Date(value) : value;
  if (Number.isNaN(d.getTime())) return "N/A";
  return d.toLocaleString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatDateOnly(value?: string | Date | null) {
  if (!value) return "N/A";
  const d = typeof value === "string" ? new Date(value) : value;
  if (Number.isNaN(d.getTime())) return "N/A";
  return d.toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

function getStatusVariant(status: string) {
  const upper = status.toUpperCase();
  if (upper === "COMPLETED") return "default";
  if (upper === "APPROVED" || upper === "ASSIGNED") return "secondary";
  if (upper === "PENDING" || upper === "SUBMITTED") return "outline";
  if (upper === "REJECTED") return "destructive";
  return "outline";
}

function getApprovalStatusIcon(status?: string) {
  if (!status) return <AlertCircle className="h-4 w-4" />;
  const upper = status.toUpperCase();
  if (upper === "APPROVED") return <CheckCircle2 className="h-4 w-4 text-green-600" />;
  if (upper === "REJECTED") return <XCircle className="h-4 w-4 text-red-600" />;
  return <AlertCircle className="h-4 w-4 text-yellow-600" />;
}

export default async function TransportRequestDetailsPage({ 
  params 
}: { 
  params: Promise<{ id: string }> 
}) {
  const { id } = await params;
  const request = await fetchRequest(id);
  
  if (!request) {
    notFound();
  }

  // Extract populated data
  const requester = typeof request.requesterId === "object" && request.requesterId !== null
    ? request.requesterId
    : null;
  const driver = typeof request.driverId === "object" && request.driverId !== null
    ? request.driverId
    : null;
  const vehicle = typeof request.vehicleId === "object" && request.vehicleId !== null
    ? request.vehicleId
    : null;
  const department = requester?.departmentId && typeof requester.departmentId === "object"
    ? requester.departmentId
    : null;

  const approvals = request.approvals || [];
  const corrections = request.corrections || [];
  const waypoints = request.waypoints || [];

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Request Details</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Request ID: {request._id.slice(-8)}
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/transport/requests">
            ← Back to Requests
          </Link>
        </Button>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Main Content - Left Column (2/3 width) */}
        <div className="lg:col-span-2 space-y-6">
          {/* Request Overview */}
          <Card>
            <CardHeader>
              <div className="flex items-start justify-between">
                <div className="space-y-1">
                  <CardTitle className="text-2xl">{request.destination || "Unknown Destination"}</CardTitle>
                  {request.purpose && (
                    <CardDescription className="text-base mt-2">{request.purpose}</CardDescription>
                  )}
                </div>
                <div className="flex flex-col items-end gap-2">
                  <Badge variant={getStatusVariant(request.status)} className="text-sm">
                    {formatStatus(request.status)}
                  </Badge>
                  {request.priority && (
                    <Badge variant="destructive" className="text-xs">Priority</Badge>
                  )}
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-6">
              <TransportRequestAdminActions
                requestId={request._id}
                currentStage={request.workflowStage || "SUBMITTED"}
                status={request.status}
              />
              {/* Trip Dates */}
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Calendar className="h-4 w-4" />
                    <span>Trip Date</span>
                  </div>
                  <p className="text-base font-medium">
                    {formatDateOnly(request.tripDate)}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {request.tripTime || "N/A"}
                  </p>
                </div>
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Calendar className="h-4 w-4" />
                    <span>Return Date</span>
                  </div>
                  <p className="text-base font-medium">
                    {formatDateOnly(request.returnDate)}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {request.returnTime || "N/A"}
                  </p>
                </div>
              </div>

              <Separator />

              {/* Requester & Assignment */}
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <User className="h-4 w-4" />
                    <span>Requester</span>
                  </div>
                  <p className="text-base font-medium">
                    {requester?.name || "Unknown"}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {requester?.email || "N/A"}
                  </p>
                  {department && (
                    <p className="text-xs text-muted-foreground">
                      {typeof department === "object" ? department.name : "N/A"}
                    </p>
                  )}
                </div>
                <div className="space-y-3">
                  <div className="space-y-2">
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <User className="h-4 w-4" />
                      <span>Driver</span>
                    </div>
                    <p className="text-base font-medium">
                      {driver?.name || "Not assigned"}
                    </p>
                    {driver?.phone && (
                      <p className="text-sm text-muted-foreground">{driver.phone}</p>
                    )}
                  </div>
                  <div className="space-y-2">
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <Car className="h-4 w-4" />
                      <span>Vehicle</span>
                    </div>
                    <p className="text-base font-medium">
                      {vehicle
                        ? `${vehicle.plateNumber || "N/A"} • ${[vehicle.make, vehicle.model]
                            .filter(Boolean)
                            .join(" ")}`
                        : "Not assigned"}
                    </p>
                    {vehicle?.capacity && (
                      <p className="text-sm text-muted-foreground">
                        Capacity: {vehicle.capacity} passengers
                      </p>
                    )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Trip Plan */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Route className="h-5 w-5" />
                Trip Plan
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Office/Start Location */}
              {request.officeLocation && (
                <div className="flex items-start gap-3 p-3 bg-muted/50 rounded-lg">
                  <div className="mt-0.5">
                    <Building className="h-5 w-5 text-primary" />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium">Start Point (Office)</p>
                    <p className="text-xs text-muted-foreground">
                      {request.officeLocation.latitude?.toFixed(6)}, {request.officeLocation.longitude?.toFixed(6)}
                    </p>
                  </div>
                </div>
              )}

              {/* Waypoints */}
              {waypoints.length > 0 && (
                <div className="space-y-2">
                  <p className="text-sm font-medium text-muted-foreground">Pickup Points</p>
                  {waypoints
                    .sort((a, b) => (a.order || 0) - (b.order || 0))
                    .map((waypoint, idx) => (
                      <div key={idx} className="flex items-start gap-3 p-3 bg-muted/30 rounded-lg border">
                        <div className="mt-0.5">
                          <div className="h-6 w-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-xs font-bold">
                            {waypoint.order || idx + 1}
                          </div>
                        </div>
                        <div className="flex-1">
                          <p className="text-sm font-medium">{waypoint.name || `Stop ${waypoint.order || idx + 1}`}</p>
                          <p className="text-xs text-muted-foreground">
                            {waypoint.latitude?.toFixed(6)}, {waypoint.longitude?.toFixed(6)}
                          </p>
                          {waypoint.distanceFromPrevious != null && (
                            <p className="text-xs text-muted-foreground mt-1">
                              Distance: {waypoint.distanceFromPrevious.toFixed(2)} km
                            </p>
                          )}
                        </div>
                        {waypoint.reached && (
                          <Badge variant="default" className="text-xs">
                            <CheckCircle2 className="h-3 w-3 mr-1" />
                            Reached
                          </Badge>
                        )}
                      </div>
                    ))}
                </div>
              )}

              {/* Destination */}
              {request.requestedDestinationLocation && (
                <div className="flex items-start gap-3 p-3 bg-primary/10 rounded-lg border border-primary/20">
                  <div className="mt-0.5">
                    <MapPin className="h-5 w-5 text-primary" />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium">Destination</p>
                    <p className="text-sm">{request.destination || "Unknown"}</p>
                    <p className="text-xs text-muted-foreground">
                      {request.requestedDestinationLocation.latitude?.toFixed(6)}, {request.requestedDestinationLocation.longitude?.toFixed(6)}
                    </p>
                  </div>
                  {request.destinationReached && (
                    <Badge variant="default" className="text-xs">
                      <CheckCircle2 className="h-3 w-3 mr-1" />
                      Reached
                    </Badge>
                  )}
                </div>
              )}

              {/* Drop-off Location */}
              {request.dropOffLocation && (
                <div className="flex items-start gap-3 p-3 bg-muted/50 rounded-lg">
                  <div className="mt-0.5">
                    <Navigation className="h-5 w-5 text-secondary" />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium">Drop-off Point</p>
                    <p className="text-xs text-muted-foreground">
                      {request.dropOffLocation.latitude?.toFixed(6)}, {request.dropOffLocation.longitude?.toFixed(6)}
                    </p>
                  </div>
                </div>
              )}

              {/* Return to Office */}
              {request.returnLocation && (
                <div className="flex items-start gap-3 p-3 bg-muted/50 rounded-lg">
                  <div className="mt-0.5">
                    <Building className="h-5 w-5 text-secondary" />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium">Return to Office</p>
                    <p className="text-xs text-muted-foreground">
                      {request.returnLocation.latitude?.toFixed(6)}, {request.returnLocation.longitude?.toFixed(6)}
                    </p>
                  </div>
                  {request.tripCompleted && (
                    <Badge variant="default" className="text-xs">
                      <CheckCircle2 className="h-3 w-3 mr-1" />
                      Completed
                    </Badge>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Workflow Timeline */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Workflow Timeline
              </CardTitle>
            </CardHeader>
            <CardContent>
              <WorkflowTimeline
                stages={[
                  { stage: 'SUBMITTED', role: null, description: 'Request Submitted' },
                  { stage: 'SUPERVISOR_REVIEW', role: 'SUPERVISOR', description: 'Supervisor Review' },
                  { stage: 'DDGS_REVIEW', role: 'DDGS', description: 'DDGS Review' },
                  { stage: 'ADGS_REVIEW', role: 'ADGS', description: 'ADGS Review' },
                  { stage: 'DGS_REVIEW', role: 'DGS', description: 'DGS Review' },
                  { stage: 'TO_REVIEW', role: 'TO', description: 'Transport Officer Review' },
                  { stage: 'ASSIGNED', role: 'TO', description: 'Assigned' },
                ]}
                currentStage={request.workflowStage || "SUBMITTED"}
                approvals={approvals}
              />
            </CardContent>
          </Card>

          {/* Approvals & Corrections */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Approvals & Corrections
              </CardTitle>
              {request.workflowStage && (
                <CardDescription>
                  Current Stage: {formatStatus(request.workflowStage)}
                </CardDescription>
              )}
            </CardHeader>
            <CardContent className="space-y-4">
              {approvals.length > 0 ? (
                <div className="space-y-3">
                  {approvals.map((approval, idx) => {
                    const approver = typeof approval.approverId === "object" && approval.approverId !== null
                      ? approval.approverId
                      : null;
                    return (
                      <div key={idx} className="flex items-start gap-3 p-3 border rounded-lg">
                        <div className="mt-0.5">
                          {getApprovalStatusIcon(approval.status)}
                        </div>
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <p className="text-sm font-medium">
                              {approval.role || "Approver"}
                            </p>
                            <Badge 
                              variant={approval.status === "APPROVED" ? "default" : approval.status === "REJECTED" ? "destructive" : "outline"}
                              className="text-xs"
                            >
                              {approval.status || "Pending"}
                            </Badge>
                          </div>
                          {approver && typeof approver === "object" && (
                            <p className="text-xs text-muted-foreground mt-1">
                              {approver.name || "Unknown"}
                            </p>
                          )}
                          {approval.comment && (
                            <p className="text-sm text-muted-foreground mt-2">
                              "{approval.comment}"
                            </p>
                          )}
                          {approval.timestamp && (
                            <p className="text-xs text-muted-foreground mt-1">
                              {formatDate(approval.timestamp)}
                            </p>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="text-sm text-muted-foreground">No approvals recorded yet</p>
              )}

              {/* Corrections */}
              {corrections.length > 0 && (
                <div className="mt-4 space-y-2">
                  <p className="text-sm font-medium">Corrections Requested</p>
                  {corrections.map((correction, idx) => (
                    <div key={idx} className="p-3 bg-yellow-50 dark:bg-yellow-950/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                      <p className="text-sm">{correction.comment || "No comment"}</p>
                      <div className="flex items-center gap-2 mt-2">
                        <p className="text-xs text-muted-foreground">
                          {formatDate(correction.timestamp)}
                        </p>
                        {correction.resolved && (
                          <Badge variant="default" className="text-xs">Resolved</Badge>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Sidebar - Right Column (1/3 width) */}
        <div className="space-y-6">
          {/* Trip Status */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Trip Status</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Trip Started</span>
                <Badge variant={request.tripStarted ? "default" : "outline"}>
                  {request.tripStarted ? "Yes" : "No"}
                </Badge>
              </div>
              {request.actualDepartureTime && (
                <div className="space-y-1">
                  <p className="text-xs text-muted-foreground">Actual Departure</p>
                  <p className="text-sm">{formatDate(request.actualDepartureTime)}</p>
                </div>
              )}
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Destination Reached</span>
                <Badge variant={request.destinationReached ? "default" : "outline"}>
                  {request.destinationReached ? "Yes" : "No"}
                </Badge>
              </div>
              {request.destinationReachedTime && (
                <div className="space-y-1">
                  <p className="text-xs text-muted-foreground">Reached At</p>
                  <p className="text-sm">{formatDate(request.destinationReachedTime)}</p>
                </div>
              )}
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Trip Completed</span>
                <Badge variant={request.tripCompleted ? "default" : "outline"}>
                  {request.tripCompleted ? "Yes" : "No"}
                </Badge>
              </div>
              {request.actualReturnTime && (
                <div className="space-y-1">
                  <p className="text-xs text-muted-foreground">Returned At</p>
                  <p className="text-sm">{formatDate(request.actualReturnTime)}</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Trip Metrics */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Navigation className="h-4 w-4" />
                Trip Metrics
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Outbound Distance</span>
                  <span className="text-sm font-medium">
                    {request.outboundDistanceKm != null 
                      ? `${request.outboundDistanceKm.toFixed(2)} km` 
                      : "N/A"}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Return Distance</span>
                  <span className="text-sm font-medium">
                    {request.returnDistanceKm != null 
                      ? `${request.returnDistanceKm.toFixed(2)} km` 
                      : "N/A"}
                  </span>
                </div>
                <Separator />
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium">Total Distance</span>
                  <span className="text-base font-bold">
                    {(request.totalTripDistanceKm ?? request.totalDistanceKm) != null 
                      ? `${(request.totalTripDistanceKm ?? request.totalDistanceKm)!.toFixed(2)} km` 
                      : "N/A"}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Fuel Consumption */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Fuel className="h-4 w-4" />
                Fuel Consumption
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Outbound Fuel</span>
                  <span className="text-sm font-medium">
                    {request.outboundFuelLiters != null 
                      ? `${request.outboundFuelLiters.toFixed(2)} L` 
                      : "N/A"}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Return Fuel</span>
                  <span className="text-sm font-medium">
                    {request.returnFuelLiters != null 
                      ? `${request.returnFuelLiters.toFixed(2)} L` 
                      : "N/A"}
                  </span>
                </div>
                <Separator />
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium">Total Fuel</span>
                  <span className="text-base font-bold">
                    {(request.totalTripFuelLiters ?? request.totalFuelLiters) != null 
                      ? `${(request.totalTripFuelLiters ?? request.totalFuelLiters)!.toFixed(2)} L` 
                      : "N/A"}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Request Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Request Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Created</span>
                <span>{formatDate(request.createdAt)}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Last Updated</span>
                <span>{formatDate(request.updatedAt)}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
