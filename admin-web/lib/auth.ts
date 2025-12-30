export interface User {
  _id: string;
  email: string;
  name: string;
  roles: string[];
  departmentId: string;
  level: number;
}

export function getUserFromToken(): User | null {
  const token = localStorage.getItem('access_token');
  if (!token) return null;

  try {
    // Decode JWT token (simple base64 decode, not full verification)
    const payload = JSON.parse(atob(token.split('.')[1]));
    return {
      _id: payload.sub,
      email: payload.email,
      name: payload.name || payload.email,
      roles: payload.roles || [],
      departmentId: payload.departmentId,
      level: payload.level || 1,
    };
  } catch (error) {
    return null;
  }
}

export function isAdmin(): boolean {
  const user = getUserFromToken();
  return user?.roles?.includes('ADMIN') || false;
}

export function hasRole(role: string): boolean {
  const user = getUserFromToken();
  return user?.roles?.includes(role) || false;
}

export function logout(): void {
  localStorage.removeItem('access_token');
  window.location.href = '/';
}







