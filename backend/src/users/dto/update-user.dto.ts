import { CreateUserDto } from './create-user.dto';
import { IsOptional, IsString, IsEmail, IsMongoId, IsNumber, IsArray } from 'class-validator';

export class UpdateUserDto {
  @IsEmail()
  @IsOptional()
  email?: string;

  @IsString()
  @IsOptional()
  password?: string;

  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  phone?: string | null;

  @IsMongoId()
  @IsOptional()
  departmentId?: string;

  @IsNumber()
  @IsOptional()
  level?: number;

  @IsArray()
  @IsOptional()
  roles?: string[];

  @IsMongoId()
  @IsOptional()
  supervisorId?: string | null;

  @IsString()
  @IsOptional()
  fcmToken?: string;

  @IsMongoId()
  @IsOptional()
  officeId?: string | null;
}

