import { IsNumber, IsNotEmpty, Min, Max, IsOptional, IsString } from 'class-validator';

export class EndTripDto {
  @IsNumber()
  @IsNotEmpty()
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber()
  @IsNotEmpty()
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsString()
  @IsOptional()
  notes?: string;
}

