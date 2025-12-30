import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AnalyticsService } from './analytics.service';
import { AnalyticsController } from './analytics.controller';
import { VehicleRequest, VehicleRequestSchema } from '../vehicles/schemas/vehicle-request.schema';
import { ICTRequest, ICTRequestSchema } from '../ict/schemas/ict-request.schema';
import { StoreRequest, StoreRequestSchema } from '../store/schemas/store-request.schema';
import { Vehicle, VehicleSchema } from '../vehicles/schemas/vehicle.schema';
import { Driver, DriverSchema } from '../vehicles/schemas/driver.schema';
import { ICTItem, ICTItemSchema } from '../ict/schemas/ict-item.schema';
import { StoreItem, StoreItemSchema } from '../store/schemas/store-item.schema';
import { AdminRoleService } from '../common/services/admin-role.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: VehicleRequest.name, schema: VehicleRequestSchema },
      { name: ICTRequest.name, schema: ICTRequestSchema },
      { name: StoreRequest.name, schema: StoreRequestSchema },
      { name: Vehicle.name, schema: VehicleSchema },
      { name: Driver.name, schema: DriverSchema },
      { name: ICTItem.name, schema: ICTItemSchema },
      { name: StoreItem.name, schema: StoreItemSchema },
    ]),
  ],
  controllers: [AnalyticsController],
  providers: [AnalyticsService, AdminRoleService],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}
