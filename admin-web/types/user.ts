export enum UserRole {
  ADMIN = 'ADMIN',
  ICT_ADMIN = 'ICT_ADMIN',
  STORE_ADMIN = 'STORE_ADMIN',
  TRANSPORT_ADMIN = 'TRANSPORT_ADMIN',
  DGS = 'DGS',
  DDGS = 'DDGS',
  ADGS = 'ADGS',
  TO = 'TO',
  DDICT = 'DDICT',
  SO = 'SO',
  SUPERVISOR = 'SUPERVISOR',
  DRIVER = 'DRIVER',
}

export interface UserProfile {
  id: string;
  email: string;
  name: string;
  role?: UserRole;
  roles?: UserRole[]; // Support multiple roles
  department?: string;
  isSupervisor?: boolean;
  phone?: string;
  employeeId?: string;
  level?: number;
}

