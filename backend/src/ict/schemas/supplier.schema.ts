import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SupplierDocument = Supplier & Document;

/**
 * Supplier (vendor) with a unique reference number for identification and printing.
 */
@Schema({ timestamps: true })
export class Supplier {
  @Prop({ required: true, unique: true })
  referenceNumber: string; // e.g. SVR-000001

  @Prop({ required: true })
  name: string;

  @Prop()
  contactEmail?: string;

  @Prop()
  contactPhone?: string;

  @Prop()
  address?: string;
}

export const SupplierSchema = SchemaFactory.createForClass(Supplier);
