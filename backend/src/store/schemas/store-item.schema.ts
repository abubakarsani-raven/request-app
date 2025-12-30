import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type StoreItemDocument = StoreItem & Document;

@Schema({ timestamps: true })
export class StoreItem {
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
}

export const StoreItemSchema = SchemaFactory.createForClass(StoreItem);

