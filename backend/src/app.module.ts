import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { BullModule } from '@nestjs/bull';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { DepartmentsModule } from './departments/departments.module';
import { OfficesModule } from './offices/offices.module';
import { WorkflowModule } from './workflow/workflow.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { ICTModule } from './ict/ict.module';
import { StoreModule } from './store/store.module';
import { EmailModule } from './email/email.module';
import { NotificationsModule } from './notifications/notifications.module';
import { FCMModule } from './fcm/fcm.module';
import { QRModule } from './qr/qr.module';
import { WebSocketModule } from './websocket/websocket.module';
import { RequestsModule } from './requests/requests.module';
import { AssignmentsModule } from './assignments/assignments.module';
import { TripsModule } from './trips/trips.module';
import { SettingsModule } from './settings/settings.module';
import { ReportsModule } from './reports/reports.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { StoreInventoryModule } from './store/inventory/store-inventory.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    MongooseModule.forRoot(process.env.MONGODB_URI || 'mongodb://localhost:27017/request-app'),
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => {
        const redisHost = configService.get<string>('REDIS_HOST') || 'localhost';
        const redisPort = configService.get<number>('REDIS_PORT') || 6379;
        const redisPassword = configService.get<string>('REDIS_PASSWORD') || undefined;

        return {
          redis: {
            host: redisHost,
            port: redisPort,
            password: redisPassword,
          },
        };
      },
      inject: [ConfigService],
    }),
    BullModule.registerQueue(
      {
        name: 'notifications',
      },
      {
        name: 'push-notifications',
      },
    ),
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => {
        const ttl = configService.get<number>('THROTTLE_TTL') || 60; // Time window in seconds
        const limit = configService.get<number>('THROTTLE_LIMIT') || 100; // Max requests per window
        
        return {
          throttlers: [
            {
              ttl,
              limit,
            },
          ],
          // Storage will use in-memory by default
          // For Redis storage, install @nestjs/throttler-storage-redis and configure it separately
        };
      },
      inject: [ConfigService],
    }),
    AuthModule,
    UsersModule,
    DepartmentsModule,
    OfficesModule,
    WorkflowModule,
    VehiclesModule,
    ICTModule,
    StoreModule,
    EmailModule,
    NotificationsModule,
    FCMModule,
    QRModule,
    WebSocketModule,
    RequestsModule,
    AssignmentsModule,
    TripsModule,
    SettingsModule,
    ReportsModule,
    AnalyticsModule,
    StoreInventoryModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}

