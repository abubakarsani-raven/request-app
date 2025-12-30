import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types, Schema as MongooseSchema } from 'mongoose';
import { RequestStatus, WorkflowStage, UserRole } from '../../shared/types';

export type ICTRequestDocument = ICTRequest & Document;

export interface RequestItem {
  itemId: Types.ObjectId;
  quantity: number;
  requestedQuantity: number;
  approvedQuantity?: number; // Quantity approved by DDICT (may differ from requested)
  fulfilledQuantity: number;
  isAvailable: boolean;
}

export interface QuantityChange {
  itemId: Types.ObjectId;
  itemName?: string;
  previousQuantity: number;
  newQuantity: number;
  changedBy: Types.ObjectId;
  changedAt: Date;
  reason?: string;
}

export interface Approval {
  approverId: Types.ObjectId;
  role: UserRole;
  status: 'APPROVED' | 'REJECTED';
  comment?: string;
  timestamp: Date;
}

export interface Participant {
  userId: Types.ObjectId;
  role: UserRole;
  action: 'created' | 'approved' | 'rejected' | 'corrected' | 'fulfilled';
  timestamp: Date;
}

// Subdocument schema for items array
const RequestItemSchema = new MongooseSchema({
  itemId: { type: Types.ObjectId, ref: 'ICTItem', required: true },
  quantity: { type: Number, required: true },
  requestedQuantity: { type: Number, required: true },
  approvedQuantity: { type: Number }, // Quantity approved by DDICT
  fulfilledQuantity: { type: Number, default: 0 },
  isAvailable: { type: Boolean, default: true },
}, { _id: false });

// Subdocument schema for quantity changes history
const QuantityChangeSchema = new MongooseSchema({
  itemId: { type: Types.ObjectId, ref: 'ICTItem', required: true },
  itemName: { type: String },
  previousQuantity: { type: Number, required: true },
  newQuantity: { type: Number, required: true },
  changedBy: { type: Types.ObjectId, ref: 'User', required: true },
  changedAt: { type: Date, default: Date.now },
  reason: { type: String },
}, { _id: false });

@Schema({ timestamps: true })
export class ICTRequest {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  requesterId: Types.ObjectId;

  @Prop({ type: [RequestItemSchema], required: true })
  items: RequestItem[];

  @Prop({ type: String, enum: Object.values(RequestStatus), default: RequestStatus.PENDING })
  status: RequestStatus;

  @Prop({ type: String, enum: Object.values(WorkflowStage), default: WorkflowStage.SUBMITTED })
  workflowStage: WorkflowStage;

  @Prop({ type: Array, default: [] })
  approvals: Approval[];

  @Prop()
  comment?: string;

  @Prop({ default: false })
  priority: boolean;

  @Prop({ unique: true })
  qrCode: string;

  @Prop({ type: Array, default: [] })
  fulfillmentStatus: Array<{
    itemId: Types.ObjectId;
    quantityFulfilled: number;
    fulfilledAt: Date;
    fulfilledBy: Types.ObjectId;
  }>;

  @Prop({ type: [QuantityChangeSchema], default: [] })
  quantityChanges: QuantityChange[];

  // Workflow participants tracking
  @Prop({
    type: [
      {
        userId: { type: Types.ObjectId, ref: 'User', required: true },
        role: { type: String, enum: Object.values(UserRole), required: true },
        action: {
          type: String,
          enum: ['created', 'approved', 'rejected', 'corrected', 'fulfilled'],
          required: true,
        },
        timestamp: { type: Date, required: true, default: Date.now },
      },
    ],
    default: [],
    _id: false,
  })
  participants: Participant[];
}

export const ICTRequestSchema = SchemaFactory.createForClass(ICTRequest);

