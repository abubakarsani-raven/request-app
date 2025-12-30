import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BullModule } from '@nestjs/bull';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { Notification, NotificationSchema } from './schemas/notification.schema';
import { NotificationProcessor } from './processors/notification.processor';
import { PushNotificationProcessor } from './processors/push-notification.processor';
import { EmailModule } from '../email/email.module';
import { UsersModule } from '../users/users.module';
import { WebSocketModule } from '../websocket/websocket.module';
import { FCMModule } from '../fcm/fcm.module';
import { AdminRoleService } from '../common/services/admin-role.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Notification.name, schema: NotificationSchema }]),
    BullModule.registerQueue(
      {
        name: 'notifications',
      },
      {
        name: 'push-notifications',
      },
    ),
    EmailModule,
    UsersModule,
    FCMModule,
    forwardRef(() => WebSocketModule),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationProcessor, PushNotificationProcessor, AdminRoleService],
  exports: [NotificationsService],
})
export class NotificationsModule {}

