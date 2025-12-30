import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type DriverDocument = Driver & Document;

@Schema({ timestamps: true })
export class Driver {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  phone: string;

  @Prop({ required: true, unique: true })
  licenseNumber: string;

  @Prop({ default: true })
  isAvailable: boolean;
}

export const DriverSchema = SchemaFactory.createForClass(Driver);

