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
  BadRequestException,
} from '@nestjs/common';
import { VehiclesService } from './vehicles.service';
import { CreateVehicleRequestDto } from './dto/create-vehicle-request.dto';
import { ApproveRequestDto } from './dto/approve-request.dto';
import { RejectRequestDto } from './dto/reject-request.dto';
import { AssignVehicleDto } from './dto/assign-vehicle.dto';
import { CorrectRequestDto } from './dto/correct-request.dto';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { CreateDriverDto } from './dto/create-driver.dto';
import { AddMaintenanceReminderDto } from './dto/add-maintenance-reminder.dto';
import { AddMaintenanceLogDto } from './dto/add-maintenance-log.dto';
import { ReportVehicleIssueDto } from './dto/report-vehicle-issue.dto';
import { StartTripDto } from './dto/start-trip.dto';
import { EndTripDto } from './dto/end-trip.dto';
import { ReachDestinationDto } from './dto/reach-destination.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '../shared/types';

@Controller('vehicles')
@UseGuards(JwtAuthGuard)
export class VehiclesController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  // Helper to safely extract user ID as string
  private getUserId(user: any): string {
    console.log('[DEBUG] getUserId - input user type:', typeof user);
    console.log('[DEBUG] getUserId - input user keys:', user ? Object.keys(user) : 'null');
    console.log('[DEBUG] getUserId - user._id:', user?._id, 'type:', typeof user?._id);
    console.log('[DEBUG] getUserId - user.id:', user?.id, 'type:', typeof user?.id);
    
    if (!user) {
      throw new BadRequestException('User not found');
    }
    
    // If user is already a string
    if (typeof user === 'string') {
      // Check if it looks like a JSON stringified object
      const trimmed = user.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        console.error('[ERROR] getUserId - received stringified object:', trimmed.substring(0, 200));
        throw new BadRequestException(
          `Invalid user ID: received stringified object instead of ID. Got: ${trimmed.substring(0, 100)}...`
        );
      }
      // Validate it's a valid ObjectId format
      if (!/^[0-9a-fA-F]{24}$/.test(trimmed)) {
        throw new BadRequestException(`Invalid user ID format: ${trimmed.substring(0, 50)}`);
      }
      return trimmed;
    }
    
    // Handle ObjectId, string, or object with _id/id property
    if (user._id !== undefined && user._id !== null) {
      const id = user._id;
      console.log('[DEBUG] getUserId - found _id:', id, 'type:', typeof id);
      if (typeof id === 'string') {
        if (!/^[0-9a-fA-F]{24}$/.test(id)) {
          throw new BadRequestException(`Invalid user ID format: ${id.substring(0, 50)}`);
        }
        return id;
      }
      // Handle ObjectId
      if (id && typeof id.toString === 'function') {
        const idStr = id.toString();
        if (!/^[0-9a-fA-F]{24}$/.test(idStr)) {
          throw new BadRequestException(`Invalid user ID format: ${idStr.substring(0, 50)}`);
        }
        return idStr;
      }
    }
    
    if (user.id !== undefined && user.id !== null) {
      const id = user.id;
      console.log('[DEBUG] getUserId - found id:', id, 'type:', typeof id);
      if (typeof id === 'string') {
        if (!/^[0-9a-fA-F]{24}$/.test(id)) {
          throw new BadRequestException(`Invalid user ID format: ${id.substring(0, 50)}`);
        }
        return id;
      }
      // Handle ObjectId
      if (id && typeof id.toString === 'function') {
        const idStr = id.toString();
        if (!/^[0-9a-fA-F]{24}$/.test(idStr)) {
          throw new BadRequestException(`Invalid user ID format: ${idStr.substring(0, 50)}`);
        }
        return idStr;
      }
    }
    
    // If we get here, the user object doesn't have _id or id
    console.error('[ERROR] getUserId - user object missing _id/id. Keys:', Object.keys(user));
    throw new BadRequestException(
      `Invalid user object: missing _id or id property. User object keys: ${Object.keys(user).join(', ')}`
    );
  }

  // Vehicle Management
  @Post('vehicles')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DGS, UserRole.TO)
  createVehicle(@Body() createVehicleDto: CreateVehicleDto) {
    return this.vehiclesService.createVehicle(createVehicleDto);
  }

  @Get('vehicles')
  findAllVehicles(
    @Query('available') available?: string,
    @Query('tripDate') tripDate?: string,
    @Query('returnDate') returnDate?: string,
  ) {
    if (available === 'true') {
      const tripDateObj = tripDate ? new Date(tripDate) : undefined;
      const returnDateObj = returnDate ? new Date(returnDate) : undefined;
      return this.vehiclesService.findAvailableVehicles(tripDateObj, returnDateObj);
    }
    return this.vehiclesService.findAllVehicles();
  }

  @Get('vehicles/:id')
  findOneVehicle(@Param('id') id: string) {
    return this.vehiclesService.findOneVehicle(id);
  }

  @Patch('vehicles/:id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TO)
  updateVehicle(@Param('id') id: string, @Body() updateDto: Partial<CreateVehicleDto>) {
    return this.vehiclesService.updateVehicle(id, updateDto);
  }

  @Delete('vehicles/:id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  deleteVehicle(@Param('id') id: string) {
    return this.vehiclesService.deleteVehicle(id);
  }

  // Driver Management
  @Post('drivers')
  @UseGuards(RolesGuard)
  @Roles(UserRole.DGS, UserRole.TO)
  createDriver(@Body() createDriverDto: CreateDriverDto) {
    return this.vehiclesService.createDriver(createDriverDto);
  }

  @Get('drivers')
  findAllDrivers(
    @Query('available') available?: string,
    @Query('tripDate') tripDate?: string,
    @Query('returnDate') returnDate?: string,
  ) {
    if (available === 'true') {
      const tripDateObj = tripDate ? new Date(tripDate) : undefined;
      const returnDateObj = returnDate ? new Date(returnDate) : undefined;
      return this.vehiclesService.findAvailableDrivers(tripDateObj, returnDateObj);
    }
    return this.vehiclesService.findAllDrivers();
  }

  @Get('drivers/:id')
  findOneDriver(@Param('id') id: string) {
    return this.vehiclesService.findOneDriver(id);
  }

  @Get('drivers/:id/assignments')
  findDriverAssignments(@Param('id') id: string) {
    return this.vehiclesService.findDriverAssignments(id);
  }

  // Vehicle Requests
  @Post('requests')
  createRequest(
    @CurrentUser() user: any,
    @Body() createVehicleRequestDto: CreateVehicleRequestDto,
  ) {
    return this.vehiclesService.createRequest(user._id || user.id, createVehicleRequestDto);
  }

  @Get('requests')
  findAllRequests(
    @CurrentUser() user: any,
    @Query('myRequests') myRequests?: string,
    @Query('pending') pending?: string,
    @Query('driverId') driverId?: string,
  ) {
    const userId = user._id?.toString() || user.id?.toString() || user._id || user.id;
    const userRoles = user.roles || [];
    
    console.log('[Vehicles Controller] findAllRequests: userId:', userId, 'roles:', userRoles, 'myRequests:', myRequests, 'pending:', pending);
    console.log('[Vehicles Controller] findAllRequests: user._id:', user._id, 'user.id:', user.id);
    
    // Handle driverId query parameter for driver dashboard
    if (driverId) {
      return this.vehiclesService.findDriverAssignments(driverId);
    }
    if (myRequests === 'true') {
      console.log('[Vehicles Controller] findAllRequests: Calling findAllRequests with userId:', userId);
      return this.vehiclesService.findAllRequests(userId);
    }
    if (pending === 'true') {
      return this.vehiclesService.findPendingApprovals(userId, userRoles);
    }
    // For "All Requests" view, use role-based filtering
    return this.vehiclesService.findAllRequestsByRole(userId, userRoles);
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
    const userId = this.getUserId(user);
    const userRoles = user.roles || [];
    
    const filters: any = {};
    if (status) {
      filters.status = status;
    }
    if (action) {
      filters.action = action as 'created' | 'approved' | 'rejected' | 'corrected' | 'assigned' | 'fulfilled';
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
    
    // For role-based users (TO, DGS, DDGS, ADGS, etc.), show all requests
    // For regular users, show only requests they participated in
    const isRoleBasedUser = userRoles.some((role: string) => 
      ['TO', 'DGS', 'DDGS', 'ADGS', 'DRIVER'].includes(role.toUpperCase())
    );
    
    if (isRoleBasedUser) {
      return this.vehiclesService.findRequestHistoryByRole(userId, userRoles, filters);
    }
    
    return this.vehiclesService.findRequestsByParticipant(userId, filters);
  }

  @Get('requests/:id')
  findOneRequest(@Param('id') id: string) {
    return this.vehiclesService.findOneRequest(id);
  }

  @Put('requests/:id/approve')
  approveRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() approveDto: ApproveRequestDto,
  ) {
    // Debug: Log what we're receiving
    console.log('[DEBUG] approveRequest - user type:', typeof user);
    console.log('[DEBUG] approveRequest - user keys:', user ? Object.keys(user) : 'null');
    console.log('[DEBUG] approveRequest - user._id:', user?._id, 'type:', typeof user?._id);
    console.log('[DEBUG] approveRequest - user.id:', user?.id, 'type:', typeof user?.id);
    
    const userId = this.getUserId(user);
    console.log('[DEBUG] approveRequest - extracted userId:', userId, 'type:', typeof userId);
    
    return this.vehiclesService.approveRequest(id, userId, user.roles, approveDto);
  }

  @Put('requests/:id/reject')
  rejectRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() rejectDto: RejectRequestDto,
  ) {
    return this.vehiclesService.rejectRequest(id, user._id || user.id, user.roles, rejectDto);
  }

  @Put('requests/:id/assign')
  assignVehicle(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() assignDto: AssignVehicleDto,
  ) {
    return this.vehiclesService.assignVehicle(id, user._id || user.id, user.roles, assignDto);
  }

  @Put('requests/:id/correct')
  correctRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() correctDto: CorrectRequestDto,
  ) {
    return this.vehiclesService.correctRequest(id, user._id || user.id, user.roles, correctDto);
  }

  @Put('requests/:id/priority')
  setPriority(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() body: { priority: boolean },
  ) {
    return this.vehiclesService.setPriority(id, user._id || user.id, user.roles, body.priority);
  }

  // Trip Tracking
  @Post('requests/:id/trip/start')
  startTrip(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() startTripDto: StartTripDto,
  ) {
    return this.vehiclesService.startTrip(id, user._id || user.id, user.roles, startTripDto);
  }

  @Post('requests/:id/trip/destination')
  reachDestination(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() reachDestinationDto: ReachDestinationDto,
  ) {
    return this.vehiclesService.reachDestination(
      id,
      user._id || user.id,
      user.roles,
      reachDestinationDto,
    );
  }

  @Post('requests/:id/trip/return')
  returnToOffice(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() endTripDto: EndTripDto,
  ) {
    return this.vehiclesService.returnToOffice(id, user._id || user.id, user.roles, endTripDto);
  }

  @Post('requests/:id/trip/location')
  updateTripLocation(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() updateLocationDto: UpdateLocationDto,
  ) {
    return this.vehiclesService.updateTripLocation(
      id,
      user._id || user.id,
      user.roles,
      updateLocationDto,
    );
  }

  @Get('requests/:id/trip')
  getTripDetails(@Param('id') id: string) {
    return this.vehiclesService.getTripDetails(id);
  }

  // Delete individual request
  @Delete('requests/:id')
  deleteRequest(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ) {
    return this.vehiclesService.deleteRequest(id, user._id || user.id, user.roles);
  }

  // Delete all requests (temporary - for testing/cleanup)
  @Delete('requests')
  @UseGuards(RolesGuard)
  @Roles(UserRole.DGS)
  deleteAllRequests(@CurrentUser() user: any) {
    return this.vehiclesService.deleteAllRequests();
  }

  // Maintenance Operations
  @Post('vehicles/:id/maintenance/reminder')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TO)
  addMaintenanceReminder(
    @Param('id') id: string,
    @Body() addReminderDto: AddMaintenanceReminderDto,
  ) {
    return this.vehiclesService.addMaintenanceReminder(id, addReminderDto);
  }

  @Post('vehicles/:id/maintenance/log')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TO)
  addMaintenanceLog(
    @Param('id') id: string,
    @Body() addLogDto: AddMaintenanceLogDto,
  ) {
    return this.vehiclesService.addMaintenanceLog(id, addLogDto);
  }

  @Post('vehicles/:id/issues')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TO)
  reportIssue(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() reportIssueDto: ReportVehicleIssueDto,
  ) {
    return this.vehiclesService.reportIssue(id, user._id || user.id, reportIssueDto);
  }

  @Get('vehicles/:id/maintenance')
  getMaintenanceHistory(@Param('id') id: string) {
    return this.vehiclesService.getMaintenanceHistory(id);
  }

  @Patch('vehicles/:id/issues/:issueIndex')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TO)
  updateIssueStatus(
    @Param('id') id: string,
    @Param('issueIndex') issueIndex: string,
    @Body() body: { status: 'REPORTED' | 'IN_PROGRESS' | 'RESOLVED'; resolutionNotes?: string },
  ) {
    return this.vehiclesService.updateIssueStatus(
      id,
      parseInt(issueIndex),
      body.status,
      body.resolutionNotes,
    );
  }

  @Patch('vehicles/:id/maintenance/reminder/:reminderIndex/complete')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.TO)
  completeMaintenanceReminder(
    @Param('id') id: string,
    @Param('reminderIndex') reminderIndex: string,
  ) {
    return this.vehiclesService.completeMaintenanceReminder(id, parseInt(reminderIndex));
  }
}

