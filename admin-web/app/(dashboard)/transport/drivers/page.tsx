"use client";

import React from "react";
import { useQuery } from "@tanstack/react-query";
import { useState, useMemo } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";
import { DriverAssignmentsList } from "@/components/transport/DriverAssignmentsList";
import { DriverStatistics } from "@/components/transport/DriverStatistics";
import { ChevronDown, ChevronRight, Phone, IdCard, User, Mail } from "lucide-react";

type UserDriver = {
  _id: string;
  name: string;
  email: string;
  phone?: string | null;
  roles?: string[];
  role?: string;
  employeeId?: string;
};

type Assignment = {
  _id: string;
  driverId: string | { _id: string };
  tripCompleted: boolean;
  status: string;
  tripStarted: boolean;
};

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) {
    throw new Error(`Failed to fetch: ${res.status}`);
  }
  return res.json();
}

export default function DriversPage() {
  const [availabilityFilter, setAvailabilityFilter] = useState<string>("all");
  const [expandedDrivers, setExpandedDrivers] = useState<Set<string>>(new Set());

  // Fetch all users
  const { data: users = [], isLoading: isLoadingUsers } = useQuery<UserDriver[]>({
    queryKey: ["users"],
    queryFn: () => fetchJSON<UserDriver[]>("/api/users"),
  });

  // Fetch all assignments to determine driver availability
  const { data: allAssignments = [], isLoading: isLoadingAssignments } = useQuery<Assignment[]>({
    queryKey: ["all-assignments"],
    queryFn: () => fetchJSON<Assignment[]>("/api/transport/requests"),
  });

  // Filter users to get only drivers
  const drivers = useMemo(() => {
    return users.filter((user) => {
      const roles = user.roles && user.roles.length > 0 ? user.roles : (user.role ? [user.role] : []);
      return roles.some((r) => r.toLowerCase() === "driver");
    });
  }, [users]);

  // Determine availability for each driver based on active assignments
  const driversWithAvailability = useMemo(() => {
    return drivers.map((driver) => {
      // Find active assignments for this driver (not completed, assigned status)
      const activeAssignments = allAssignments.filter((assignment) => {
        if (!assignment.driverId) return false;
        
        // Handle both ObjectId and populated driverId with null safety
        let driverId: string | null = null;
        if (typeof assignment.driverId === "object" && assignment.driverId !== null) {
          driverId = assignment.driverId._id || assignment.driverId.id || null;
        } else if (assignment.driverId) {
          driverId = assignment.driverId;
        }
        
        if (!driverId) return false;
        
        return (
          driverId === driver._id &&
          !assignment.tripCompleted &&
          (assignment.status === "ASSIGNED" || assignment.status === "APPROVED" || assignment.tripStarted)
        );
      });

      return {
        ...driver,
        isAvailable: activeAssignments.length === 0,
        activeAssignmentsCount: activeAssignments.length,
      };
    });
  }, [drivers, allAssignments]);

  const filteredDrivers = driversWithAvailability.filter((driver) => {
    if (availabilityFilter === "available") return driver.isAvailable;
    if (availabilityFilter === "engaged") return !driver.isAvailable;
    return true;
  });

  const isLoading = isLoadingUsers || isLoadingAssignments;

  const toggleDriverExpansion = (driverId: string) => {
    setExpandedDrivers((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(driverId)) {
        newSet.delete(driverId);
      } else {
        newSet.add(driverId);
      }
      return newSet;
    });
  };

  if (isLoading) {
    return (
      <div className="container mx-auto p-6 space-y-6">
        <div>
          <h1 className="text-3xl font-bold">Drivers Management</h1>
          <p className="text-muted-foreground">Manage and view driver assignments</p>
        </div>
        <Card>
          <CardHeader>
            <CardTitle>Drivers</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[50px]"></TableHead>
                  <TableHead>Name</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Phone</TableHead>
                  <TableHead>Employee ID</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <SkeletonTableRows rows={5} cols={7} />
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Drivers Management</h1>
        <p className="text-muted-foreground">Manage and view driver assignments</p>
      </div>
      <DriverStatistics />
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Drivers</CardTitle>
              <CardDescription>
                {filteredDrivers.length} driver(s) found
                {availabilityFilter !== "all" && ` (${availabilityFilter})`}
              </CardDescription>
            </div>
            <Select value={availabilityFilter} onValueChange={setAvailabilityFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Filter by status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Drivers</SelectItem>
                <SelectItem value="available">Available</SelectItem>
                <SelectItem value="engaged">Engaged</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {filteredDrivers.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No drivers found
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[50px]"></TableHead>
                  <TableHead>Name</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Phone</TableHead>
                  <TableHead>Employee ID</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredDrivers.map((driver) => {
                  const isExpanded = expandedDrivers.has(driver._id);
                  return (
                    <React.Fragment key={driver._id}>
                      <TableRow>
                        <TableCell>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => toggleDriverExpansion(driver._id)}
                            className="h-8 w-8 p-0"
                          >
                            {isExpanded ? (
                              <ChevronDown className="h-4 w-4" />
                            ) : (
                              <ChevronRight className="h-4 w-4" />
                            )}
                          </Button>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <User className="h-4 w-4 text-muted-foreground" />
                            <span className="font-medium">{driver.name}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <Mail className="h-4 w-4 text-muted-foreground" />
                            <span className="text-sm">{driver.email}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <Phone className="h-4 w-4 text-muted-foreground" />
                            <span>{driver.phone || "N/A"}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <IdCard className="h-4 w-4 text-muted-foreground" />
                            <span className="font-mono text-sm">{driver.employeeId || "N/A"}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant={driver.isAvailable ? "default" : "secondary"}>
                            {driver.isAvailable ? "Available" : "Engaged"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => toggleDriverExpansion(driver._id)}
                          >
                            {isExpanded ? "Hide" : "View"} Assignments
                          </Button>
                        </TableCell>
                      </TableRow>
                      {isExpanded && (
                        <TableRow key={`${driver._id}-expanded`}>
                          <TableCell colSpan={7} className="p-0">
                            <div className="p-4 bg-muted/50">
                              <DriverAssignmentsList driverId={driver._id} showHistory={true} />
                            </div>
                          </TableCell>
                        </TableRow>
                      )}
                    </React.Fragment>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

