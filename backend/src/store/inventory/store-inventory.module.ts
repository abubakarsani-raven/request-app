import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { StoreInventoryService } from './store-inventory.service';
import { StoreInventoryController } from './store-inventory.controller';
import { StoreItem, StoreItemSchema } from '../schemas/store-item.schema';
import { StoreRequest, StoreRequestSchema } from '../schemas/store-request.schema';
import { StoreStockHistory, StoreStockHistorySchema } from './schemas/store-stock-history.schema';
import { NotificationsModule } from '../../notifications/notifications.module';
import { UsersModule } from '../../users/users.module';
import { AdminRoleService } from '../../common/services/admin-role.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StoreItem.name, schema: StoreItemSchema },
      { name: StoreRequest.name, schema: StoreRequestSchema },
      { name: StoreStockHistory.name, schema: StoreStockHistorySchema },
    ]),
    NotificationsModule,
    UsersModule,
  ],
  controllers: [StoreInventoryController],
  providers: [StoreInventoryService, AdminRoleService],
  exports: [StoreInventoryService],
})
export class StoreInventoryModule {}
