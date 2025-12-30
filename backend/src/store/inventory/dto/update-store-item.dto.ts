import { IsString, IsNumber, Min, IsBoolean, IsOptional } from 'class-validator';

export class UpdateStoreItemDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  category?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  quantity?: number;

  @IsBoolean()
  @IsOptional()
  isAvailable?: boolean;

  @IsNumber()
  @Min(0)
  @IsOptional()
  lowStockThreshold?: number;
}
