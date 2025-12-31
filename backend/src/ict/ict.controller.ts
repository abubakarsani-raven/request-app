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
import { ICTService } from './ict.service';
import { CreateICTRequestDto } from './dto/create-ict-request.dto';
import { CreateICTItemDto } from './dto/create-ict-item.dto';
import { UpdateICTItemDto } from './dto/update-ict-item.dto';
import { UpdateQuantityDto } from './dto/update-quantity.dto';
import { FulfillRequestDto } from './dto/fulfill-request.dto';
import { ApproveRequestDto } from '../vehicles/dto/approve-request.dto';
import { RejectRequestDto } from '../vehicles/dto/reject-request.dto';
import { UpdateRequestItemsDto } from './dto/update-request-item.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '../shared/types';

@Controller('ict')
@UseGuards(JwtAuthGuard)
export class ICTController {
  constructor(private readonly ictService: ICTService) {}

  // ICT Item Management
  @Post('items')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.ICT_ADMIN, UserRole.DDICT, UserRole.DGS, UserRole.SO)
  createItem(@Body() createICTItemDto: CreateICTItemDto) {
    return this.ictService.createItem(createICTItemDto);
  }

  @Get('items')
  findAllItems(
    @Query('available') available?: string,
    @Query('category') category?: string,
  ) {
    if (available === 'true') {
      return this.ictService.findAvailableItems(category);
    }
    return this.ictService.findAllItems(category);
  }

  @Get('items/:id')
  findOneItem(@Param('id') id: string) {
    return this.ictService.findOneItem(id);
  }

  @Put('items/:id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.ICT_ADMIN, UserRole.DDICT, UserRole.DGS, UserRole.SO)
  updateItem(
    @Param('id') id: string,
    @Body() updateDto: UpdateICTItemDto,
  ) {
    return this.ictService.updateItem(id, updateDto);
  }

  @Put('items/:id/availability')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.ICT_ADMIN, UserRole.SO)
  updateItemAvailability(
    @Param('id') id: string,
    @Body() body: { isAvailable: boolean },
  ) {
    return this.ictService.updateItemAvailability(id, body.isAvailable);
  }

  @Patch('items/:id/quantity')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.ICT_ADMIN, UserRole.DDICT, UserRole.DGS, UserRole.SO)
  updateItemQuantity(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() updateQuantityDto: UpdateQuantityDto,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.ictService.updateItemQuantity(id, updateQuantityDto, userId);
  }

  @Get('items/:id/history')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.ICT_ADMIN, UserRole.DDICT, UserRole.DGS, UserRole.SO)
  getStockHistory(@Param('id') id: string) {
    return this.ictService.getStockHistory(id);
  }

  @Get('items/low-stock/all')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.ICT_ADMIN, UserRole.DDICT, UserRole.DGS, UserRole.SO)
  getLowStockItems() {
    return this.ictService.getLowStockItems();
  }

  @Post('items/bulk')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.ICT_ADMIN, UserRole.DDICT, UserRole.DGS, UserRole.SO)
  bulkCreateItems(@Body() body: { items: CreateICTItemDto[] }) {
    return this.ictService.bulkCreateItems(body.items);
  }

  @Delete('items/:id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.ICT_ADMIN, UserRole.DDICT, UserRole.DGS, UserRole.SO)
  deleteItem(@Param('id') id: string) {
    return this.ictService.deleteItem(id);
  }

  // ICT Requests
  @Post('requests')
  createRequest(
    @CurrentUser() user: any,
    @Body() createICTRequestDto: CreateICTRequestDto,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.ictService.createRequest(userId, createICTRequestDto);
  }

  @Get('requests')
  findAllRequests(
    @CurrentUser() user: any,
    @Query('myRequests') myRequests?: string,
    @Query('pending') pending?: string,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    const userRoles = user.roles || [];
    
    console.log('[ICT Controller] findAllRequests: userId:', userId, 'roles:', userRoles, 'myRequests:', myRequests, 'pending:', pending);
    console.log('[ICT Controller] findAllRequests: user._id:', user._id, 'user.id:', user.id);
    
    // If explicitly requesting my requests, filter by userId
    if (myRequests === 'true') {
      console.log('[ICT Controller] findAllRequests: Calling findAllRequests with userId:', userId);
      return this.ictService.findAllRequests(userId);
    }
    
    // If explicitly requesting pending approvals, return pending approvals
    if (pending === 'true') {
      return this.ictService.findPendingApprovals(userId, userRoles);
    }
    
    // For "All Requests" view, use role-based filtering
    return this.ictService.findAllRequestsByRole(userId, userRoles);
  }

  @Get('requests/unfulfilled')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SO)
  findUnfulfilledRequests(@CurrentUser() user: any) {
    return this.ictService.findUnfulfilledRequests();
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
    
    // For role-based users (DDICT, DGS, SO, etc.), show all completed/fulfilled requests
    // For regular users, show only requests they participated in
    const isRoleBasedUser = userRoles.some((role: string) => 
      ['DDICT', 'DGS', 'DDGS', 'ADGS', 'SO'].includes(role.toUpperCase())
    );
    
    if (isRoleBasedUser) {
      return this.ictService.findRequestHistoryByRole(userId, userRoles, filters);
    }
    
    return this.ictService.findRequestsByParticipant(userId, filters);
  }

  @Get('requests/:id')
  findOneRequest(@Param('id') id: string) {
    return this.ictService.findOneRequest(id);
  }

  @Put('requests/:id/approve')
  approveRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() approveDto: ApproveRequestDto,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.ictService.approveRequest(id, userId, user.roles, approveDto);
  }

  @Put('requests/:id/reject')
  rejectRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() rejectDto: RejectRequestDto,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.ictService.rejectRequest(id, userId, user.roles, rejectDto);
  }

  @Put('requests/:id/fulfill')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SO) // Only Store Officer (SO) can fulfill ICT requests
  fulfillRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() fulfillDto: FulfillRequestDto,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.ictService.fulfillRequest(id, userId, user.roles, fulfillDto);
  }

  @Post('requests/:id/notify-requester')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SO)
  notifyRequester(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() body: { message?: string },
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.ictService.notifyRequester(id, userId, body.message);
  }

  @Put('requests/:id/priority')
  @UseGuards(RolesGuard)
  @Roles(UserRole.DDICT)
  setPriority(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() body: { priority: boolean },
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.ictService.setPriority(id, userId, user.roles, body.priority);
  }

  @Put('requests/:id/items')
  @UseGuards(RolesGuard)
  @Roles(UserRole.DDICT)
  updateRequestItems(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() updateItemsDto: UpdateRequestItemsDto,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.ictService.updateRequestItems(id, userId, user.roles, updateItemsDto);
  }

  @Delete('requests/:id')
  deleteRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    return this.ictService.deleteRequest(id, userId, user.roles);
  }
}

