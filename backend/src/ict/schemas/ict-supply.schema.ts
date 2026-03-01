import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ICTSupplyDocument = ICTSupply & Document;

/**
 * A supply record: stock added to an item from a specific supplier.
 * Multiple suppliers can supply the same item; each addition is a separate supply.
 */
@Schema({ timestamps: true })
export class ICTSupply {
  @Prop({ type: Types.ObjectId, ref: 'ICTItem', required: true })
  itemId: Types.ObjectId;

  @Prop({ required: true })
  quantity: number;

  @Prop()
  supplier?: string;

  @Prop()
  supplierContact?: string;

  @Prop()
  cost?: number;

  @Prop({ default: 'pieces' })
  unit: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  performedBy: Types.ObjectId;

  @Prop()
  reference?: string; // e.g. PO number, delivery note
}

export const ICTSupplySchema = SchemaFactory.createForClass(ICTSupply);
