import { IsMongoId, IsNumber, Min, IsNotEmpty } from 'class-validator';

export class UpdateRequestItemDto {
  @IsMongoId()
  @IsNotEmpty()
  itemId: string;

  @IsNumber()
  @Min(1)
  quantity: number;
}

export class UpdateRequestItemsDto {
  @IsNotEmpty()
  items: UpdateRequestItemDto[];
}

