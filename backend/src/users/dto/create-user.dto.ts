import { IsString, IsEmail, IsNotEmpty, MinLength, IsNumber, IsArray, IsOptional, IsMongoId } from 'class-validator';
import { UserRole } from '../../shared/types';

export class CreateUserDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsOptional()
  phone?: string | null;

  @IsMongoId()
  @IsNotEmpty()
  departmentId: string;

  @IsNumber()
  @IsNotEmpty()
  level: number;

  @IsArray()
  @IsOptional()
  roles?: UserRole[];

  @IsMongoId()
  @IsOptional()
  supervisorId?: string | null;

  @IsMongoId()
  @IsOptional()
  officeId?: string | null;
}

