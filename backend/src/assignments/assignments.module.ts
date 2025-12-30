import { Module } from '@nestjs/common';
import { AssignmentsController } from './assignments.controller';
import { VehiclesModule } from '../vehicles/vehicles.module';

@Module({
  imports: [VehiclesModule],
  controllers: [AssignmentsController],
})
export class AssignmentsModule {}

