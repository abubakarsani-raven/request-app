'use client'

import { useState, useCallback, useRef } from 'react'
import { GoogleMap, LoadScript, Marker, useJsApiLoader } from '@react-google-maps/api'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Search, MapPin } from 'lucide-react'

const libraries: ("places" | "drawing" | "geometry" | "localContext" | "visualization")[] = ["places"]

interface MapPickerProps {
  initialLat?: number
  initialLng?: number
  initialAddress?: string
  onLocationSelect: (lat: number, lng: number, address: string) => void
}

const defaultCenter = {
  lat: 6.5244, // Default to Lagos, Nigeria
  lng: 3.3792,
}

export default function MapPicker({
  initialLat,
  initialLng,
  initialAddress = '',
  onLocationSelect,
}: MapPickerProps) {
  const [selectedLocation, setSelectedLocation] = useState<{ lat: number; lng: number } | null>(
    initialLat && initialLng ? { lat: initialLat, lng: initialLng } : null
  )
  const [address, setAddress] = useState(initialAddress)
  const [searchQuery, setSearchQuery] = useState(initialAddress)
  const [isSearching, setIsSearching] = useState(false)
  const mapRef = useRef<google.maps.Map | null>(null)
  const geocoderRef = useRef<google.maps.Geocoder | null>(null)
  const autocompleteRef = useRef<google.maps.places.Autocomplete | null>(null)
  const searchInputRef = useRef<HTMLInputElement>(null)

  const { isLoaded, loadError } = useJsApiLoader({
    id: 'google-map-script',
    googleMapsApiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || '',
    libraries,
  })

  const onMapLoad = useCallback((map: google.maps.Map) => {
    mapRef.current = map
    geocoderRef.current = new google.maps.Geocoder()
  }, [])

  const onMapClick = useCallback(
    async (e: google.maps.MapMouseEvent) => {
      if (!e.latLng) return

      const lat = e.latLng.lat()
      const lng = e.latLng.lng()

      setSelectedLocation({ lat, lng })

      // Reverse geocode to get address
      if (geocoderRef.current) {
        geocoderRef.current.geocode({ location: { lat, lng } }, (results, status) => {
          if (status === 'OK' && results && results[0]) {
            const addr = results[0].formatted_address
            setAddress(addr)
            setSearchQuery(addr)
            onLocationSelect(lat, lng, addr)
          }
        })
      }
    },
    [onLocationSelect]
  )

  const handleSearch = useCallback(() => {
    if (!geocoderRef.current || !searchQuery.trim()) return

    setIsSearching(true)
    geocoderRef.current.geocode({ address: searchQuery }, (results, status) => {
      setIsSearching(false)
      if (status === 'OK' && results && results[0]) {
        const location = results[0].geometry.location
        const lat = location.lat()
        const lng = location.lng()
        const addr = results[0].formatted_address

        setSelectedLocation({ lat, lng })
        setAddress(addr)
        setSearchQuery(addr)

        if (mapRef.current) {
          mapRef.current.setCenter({ lat, lng })
          mapRef.current.setZoom(16)
        }

        onLocationSelect(lat, lng, addr)
      }
    })
  }, [searchQuery, onLocationSelect])

  const initializeAutocomplete = useCallback(() => {
    if (!searchInputRef.current || !window.google) return

    autocompleteRef.current = new google.maps.places.Autocomplete(searchInputRef.current, {
      types: ['address'],
    })

    autocompleteRef.current.addListener('place_changed', () => {
      const place = autocompleteRef.current?.getPlace()
      if (place?.geometry?.location) {
        const lat = place.geometry.location.lat()
        const lng = place.geometry.location.lng()
        const addr = place.formatted_address || place.name || ''

        setSelectedLocation({ lat, lng })
        setAddress(addr)
        setSearchQuery(addr)

        if (mapRef.current) {
          mapRef.current.setCenter({ lat, lng })
          mapRef.current.setZoom(16)
        }

        onLocationSelect(lat, lng, addr)
      }
    })
  }, [onLocationSelect])

  if (loadError) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="text-center text-destructive">
            Error loading Google Maps. Please check your API key.
          </div>
        </CardContent>
      </Card>
    )
  }

  if (!isLoaded) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="text-center">Loading map...</div>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            ref={searchInputRef}
            placeholder="Search for an address..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                handleSearch()
              }
            }}
            onFocus={initializeAutocomplete}
            className="pl-10"
          />
        </div>
        <Button onClick={handleSearch} disabled={isSearching || !searchQuery.trim()}>
          {isSearching ? 'Searching...' : 'Search'}
        </Button>
      </div>

      <div className="relative h-[400px] rounded-lg overflow-hidden border">
        <GoogleMap
          mapContainerStyle={{ width: '100%', height: '100%' }}
          center={selectedLocation || defaultCenter}
          zoom={selectedLocation ? 16 : 10}
          onLoad={onMapLoad}
          onClick={onMapClick}
          options={{
            disableDefaultUI: false,
            zoomControl: true,
            streetViewControl: false,
            mapTypeControl: false,
          }}
        >
          {selectedLocation && (
            <Marker
              position={selectedLocation}
              draggable
              onDragEnd={(e) => {
                if (e.latLng) {
                  const lat = e.latLng.lat()
                  const lng = e.latLng.lng()
                  setSelectedLocation({ lat, lng })

                  // Reverse geocode
                  if (geocoderRef.current) {
                    geocoderRef.current.geocode({ location: { lat, lng } }, (results, status) => {
                      if (status === 'OK' && results && results[0]) {
                        const addr = results[0].formatted_address
                        setAddress(addr)
                        setSearchQuery(addr)
                        onLocationSelect(lat, lng, addr)
                      }
                    })
                  }
                }
              }}
            />
          )}
        </GoogleMap>
      </div>

      {address && (
        <div className="flex items-start gap-2 p-3 bg-muted rounded-lg">
          <MapPin className="h-5 w-5 text-primary mt-0.5 flex-shrink-0" />
          <div className="flex-1">
            <div className="text-sm font-medium">Selected Address:</div>
            <div className="text-sm text-muted-foreground">{address}</div>
            {selectedLocation && (
              <div className="text-xs text-muted-foreground mt-1">
                {selectedLocation.lat.toFixed(6)}, {selectedLocation.lng.toFixed(6)}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}


