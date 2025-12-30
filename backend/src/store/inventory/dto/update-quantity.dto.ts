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
}
