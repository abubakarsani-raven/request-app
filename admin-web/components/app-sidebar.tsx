"use client"

import * as React from "react"
import {
  LayoutDashboard,
  FileText,
  Car,
  Users,
  Building2,
  MapPin,
  Building,
  Truck,
  Package,
  Wrench,
  Bell,
  User,
  Settings,
  BarChart3,
  FileSpreadsheet,
} from "lucide-react"
import { usePathname } from "next/navigation"

import { NavMain, type NavItem } from "@/components/nav-main"
import { NavUser } from "@/components/nav-user"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarRail,
} from "@/components/ui/sidebar"
import { useAuth } from "@/hooks/useAuth"
import { useAdminPermissions } from "@/hooks/useAdminPermissions"

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const pathname = usePathname()
  const { user } = useAuth()
  const permissions = useAdminPermissions()

  const navMain: NavItem[] = [
    {
      title: "Dashboard",
      url: "/",
      icon: LayoutDashboard,
      isActive: pathname === "/",
    },
    // ICT Requests - Main Admin or ICT Admin
    ...(permissions.canManageICT ? [{
      title: "ICT Requests",
      url: "/ict-requests",
      icon: FileText,
      isActive: pathname === "/ict-requests",
    }] : []),
    // ICT Inventory - Main Admin or ICT Admin
    ...(permissions.canManageICT ? [{
      title: "ICT Inventory",
      url: "/ict-inventory",
      icon: Package,
      isActive: pathname === "/ict-inventory",
    }] : []),
    // Store Requests - Main Admin or Store Admin
    ...(permissions.canManageStore ? [{
      title: "Store Requests",
      url: "/store-requests",
      icon: Package,
      isActive: pathname === "/store-requests",
    }] : []),
    // Store Inventory - Main Admin or Store Admin
    ...(permissions.canManageStore ? [{
      title: "Store Inventory",
      url: "/store-inventory",
      icon: Package,
      isActive: pathname === "/store-inventory",
    }] : []),
    // Transport - Main Admin or Transport Admin
    ...(permissions.canManageTransport ? [{
      title: "Transport",
      icon: Truck,
      isActive: pathname.startsWith("/transport"),
      items: [
        {
          title: "Transport Requests",
          url: "/transport/requests",
          isActive: pathname === "/transport/requests",
        },
        {
          title: "Vehicles",
          url: "/transport/vehicles",
          icon: Car,
          isActive: pathname.startsWith("/transport/vehicles"),
          items: [
            {
              title: "All Vehicles",
              url: "/transport/vehicles",
              icon: Car,
              isActive: pathname === "/transport/vehicles",
            },
            {
              title: "Maintenance",
              url: "/transport/vehicles",
              icon: Wrench,
              isActive: pathname.startsWith("/transport/vehicles") && pathname.includes("maintenance"),
            },
            {
              title: "Reminders",
              url: "/transport/vehicles",
              icon: Bell,
              isActive: pathname.startsWith("/transport/vehicles") && pathname.includes("reminders"),
            },
          ],
        },
        {
          title: "Drivers",
          url: "/transport/drivers",
          icon: User,
          isActive: pathname === "/transport/drivers",
        },
        {
          title: "Tracking",
          url: "/transport/tracking",
          icon: MapPin,
          isActive: pathname === "/transport/tracking",
        },
        {
          title: "Analytics",
          url: "/transport/analytics",
          icon: BarChart3,
          isActive: pathname === "/transport/analytics",
        },
      ],
    }] : []),
    // Reports - Any Admin
    ...(permissions.canApproveAll ? [{
      title: "Reports",
      url: "/reports",
      icon: FileSpreadsheet,
      isActive: pathname === "/reports",
    }] : []),
    // Analytics - Any Admin
    ...(permissions.canApproveAll ? [{
      title: "Analytics",
      url: "/analytics",
      icon: BarChart3,
      isActive: pathname === "/analytics",
    }] : []),
    // Notifications - Any Admin
    ...(permissions.canApproveAll ? [{
      title: "Notifications",
      url: "/notifications",
      icon: Bell,
      isActive: pathname === "/notifications",
    }] : []),
    // Users - Main Admin only
    ...(permissions.canManageUsers ? [{
      title: "Users",
      url: "/users",
      icon: Users,
      isActive: pathname === "/users",
    }] : []),
    // Offices - Main Admin only
    ...(permissions.canViewAll ? [{
      title: "Offices",
      url: "/offices",
      icon: Building2,
      isActive: pathname === "/offices",
    }] : []),
    // Departments - Main Admin only
    ...(permissions.canViewAll ? [{
      title: "Departments",
      url: "/departments",
      icon: Building,
      isActive: pathname === "/departments",
    }] : []),
    // Settings - Main Admin only
    ...(permissions.canViewAll ? [{
      title: "Settings",
      url: "/settings",
      icon: Settings,
      isActive: pathname === "/settings",
    }] : []),
  ].filter(Boolean) as NavItem[]

  return (
    <Sidebar collapsible="icon" {...props}>
      <SidebarHeader>
        <div className="flex items-center gap-2 px-2 py-4 group-data-[collapsible=icon]:justify-center group-data-[collapsible=icon]:gap-0 group-data-[collapsible=icon]:px-0">
          <div className="flex aspect-square size-8 shrink-0 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground">
            <Car className="size-4" />
          </div>
          <div className="grid flex-1 text-left text-sm leading-tight group-data-[collapsible=icon]:hidden">
            <span className="truncate font-semibold">Admin Panel</span>
            <span className="truncate text-xs">Transport Management</span>
          </div>
        </div>
      </SidebarHeader>
      <SidebarContent>
        <NavMain items={navMain} />
      </SidebarContent>
      <SidebarFooter>
        <NavUser user={user ? { name: user.name, email: user.email, avatar: "" } : { name: "Admin", email: "", avatar: "" }} />
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  )
}
