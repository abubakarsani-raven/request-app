import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Put,
  Delete,
  UseGuards,
  Query,
} from '@nestjs/common';
import { StoreService } from './store.service';
import { CreateStoreRequestDto } from './dto/create-store-request.dto';
import { CreateStoreItemDto } from './dto/create-store-item.dto';
import { FulfillRequestDto } from './dto/fulfill-request.dto';
import { RouteRequestDto } from './dto/route-request.dto';
import { ApproveRequestDto } from '../vehicles/dto/approve-request.dto';
import { RejectRequestDto } from '../vehicles/dto/reject-request.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '../shared/types';

@Controller('store')
@UseGuards(JwtAuthGuard)
export class StoreController {
  constructor(private readonly storeService: StoreService) {}

  // Store Item Management
  @Post('items')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.DGS, UserRole.SO)
  createItem(@Body() createStoreItemDto: CreateStoreItemDto) {
    return this.storeService.createItem(createStoreItemDto);
  }

  @Get('items')
  findAllItems(@Query('available') available?: string) {
    if (available === 'true') {
      return this.storeService.findAvailableItems();
    }
    return this.storeService.findAllItems();
  }

  @Get('items/:id')
  findOneItem(@Param('id') id: string) {
    return this.storeService.findOneItem(id);
  }

  @Put('items/:id/availability')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.STORE_ADMIN, UserRole.SO)
  updateItemAvailability(
    @Param('id') id: string,
    @Body() body: { isAvailable: boolean },
  ) {
    return this.storeService.updateItemAvailability(id, body.isAvailable);
  }

  // Store Requests
  @Post('requests')
  createRequest(
    @CurrentUser() user: any,
    @Body() createStoreRequestDto: CreateStoreRequestDto,
  ) {
    return this.storeService.createRequest(user._id || user.id, createStoreRequestDto);
  }

  @Get('requests')
  findAllRequests(
    @CurrentUser() user: any,
    @Query('myRequests') myRequests?: string,
    @Query('pending') pending?: string,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    const userRoles = user.roles || [];
    
    console.log('[Store Controller] findAllRequests: userId:', userId, 'roles:', userRoles, 'myRequests:', myRequests, 'pending:', pending);
    console.log('[Store Controller] findAllRequests: user._id:', user._id, 'user.id:', user.id);
    
    if (myRequests === 'true') {
      console.log('[Store Controller] findAllRequests: Calling findAllRequests with userId:', userId);
      return this.storeService.findAllRequests(userId);
    }
    if (pending === 'true') {
      return this.storeService.findPendingApprovals(userId, userRoles);
    }
    // For "All Requests" view, use role-based filtering
    return this.storeService.findAllRequestsByRole(userId, userRoles);
  }

  @Get('requests/history')
  findRequestHistory(
    @CurrentUser() user: any,
    @Query('status') status?: string,
    @Query('action') action?: string,
    @Query('workflowStage') workflowStage?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    const userRoles = user.roles || [];
    
    const filters: any = {};
    if (status) {
      filters.status = status;
    }
    if (action) {
      filters.action = action as 'created' | 'approved' | 'rejected' | 'corrected' | 'fulfilled';
    }
    if (workflowStage) {
      filters.workflowStage = workflowStage;
    }
    if (dateFrom) {
      filters.dateFrom = new Date(dateFrom);
    }
    if (dateTo) {
      filters.dateTo = new Date(dateTo);
    }
    
    // For role-based users (SO, DGS, DDGS, ADGS, etc.), show all requests
    // For regular users, show only requests they participated in
    const isRoleBasedUser = userRoles.some((role: string) => 
      ['SO', 'DGS', 'DDGS', 'ADGS'].includes(role.toUpperCase())
    );
    
    if (isRoleBasedUser) {
      return this.storeService.findRequestHistoryByRole(userId, userRoles, filters);
    }
    
    return this.storeService.findRequestsByParticipant(userId, filters);
  }

  @Get('requests/:id')
  findOneRequest(@Param('id') id: string) {
    return this.storeService.findOneRequest(id);
  }

  @Put('requests/:id/approve')
  approveRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() approveDto: ApproveRequestDto,
  ) {
    return this.storeService.approveRequest(id, user._id || user.id, user.roles, approveDto);
  }

  @Put('requests/:id/route')
  @UseGuards(RolesGuard)
  @Roles(UserRole.DGS)
  routeRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() routeDto: RouteRequestDto,
  ) {
    return this.storeService.routeRequest(id, user._id || user.id, user.roles, routeDto);
  }

  @Put('requests/:id/reject')
  rejectRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() rejectDto: RejectRequestDto,
  ) {
    return this.storeService.rejectRequest(id, user._id || user.id, user.roles, rejectDto);
  }

  @Put('requests/:id/fulfill')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SO)
  fulfillRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() fulfillDto: FulfillRequestDto,
  ) {
    return this.storeService.fulfillRequest(id, user._id || user.id, user.roles, fulfillDto);
  }

  @Put('requests/:id/priority')
  @UseGuards(RolesGuard)
  @Roles(UserRole.DGS)
  setPriority(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() body: { priority: boolean },
  ) {
    return this.storeService.setPriority(id, user._id || user.id, user.roles, body.priority);
  }

  @Delete('requests/:id')
  deleteRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ) {
    return this.storeService.deleteRequest(id, user._id || user.id, user.roles);
  }
}

