import { IsArray, IsNotEmpty, IsEnum } from 'class-validator';
import { UserRole } from '../../shared/types';

export class AssignRolesDto {
  @IsArray()
  @IsNotEmpty()
  @IsEnum(UserRole, { each: true })
  roles: UserRole[];
}
