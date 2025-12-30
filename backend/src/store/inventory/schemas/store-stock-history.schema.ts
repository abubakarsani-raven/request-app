import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type StoreStockHistoryDocument = StoreStockHistory & Document;

export enum StoreStockOperation {
  ADD = 'ADD',
  REMOVE = 'REMOVE',
  ADJUST = 'ADJUST',
  FULFILLMENT = 'FULFILLMENT',
  RETURN = 'RETURN',
}

@Schema({ timestamps: true })
export class StoreStockHistory {
  @Prop({ type: Types.ObjectId, ref: 'StoreItem', required: true })
  itemId: Types.ObjectId;

  @Prop({ required: true })
  previousQuantity: number;

  @Prop({ required: true })
  newQuantity: number;

  @Prop({ required: true })
  changeAmount: number; // positive for additions, negative for removals

  @Prop({ type: String, enum: Object.values(StoreStockOperation), required: true })
  operation: StoreStockOperation;

  @Prop()
  reason?: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  performedBy: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'StoreRequest' })
  requestId?: Types.ObjectId;
}

export const StoreStockHistorySchema = SchemaFactory.createForClass(StoreStockHistory);
