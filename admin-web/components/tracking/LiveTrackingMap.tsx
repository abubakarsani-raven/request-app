"use client";

import { useState, useCallback, useMemo } from "react";
import { GoogleMap, Marker, Polyline, useJsApiLoader } from "@react-google-maps/api";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { MapPin, Navigation, Car, User } from "lucide-react";

const libraries: ("places" | "drawing" | "geometry" | "localContext" | "visualization")[] = ["places"];

interface Location {
  lat: number;
  lng: number;
}

interface VehicleLocation {
  vehicleId?: string;
  tripId?: string;
  plateNumber?: string;
  location?: Location;
  status?: string;
}

interface DriverLocation {
  driverId?: string;
  tripId?: string;
  driverName?: string;
  location?: Location;
  status?: string;
}

interface Route {
  points: Location[];
  color?: string;
}

interface LiveTrackingMapProps {
  vehicles: VehicleLocation[];
  drivers: DriverLocation[];
  routes?: Route[];
  center?: Location;
  zoom?: number;
}

const defaultCenter: Location = {
  lat: 6.5244, // Lagos, Nigeria
  lng: 3.3792,
};

export function LiveTrackingMap({
  vehicles,
  drivers,
  routes = [],
  center,
  zoom = 12,
}: LiveTrackingMapProps) {
  const [selectedVehicle, setSelectedVehicle] = useState<VehicleLocation | null>(null);
  const [selectedDriver, setSelectedDriver] = useState<DriverLocation | null>(null);
  const [mapCenter, setMapCenter] = useState<Location>(center || defaultCenter);
  const [mapZoom, setMapZoom] = useState(zoom);

  const { isLoaded, loadError } = useJsApiLoader({
    id: "google-map-script",
    googleMapsApiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || "",
    libraries,
  });

  const handleCenterOnLocation = useCallback((location: Location) => {
    setMapCenter(location);
    setMapZoom(16);
  }, []);

  const mapOptions = useMemo(
    () => ({
      disableDefaultUI: false,
      zoomControl: true,
      streetViewControl: false,
      mapTypeControl: true,
      fullscreenControl: true,
    }),
    []
  );

  if (loadError) {
    return (
      <Card>
        <CardContent className="py-8 text-center">
          <p className="text-destructive">Error loading Google Maps. Please check your API key.</p>
        </CardContent>
      </Card>
    );
  }

  if (!isLoaded) {
    return (
      <Card>
        <CardContent className="py-8 text-center">
          <p className="text-muted-foreground">Loading map...</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardContent className="p-0">
          <div className="relative h-[600px] w-full">
            <GoogleMap
              mapContainerStyle={{ width: "100%", height: "100%" }}
              center={mapCenter}
              zoom={mapZoom}
              options={mapOptions}
            >
              {/* Vehicle Markers */}
              {vehicles.map((vehicle) => {
                if (!vehicle.location) return null;
                return (
                  <Marker
                    key={vehicle.vehicleId || vehicle.tripId || `vehicle-${vehicle.plateNumber}`}
                    position={vehicle.location}
                    icon={{
                      url: "data:image/svg+xml;charset=UTF-8," + encodeURIComponent(`
                        <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
                          <circle cx="16" cy="16" r="12" fill="#3b82f6" stroke="white" stroke-width="2"/>
                          <text x="16" y="20" font-size="16" fill="white" text-anchor="middle">🚗</text>
                        </svg>
                      `),
                      scaledSize: new google.maps.Size(32, 32),
                    }}
                    onClick={() => setSelectedVehicle(vehicle)}
                  />
                );
              })}

              {/* Driver Markers */}
              {drivers.map((driver) => {
                if (!driver.location) return null;
                return (
                  <Marker
                    key={driver.driverId || driver.tripId || `driver-${driver.driverName}`}
                    position={driver.location}
                    icon={{
                      url: "data:image/svg+xml;charset=UTF-8," + encodeURIComponent(`
                        <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
                          <circle cx="16" cy="16" r="12" fill="#10b981" stroke="white" stroke-width="2"/>
                          <text x="16" y="20" font-size="16" fill="white" text-anchor="middle">👤</text>
                        </svg>
                      `),
                      scaledSize: new google.maps.Size(32, 32),
                    }}
                    onClick={() => setSelectedDriver(driver)}
                  />
                );
              })}

              {/* Routes */}
              {routes.map((route, index) => (
                <Polyline
                  key={`route-${index}`}
                  path={route.points}
                  options={{
                    strokeColor: route.color || "#3b82f6",
                    strokeWeight: 3,
                    strokeOpacity: 0.6,
                  }}
                />
              ))}
            </GoogleMap>

            {/* Map Controls */}
            <div className="absolute top-4 right-4 flex flex-col gap-2">
              {vehicles.length > 0 && vehicles[0]?.location && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => vehicles[0].location && handleCenterOnLocation(vehicles[0].location!)}
                  className="bg-background"
                >
                  <Navigation className="h-4 w-4 mr-2" />
                  Center on Vehicle
                </Button>
              )}
              {drivers.length > 0 && drivers[0]?.location && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => drivers[0].location && handleCenterOnLocation(drivers[0].location!)}
                  className="bg-background"
                >
                  <User className="h-4 w-4 mr-2" />
                  Center on Driver
                </Button>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Selected Vehicle Info */}
      {selectedVehicle && (
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Car className="h-5 w-5 text-blue-600" />
                <div>
                  <p className="font-medium">Vehicle: {selectedVehicle.plateNumber || "N/A"}</p>
                  <p className="text-sm text-muted-foreground">
                    Trip: {selectedVehicle.tripId || "N/A"}
                  </p>
                  {selectedVehicle.location && (
                    <p className="text-xs text-muted-foreground">
                      {selectedVehicle.location.lat.toFixed(6)}, {selectedVehicle.location.lng.toFixed(6)}
                    </p>
                  )}
                </div>
              </div>
              <div className="flex gap-2">
                <Badge variant="secondary">{selectedVehicle.status || "Active"}</Badge>
                <Button variant="ghost" size="sm" onClick={() => setSelectedVehicle(null)}>
                  Close
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Selected Driver Info */}
      {selectedDriver && (
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <User className="h-5 w-5 text-green-600" />
                <div>
                  <p className="font-medium">Driver: {selectedDriver.driverName || "N/A"}</p>
                  <p className="text-sm text-muted-foreground">
                    Trip: {selectedDriver.tripId || "N/A"}
                  </p>
                  {selectedDriver.location && (
                    <p className="text-xs text-muted-foreground">
                      {selectedDriver.location.lat.toFixed(6)}, {selectedDriver.location.lng.toFixed(6)}
                    </p>
                  )}
                </div>
              </div>
              <div className="flex gap-2">
                <Badge variant="secondary">{selectedDriver.status || "Active"}</Badge>
                <Button variant="ghost" size="sm" onClick={() => setSelectedDriver(null)}>
                  Close
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
