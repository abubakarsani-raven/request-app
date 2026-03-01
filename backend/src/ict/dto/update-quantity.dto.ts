import { IsNumber, IsNotEmpty, IsString, IsOptional, IsEnum } from 'class-validator';

export enum QuantityOperation {
  ADD = 'ADD',
  REMOVE = 'REMOVE',
  ADJUST = 'ADJUST',
}

export class UpdateQuantityDto {
  @IsNumber()
  @IsNotEmpty()
  quantity: number;

  @IsEnum(QuantityOperation)
  @IsNotEmpty()
  operation: QuantityOperation;

  @IsString()
  @IsOptional()
  reason?: string;

  /** For ADD: supplier name (multiple suppliers can supply the same item) */
  @IsString()
  @IsOptional()
  supplier?: string;

  @IsString()
  @IsOptional()
  supplierContact?: string;

  @IsNumber()
  @IsOptional()
  cost?: number;

  @IsString()
  @IsOptional()
  reference?: string;
}

