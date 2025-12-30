'use client'

import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import api from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
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
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Plus, Pencil, Trash2, AlertCircle, Wrench, FileText, AlertTriangle, CheckCircle2 } from 'lucide-react'
import { format } from 'date-fns'

const vehicleSchema = z.object({
  plateNumber: z.string().min(1, 'Plate number is required'),
  model: z.string().min(1, 'Model is required'),
  type: z.string().min(1, 'Type is required'),
  isPermanent: z.boolean().optional(),
  isAvailable: z.boolean().optional(),
})

const maintenanceReminderSchema = z.object({
  type: z.string().min(1, 'Type is required'),
  dueDate: z.string().min(1, 'Due date is required'),
  mileage: z.number().optional(),
  description: z.string().optional(),
})

const maintenanceLogSchema = z.object({
  type: z.string().min(1, 'Type is required'),
  date: z.string().min(1, 'Date is required'),
  mileage: z.number().optional(),
  cost: z.number().optional(),
  description: z.string().min(1, 'Description is required'),
  serviceProvider: z.string().optional(),
})

const issueSchema = z.object({
  type: z.string().min(1, 'Issue type is required'),
  description: z.string().min(1, 'Description is required'),
})

type VehicleFormValues = z.infer<typeof vehicleSchema>
type MaintenanceReminderFormValues = z.infer<typeof maintenanceReminderSchema>
type MaintenanceLogFormValues = z.infer<typeof maintenanceLogSchema>
type IssueFormValues = z.infer<typeof issueSchema>

interface Vehicle {
  _id: string
  plateNumber: string
  model: string
  type: string
  isPermanent: boolean
  isAvailable: boolean
  assignedToUserId?: string
  maintenanceReminders?: MaintenanceReminder[]
  maintenanceLogs?: MaintenanceLog[]
  issues?: VehicleIssue[]
}

interface MaintenanceReminder {
  type: string
  dueDate: string
  mileage?: number
  description?: string
  isCompleted: boolean
  createdAt: string
}

interface MaintenanceLog {
  type: string
  date: string
  mileage?: number
  cost?: number
  description: string
  serviceProvider?: string
  createdAt: string
}

interface VehicleIssue {
  type: string
  description: string
  reportedDate: string
  reportedBy: string
  status: 'REPORTED' | 'IN_PROGRESS' | 'RESOLVED'
  resolvedDate?: string
  resolutionNotes?: string
  createdAt: string
}

