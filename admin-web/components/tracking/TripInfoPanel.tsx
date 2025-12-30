"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { MapPin, Clock, Car, User, Route } from "lucide-react";

interface TripInfo {
  tripId: string;
  vehicle?: {
    plateNumber?: string;
    make?: string;
    model?: string;
  };
  driver?: {
    name?: string;
    phone?: string;
  };
  destination?: string;
  status?: string;
  startTime?: string;
  estimatedArrival?: string;
  distance?: number;
  duration?: number;
}

interface TripInfoPanelProps {
  trips: TripInfo[];
  onTripSelect?: (tripId: string) => void;
}

export function TripInfoPanel({ trips, onTripSelect }: TripInfoPanelProps) {
  if (trips.length === 0) {
    return (
      <Card>
        <CardContent className="py-8 text-center">
          <p className="text-muted-foreground">No active trips</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Active Trips</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {trips.map((trip, index) => (
            <div key={trip.tripId}>
              {index > 0 && <Separator className="my-4" />}
              <div
                className="space-y-3 cursor-pointer hover:bg-muted/50 p-3 rounded-lg transition-colors"
                onClick={() => onTripSelect?.(trip.tripId)}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Route className="h-4 w-4 text-muted-foreground" />
                    <span className="font-medium text-sm">Trip {trip.tripId.slice(-8)}</span>
                  </div>
                  <Badge variant={trip.status === "ACTIVE" ? "default" : "secondary"}>
                    {trip.status || "Active"}
                  </Badge>
                </div>

                {trip.destination && (
                  <div className="flex items-start gap-2 text-sm">
                    <MapPin className="h-4 w-4 text-muted-foreground mt-0.5" />
                    <span className="text-muted-foreground">{trip.destination}</span>
                  </div>
                )}

                {trip.vehicle && (
                  <div className="flex items-center gap-2 text-sm">
                    <Car className="h-4 w-4 text-muted-foreground" />
                    <span className="text-muted-foreground">
                      {trip.vehicle.plateNumber || "N/A"}
                      {trip.vehicle.make && trip.vehicle.model && (
                        <span className="ml-2">
                          ({trip.vehicle.make} {trip.vehicle.model})
                        </span>
                      )}
                    </span>
                  </div>
                )}

                {trip.driver && (
                  <div className="flex items-center gap-2 text-sm">
                    <User className="h-4 w-4 text-muted-foreground" />
                    <span className="text-muted-foreground">
                      {trip.driver.name || "N/A"}
                      {trip.driver.phone && <span className="ml-2">({trip.driver.phone})</span>}
                    </span>
                  </div>
                )}

                {(trip.distance || trip.duration) && (
                  <div className="flex items-center gap-4 text-xs text-muted-foreground">
                    {trip.distance && (
                      <div className="flex items-center gap-1">
                        <Route className="h-3 w-3" />
                        <span>{trip.distance.toFixed(1)} km</span>
                      </div>
                    )}
                    {trip.duration && (
                      <div className="flex items-center gap-1">
                        <Clock className="h-3 w-3" />
                        <span>{Math.round(trip.duration / 60)} min</span>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
