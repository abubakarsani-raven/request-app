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
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Textarea } from '@/components/ui/textarea'
import { Plus, Pencil, Trash2, AlertCircle, MapPin } from 'lucide-react'
import MapPicker from './MapPicker'

const officeSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  address: z.string().min(1, 'Address is required'),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  description: z.string().optional(),
})

type OfficeFormValues = z.infer<typeof officeSchema>

interface Office {
  _id: string
  name: string
  address: string
  latitude: number
  longitude: number
  description?: string
  createdAt?: string
  updatedAt?: string
}

export default function OfficesManagement() {
  const [offices, setOffices] = useState<Office[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false)
  const [selectedOffice, setSelectedOffice] = useState<Office | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [mapLocation, setMapLocation] = useState<{
    lat: number
    lng: number
    address: string
  } | null>(null)

  const form = useForm<OfficeFormValues>({
    resolver: zodResolver(officeSchema),
    defaultValues: {
      name: '',
      address: '',
      latitude: 0,
      longitude: 0,
      description: '',
    },
  })

  const fetchOffices = async () => {
    try {
      setLoading(true)
      const response = await api.get('/offices')
      setOffices(response.data)
      setError('')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch offices')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchOffices()
  }, [])

  const handleOpenDialog = (office?: Office) => {
    if (office) {
      setSelectedOffice(office)
      form.reset({
        name: office.name,
        address: office.address,
        latitude: office.latitude,
        longitude: office.longitude,
        description: office.description || '',
      })
      setMapLocation({
        lat: office.latitude,
        lng: office.longitude,
        address: office.address,
      })
    } else {
      setSelectedOffice(null)
      form.reset({
        name: '',
        address: '',
        latitude: 0,
        longitude: 0,
        description: '',
      })
      setMapLocation(null)
    }
    setIsDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setIsDialogOpen(false)
    setSelectedOffice(null)
    form.reset()
    setMapLocation(null)
  }

  const handleLocationSelect = (lat: number, lng: number, address: string) => {
    setMapLocation({ lat, lng, address })
    form.setValue('latitude', lat)
    form.setValue('longitude', lng)
    form.setValue('address', address)
  }

  const onSubmit = async (data: OfficeFormValues) => {
    if (!mapLocation) {
      setError('Please select a location on the map')
      return
    }

    try {
      setIsSubmitting(true)
      const payload = {
        ...data,
        latitude: mapLocation.lat,
        longitude: mapLocation.lng,
        address: mapLocation.address,
      }

      if (selectedOffice) {
        await api.patch(`/offices/${selectedOffice._id}`, payload)
      } else {
        await api.post('/offices', payload)
      }
      await fetchOffices()
      handleCloseDialog()
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to save office')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleDelete = async () => {
    if (!selectedOffice) return
    try {
      await api.delete(`/offices/${selectedOffice._id}`)
      await fetchOffices()
      setIsDeleteDialogOpen(false)
      setSelectedOffice(null)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to delete office')
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Offices Management</CardTitle>
              <CardDescription>Create and manage office locations</CardDescription>
            </div>
            <Button onClick={() => handleOpenDialog()}>
              <Plus className="mr-2 h-4 w-4" />
              Add Office
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
            <div className="text-center py-8">Loading offices...</div>
          ) : offices.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No offices found. Create your first office.
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Address</TableHead>
                  <TableHead>Coordinates</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {offices.map((office) => (
                  <TableRow key={office._id}>
                    <TableCell className="font-medium">{office.name}</TableCell>
                    <TableCell>
                      <div className="flex items-start gap-2">
                        <MapPin className="h-4 w-4 text-muted-foreground mt-0.5 flex-shrink-0" />
                        <span className="text-sm">{office.address}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="text-xs text-muted-foreground">
                        {office.latitude.toFixed(6)}, {office.longitude.toFixed(6)}
                      </span>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleOpenDialog(office)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => {
                            setSelectedOffice(office)
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

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {selectedOffice ? 'Edit Office' : 'Create Office'}
            </DialogTitle>
            <DialogDescription>
              {selectedOffice
                ? 'Update office information and location'
                : 'Add a new office location to the system'}
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Office Name</FormLabel>
                    <FormControl>
                      <Input placeholder="Main Office" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="space-y-2">
                <Label>Location</Label>
                <MapPicker
                  initialLat={mapLocation?.lat}
                  initialLng={mapLocation?.lng}
                  initialAddress={mapLocation?.address}
                  onLocationSelect={handleLocationSelect}
                />
                {!mapLocation && (
                  <p className="text-sm text-muted-foreground">
                    Please select a location on the map
                  </p>
                )}
              </div>

              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description (Optional)</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Additional information about this office..."
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <DialogFooter>
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleCloseDialog}
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
                <Button type="submit" disabled={isSubmitting || !mapLocation}>
                  {isSubmitting ? 'Saving...' : selectedOffice ? 'Update' : 'Create'}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      <AlertDialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete the office "{selectedOffice?.name}". This action
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