export default function VehiclesManagement() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false)
  const [isMaintenanceDialogOpen, setIsMaintenanceDialogOpen] = useState(false)
  const [isLogDialogOpen, setIsLogDialogOpen] = useState(false)
  const [isIssueDialogOpen, setIsIssueDialogOpen] = useState(false)
  const [selectedVehicle, setSelectedVehicle] = useState<Vehicle | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [maintenanceType, setMaintenanceType] = useState<'reminder' | 'log' | 'issue'>('reminder')
  const [viewVehicleId, setViewVehicleId] = useState<string | null>(null)

  const vehicleForm = useForm<VehicleFormValues>({
    resolver: zodResolver(vehicleSchema),
    defaultValues: {
      plateNumber: '',
      model: '',
      type: '',
      isPermanent: false,
      isAvailable: true,
    },
  })

  const reminderForm = useForm<MaintenanceReminderFormValues>({
    resolver: zodResolver(maintenanceReminderSchema),
    defaultValues: {
      type: '',
      dueDate: '',
      mileage: undefined,
      description: '',
    },
  })

  const logForm = useForm<MaintenanceLogFormValues>({
    resolver: zodResolver(maintenanceLogSchema),
    defaultValues: {
      type: '',
      date: '',
      mileage: undefined,
      cost: undefined,
      description: '',
      serviceProvider: '',
    },
  })

  const issueForm = useForm<IssueFormValues>({
    resolver: zodResolver(issueSchema),
    defaultValues: {
      type: '',
      description: '',
    },
  })

  const fetchVehicles = async () => {
    try {
      setLoading(true)
      const response = await api.get('/vehicles/vehicles')
      setVehicles(response.data)
      setError('')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch vehicles')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchVehicles()
  }, [])

  const handleOpenDialog = (vehicle?: Vehicle) => {
    if (vehicle) {
      setSelectedVehicle(vehicle)
      vehicleForm.reset({
        plateNumber: vehicle.plateNumber,
        model: vehicle.model,
        type: vehicle.type,
        isPermanent: vehicle.isPermanent,
        isAvailable: vehicle.isAvailable,
      })
    } else {
      setSelectedVehicle(null)
      vehicleForm.reset({
        plateNumber: '',
        model: '',
        type: '',
        isPermanent: false,
        isAvailable: true,
      })
    }
    setIsDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setIsDialogOpen(false)
    setSelectedVehicle(null)
    vehicleForm.reset()
  }

  const onSubmitVehicle = async (data: VehicleFormValues) => {
    try {
      setIsSubmitting(true)
      if (selectedVehicle) {
        await api.patch(`/vehicles/vehicles/${selectedVehicle._id}`, data)
      } else {
        await api.post('/vehicles/vehicles', data)
      }
      await fetchVehicles()
      handleCloseDialog()
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to save vehicle')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleDelete = async () => {
    if (!selectedVehicle) return
    try {
      await api.delete(`/vehicles/vehicles/${selectedVehicle._id}`)
      await fetchVehicles()
      setIsDeleteDialogOpen(false)
      setSelectedVehicle(null)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to delete vehicle')
    }
  }

  const handleOpenMaintenanceDialog = (vehicle: Vehicle, type: 'reminder' | 'log' | 'issue') => {
    setSelectedVehicle(vehicle)
    setMaintenanceType(type)
    if (type === 'reminder') {
      reminderForm.reset({
        type: '',
        dueDate: '',
        mileage: undefined,
        description: '',
      })
      setIsMaintenanceDialogOpen(true)
    } else if (type === 'log') {
      logForm.reset({
        type: '',
        date: format(new Date(), 'yyyy-MM-dd'),
        mileage: undefined,
        cost: undefined,
        description: '',
        serviceProvider: '',
      })
      setIsLogDialogOpen(true)
    } else {
      issueForm.reset({
        type: '',
        description: '',
      })
      setIsIssueDialogOpen(true)
    }
  }

  const onSubmitReminder = async (data: MaintenanceReminderFormValues) => {
    if (!selectedVehicle) return
    try {
      setIsSubmitting(true)
      await api.post(`/vehicles/vehicles/${selectedVehicle._id}/maintenance/reminder`, data)
      await fetchVehicles()
      setIsMaintenanceDialogOpen(false)
      reminderForm.reset()
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to add maintenance reminder')
    } finally {
      setIsSubmitting(false)
    }
  }

  const onSubmitLog = async (data: MaintenanceLogFormValues) => {
    if (!selectedVehicle) return
    try {
      setIsSubmitting(true)
      await api.post(`/vehicles/vehicles/${selectedVehicle._id}/maintenance/log`, data)
      await fetchVehicles()
      setIsLogDialogOpen(false)
      logForm.reset()
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to add maintenance log')
    } finally {
      setIsSubmitting(false)
    }
  }

  const onSubmitIssue = async (data: IssueFormValues) => {
    if (!selectedVehicle) return
    try {
      setIsSubmitting(true)
      await api.post(`/vehicles/vehicles/${selectedVehicle._id}/issues`, data)
      await fetchVehicles()
      setIsIssueDialogOpen(false)
      issueForm.reset()
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to report issue')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleViewVehicle = async (vehicleId: string) => {
    try {
      const response = await api.get(`/vehicles/vehicles/${vehicleId}`)
      setSelectedVehicle(response.data)
      setViewVehicleId(vehicleId)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch vehicle details')
    }
  }

  const getStatusBadge = (vehicle: Vehicle) => {
    if (!vehicle.isAvailable) {
      return <Badge variant="destructive">Unavailable</Badge>
    }
    if (vehicle.isPermanent) {
      return <Badge variant="secondary">Permanent</Badge>
    }
    return <Badge variant="default">Available</Badge>
  }

  const getIssueStatusBadge = (status: string) => {
    switch (status) {
      case 'RESOLVED':
        return <Badge variant="default">Resolved</Badge>
      case 'IN_PROGRESS':
        return <Badge variant="secondary">In Progress</Badge>
      default:
        return <Badge variant="destructive">Reported</Badge>
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Vehicles Management</CardTitle>
              <CardDescription>Manage vehicles, maintenance, and issues</CardDescription>
            </div>
            <Button onClick={() => handleOpenDialog()}>
              <Plus className="mr-2 h-4 w-4" />
              Add Vehicle
            </Button>
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
            <div className="text-center py-8">Loading vehicles...</div>
          ) : vehicles.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No vehicles found. Create your first vehicle.
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Plate Number</TableHead>
                  <TableHead>Model</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {vehicles.map((vehicle) => (
                  <TableRow key={vehicle._id}>
                    <TableCell className="font-medium">{vehicle.plateNumber}</TableCell>
                    <TableCell>{vehicle.model}</TableCell>
                    <TableCell>{vehicle.type}</TableCell>
                    <TableCell>{getStatusBadge(vehicle)}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleViewVehicle(vehicle._id)}
                        >
                          <FileText className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleOpenDialog(vehicle)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => {
                            setSelectedVehicle(vehicle)
                            setIsDeleteDialogOpen(true)
                          }}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Vehicle CRUD Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {selectedVehicle ? 'Edit Vehicle' : 'Create Vehicle'}
            </DialogTitle>
            <DialogDescription>
              {selectedVehicle
                ? 'Update vehicle information'
                : 'Add a new vehicle to the system'}
            </DialogDescription>
          </DialogHeader>
          <Form {...vehicleForm}>
            <form onSubmit={vehicleForm.handleSubmit(onSubmitVehicle)} className="space-y-4">
              <FormField
                control={vehicleForm.control}
                name="plateNumber"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Plate Number</FormLabel>
                    <FormControl>
                      <Input placeholder="ABC-123" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={vehicleForm.control}
                name="model"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Model</FormLabel>
                    <FormControl>
                      <Input placeholder="Toyota Camry" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={vehicleForm.control}
                name="type"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Type</FormLabel>
                    <FormControl>
                      <Input placeholder="Sedan" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <div className="flex items-center space-x-4">
                <FormField
                  control={vehicleForm.control}
                  name="isPermanent"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-center space-x-3 space-y-0">
                      <FormControl>
                        <input
                          type="checkbox"
                          checked={field.value}
                          onChange={field.onChange}
                          className="h-4 w-4 rounded border-gray-300"
                        />
                      </FormControl>
                      <div className="space-y-1 leading-none">
                        <FormLabel>Permanent Assignment</FormLabel>
                      </div>
                    </FormItem>
                  )}
                />
                <FormField
                  control={vehicleForm.control}
                  name="isAvailable"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-center space-x-3 space-y-0">
                      <FormControl>
                        <input
                          type="checkbox"
                          checked={field.value}
                          onChange={field.onChange}
                          className="h-4 w-4 rounded border-gray-300"
                        />
                      </FormControl>
                      <div className="space-y-1 leading-none">
                        <FormLabel>Available</FormLabel>
                      </div>
                    </FormItem>
                  )}
                />
              </div>
              <DialogFooter>
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleCloseDialog}
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting ? 'Saving...' : selectedVehicle ? 'Update' : 'Create'}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      {/* Vehicle Details Dialog */}
      {selectedVehicle && viewVehicleId && (
        <Dialog open={!!viewVehicleId} onOpenChange={() => setViewVehicleId(null)}>
          <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>Vehicle Details - {selectedVehicle.plateNumber}</DialogTitle>
              <DialogDescription>View maintenance, logs, and issues</DialogDescription>
            </DialogHeader>
            <Tabs defaultValue="reminders" className="w-full">
              <TabsList>
                <TabsTrigger value="reminders">Reminders</TabsTrigger>
                <TabsTrigger value="logs">Maintenance Logs</TabsTrigger>
                <TabsTrigger value="issues">Issues</TabsTrigger>
              </TabsList>
              <TabsContent value="reminders" className="space-y-4">
                <div className="flex justify-between items-center">
                  <h3 className="text-lg font-semibold">Maintenance Reminders</h3>
                  <Button
                    size="sm"
                    onClick={() => handleOpenMaintenanceDialog(selectedVehicle, 'reminder')}
                  >
                    <Plus className="mr-2 h-4 w-4" />
                    Add Reminder
                  </Button>
                </div>
                {selectedVehicle.maintenanceReminders && selectedVehicle.maintenanceReminders.length > 0 ? (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Type</TableHead>
                        <TableHead>Due Date</TableHead>
                        <TableHead>Mileage</TableHead>
                        <TableHead>Status</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {selectedVehicle.maintenanceReminders.map((reminder, index) => (
                        <TableRow key={index}>
                          <TableCell>{reminder.type}</TableCell>
                          <TableCell>
                            {format(new Date(reminder.dueDate), 'MMM dd, yyyy')}
                          </TableCell>
                          <TableCell>{reminder.mileage || 'N/A'}</TableCell>
                          <TableCell>
                            {reminder.isCompleted ? (
                              <Badge variant="default">
                                <CheckCircle2 className="mr-1 h-3 w-3" />
                                Completed
                              </Badge>
                            ) : (
                              <Badge variant="destructive">Pending</Badge>
                            )}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    No maintenance reminders
                  </div>
                )}
              </TabsContent>
              <TabsContent value="logs" className="space-y-4">
                <div className="flex justify-between items-center">
                  <h3 className="text-lg font-semibold">Maintenance Logs</h3>
                  <Button
                    size="sm"
                    onClick={() => handleOpenMaintenanceDialog(selectedVehicle, 'log')}
                  >
                    <Plus className="mr-2 h-4 w-4" />
                    Add Log
                  </Button>
                </div>
                {selectedVehicle.maintenanceLogs && selectedVehicle.maintenanceLogs.length > 0 ? (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Type</TableHead>
                        <TableHead>Date</TableHead>
                        <TableHead>Mileage</TableHead>
                        <TableHead>Cost</TableHead>
                        <TableHead>Description</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {selectedVehicle.maintenanceLogs.map((log, index) => (
                        <TableRow key={index}>
                          <TableCell>{log.type}</TableCell>
                          <TableCell>
                            {format(new Date(log.date), 'MMM dd, yyyy')}
                          </TableCell>
                          <TableCell>{log.mileage || 'N/A'}</TableCell>
                          <TableCell>{log.cost ? `$${log.cost}` : 'N/A'}</TableCell>
                          <TableCell>{log.description}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    No maintenance logs
                  </div>
                )}
              </TabsContent>
              <TabsContent value="issues" className="space-y-4">
                <div className="flex justify-between items-center">
                  <h3 className="text-lg font-semibold">Vehicle Issues</h3>
                  <Button
                    size="sm"
                    onClick={() => handleOpenMaintenanceDialog(selectedVehicle, 'issue')}
                  >
                    <Plus className="mr-2 h-4 w-4" />
                    Report Issue
                  </Button>
                </div>
                {selectedVehicle.issues && selectedVehicle.issues.length > 0 ? (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Type</TableHead>
                        <TableHead>Description</TableHead>
                        <TableHead>Reported Date</TableHead>
                        <TableHead>Status</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {selectedVehicle.issues.map((issue, index) => (
                        <TableRow key={index}>
                          <TableCell>
                            <Badge variant="outline">{issue.type}</Badge>
                          </TableCell>
                          <TableCell>{issue.description}</TableCell>
                          <TableCell>
                            {format(new Date(issue.reportedDate), 'MMM dd, yyyy')}
                          </TableCell>
                          <TableCell>{getIssueStatusBadge(issue.status)}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    No reported issues
                  </div>
                )}
              </TabsContent>
            </Tabs>
          </DialogContent>
        </Dialog>
      )}

      {/* Maintenance Reminder Dialog */}
      <Dialog open={isMaintenanceDialogOpen} onOpenChange={setIsMaintenanceDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Maintenance Reminder</DialogTitle>
            <DialogDescription>Set up a maintenance reminder for this vehicle</DialogDescription>
          </DialogHeader>
          <Form {...reminderForm}>
            <form onSubmit={reminderForm.handleSubmit(onSubmitReminder)} className="space-y-4">
              <FormField
                control={reminderForm.control}
                name="type"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Type</FormLabel>
                    <FormControl>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <SelectTrigger>
                          <SelectValue placeholder="Select type" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="Oil Change">Oil Change</SelectItem>
                          <SelectItem value="Tire Rotation">Tire Rotation</SelectItem>
                          <SelectItem value="Brake Inspection">Brake Inspection</SelectItem>
                          <SelectItem value="Battery Check">Battery Check</SelectItem>
                          <SelectItem value="General Service">General Service</SelectItem>
                        </SelectContent>
                      </Select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={reminderForm.control}
                name="dueDate"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Due Date</FormLabel>
                    <FormControl>
                      <Input type="date" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={reminderForm.control}
                name="mileage"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Mileage (Optional)</FormLabel>
                    <FormControl>
                      <Input
                        type="number"
                        {...field}
                        onChange={(e) => field.onChange(e.target.value ? parseInt(e.target.value) : undefined)}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={reminderForm.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description (Optional)</FormLabel>
                    <FormControl>
                      <Input placeholder="Additional notes..." {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <DialogFooter>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setIsMaintenanceDialogOpen(false)}
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting ? 'Adding...' : 'Add Reminder'}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      {/* Maintenance Log Dialog */}
      <Dialog open={isLogDialogOpen} onOpenChange={setIsLogDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Maintenance Log</DialogTitle>
            <DialogDescription>Record a maintenance activity</DialogDescription>
          </DialogHeader>
          <Form {...logForm}>
            <form onSubmit={logForm.handleSubmit(onSubmitLog)} className="space-y-4">
              <FormField
                control={logForm.control}
                name="type"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Type</FormLabel>
                    <FormControl>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <SelectTrigger>
                          <SelectValue placeholder="Select type" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="Oil Change">Oil Change</SelectItem>
                          <SelectItem value="Repair">Repair</SelectItem>
                          <SelectItem value="Inspection">Inspection</SelectItem>
                          <SelectItem value="Tire Replacement">Tire Replacement</SelectItem>
                          <SelectItem value="General Service">General Service</SelectItem>
                        </SelectContent>
                      </Select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={logForm.control}
                name="date"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Date</FormLabel>
                    <FormControl>
                      <Input type="date" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <div className="grid grid-cols-2 gap-4">
                <FormField
                  control={logForm.control}
                  name="mileage"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Mileage (Optional)</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          {...field}
                          onChange={(e) => field.onChange(e.target.value ? parseInt(e.target.value) : undefined)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={logForm.control}
                  name="cost"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Cost (Optional)</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          step="0.01"
                          {...field}
                          onChange={(e) => field.onChange(e.target.value ? parseFloat(e.target.value) : undefined)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
              <FormField
                control={logForm.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Input placeholder="What was done..." {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={logForm.control}
                name="serviceProvider"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Service Provider (Optional)</FormLabel>
                    <FormControl>
                      <Input placeholder="Garage name..." {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <DialogFooter>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setIsLogDialogOpen(false)}
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting ? 'Adding...' : 'Add Log'}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      {/* Report Issue Dialog */}
      <Dialog open={isIssueDialogOpen} onOpenChange={setIsIssueDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Report Vehicle Issue</DialogTitle>
            <DialogDescription>Report a problem with this vehicle</DialogDescription>
          </DialogHeader>
          <Form {...issueForm}>
            <form onSubmit={issueForm.handleSubmit(onSubmitIssue)} className="space-y-4">
              <FormField
                control={issueForm.control}
                name="type"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Issue Type</FormLabel>
                    <FormControl>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <SelectTrigger>
                          <SelectValue placeholder="Select issue type" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="Brake Light">Brake Light</SelectItem>
                          <SelectItem value="Engine">Engine</SelectItem>
                          <SelectItem value="Transmission">Transmission</SelectItem>
                          <SelectItem value="Tire">Tire</SelectItem>
                          <SelectItem value="Electrical">Electrical</SelectItem>
                          <SelectItem value="Body">Body</SelectItem>
                          <SelectItem value="Other">Other</SelectItem>
                        </SelectContent>
                      </Select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={issueForm.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Input placeholder="Describe the issue..." {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <DialogFooter>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setIsIssueDialogOpen(false)}
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting ? 'Reporting...' : 'Report Issue'}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <AlertDialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete the vehicle "{selectedVehicle?.plateNumber}". This action
              cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}







