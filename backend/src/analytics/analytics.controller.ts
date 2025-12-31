import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AnalyticsService } from './analytics.service';
import { AdminRoleService } from '../common/services/admin-role.service';
import { RequestType, RequestStatus, UserRole } from '../shared/types';

@Controller('analytics')
@UseGuards(JwtAuthGuard)
export class AnalyticsController {
  constructor(
    private readonly analyticsService: AnalyticsService,
    private readonly adminRoleService: AdminRoleService,
  ) {}

  @Get('dashboard')
  async getDashboardMetrics(@CurrentUser() user: any) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      throw new Error('Unauthorized: Admin access required');
    }

    return this.analyticsService.getDashboardMetrics(userRoles);
  }

  @Get('requests')
  async getRequestStatistics(
    @CurrentUser() user: any,
    @Query('requestType') requestType?: string,
    @Query('status') status?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    // Filter to only show ICT requests for ICT admins
    const isICTAdmin = this.adminRoleService.isICTAdmin(userRoles);
    const isMainAdmin = this.adminRoleService.isMainAdmin(userRoles);
    
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      throw new Error('Unauthorized: Admin access required');
    }

    // If ICT admin and no requestType specified, default to ICT only
    if (isICTAdmin && !isMainAdmin && !requestType) {
      requestType = RequestType.ICT;
    }

    const filters: any = {};
    if (requestType) {
      filters.requestType = requestType as RequestType;
    }
    if (status) {
      filters.status = status as RequestStatus;
    }
    if (dateFrom) {
      filters.dateFrom = new Date(dateFrom);
    }
    if (dateTo) {
      filters.dateTo = new Date(dateTo);
    }

    return this.analyticsService.getRequestStatistics(filters);
  }

  @Get('vehicles')
  async getVehicleStatistics(@CurrentUser() user: any) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.canManageTransport(userRoles)) {
      throw new Error('Unauthorized: Transport Admin access required');
    }

    return this.analyticsService.getVehicleStatistics();
  }

  @Get('drivers')
  async getDriverStatistics(@CurrentUser() user: any) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.canManageTransport(userRoles)) {
      throw new Error('Unauthorized: Transport Admin access required');
    }

    return this.analyticsService.getDriverStatistics();
  }

  @Get('inventory')
  async getInventoryStatistics(
    @CurrentUser() user: any,
    @Query('requestType') requestType?: string,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    const isICTAdmin = this.adminRoleService.isICTAdmin(userRoles);
    const isStoreAdmin = this.adminRoleService.isStoreAdmin(userRoles);
    const isMainAdmin = this.adminRoleService.isMainAdmin(userRoles);

    if (!isMainAdmin && !isICTAdmin && !isStoreAdmin) {
      throw new Error('Unauthorized: Admin access required');
    }

    // Check if user has permission for the requested type
    if (requestType === RequestType.ICT && !isMainAdmin && !isICTAdmin) {
      throw new Error('Unauthorized: ICT Admin access required');
    }
    if (requestType === RequestType.STORE && !isMainAdmin && !isStoreAdmin) {
      throw new Error('Unauthorized: Store Admin access required');
    }

    return this.analyticsService.getInventoryStatistics(requestType as RequestType);
  }

  @Get('fulfillment')
  async getFulfillmentRates(
    @CurrentUser() user: any,
    @Query('requestType') requestType?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    const userRoles = (user.roles || []) as UserRole[];
    
    if (!this.adminRoleService.isAnyAdmin(userRoles)) {
      throw new Error('Unauthorized: Admin access required');
    }

    const filters: any = {};
    if (requestType) {
      filters.requestType = requestType as RequestType;
    }
    if (dateFrom) {
      filters.dateFrom = new Date(dateFrom);
    }
    if (dateTo) {
      filters.dateTo = new Date(dateTo);
    }

    return this.analyticsService.getFulfillmentRates(filters);
  }
}
