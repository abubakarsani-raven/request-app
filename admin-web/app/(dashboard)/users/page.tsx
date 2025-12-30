"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { useToast } from "@/components/ui/use-toast";
import { Pencil, KeyRound, UserCog, Trash2 } from "lucide-react";
import { SkeletonTableRows } from "@/components/ui/skeleton-variants";
import { ResetPasswordDialog } from "@/components/user-management/ResetPasswordDialog";
import { RoleAssignmentDialog } from "@/components/user-management/RoleAssignmentDialog";
import { BulkUserOperations } from "@/components/user-management/BulkUserOperations";
import { useAdminPermissions } from "@/hooks/useAdminPermissions";

type User = { 
  _id: string; 
  name: string; 
  email: string; 
  phone?: string; 
  department?: string; 
  departmentId?: any; // Can be ObjectId or populated object
  role?: string; 
  roles?: string[]; 
  employeeId?: string; 
  isSupervisor?: boolean; 
  office?: string; 
  officeId?: any; // Can be ObjectId or populated object
  level?: number 
};
type Department = { _id: string; name: string; description?: string };
type Office = { _id: string; name: string; address?: string; isHeadOffice?: boolean };

async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed");
  return res.json();
}

export default function UsersPage() {
  const qc = useQueryClient();
  const { success, error } = useToast();
  const permissions = useAdminPermissions();
  const [showCreateUser, setShowCreateUser] = useState(false);
  const [resetPasswordUser, setResetPasswordUser] = useState<{ id: string; name: string } | null>(null);
  const [roleAssignmentUser, setRoleAssignmentUser] = useState<{ id: string; name: string; roles: string[] } | null>(null);
  const [selectedUserIds, setSelectedUserIds] = useState<string[]>([]);
  const [bulkOperationsOpen, setBulkOperationsOpen] = useState(false);
  const [userForm, setUserForm] = useState({ 
    name: "", 
    email: "", 
    phone: "", 
    password: "", 
    department: "", 
    office: "",
    isSupervisor: false, 
    roles: [] as string[],
    employeeId: "",
    level: 1
  });
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [editUserForm, setEditUserForm] = useState({ 
    name: "", 
    phone: "", 
    password: "", 
    department: "", 
    office: "",
    isSupervisor: false, 
    roles: [] as string[],
    employeeId: "",
    level: 1
  });

  const allUsersQ = useQuery<User[]>({ 
    queryKey: ["allUsers"], 
    queryFn: async () => {
      const res = await fetch("/api/users", { cache: "no-store" });
      if (res.status === 403) {
        // Try to bootstrap admin role
        const bootstrapRes = await fetch("/api/users/bootstrap-admin", { cache: "no-store" });
        if (bootstrapRes.ok) {
          const bootstrapData = await bootstrapRes.json();
          success(`Admin role added: ${bootstrapData.message}`);
          // Retry fetching users
          const retryRes = await fetch("/api/users", { cache: "no-store" });
          if (retryRes.ok) {
            return retryRes.json();
          }
        }
        throw new Error("Forbidden: Admin role required");
      }
      if (!res.ok) throw new Error("Failed to fetch users");
      return res.json();
    },
    retry: false,
  });
  const departmentsQ = useQuery<Department[]>({ queryKey: ["departments"], queryFn: () => fetchJSON<Department[]>("/api/departments") });
  const officesQ = useQuery<Office[]>({ queryKey: ["offices"], queryFn: () => fetchJSON<Office[]>("/api/offices") });

  async function createUser() {
    if (!userForm.name || !userForm.email || !userForm.phone || !userForm.password) {
      error('Please fill all required fields');
      return;
    }
    if (userForm.roles.length === 0) {
      error('Please select at least one role');
      return;
    }
    if (userForm.password.length < 6) {
      error('Password must be at least 6 characters');
      return;
    }
    // Validate department if supervisor role is selected
    if (userForm.roles.includes('SUPERVISOR') && !userForm.department) {
      error('Department is required for supervisor role');
      return;
    }
    
    // Find department ID from department name
    const selectedDepartment = departmentsQ.data?.find(d => d.name === userForm.department);
    if (!selectedDepartment && userForm.roles.includes('SUPERVISOR')) {
      error('Department is required for supervisor role');
      return;
    }
    // Find office ID from office name
    const selectedOffice = officesQ.data?.find(o => o.name === userForm.office);
    if (!selectedOffice) {
      error('Office is required');
      return;
    }
    const res = await fetch('/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        name: userForm.name, 
        email: userForm.email, 
        phone: userForm.phone || null,
        password: userForm.password, 
        roles: normalizeRolesForBackend(userForm.roles),
        departmentId: selectedDepartment?._id,
        officeId: selectedOffice?._id,
        level: userForm.level,
      }),
    });
    if (res.ok) {
      setShowCreateUser(false);
      setUserForm({ name: "", email: "", phone: "", password: "", department: "", office: "", isSupervisor: false, roles: [], employeeId: "", level: 1 });
      qc.invalidateQueries({ queryKey: ["allUsers"] });
      success('User created successfully');
    } else {
      const data = await res.json().catch(() => ({}));
      error(data.message || 'Failed to create user');
    }
  }

  async function updateUser() {
    if (!editingUser || !editUserForm.name || !editUserForm.phone) {
      error('Please fill all required fields');
      return;
    }
    if (editUserForm.password && editUserForm.password.length < 6) {
      error('Password must be at least 6 characters');
      return;
    }
    if (editUserForm.roles.length === 0) {
      error('Please select at least one role');
      return;
    }
    const updateData: any = {
      name: editUserForm.name,
      phone: editUserForm.phone || null,
      roles: normalizeRolesForBackend(editUserForm.roles), // Convert to backend format
      level: editUserForm.level,
    };
    if (editUserForm.password) {
      updateData.password = editUserForm.password;
    }
    // Find department ID from department name
    const selectedDepartment = departmentsQ.data?.find(d => d.name === editUserForm.department);
    if (selectedDepartment) {
      updateData.departmentId = selectedDepartment._id;
    }
    // Find office ID from office name
    const selectedOffice = officesQ.data?.find(o => o.name === editUserForm.office);
    if (selectedOffice) {
      updateData.officeId = selectedOffice._id;
    }
    
    console.log('Updating user with data:', updateData); // Debug log
    
    const res = await fetch(`/api/users/${editingUser._id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updateData),
    });
    if (res.ok) {
      const updatedData = await res.json().catch(() => ({}));
      console.log('User updated successfully:', updatedData); // Debug log
      setEditingUser(null);
      setEditUserForm({ name: "", phone: "", password: "", department: "", office: "", isSupervisor: false, roles: [], employeeId: "", level: 1 });
      qc.invalidateQueries({ queryKey: ["allUsers"] });
      success('User updated successfully');
    } else {
      const data = await res.json().catch(() => ({}));
      const errorMessage = data.message || 'Failed to update user';
      console.error('Update error:', errorMessage, data); // Debug log
      error(errorMessage);
    }
  }

  function openEditUserDialog(user: User) {
    setEditingUser(user);
    // Get roles from roles array or fallback to single role (backward compatibility)
    // Normalize roles to uppercase for frontend display (backend sends uppercase)
    const userRoles = user.roles && user.roles.length > 0 
      ? user.roles.map(r => r.toUpperCase()) 
      : (user.role ? [user.role.toUpperCase()] : []);
    // Extract department and office names from populated objects
    const departmentName = typeof user.departmentId === 'object' && user.departmentId?.name 
      ? user.departmentId.name 
      : user.department || "";
    const officeName = typeof user.officeId === 'object' && user.officeId?.name 
      ? user.officeId.name 
      : user.office || "";
    
    setEditUserForm({
      name: user.name,
      phone: user.phone || "",
      password: "",
      department: departmentName,
      office: officeName,
      isSupervisor: user.isSupervisor || false,
      roles: userRoles,
      employeeId: user.employeeId || "",
      level: user.level || 1,
    });
  }

  // Helper function to get display roles (normalize to uppercase for display)
  function getDisplayRoles(user: User): string[] {
    const roles = user.roles && user.roles.length > 0 ? user.roles : (user.role ? [user.role] : []);
    return roles.map(r => r.toUpperCase());
  }

  // Helper function to convert frontend roles to backend format (uppercase)
  function normalizeRolesForBackend(roles: string[]): string[] {
    // Frontend already uses uppercase, so just ensure they're uppercase
    return roles.map(r => r.toUpperCase());
  }

  // Helper function to get role badge color
  function getRoleBadgeColor(role: string): string {
    const colors: Record<string, string> = {
      staff: 'bg-blue-100 text-blue-800',
      driver: 'bg-green-100 text-green-800',
      transport_officer: 'bg-purple-100 text-purple-800',
      dgs: 'bg-yellow-100 text-yellow-800',
      ddgs: 'bg-orange-100 text-orange-800',
      ad_transport: 'bg-red-100 text-red-800',
      admin: 'bg-gray-100 text-gray-800',
    };
    return colors[role] || 'bg-gray-100 text-gray-800';
  }

  const rows = allUsersQ.data ?? [];

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Users Management</CardTitle>
            <div className="flex gap-2">
              {selectedUserIds.length > 0 && permissions.isMainAdmin && (
                <Button
                  variant="outline"
                  onClick={() => setBulkOperationsOpen(true)}
                >
                  Bulk Operations ({selectedUserIds.length})
                </Button>
              )}
              <Dialog open={showCreateUser} onOpenChange={setShowCreateUser}>
                <DialogTrigger asChild>
                  <Button>Create User</Button>
                </DialogTrigger>
                <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
                  <DialogHeader>
                    <DialogTitle>Create User</DialogTitle>
                  </DialogHeader>
                  <div className="space-y-4 py-4">
                    <div className="space-y-2">
                      <Label htmlFor="user-name">Name *</Label>
                      <Input id="user-name" value={userForm.name} onChange={(e) => setUserForm({ ...userForm, name: e.target.value })} />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="user-email">Email *</Label>
                      <Input id="user-email" type="email" value={userForm.email} onChange={(e) => setUserForm({ ...userForm, email: e.target.value })} />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="user-phone">Phone *</Label>
                      <Input id="user-phone" value={userForm.phone} onChange={(e) => setUserForm({ ...userForm, phone: e.target.value })} />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="user-password">Password *</Label>
                      <Input id="user-password" type="password" value={userForm.password} onChange={(e) => setUserForm({ ...userForm, password: e.target.value })} />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="user-roles">Roles * (Select multiple)</Label>
                      <div className="space-y-2 border rounded-md p-3 max-h-48 overflow-y-auto">
                        {['ADMIN', 'DGS', 'DDGS', 'ADGS', 'TO', 'DDICT', 'SO', 'SUPERVISOR', 'DRIVER', 'ICT_ADMIN', 'STORE_ADMIN', 'TRANSPORT_ADMIN'].map((role) => (
                          <div key={role} className="flex items-center space-x-2">
                            <Checkbox
                              id={`user-role-${role}`}
                              checked={userForm.roles.includes(role)}
                              onCheckedChange={(checked) => {
                                const currentRoles = [...userForm.roles];
                                if (checked) {
                                  if (!currentRoles.includes(role)) {
                                    setUserForm({ ...userForm, roles: [...currentRoles, role] });
                                  }
                                } else {
                                  setUserForm({ ...userForm, roles: currentRoles.filter(r => r !== role) });
                                }
                              }}
                            />
                            <Label htmlFor={`user-role-${role}`} className="cursor-pointer">
                              {role}
                            </Label>
                          </div>
                        ))}
                      </div>
                      {userForm.roles.length === 0 && (
                        <p className="text-xs text-red-500">Please select at least one role</p>
                      )}
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="user-department">Department {userForm.roles.includes('SUPERVISOR') ? '*' : ''}</Label>
                      <Select
                        value={userForm.department}
                        onValueChange={(value) => setUserForm({ ...userForm, department: value })}
                      >
                        <SelectTrigger id="user-department">
                          <SelectValue placeholder="Select a department" />
                        </SelectTrigger>
                        <SelectContent>
                          {departmentsQ.data?.map((dept) => (
                            <SelectItem key={dept._id} value={dept.name}>
                              {dept.name}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {departmentsQ.data?.length === 0 && (
                        <p className="text-xs text-muted-foreground">
                          No departments available. Please create a department first.
                        </p>
                      )}
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="user-office">Office *</Label>
                      <Select
                        value={userForm.office}
                        onValueChange={(value) => setUserForm({ ...userForm, office: value })}
                      >
                        <SelectTrigger id="user-office">
                          <SelectValue placeholder="Select an office" />
                        </SelectTrigger>
                        <SelectContent>
                          {officesQ.data?.map((office) => (
                            <SelectItem key={office._id} value={office.name}>
                              {office.name} {office.isHeadOffice ? '(Head Office)' : ''}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {officesQ.data?.length === 0 && (
                        <p className="text-xs text-muted-foreground">
                          No offices available. Please create an office first.
                        </p>
                      )}
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="user-level">Level *</Label>
                      <Input 
                        id="user-level" 
                        type="number" 
                        min="1" 
                        value={userForm.level} 
                        onChange={(e) => setUserForm({ ...userForm, level: parseInt(e.target.value) || 1 })} 
                      />
                      <p className="text-xs text-muted-foreground">
                        User level for workflow (1 = lowest, higher numbers = higher authority)
                      </p>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="user-supervisor"
                        checked={userForm.isSupervisor}
                        onCheckedChange={(checked) => setUserForm({ ...userForm, isSupervisor: checked === true })}
                      />
                      <Label htmlFor="user-supervisor" className="cursor-pointer">Is Supervisor</Label>
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="user-employeeId">Employee ID (optional)</Label>
                      <Input id="user-employeeId" value={userForm.employeeId} onChange={(e) => setUserForm({ ...userForm, employeeId: e.target.value })} />
                    </div>
                    <div className="flex gap-2 justify-end">
                      <Button variant="outline" onClick={() => setShowCreateUser(false)}>Cancel</Button>
                      <Button onClick={createUser}>Create</Button>
                    </div>
                  </div>
                </DialogContent>
              </Dialog>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="mt-4">
            <Table>
              <TableHeader>
                <TableRow>
                  {permissions.isMainAdmin && (
                    <TableHead className="w-12">
                      <Checkbox
                        checked={selectedUserIds.length === rows.length && rows.length > 0}
                        onCheckedChange={(checked) => {
                          if (checked) {
                            setSelectedUserIds(rows.map((u) => u._id));
                          } else {
                            setSelectedUserIds([]);
                          }
                        }}
                      />
                    </TableHead>
                  )}
                  <TableHead>Name</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Phone</TableHead>
                  <TableHead>Department</TableHead>
                  <TableHead>Office</TableHead>
                  <TableHead>Level</TableHead>
                  <TableHead>Employee ID</TableHead>
                  <TableHead>Roles</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {allUsersQ.isLoading ? (
                  <SkeletonTableRows rows={5} cols={9} />
                ) : rows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={permissions.isMainAdmin ? 10 : 9} className="text-center">No users found</TableCell>
                  </TableRow>
                ) : (
                  rows.map((u) => (
                    <TableRow key={u._id}>
                      {permissions.isMainAdmin && (
                        <TableCell>
                          <Checkbox
                            checked={selectedUserIds.includes(u._id)}
                            onCheckedChange={(checked) => {
                              if (checked) {
                                setSelectedUserIds([...selectedUserIds, u._id]);
                              } else {
                                setSelectedUserIds(selectedUserIds.filter((id) => id !== u._id));
                              }
                            }}
                          />
                        </TableCell>
                      )}
                      <TableCell>{u.name}</TableCell>
                      <TableCell>{u.email}</TableCell>
                      <TableCell>{u.phone ?? 'N/A'}</TableCell>
                      <TableCell>
                        {typeof u.departmentId === 'object' && u.departmentId?.name 
                          ? u.departmentId.name 
                          : u.department ?? 'N/A'}
                      </TableCell>
                      <TableCell>
                        {typeof u.officeId === 'object' && u.officeId?.name 
                          ? u.officeId.name 
                          : u.office ?? 'N/A'}
                      </TableCell>
                      <TableCell>{u.level ?? 'N/A'}</TableCell>
                      <TableCell>{u.employeeId ?? 'N/A'}</TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-1">
                          {getDisplayRoles(u).map((role, idx) => (
                            <span key={idx} className={`text-xs px-2 py-1 rounded ${getRoleBadgeColor(role)}`}>
                              {role}
                            </span>
                          ))}
                        </div>
                        {u.isSupervisor && <span className="text-xs text-gray-500 ml-1 block">(Supervisor)</span>}
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-1">
                          <Button 
                            variant="outline" 
                            size="sm" 
                            onClick={() => openEditUserDialog(u)}
                            title="Edit User"
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                          {permissions.isMainAdmin && (
                            <>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setResetPasswordUser({ id: u._id, name: u.name })}
                                title="Reset Password"
                              >
                                <KeyRound className="h-4 w-4" />
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setRoleAssignmentUser({ 
                                  id: u._id, 
                                  name: u.name, 
                                  roles: getDisplayRoles(u) 
                                })}
                                title="Assign Roles"
                              >
                                <UserCog className="h-4 w-4" />
                              </Button>
                            </>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {/* Edit User Dialog */}
      <Dialog open={!!editingUser} onOpenChange={(open) => !open && setEditingUser(null)}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Edit User</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="edit-user-name">Name *</Label>
              <Input 
                id="edit-user-name" 
                value={editUserForm.name} 
                onChange={(e) => setEditUserForm({ ...editUserForm, name: e.target.value })} 
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-user-email">Email</Label>
              <Input 
                id="edit-user-email" 
                type="email" 
                value={editingUser?.email || ""} 
                disabled
                className="bg-muted cursor-not-allowed"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-user-phone">Phone *</Label>
              <Input 
                id="edit-user-phone" 
                value={editUserForm.phone} 
                onChange={(e) => setEditUserForm({ ...editUserForm, phone: e.target.value })} 
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-user-roles">Roles * (Select multiple)</Label>
              <div className="space-y-2 border rounded-md p-3 max-h-48 overflow-y-auto">
                {['ADMIN', 'DGS', 'DDGS', 'ADGS', 'TO', 'DDICT', 'SO', 'SUPERVISOR'].map((role) => (
                  <div key={role} className="flex items-center space-x-2">
                    <Checkbox
                      id={`edit-role-${role}`}
                      checked={editUserForm.roles.includes(role)}
                      onCheckedChange={(checked) => {
                        const currentRoles = [...editUserForm.roles];
                        if (checked) {
                          if (!currentRoles.includes(role)) {
                            setEditUserForm({ ...editUserForm, roles: [...currentRoles, role] });
                          }
                        } else {
                          setEditUserForm({ ...editUserForm, roles: currentRoles.filter(r => r !== role) });
                        }
                      }}
                    />
                    <Label htmlFor={`edit-role-${role}`} className="cursor-pointer">
                      {role}
                    </Label>
                  </div>
                ))}
              </div>
              {editUserForm.roles.length === 0 && (
                <p className="text-xs text-red-500">Please select at least one role</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-user-password">New Password (leave blank to keep current)</Label>
              <Input 
                id="edit-user-password" 
                type="password" 
                value={editUserForm.password} 
                onChange={(e) => setEditUserForm({ ...editUserForm, password: e.target.value })} 
                placeholder="Enter new password"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-user-department">Department {editUserForm.roles.includes('SUPERVISOR') ? '*' : ''}</Label>
              <Select
                value={editUserForm.department}
                onValueChange={(value) => setEditUserForm({ ...editUserForm, department: value })}
              >
                <SelectTrigger id="edit-user-department">
                  <SelectValue placeholder="Select a department" />
                </SelectTrigger>
                <SelectContent>
                  {departmentsQ.data?.map((dept) => (
                    <SelectItem key={dept._id} value={dept.name}>
                      {dept.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-user-office">Office *</Label>
              <Select
                value={editUserForm.office}
                onValueChange={(value) => setEditUserForm({ ...editUserForm, office: value })}
              >
                <SelectTrigger id="edit-user-office">
                  <SelectValue placeholder="Select an office" />
                </SelectTrigger>
                <SelectContent>
                  {officesQ.data?.map((office) => (
                    <SelectItem key={office._id} value={office.name}>
                      {office.name} {office.isHeadOffice ? '(Head Office)' : ''}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {officesQ.data?.length === 0 && (
                <p className="text-xs text-muted-foreground">
                  No offices available. Please create an office first.
                </p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-user-level">Level *</Label>
              <Input 
                id="edit-user-level" 
                type="number" 
                min="1" 
                value={editUserForm.level} 
                onChange={(e) => setEditUserForm({ ...editUserForm, level: parseInt(e.target.value) || 1 })} 
              />
              <p className="text-xs text-muted-foreground">
                User level for workflow (1 = lowest, higher numbers = higher authority)
              </p>
            </div>
            <div className="flex items-center space-x-2">
              <Checkbox
                id="edit-user-supervisor"
                checked={editUserForm.isSupervisor}
                onCheckedChange={(checked) => setEditUserForm({ ...editUserForm, isSupervisor: checked === true })}
              />
              <Label htmlFor="edit-user-supervisor" className="cursor-pointer">Is Supervisor</Label>
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-user-employeeId">Employee ID (optional)</Label>
              <Input
                id="edit-user-employeeId"
                value={editUserForm.employeeId}
                onChange={(e) => setEditUserForm({ ...editUserForm, employeeId: e.target.value })}
              />
            </div>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setEditingUser(null)}>Cancel</Button>
              <Button onClick={updateUser}>Update</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {resetPasswordUser && (
        <ResetPasswordDialog
          open={!!resetPasswordUser}
          userId={resetPasswordUser.id}
          userName={resetPasswordUser.name}
          onClose={() => setResetPasswordUser(null)}
          onSuccess={() => {
            qc.invalidateQueries({ queryKey: ["allUsers"] });
          }}
        />
      )}

      {roleAssignmentUser && (
        <RoleAssignmentDialog
          open={!!roleAssignmentUser}
          userId={roleAssignmentUser.id}
          userName={roleAssignmentUser.name}
          currentRoles={roleAssignmentUser.roles}
          onClose={() => setRoleAssignmentUser(null)}
          onSuccess={() => {
            qc.invalidateQueries({ queryKey: ["allUsers"] });
          }}
        />
      )}

      {bulkOperationsOpen && (
        <BulkUserOperations
          open={bulkOperationsOpen}
          selectedUserIds={selectedUserIds}
          onClose={() => {
            setBulkOperationsOpen(false);
            setSelectedUserIds([]);
          }}
          onSuccess={() => {
            qc.invalidateQueries({ queryKey: ["allUsers"] });
            setSelectedUserIds([]);
          }}
        />
      )}
    </div>
  );
}


