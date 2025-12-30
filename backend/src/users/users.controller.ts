import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Put,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '../shared/types';
import { AdminRoleService } from '../common/services/admin-role.service';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { AssignRolesDto } from './dto/assign-roles.dto';
import { BulkUserOperationDto } from './dto/bulk-user-operation.dto';
import { ForbiddenException } from '@nestjs/common';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly adminRoleService: AdminRoleService,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DGS)
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DGS, UserRole.DDGS)
  findAll() {
    return this.usersService.findAll();
  }

  @Get('profile')
  getProfile(@CurrentUser() user: any) {
    return this.usersService.findOne(user._id || user.id);
  }

  @Get('dashboard')
  getDashboard(@CurrentUser() user: any) {
    return this.usersService.getDashboard(user._id || user.id);
  }

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DGS, UserRole.DDGS)
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Patch('profile')
  updateProfile(@CurrentUser() user: any, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(user._id || user.id, updateUserDto);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DGS)
  update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DGS)
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }

  @Post(':id/reset-password')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  async resetPassword(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() resetPasswordDto: ResetPasswordDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    // Only Main Admin can reset passwords
    if (!this.adminRoleService.isMainAdmin(userRoles)) {
      throw new ForbiddenException('Unauthorized: Main Admin access required');
    }

    return this.usersService.resetPassword(id, resetPasswordDto.newPassword);
  }

  @Put(':id/roles')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  async assignRoles(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() assignRolesDto: AssignRolesDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    // Only Main Admin can assign roles (including admin roles)
    if (!this.adminRoleService.isMainAdmin(userRoles)) {
      throw new ForbiddenException('Unauthorized: Main Admin access required');
    }

    return this.usersService.assignRoles(id, assignRolesDto.roles);
  }

  @Post('bulk')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  async bulkOperation(
    @CurrentUser() user: any,
    @Body() bulkOperationDto: BulkUserOperationDto,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    // Only Main Admin can perform bulk operations
    if (!this.adminRoleService.isMainAdmin(userRoles)) {
      throw new ForbiddenException('Unauthorized: Main Admin access required');
    }

    return this.usersService.bulkOperation(bulkOperationDto);
  }
}

