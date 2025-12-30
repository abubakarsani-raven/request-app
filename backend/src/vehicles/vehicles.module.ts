import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { VehiclesService } from './vehicles.service';
import { VehiclesController } from './vehicles.controller';
import { Vehicle, VehicleSchema } from './schemas/vehicle.schema';
import { Driver, DriverSchema } from './schemas/driver.schema';
import { VehicleRequest, VehicleRequestSchema } from './schemas/vehicle-request.schema';
import { Notification, NotificationSchema } from '../notifications/schemas/notification.schema';
import { ICTRequest, ICTRequestSchema } from '../ict/schemas/ict-request.schema';
import { StoreRequest, StoreRequestSchema } from '../store/schemas/store-request.schema';
import { WorkflowModule } from '../workflow/workflow.module';
import { UsersModule } from '../users/users.module';
import { WebSocketModule } from '../websocket/websocket.module';
import { OfficesModule } from '../offices/offices.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ICTModule } from '../ict/ict.module';
import { StoreModule } from '../store/store.module';
import { SettingsModule } from '../settings/settings.module';
import { TripTrackingService } from './services/trip-tracking.service';
import { UserCapabilityService } from '../common/services/user-capability.service';
import { AdminRoleService } from '../common/services/admin-role.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Vehicle.name, schema: VehicleSchema },
      { name: Driver.name, schema: DriverSchema },
      { name: VehicleRequest.name, schema: VehicleRequestSchema },
      { name: Notification.name, schema: NotificationSchema },
      { name: ICTRequest.name, schema: ICTRequestSchema },
      { name: StoreRequest.name, schema: StoreRequestSchema },
    ]),
    WorkflowModule,
    UsersModule,
    OfficesModule,
    WebSocketModule,
    NotificationsModule,
    ICTModule,
    StoreModule,
    SettingsModule,
  ],
  controllers: [VehiclesController],
  providers: [VehiclesService, TripTrackingService, UserCapabilityService, AdminRoleService],
  exports: [VehiclesService],
})
export class VehiclesModule {}

