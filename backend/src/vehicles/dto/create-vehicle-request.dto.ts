import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsOptional,
  IsNumber,
  Min,
  Max,
  ValidateIf,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateVehicleRequestDto {
  @IsDateString()
  @IsNotEmpty()
  tripDate: string;

  @IsString()
  @IsNotEmpty()
  tripTime: string;

  @IsDateString()
  @IsNotEmpty()
  returnDate: string;

  @IsString()
  @IsNotEmpty()
  returnTime: string;

  @IsString()
  @IsNotEmpty()
  destination: string; // Destination address/name

  @IsString()
  @IsNotEmpty()
  purpose: string;

  // Destination coordinates from map picker
  @IsNumber()
  @Min(-90)
  @Max(90)
  @IsOptional()
  destinationLatitude?: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  @IsOptional()
  destinationLongitude?: number;

  // Office/start location coordinates (optional, can be set by system)
  @IsNumber()
  @Min(-90)
  @Max(90)
  @IsOptional()
  officeLatitude?: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  @IsOptional()
  officeLongitude?: number;

  // Start point coordinates (optional, defaults to office if not provided)
  @IsNumber()
  @Min(-90)
  @Max(90)
  @IsOptional()
  startLatitude?: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  @IsOptional()
  startLongitude?: number;

  // Drop-off point coordinates (optional, if not set, return to office)
  @IsNumber()
  @Min(-90)
  @Max(90)
  @IsOptional()
  dropOffLatitude?: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  @IsOptional()
  dropOffLongitude?: number;

  // Multi-stop waypoints (optional)
  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => WaypointDto)
  waypoints?: WaypointDto[];
}

export class WaypointDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsNumber()
  @Min(1)
  order: number; // Order of stop (1, 2, 3, etc.)
}

