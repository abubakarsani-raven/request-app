import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ICTService } from './ict.service';
import { ICTController } from './ict.controller';
import { ICTItem, ICTItemSchema } from './schemas/ict-item.schema';
import { ICTRequest, ICTRequestSchema } from './schemas/ict-request.schema';
import { StockHistory, StockHistorySchema } from './schemas/stock-history.schema';
import { Notification, NotificationSchema } from '../notifications/schemas/notification.schema';
import { WorkflowModule } from '../workflow/workflow.module';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { UserCapabilityService } from '../common/services/user-capability.service';
import { AdminRoleService } from '../common/services/admin-role.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ICTItem.name, schema: ICTItemSchema },
      { name: ICTRequest.name, schema: ICTRequestSchema },
      { name: StockHistory.name, schema: StockHistorySchema },
      { name: Notification.name, schema: NotificationSchema },
    ]),
    WorkflowModule,
    UsersModule,
    NotificationsModule,
  ],
  controllers: [ICTController],
  providers: [ICTService, UserCapabilityService, AdminRoleService],
  exports: [ICTService],
})
export class ICTModule {}

