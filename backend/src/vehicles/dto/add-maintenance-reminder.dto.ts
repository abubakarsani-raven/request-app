import { IsString, IsNotEmpty, IsDateString, IsNumber, IsOptional, Min } from 'class-validator';

export class AddMaintenanceReminderDto {
  @IsString()
  @IsNotEmpty()
  type: string;

  @IsDateString()
  @IsNotEmpty()
  dueDate: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  mileage?: number;

  @IsString()
  @IsOptional()
  description?: string;
}







