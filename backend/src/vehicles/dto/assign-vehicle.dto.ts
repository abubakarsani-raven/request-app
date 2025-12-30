import { IsMongoId, IsNotEmpty, IsOptional } from 'class-validator';

export class AssignVehicleDto {
  @IsMongoId()
  @IsNotEmpty()
  vehicleId: string;

  @IsMongoId()
  @IsOptional()
  driverId?: string;
}

