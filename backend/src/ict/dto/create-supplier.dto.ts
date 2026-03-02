import { IsString, IsOptional, IsEmail } from 'class-validator';

export class CreateSupplierDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsEmail()
  contactEmail?: string;

  @IsOptional()
  @IsString()
  contactPhone?: string;

  @IsOptional()
  @IsString()
  address?: string;
}
