"use client";

import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Plus, List } from "lucide-react";

interface VehicleQuickLinksProps {
  onAddVehicle?: () => void;
}

export function VehicleQuickLinks({ onAddVehicle }: VehicleQuickLinksProps) {
  const router = useRouter();

  const handleAddVehicle = () => {
    if (onAddVehicle) {
      onAddVehicle();
    } else {
      router.push("/transport/vehicles");
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Quick Actions</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex gap-2">
          <Button
            onClick={handleAddVehicle}
            className="flex items-center gap-2"
          >
            <Plus className="h-4 w-4" />
            Add Vehicle
          </Button>
          <Button
            variant="outline"
            onClick={() => {
              router.push("/transport/vehicles");
            }}
            className="flex items-center gap-2"
          >
            <List className="h-4 w-4" />
            View All Vehicles
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

