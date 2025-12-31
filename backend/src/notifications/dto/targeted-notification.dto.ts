import { IsString, IsNotEmpty, IsArray, IsOptional } from 'class-validator';

export class TargetedNotificationDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  message: string;

  @IsString()
  @IsOptional()
  type?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  userIds?: string[];

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  roles?: string[];

  @IsString()
  @IsOptional()
  requestType?: string;

  @IsString()
  @IsOptional()
  requestId?: string;
}
