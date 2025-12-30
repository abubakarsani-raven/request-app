'use client'

import { useState, useEffect } from 'react'
import api from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Badge } from '@/components/ui/badge'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Eye,
  CheckCircle2,
  XCircle,
  AlertCircle,
  Truck,
  Calendar,
  MapPin,
  User,
} from 'lucide-react'
import { format } from 'date-fns'
import WorkflowVisualization from './WorkflowVisualization'

interface VehicleRequest {
  _id: string
  requesterId: {
    _id: string
    name: string
    email: string
  }
  tripDate: string
  tripTime: string
  returnDate: string
  returnTime: string
  destination: string
  purpose: string
  status: string
  workflowStage: string
  priority: boolean
  vehicleId?: {
    _id: string
    plateNumber: string
  }
  driverId?: {
    _id: string
    name: string
  }
  approvals: Approval[]
  createdAt: string
  requestedDestinationLocation?: {
    latitude: number
    longitude: number
  }
}

interface Approval {
  approverId: string
  role: string
  status: 'APPROVED' | 'REJECTED'
  comment?: string
  timestamp: string
}

const workflowStages = [
  { stage: 'SUBMITTED', role: null, description: 'Request Submitted' },
  { stage: 'SUPERVISOR_REVIEW', role: 'SUPERVISOR', description: 'Supervisor Review' },
  { stage: 'DGS_REVIEW', role: 'DGS', description: 'DGS Review' },
  { stage: 'DDGS_REVIEW', role: 'DDGS', description: 'DDGS Review' },
  { stage: 'ADGS_REVIEW', role: 'ADGS', description: 'ADGS Review' },
  { stage: 'TO_REVIEW', role: 'TO', description: 'Transport Officer Assignment' },
]

