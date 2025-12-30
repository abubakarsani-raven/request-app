import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { MaintenanceReminder, MaintenanceLog, VehicleIssue } from './maintenance.schema';

export type VehicleDocument = Vehicle & Document;

@Schema({ timestamps: true })
export class Vehicle {
  @Prop({ required: true, unique: true })
  plateNumber: string;

  @Prop({ required: true })
  make: string;

  @Prop({ required: true })
  model: string;

  @Prop({ required: true })
  type: string;

  @Prop({ required: true })
  year: number;

  @Prop({ required: true })
  capacity: number;

  @Prop({ default: 'available' })
  status: string;

  @Prop({ default: false })
  isPermanent: boolean;

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  assignedToUserId: Types.ObjectId | null;

  @Prop({ type: Types.ObjectId, ref: 'Office', default: null })
  officeId: Types.ObjectId | null;

  @Prop({ default: true })
  isAvailable: boolean;

  @Prop({ type: Array, default: [] })
  maintenanceReminders: MaintenanceReminder[];

  @Prop({ type: Array, default: [] })
  maintenanceLogs: MaintenanceLog[];

  @Prop({ type: Array, default: [] })
  issues: VehicleIssue[];
}

export const VehicleSchema = SchemaFactory.createForClass(Vehicle);

