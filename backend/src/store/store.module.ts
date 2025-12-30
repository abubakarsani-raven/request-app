import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { StoreService } from './store.service';
import { StoreController } from './store.controller';
import { StoreItem, StoreItemSchema } from './schemas/store-item.schema';
import { StoreRequest, StoreRequestSchema } from './schemas/store-request.schema';
import { Notification, NotificationSchema } from '../notifications/schemas/notification.schema';
import { WorkflowModule } from '../workflow/workflow.module';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { UserCapabilityService } from '../common/services/user-capability.service';
import { AdminRoleService } from '../common/services/admin-role.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StoreItem.name, schema: StoreItemSchema },
      { name: StoreRequest.name, schema: StoreRequestSchema },
      { name: Notification.name, schema: NotificationSchema },
    ]),
    WorkflowModule,
    UsersModule,
    NotificationsModule,
  ],
  controllers: [StoreController],
  providers: [StoreService, UserCapabilityService, AdminRoleService],
  exports: [StoreService],
})
export class StoreModule {}

