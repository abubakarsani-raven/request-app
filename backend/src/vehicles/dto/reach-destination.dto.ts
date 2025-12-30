import { IsNumber, IsNotEmpty, Min, Max, IsOptional, IsString } from 'class-validator';

export class ReachDestinationDto {
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

  @IsNumber()
  @IsOptional()
  @Min(0)
  stopIndex?: number; // For multi-stop trips: 0 = office, 1 = stop 1, 2 = stop 2, etc. If not provided, assumes final destination
}

