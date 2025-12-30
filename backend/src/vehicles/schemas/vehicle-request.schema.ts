import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { RequestStatus, WorkflowStage, UserRole } from '../../shared/types';

export type VehicleRequestDocument = VehicleRequest & Document;

export interface Approval {
  approverId: Types.ObjectId;
  role: UserRole;
  status: 'APPROVED' | 'REJECTED';
  comment?: string;
  timestamp: Date;
}

export interface Correction {
  requestedBy: Types.ObjectId;
  role: UserRole;
  comment: string;
  timestamp: Date;
  resolved: boolean;
}

export interface Participant {
  userId: Types.ObjectId;
  role: UserRole;
  action: 'created' | 'approved' | 'rejected' | 'corrected' | 'assigned' | 'fulfilled';
  timestamp: Date;
}

@Schema({ timestamps: true })
export class VehicleRequest {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  requesterId: Types.ObjectId;

  @Prop({ required: true })
  tripDate: Date;

  @Prop({ required: true })
  tripTime: string;

  @Prop({ required: true })
  returnDate: Date;

  @Prop({ required: true })
  returnTime: string;

  @Prop({ required: true })
  destination: string;

  @Prop({ required: true })
  purpose: string;

  // Destination coordinates (from map picker)
  @Prop({
    type: {
      latitude: { type: Number },
      longitude: { type: Number },
    },
    default: null,
    _id: false,
  })
  requestedDestinationLocation: { latitude: number; longitude: number } | null;

  @Prop({ type: Types.ObjectId, ref: 'Vehicle', default: null })
  vehicleId: Types.ObjectId | null;

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  driverId: Types.ObjectId | null;

  @Prop({ type: String, enum: Object.values(RequestStatus), default: RequestStatus.PENDING })
  status: RequestStatus;

  @Prop({ default: false })
  priority: boolean;

  @Prop({ type: String, enum: Object.values(WorkflowStage), default: WorkflowStage.SUBMITTED })
  workflowStage: WorkflowStage;

  @Prop({ type: Array, default: [] })
  approvals: Approval[];

  @Prop({ type: Array, default: [] })
  corrections: Correction[];

  // Workflow participants tracking
  @Prop({
    type: [
      {
        userId: { type: Types.ObjectId, ref: 'User', required: true },
        role: { type: String, enum: Object.values(UserRole), required: true },
        action: {
          type: String,
          enum: ['created', 'approved', 'rejected', 'corrected', 'assigned', 'fulfilled'],
          required: true,
        },
        timestamp: { type: Date, required: true, default: Date.now },
      },
    ],
    default: [],
    _id: false,
  })
  participants: Participant[];

  // Trip tracking fields
  @Prop({ default: null })
  actualDepartureTime: Date | null;

  @Prop({ default: null })
  destinationReachedTime: Date | null;

  @Prop({ default: null })
  actualReturnTime: Date | null;

  @Prop({
    type: {
      latitude: { type: Number },
      longitude: { type: Number },
    },
    default: null,
    _id: false,
  })
  startLocation: { latitude: number; longitude: number } | null; // Office/start location

  @Prop({
    type: {
      latitude: { type: Number },
      longitude: { type: Number },
    },
    default: null,
    _id: false,
  })
  destinationLocation: { latitude: number; longitude: number } | null; // Trip destination

  @Prop({
    type: {
      latitude: { type: Number },
      longitude: { type: Number },
    },
    default: null,
    _id: false,
  })
  returnLocation: { latitude: number; longitude: number } | null; // Office return location

  @Prop({
    type: {
      latitude: { type: Number },
      longitude: { type: Number },
    },
    default: null,
    _id: false,
  })
  dropOffLocation: { latitude: number; longitude: number } | null; // Drop-off point (optional, if not set, return to office)

  @Prop({
    type: {
      latitude: { type: Number },
      longitude: { type: Number },
    },
    default: null,
    _id: false,
  })
  officeLocation: { latitude: number; longitude: number } | null; // Office coordinates

  @Prop({ type: Types.ObjectId, ref: 'Office', default: null })
  officeId: Types.ObjectId | null; // Reference to Office entity

  @Prop({ default: null })
  outboundDistanceKm: number | null; // Distance from office to destination

  @Prop({ default: null })
  returnDistanceKm: number | null; // Distance from destination back to office

  @Prop({ default: null })
  totalDistanceKm: number | null; // Total distance (outbound + return)

  @Prop({ default: null })
  outboundFuelLiters: number | null; // Fuel for outbound leg

  @Prop({ default: null })
  returnFuelLiters: number | null; // Fuel for return leg

  @Prop({ default: null })
  totalFuelLiters: number | null; // Total fuel (outbound + return)

  @Prop({ default: false })
  tripStarted: boolean;

  @Prop({ default: false })
  destinationReached: boolean;

  @Prop({ default: false })
  tripCompleted: boolean; // Only true when returned to office

  // Multi-stop trip support
  @Prop({
    type: [
      {
        name: { type: String, required: true },
        latitude: { type: Number, required: true },
        longitude: { type: Number, required: true },
        order: { type: Number, required: true }, // Order of stop (1, 2, 3, etc.)
        reached: { type: Boolean, default: false },
        reachedTime: { type: Date, default: null },
        distanceFromPrevious: { type: Number, default: null }, // Distance from previous stop
        fuelFromPrevious: { type: Number, default: null }, // Fuel from previous stop
      },
    ],
    default: [],
    _id: false,
  })
  waypoints: Array<{
    name: string;
    latitude: number;
    longitude: number;
    order: number;
    reached: boolean;
    reachedTime?: Date | null;
    distanceFromPrevious?: number | null;
    fuelFromPrevious?: number | null;
  }>;

  // Track current stop
  @Prop({ default: 0 })
  currentStopIndex: number; // 0 = office, 1 = stop 1, 2 = stop 2, etc.

  // Total distance/fuel for multi-stop trip
  @Prop({ default: null })
  totalTripDistanceKm: number | null; // Sum of all legs
  @Prop({ default: null })
  totalTripFuelLiters: number | null; // Sum of all legs
}

export const VehicleRequestSchema = SchemaFactory.createForClass(VehicleRequest);

