import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type ICTItemDocument = ICTItem & Document;

@Schema({ timestamps: true })
export class ICTItem {
  @Prop({ required: true })
  name: string;

  @Prop()
  description: string;

  @Prop({ required: true })
  category: string;

  @Prop({ required: true, default: 0 })
  quantity: number;

  @Prop({ default: true })
  isAvailable: boolean;

  @Prop()
  brand?: string;

  @Prop()
  model?: string;

  @Prop({ unique: true, sparse: true })
  sku?: string;

  @Prop({ default: 'pieces' })
  unit: string;

  @Prop()
  location?: string;

  @Prop({ default: 5 })
  lowStockThreshold: number;

  @Prop()
  supplier?: string;

  @Prop()
  supplierContact?: string;

  @Prop()
  cost?: number;
}

export const ICTItemSchema = SchemaFactory.createForClass(ICTItem);

