"use client";

import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { LiveTrackingMap } from "@/components/tracking/LiveTrackingMap";
import { TripInfoPanel } from "@/components/tracking/TripInfoPanel";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { RefreshCw } from "lucide-react";

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed");
  return res.json();
}

export default function TrackingPage() {
  const [selectedTripId, setSelectedTripId] = useState<string | null>(null);

  const { data: vehicles = [], isLoading: loadingVehicles, refetch: refetchVehicles } = useQuery<any[]>({ 
    queryKey: ['vehicleLocations'], 
    queryFn: () => fetchJSON('/api/tracking/vehicles'),
    refetchInterval: 30000, // Refetch every 30 seconds
  });
  
  const { data: drivers = [], isLoading: loadingDrivers, refetch: refetchDrivers } = useQuery<any[]>({ 
    queryKey: ['driverLocations'], 
    queryFn: () => fetchJSON('/api/tracking/drivers'),
    refetchInterval: 30000, // Refetch every 30 seconds
  });

  const { data: activeTrips = [] } = useQuery<any[]>({
    queryKey: ['activeTrips'],
    queryFn: () => fetchJSON('/api/transport/requests?status=ASSIGNED&tripStarted=true'),
  });

  const handleRefresh = () => {
    refetchVehicles();
    refetchDrivers();
  };

  const isLoading = loadingVehicles || loadingDrivers;

  // Transform data for map
  const vehicleLocations = vehicles.map((v) => ({
    vehicleId: v?.vehicleId,
    tripId: v?.tripId,
    plateNumber: v?.plateNumber,
    location: v?.location ? { lat: v.location.lat, lng: v.location.lng } : undefined,
    status: v?.status,
  }));

  const driverLocations = drivers.map((d) => ({
    driverId: d?.driverId,
    tripId: d?.tripId,
    driverName: d?.driverName,
    location: d?.location ? { lat: d.location.lat, lng: d.location.lng } : undefined,
    status: d?.status,
  }));

  const tripInfo = activeTrips.map((trip) => ({
    tripId: trip._id,
    vehicle: trip.vehicleId
      ? {
          plateNumber: typeof trip.vehicleId === "object" ? trip.vehicleId.plateNumber : undefined,
          make: typeof trip.vehicleId === "object" ? trip.vehicleId.make : undefined,
          model: typeof trip.vehicleId === "object" ? trip.vehicleId.model : undefined,
        }
      : undefined,
    driver: trip.driverId
      ? {
          name: typeof trip.driverId === "object" ? trip.driverId.name : undefined,
          phone: typeof trip.driverId === "object" ? trip.driverId.phone : undefined,
        }
      : undefined,
    destination: trip.destination,
    status: trip.status,
    distance: trip.totalTripDistanceKm,
    duration: trip.duration,
  }));

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Live Tracking</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Real-time vehicle and driver location tracking
          </p>
        </div>
        <Button variant="outline" onClick={handleRefresh} disabled={isLoading}>
          <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? "animate-spin" : ""}`} />
          Refresh
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2">
          <LiveTrackingMap
            vehicles={vehicleLocations}
            drivers={driverLocations}
            center={
              vehicleLocations[0]?.location ||
              driverLocations[0]?.location || {
                lat: 6.5244,
                lng: 3.3792,
              }
            }
          />
        </div>
        <div>
          <TripInfoPanel trips={tripInfo} onTripSelect={setSelectedTripId} />
        </div>
      </div>
    </div>
  );
}


