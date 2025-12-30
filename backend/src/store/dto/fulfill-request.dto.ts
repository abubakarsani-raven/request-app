import { IsArray, IsNotEmpty, ValidateNested, IsMongoId, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class FulfillmentItemDto {
  @IsMongoId()
  @IsNotEmpty()
  itemId: string;

  @IsNumber()
  @Min(0)
  quantityFulfilled: number;
}

export class FulfillRequestDto {
  @IsArray()
  @IsNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => FulfillmentItemDto)
  items: FulfillmentItemDto[];
}

