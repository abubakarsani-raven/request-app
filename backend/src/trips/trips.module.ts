import { Module } from '@nestjs/common';
import { TripsController } from './trips.controller';
import { VehiclesModule } from '../vehicles/vehicles.module';

@Module({
  imports: [VehiclesModule],
  controllers: [TripsController],
})
export class TripsModule {}

