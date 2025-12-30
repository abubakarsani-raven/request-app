import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class BroadcastNotificationDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  message: string;

  @IsString()
  @IsOptional()
  requestType?: string;

  @IsString()
  @IsOptional()
  requestId?: string;
}
