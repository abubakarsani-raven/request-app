import { IsString, IsNotEmpty, IsBoolean, IsOptional } from 'class-validator';

export class CreateDriverDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  phone: string;

  @IsString()
  @IsNotEmpty()
  licenseNumber: string;

  @IsBoolean()
  @IsOptional()
  isAvailable?: boolean;
}

