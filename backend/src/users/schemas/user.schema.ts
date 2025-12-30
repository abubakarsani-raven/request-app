import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { UserRole } from '../../shared/types';

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  password: string;

  @Prop({ required: true })
  name: string;

  @Prop({ default: null })
  phone: string | null;

  @Prop({ type: Types.ObjectId, ref: 'Department', required: true })
  departmentId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Office', default: null })
  officeId: Types.ObjectId | null;

  @Prop({ required: true })
  level: number;

  @Prop({ type: [String], enum: Object.values(UserRole), default: [] })
  roles: UserRole[];

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  supervisorId: Types.ObjectId | null;

  @Prop({ default: null })
  fcmToken: string | null;
}

export const UserSchema = SchemaFactory.createForClass(User);

