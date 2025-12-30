import { IsArray, ValidateNested, IsNotEmpty } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateStoreItemDto } from './create-store-item.dto';

export class BulkImportDto {
  @IsArray()
  @IsNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => CreateStoreItemDto)
  items: CreateStoreItemDto[];
}
