import { IsString, IsNotEmpty, IsOptional, IsDateString } from 'class-validator';

export class CorrectRequestDto {
  @IsString()
  @IsNotEmpty()
  comment: string;

  @IsDateString()
  @IsOptional()
  tripDate?: string;

  @IsString()
  @IsOptional()
  tripTime?: string;

  @IsString()
  @IsOptional()
  destination?: string;

  @IsString()
  @IsOptional()
  purpose?: string;
}

