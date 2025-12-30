export interface MaintenanceReminder {
  type: string; // e.g., 'Oil Change', 'Tire Rotation', 'Brake Inspection'
  dueDate: Date;
  mileage?: number;
  description?: string;
  isCompleted: boolean;
  createdAt: Date;
}

export interface MaintenanceLog {
  type: string; // e.g., 'Oil Change', 'Repair', 'Inspection'
  date: Date;
  mileage?: number;
  cost?: number;
  description: string;
  serviceProvider?: string;
  createdAt: Date;
}

export interface VehicleIssue {
  type: string; // e.g., 'Brake Light', 'Engine', 'Transmission', 'Tire'
  description: string;
  reportedDate: Date;
  reportedBy: string; // User ID
  status: 'REPORTED' | 'IN_PROGRESS' | 'RESOLVED';
  resolvedDate?: Date;
  resolutionNotes?: string;
  createdAt: Date;
}







