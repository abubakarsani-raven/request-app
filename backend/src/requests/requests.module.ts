import { Module } from '@nestjs/common';
import { RequestsController } from './requests.controller';
import { VehiclesModule } from '../vehicles/vehicles.module';
import { ICTModule } from '../ict/ict.module';
import { StoreModule } from '../store/store.module';

@Module({
  imports: [VehiclesModule, ICTModule, StoreModule],
  controllers: [RequestsController],
})
export class RequestsModule {}

