import { IsString, IsNotEmpty, IsBoolean, IsOptional, IsMongoId, IsNumber } from 'class-validator';

export class CreateVehicleDto {
  @IsString()
  @IsNotEmpty()
  plateNumber: string;

  @IsString()
  @IsNotEmpty()
  make: string;

  @IsString()
  @IsNotEmpty()
  model: string;

  @IsString()
  @IsNotEmpty()
  type: string;

  @IsNumber()
  @IsNotEmpty()
  year: number;

  @IsNumber()
  @IsNotEmpty()
  capacity: number;

  @IsString()
  @IsOptional()
  status?: string;

  @IsBoolean()
  @IsOptional()
  isPermanent?: boolean;

  @IsMongoId()
  @IsOptional()
  assignedToUserId?: string;

  @IsMongoId()
  @IsOptional()
  officeId?: string | null;

  @IsBoolean()
  @IsOptional()
  isAvailable?: boolean;
}

