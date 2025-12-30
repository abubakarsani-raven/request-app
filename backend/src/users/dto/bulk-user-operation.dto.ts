import { IsArray, IsNotEmpty, IsEnum, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateUserDto } from './create-user.dto';

export enum BulkOperationType {
  CREATE = 'CREATE',
  UPDATE = 'UPDATE',
  DELETE = 'DELETE',
  ASSIGN_ROLES = 'ASSIGN_ROLES',
}

export class BulkUserOperationDto {
  @IsEnum(BulkOperationType)
  @IsNotEmpty()
  operation: BulkOperationType;

  @IsArray()
  @IsNotEmpty()
  userIds?: string[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateUserDto)
  users?: CreateUserDto[];

  @IsArray()
  @IsString({ each: true })
  roles?: string[];
}
