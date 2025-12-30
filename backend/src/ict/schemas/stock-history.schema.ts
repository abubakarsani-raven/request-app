import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type StockHistoryDocument = StockHistory & Document;

export enum StockOperation {
  ADD = 'ADD',
  REMOVE = 'REMOVE',
  ADJUST = 'ADJUST',
  FULFILLMENT = 'FULFILLMENT',
  RETURN = 'RETURN',
}

@Schema({ timestamps: true })
export class StockHistory {
  @Prop({ type: Types.ObjectId, ref: 'ICTItem', required: true })
  itemId: Types.ObjectId;

  @Prop({ required: true })
  previousQuantity: number;

  @Prop({ required: true })
  newQuantity: number;

  @Prop({ required: true })
  changeAmount: number; // positive for additions, negative for removals

  @Prop({ type: String, enum: Object.values(StockOperation), required: true })
  operation: StockOperation;

  @Prop()
  reason?: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  performedBy: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'ICTRequest' })
  requestId?: Types.ObjectId;
}

export const StockHistorySchema = SchemaFactory.createForClass(StockHistory);

