"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Plus, Search, Package, AlertTriangle, History, Edit, Trash2 } from "lucide-react";
import { useToast } from "@/components/ui/use-toast";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";
import { StoreInventoryManagement } from "@/components/store-inventory/StoreInventoryManagement";

export default function StoreInventoryPage() {
  return <StoreInventoryManagement />;
}
