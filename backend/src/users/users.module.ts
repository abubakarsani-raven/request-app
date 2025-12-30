import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User, UserSchema } from './schemas/user.schema';
import { DepartmentsModule } from '../departments/departments.module';
import { OfficesModule } from '../offices/offices.module';
import { AdminRoleService } from '../common/services/admin-role.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
    DepartmentsModule,
    OfficesModule,
  ],
  controllers: [UsersController],
  providers: [UsersService, AdminRoleService],
  exports: [UsersService],
})
export class UsersModule {}

