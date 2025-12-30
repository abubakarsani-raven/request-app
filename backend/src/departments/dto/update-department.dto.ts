import { CreateDepartmentDto } from './create-department.dto';
import { IsString, IsOptional, MinLength } from 'class-validator';

export class UpdateDepartmentDto {
  @IsString()
  @IsOptional()
  @MinLength(2)
  name?: string;

  @IsString()
  @IsOptional()
  @MinLength(2)
  code?: string;
}

