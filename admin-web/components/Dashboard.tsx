'use client'

import { useState, useEffect } from 'react'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Users, FileText, Building2, Truck, LogOut } from 'lucide-react'
import UsersManagement from './UsersManagement'
import DepartmentsManagement from './DepartmentsManagement'
import OfficesManagement from './OfficesManagement'
import VehiclesManagement from './VehiclesManagement'
import RequestsMonitoring from './RequestsMonitoring'
import { logout } from '@/lib/auth'
import api from '@/lib/api'

interface DashboardStats {
  totalUsers: number
  pendingRequests: number
  departments: number
  vehicles: number
  offices: number
  todayRequests: number
}

export default function Dashboard() {
  const [activeTab, setActiveTab] = useState('dashboard')
  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    pendingRequests: 0,
    departments: 0,
    vehicles: 0,
    offices: 0,
    todayRequests: 0,
  })
  const [loading, setLoading] = useState(true)

  const fetchStats = async () => {
    try {
      setLoading(true)
      const [usersRes, requestsRes, departmentsRes, vehiclesRes, officesRes] = await Promise.all([
        api.get('/users').catch(() => ({ data: [] })),
        api.get('/vehicles/requests').catch(() => ({ data: [] })),
        api.get('/departments').catch(() => ({ data: [] })),
        api.get('/vehicles/vehicles').catch(() => ({ data: [] })),
        api.get('/offices').catch(() => ({ data: [] })),
      ])

      const today = new Date()
      today.setHours(0, 0, 0, 0)
      const todayRequests = requestsRes.data.filter((req: any) => {
        const requestDate = new Date(req.tripDate)
        requestDate.setHours(0, 0, 0, 0)
        return requestDate.getTime() === today.getTime()
      })

      setStats({
        totalUsers: usersRes.data.length || 0,
        pendingRequests: requestsRes.data.filter((r: any) => r.status === 'PENDING').length || 0,
        departments: departmentsRes.data.length || 0,
        vehicles: vehiclesRes.data.length || 0,
        offices: officesRes.data.length || 0,
        todayRequests: todayRequests.length || 0,
      })
    } catch (error) {
      console.error('Failed to fetch stats', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchStats()
  }, [])

  const handleLogout = () => {
    logout()
  }

  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-bold">Request Management Admin</h1>
            </div>
            <div className="flex items-center">
              <Button variant="ghost" onClick={handleLogout}>
                <LogOut className="mr-2 h-4 w-4" />
                Logout
              </Button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-6">
            <TabsTrigger value="dashboard">Dashboard</TabsTrigger>
            <TabsTrigger value="users">Users</TabsTrigger>
            <TabsTrigger value="departments">Departments</TabsTrigger>
            <TabsTrigger value="offices">Offices</TabsTrigger>
            <TabsTrigger value="vehicles">Vehicles</TabsTrigger>
            <TabsTrigger value="requests">Requests</TabsTrigger>
          </TabsList>

          <TabsContent value="dashboard" className="space-y-6">
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Total Users</CardTitle>
                  <Users className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">
                    {loading ? '...' : stats.totalUsers}
                  </div>
                  <p className="text-xs text-muted-foreground">All registered users</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Pending Requests</CardTitle>
                  <FileText className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">
                    {loading ? '...' : stats.pendingRequests}
                  </div>
                  <p className="text-xs text-muted-foreground">Awaiting approval</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Departments</CardTitle>
                  <Building2 className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">
                    {loading ? '...' : stats.departments}
                  </div>
                  <p className="text-xs text-muted-foreground">Total departments</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Vehicles</CardTitle>
                  <Truck className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">
                    {loading ? '...' : stats.vehicles}
                  </div>
                  <p className="text-xs text-muted-foreground">Total vehicles</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Offices</CardTitle>
                  <Building2 className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">
                    {loading ? '...' : stats.offices}
                  </div>
                  <p className="text-xs text-muted-foreground">Office locations</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Today's Requests</CardTitle>
                  <FileText className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">
                    {loading ? '...' : stats.todayRequests}
                  </div>
                  <p className="text-xs text-muted-foreground">Requests for today</p>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="users">
            <UsersManagement />
          </TabsContent>

          <TabsContent value="departments">
            <DepartmentsManagement />
          </TabsContent>

          <TabsContent value="offices">
            <OfficesManagement />
          </TabsContent>

          <TabsContent value="vehicles">
            <VehiclesManagement />
          </TabsContent>

          <TabsContent value="requests">
            <RequestsMonitoring />
          </TabsContent>
        </Tabs>
      </main>
    </div>
  )
}
