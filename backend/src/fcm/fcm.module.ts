import { Module } from '@nestjs/common';
import { FCMService } from './fcm.service';

@Module({
  providers: [FCMService],
  exports: [FCMService],
})
export class FCMModule {}