export default function RequestsMonitoring() {
  const [requests, setRequests] = useState<VehicleRequest[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [selectedRequest, setSelectedRequest] = useState<VehicleRequest | null>(null)
  const [isDetailsDialogOpen, setIsDetailsDialogOpen] = useState(false)
  const [isApproveDialogOpen, setIsApproveDialogOpen] = useState(false)
  const [isRejectDialogOpen, setIsRejectDialogOpen] = useState(false)
  const [isAssignDialogOpen, setIsAssignDialogOpen] = useState(false)
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [availableVehicles, setAvailableVehicles] = useState<any[]>([])
  const [availableDrivers, setAvailableDrivers] = useState<any[]>([])
  const [selectedVehicleId, setSelectedVehicleId] = useState<string>('')
  const [selectedDriverId, setSelectedDriverId] = useState<string>('')
  const [approveComment, setApproveComment] = useState('')
  const [rejectComment, setRejectComment] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  const fetchRequests = async () => {
    try {
      setLoading(true)
      const response = await api.get('/vehicles/requests')
      setRequests(response.data)
      setError('')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch requests')
    } finally {
      setLoading(false)
    }
  }

  const fetchAvailableVehicles = async () => {
    try {
      const response = await api.get('/vehicles/vehicles?available=true')
      setAvailableVehicles(response.data)
    } catch (err) {
      console.error('Failed to fetch vehicles', err)
    }
  }

  const fetchAvailableDrivers = async () => {
    try {
      const response = await api.get('/vehicles/drivers?available=true')
      setAvailableDrivers(response.data)
    } catch (err) {
      console.error('Failed to fetch drivers', err)
    }
  }

  useEffect(() => {
    fetchRequests()
  }, [])

  useEffect(() => {
    if (isAssignDialogOpen) {
      fetchAvailableVehicles()
      fetchAvailableDrivers()
    }
  }, [isAssignDialogOpen])

  const handleViewDetails = async (requestId: string) => {
    try {
      const response = await api.get(`/vehicles/requests/${requestId}`)
      setSelectedRequest(response.data)
      setIsDetailsDialogOpen(true)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch request details')
    }
  }

  const handleApprove = async () => {
    if (!selectedRequest) return
    try {
      setIsSubmitting(true)
      await api.put(`/vehicles/requests/${selectedRequest._id}/approve`, {
        comment: approveComment || undefined,
      })
      await fetchRequests()
      setIsApproveDialogOpen(false)
      setApproveComment('')
      setSelectedRequest(null)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to approve request')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleReject = async () => {
    if (!selectedRequest) return
    try {
      setIsSubmitting(true)
      await api.put(`/vehicles/requests/${selectedRequest._id}/reject`, {
        comment: rejectComment,
      })
      await fetchRequests()
      setIsRejectDialogOpen(false)
      setRejectComment('')
      setSelectedRequest(null)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to reject request')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleAssign = async () => {
    if (!selectedRequest || !selectedVehicleId) return
    try {
      setIsSubmitting(true)
      await api.put(`/vehicles/requests/${selectedRequest._id}/assign`, {
        vehicleId: selectedVehicleId,
        driverId: selectedDriverId || undefined,
      })
      await fetchRequests()
      setIsAssignDialogOpen(false)
      setSelectedVehicleId('')
      setSelectedDriverId('')
      setSelectedRequest(null)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to assign vehicle')
    } finally {
      setIsSubmitting(false)
    }
  }

  const getStatusBadge = (status: string) => {
    const variants: Record<string, any> = {
      PENDING: { variant: 'secondary' as const, label: 'Pending' },
      APPROVED: { variant: 'default' as const, label: 'Approved' },
      REJECTED: { variant: 'destructive' as const, label: 'Rejected' },
      ASSIGNED: { variant: 'default' as const, label: 'Assigned' },
      COMPLETED: { variant: 'default' as const, label: 'Completed' },
    }
    const config = variants[status] || { variant: 'secondary' as const, label: status }
    return <Badge variant={config.variant}>{config.label}</Badge>
  }

  const filteredRequests = requests.filter((req) => {
    if (statusFilter === 'all') return true
    return req.status === statusFilter
  })

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Transport Requests</CardTitle>
              <CardDescription>Monitor and manage all vehicle requests</CardDescription>
            </div>
            <div className="flex items-center gap-2">
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Filter by status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="PENDING">Pending</SelectItem>
                  <SelectItem value="APPROVED">Approved</SelectItem>
                  <SelectItem value="ASSIGNED">Assigned</SelectItem>
                  <SelectItem value="COMPLETED">Completed</SelectItem>
                  <SelectItem value="REJECTED">Rejected</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {error && (
            <Alert variant="destructive" className="mb-4">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          {loading ? (
            <div className="text-center py-8">Loading requests...</div>
          ) : filteredRequests.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No requests found
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Requester</TableHead>
                  <TableHead>Destination</TableHead>
                  <TableHead>Trip Date</TableHead>
                  <TableHead>Return Date</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Vehicle</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredRequests.map((request) => (
                  <TableRow key={request._id}>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <User className="h-4 w-4 text-muted-foreground" />
                        <div>
                          <div className="font-medium">
                            {request.requesterId?.name || 'Unknown'}
                          </div>
                          <div className="text-xs text-muted-foreground">
                            {request.requesterId?.email}
                          </div>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-muted-foreground" />
                        <span className="max-w-[200px] truncate">{request.destination}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Calendar className="h-4 w-4 text-muted-foreground" />
                        <div>
                          <div className="text-sm">
                            {format(new Date(request.tripDate), 'MMM dd, yyyy')}
                          </div>
                          <div className="text-xs text-muted-foreground">{request.tripTime}</div>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-sm">
                        {format(new Date(request.returnDate), 'MMM dd, yyyy')}
                      </div>
                      <div className="text-xs text-muted-foreground">{request.returnTime}</div>
                    </TableCell>
                    <TableCell>
                      {getStatusBadge(request.status)}
                      {request.priority && (
                        <Badge variant="outline" className="ml-2">
                          Priority
                        </Badge>
                      )}
                    </TableCell>
                    <TableCell>
                      {request.vehicleId ? (
                        <div className="flex items-center gap-2">
                          <Truck className="h-4 w-4 text-muted-foreground" />
                          <span>{request.vehicleId.plateNumber}</span>
                        </div>
                      ) : (
                        <span className="text-muted-foreground">Not assigned</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleViewDetails(request._id)}
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                        {request.status === 'PENDING' && (
                          <>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => {
                                setSelectedRequest(request)
                                setIsApproveDialogOpen(true)
                              }}
                            >
                              <CheckCircle2 className="h-4 w-4 text-green-600" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => {
                                setSelectedRequest(request)
                                setIsRejectDialogOpen(true)
                              }}
                            >
                              <XCircle className="h-4 w-4 text-destructive" />
                            </Button>
                          </>
                        )}
                        {request.status === 'APPROVED' && !request.vehicleId && (
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => {
                              setSelectedRequest(request)
                              setIsAssignDialogOpen(true)
                            }}
                          >
                            <Truck className="h-4 w-4" />
                          </Button>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Request Details Dialog */}
      <Dialog open={isDetailsDialogOpen} onOpenChange={setIsDetailsDialogOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Request Details</DialogTitle>
            <DialogDescription>View full request information and workflow</DialogDescription>
          </DialogHeader>
          {selectedRequest && (
            <Tabs defaultValue="details" className="w-full">
              <TabsList>
                <TabsTrigger value="details">Details</TabsTrigger>
                <TabsTrigger value="workflow">Workflow</TabsTrigger>
              </TabsList>
              <TabsContent value="details" className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label className="text-muted-foreground">Requester</Label>
                    <div className="font-medium">
                      {selectedRequest.requesterId?.name || 'Unknown'}
                    </div>
                    <div className="text-sm text-muted-foreground">
                      {selectedRequest.requesterId?.email}
                    </div>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Status</Label>
                    <div className="mt-1">{getStatusBadge(selectedRequest.status)}</div>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Destination</Label>
                    <div className="font-medium">{selectedRequest.destination}</div>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Purpose</Label>
                    <div className="font-medium">{selectedRequest.purpose}</div>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Trip Date & Time</Label>
                    <div className="font-medium">
                      {format(new Date(selectedRequest.tripDate), 'MMM dd, yyyy')} at{' '}
                      {selectedRequest.tripTime}
                    </div>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Return Date & Time</Label>
                    <div className="font-medium">
                      {format(new Date(selectedRequest.returnDate), 'MMM dd, yyyy')} at{' '}
                      {selectedRequest.returnTime}
                    </div>
                  </div>
                  {selectedRequest.vehicleId && (
                    <div>
                      <Label className="text-muted-foreground">Assigned Vehicle</Label>
                      <div className="font-medium">{selectedRequest.vehicleId.plateNumber}</div>
                    </div>
                  )}
                  {selectedRequest.driverId && (
                    <div>
                      <Label className="text-muted-foreground">Assigned Driver</Label>
                      <div className="font-medium">{selectedRequest.driverId.name}</div>
                    </div>
                  )}
                </div>
              </TabsContent>
              <TabsContent value="workflow">
                <WorkflowVisualization
                  currentStage={selectedRequest.workflowStage}
                  workflowStages={workflowStages}
                  approvals={selectedRequest.approvals || []}
                />
              </TabsContent>
            </Tabs>
          )}
        </DialogContent>
      </Dialog>

      {/* Approve Dialog */}
      <Dialog open={isApproveDialogOpen} onOpenChange={setIsApproveDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Approve Request</DialogTitle>
            <DialogDescription>Approve this vehicle request</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Comment (Optional)</Label>
              <Textarea
                placeholder="Add a comment..."
                value={approveComment}
                onChange={(e) => setApproveComment(e.target.value)}
              />
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setIsApproveDialogOpen(false)
                  setApproveComment('')
                }}
                disabled={isSubmitting}
              >
                Cancel
              </Button>
              <Button onClick={handleApprove} disabled={isSubmitting}>
                {isSubmitting ? 'Approving...' : 'Approve'}
              </Button>
            </DialogFooter>
          </div>
        </DialogContent>
      </Dialog>

      {/* Reject Dialog */}
      <Dialog open={isRejectDialogOpen} onOpenChange={setIsRejectDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reject Request</DialogTitle>
            <DialogDescription>Reject this vehicle request</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Comment (Required)</Label>
              <Textarea
                placeholder="Reason for rejection..."
                value={rejectComment}
                onChange={(e) => setRejectComment(e.target.value)}
                required
              />
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setIsRejectDialogOpen(false)
                  setRejectComment('')
                }}
                disabled={isSubmitting}
              >
                Cancel
              </Button>
              <Button
                variant="destructive"
                onClick={handleReject}
                disabled={isSubmitting || !rejectComment.trim()}
              >
                {isSubmitting ? 'Rejecting...' : 'Reject'}
              </Button>
            </DialogFooter>
          </div>
        </DialogContent>
      </Dialog>

      {/* Assign Vehicle Dialog */}
      <Dialog open={isAssignDialogOpen} onOpenChange={setIsAssignDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Assign Vehicle</DialogTitle>
            <DialogDescription>Assign a vehicle and driver to this request</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Vehicle *</Label>
              <Select value={selectedVehicleId} onValueChange={setSelectedVehicleId}>
                <SelectTrigger>
                  <SelectValue placeholder="Select a vehicle" />
                </SelectTrigger>
                <SelectContent>
                  {availableVehicles.map((vehicle) => (
                    <SelectItem key={vehicle._id} value={vehicle._id}>
                      {vehicle.plateNumber} - {vehicle.model} ({vehicle.type})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>Driver (Optional)</Label>
              <Select value={selectedDriverId || "__none__"} onValueChange={(value) => setSelectedDriverId(value === "__none__" ? "" : value)}>
                <SelectTrigger>
                  <SelectValue placeholder="Select a driver" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__none__">None</SelectItem>
                  {availableDrivers.map((driver) => (
                    <SelectItem key={driver._id} value={driver._id}>
                      {driver.name} - {driver.licenseNumber}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setIsAssignDialogOpen(false)
                  setSelectedVehicleId('')
                  setSelectedDriverId('')
                }}
                disabled={isSubmitting}
              >
                Cancel
              </Button>
              <Button onClick={handleAssign} disabled={isSubmitting || !selectedVehicleId}>
                {isSubmitting ? 'Assigning...' : 'Assign'}
              </Button>
            </DialogFooter>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
