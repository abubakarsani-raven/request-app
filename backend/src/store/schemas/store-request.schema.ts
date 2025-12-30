import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { RequestStatus, WorkflowStage, UserRole } from '../../shared/types';

export type StoreRequestDocument = StoreRequest & Document;

export interface RequestItem {
  itemId: Types.ObjectId;
  quantity: number;
  requestedQuantity: number;
  fulfilledQuantity: number;
  isAvailable: boolean;
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

@Schema({ timestamps: true })
export class StoreRequest {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  requesterId: Types.ObjectId;

  @Prop({ type: Array, required: true })
  items: RequestItem[];

  @Prop({ type: String, enum: Object.values(RequestStatus), default: RequestStatus.PENDING })
  status: RequestStatus;

  @Prop({ type: String, enum: Object.values(WorkflowStage), default: WorkflowStage.SUBMITTED })
  workflowStage: WorkflowStage;

  @Prop({ type: Array, default: [] })
  approvals: Approval[];

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

  @Prop({ default: false })
  directToSO: boolean; // If true, DGS routed directly to SO, otherwise through DDGS → ADGS → SO

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

export const StoreRequestSchema = SchemaFactory.createForClass(StoreRequest);

