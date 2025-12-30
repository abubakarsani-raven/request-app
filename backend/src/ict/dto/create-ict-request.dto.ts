import { IsArray, IsNotEmpty, ValidateNested, IsMongoId, IsNumber, Min, IsString, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

export class RequestItemDto {
  @IsMongoId()
  @IsNotEmpty()
  itemId: string;

  @IsNumber()
  @Min(1)
  quantity: number;
}

export class CreateICTRequestDto {
  @IsArray()
  @IsNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => RequestItemDto)
  items: RequestItemDto[];

  @IsString()
  @IsOptional()
  notes?: string;
}

