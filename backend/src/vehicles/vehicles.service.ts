import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Vehicle, VehicleDocument } from './schemas/vehicle.schema';
import { Driver, DriverDocument } from './schemas/driver.schema';
import { VehicleRequest, VehicleRequestDocument } from './schemas/vehicle-request.schema';
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
import { MaintenanceReminder, MaintenanceLog, VehicleIssue } from './schemas/maintenance.schema';
import { WorkflowService } from '../workflow/workflow.service';
import { UsersService } from '../users/users.service';
import { OfficesService } from '../offices/offices.service';
import { TripTrackingService } from './services/trip-tracking.service';
import { StartTripDto } from './dto/start-trip.dto';
import { EndTripDto } from './dto/end-trip.dto';
import { ReachDestinationDto } from './dto/reach-destination.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { AppWebSocketGateway } from '../websocket/websocket.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { Notification, NotificationDocument } from '../notifications/schemas/notification.schema';
import { ICTRequest, ICTRequestDocument } from '../ict/schemas/ict-request.schema';
import { StoreRequest, StoreRequestDocument } from '../store/schemas/store-request.schema';
import { RequestStatus, WorkflowStage, RequestType, UserRole, NotificationType } from '../shared/types';
import { UserDocument } from '../users/schemas/user.schema';
import { UserCapabilityService } from '../common/services/user-capability.service';
import { AdminRoleService } from '../common/services/admin-role.service';

@Injectable()
export class VehiclesService {
  constructor(
    @InjectModel(Vehicle.name) private vehicleModel: Model<VehicleDocument>,
    @InjectModel(Driver.name) private driverModel: Model<DriverDocument>,
    @InjectModel(VehicleRequest.name)
    private vehicleRequestModel: Model<VehicleRequestDocument>,
    @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
    @InjectModel(ICTRequest.name) private ictRequestModel: Model<ICTRequestDocument>,
    @InjectModel(StoreRequest.name) private storeRequestModel: Model<StoreRequestDocument>,
    private workflowService: WorkflowService,
    private usersService: UsersService,
    private officesService: OfficesService,
    private tripTrackingService: TripTrackingService,
    private webSocketGateway: AppWebSocketGateway,
    private notificationsService: NotificationsService,
    private capabilityService: UserCapabilityService,
    private adminRoleService: AdminRoleService,
  ) {}

  // Vehicle CRUD
  async createVehicle(createVehicleDto: CreateVehicleDto): Promise<Vehicle> {
    const vehicle = new this.vehicleModel(createVehicleDto);
    return vehicle.save();
  }

  async findAllVehicles(): Promise<Vehicle[]> {
    return this.vehicleModel.find().populate('assignedToUserId').populate('officeId').exec();
  }

  /**
   * Check if two date ranges overlap
   * Returns true if the ranges overlap (conflict), false otherwise
   */
  private datesOverlap(
    start1: Date,
    end1: Date,
    start2: Date,
    end2: Date,
  ): boolean {
    // Two date ranges overlap if: start1 <= end2 && start2 <= end1
    return start1 <= end2 && start2 <= end1;
  }

  /**
   * Check if a vehicle has conflicting assignments for a given date range
   */
  private async hasVehicleDateConflict(
    vehicleId: string,
    tripDate: Date,
    returnDate: Date,
    excludeRequestId?: string,
  ): Promise<boolean> {
    const allRequests = await this.vehicleRequestModel.find({
      vehicleId: new Types.ObjectId(vehicleId),
      _id: excludeRequestId ? { $ne: new Types.ObjectId(excludeRequestId) } : undefined,
      status: { $in: [RequestStatus.ASSIGNED, RequestStatus.APPROVED] },
      tripCompleted: false,
    }).exec();

    for (const req of allRequests) {
      // Check if dates overlap
      if (this.datesOverlap(tripDate, returnDate, req.tripDate, req.returnDate)) {
        return true; // Conflict found
      }
    }

    return false; // No conflicts
  }

  /**
   * Check if a driver has conflicting assignments for a given date range
   */
  private async hasDriverDateConflict(
    driverId: string,
    tripDate: Date,
    returnDate: Date,
    excludeRequestId?: string,
  ): Promise<boolean> {
    const allRequests = await this.vehicleRequestModel.find({
      driverId: new Types.ObjectId(driverId),
      _id: excludeRequestId ? { $ne: new Types.ObjectId(excludeRequestId) } : undefined,
      status: { $in: [RequestStatus.ASSIGNED, RequestStatus.APPROVED] },
      tripCompleted: false,
    }).exec();

    for (const req of allRequests) {
      // Check if dates overlap
      if (this.datesOverlap(tripDate, returnDate, req.tripDate, req.returnDate)) {
        return true; // Conflict found
      }
    }

    return false; // No conflicts
  }

  async findAvailableVehicles(
    tripDate?: Date,
    returnDate?: Date,
  ): Promise<Vehicle[]> {
    // Get all non-permanent vehicles (we'll filter by date conflicts if dates provided)
    const allVehicles = await this.vehicleModel
      .find({ isPermanent: false })
      .populate('assignedToUserId')
      .exec();

    // If no dates provided, return vehicles that are not explicitly marked unavailable
    // (for backward compatibility and general listing)
    if (!tripDate || !returnDate) {
      return allVehicles.filter((v) => v.isAvailable !== false);
    }

    // Filter vehicles that don't have date conflicts
    const availableVehicles: Vehicle[] = [];
    for (const vehicle of allVehicles) {
      // Skip if explicitly marked unavailable (e.g., maintenance)
      if (vehicle.isAvailable === false) {
        continue;
      }

      // Check for date conflicts
      const hasConflict = await this.hasVehicleDateConflict(
        vehicle._id.toString(),
        tripDate,
        returnDate,
      );

      if (!hasConflict) {
        availableVehicles.push(vehicle);
      }
    }

    return availableVehicles;
  }

  async findOneVehicle(id: string): Promise<VehicleDocument> {
    const vehicle = await this.vehicleModel.findById(id).populate('assignedToUserId').exec();
    if (!vehicle) {
      throw new NotFoundException('Vehicle not found');
    }
    return vehicle;
  }

  async updateVehicle(id: string, updateDto: Partial<CreateVehicleDto>): Promise<Vehicle> {
    return this.vehicleModel.findByIdAndUpdate(id, updateDto, { new: true }).exec();
  }

  // Driver CRUD
  async createDriver(createDriverDto: CreateDriverDto): Promise<Driver> {
    const driver = new this.driverModel(createDriverDto);
    return driver.save();
  }

  async findAllDrivers(): Promise<any[]> {
    // Get all users with DRIVER role
    const allUsers = await this.usersService.findAll();
    console.log(`[findAllDrivers] Total users: ${allUsers.length}`);
    
    // Filter users with DRIVER role - handle both enum and string formats
    const drivers = allUsers.filter((user) => {
      const userDoc = user as any as UserDocument;
      const roles = user.roles || [];
      // Normalize roles to uppercase strings for comparison
      const normalizedRoles = roles.map((role) => {
        if (typeof role === 'string') {
          return role.toUpperCase().trim();
        }
        return String(role).toUpperCase().trim();
      });
      
      // Check if 'DRIVER' is in the normalized roles
      const hasDriverRole = normalizedRoles.includes('DRIVER');
      
      if (hasDriverRole) {
        console.log(`[findAllDrivers] ✅ Found driver: ${user.name} (${userDoc._id || userDoc.id}), roles: ${JSON.stringify(roles)}`);
      }
      
      return hasDriverRole;
    });
    
    console.log(`[findAllDrivers] Total drivers found: ${drivers.length}`);
    
    // Get all vehicle requests to check assignments
    const allRequests = await this.vehicleRequestModel.find().exec();
    
    // Map to driver-like format for backward compatibility
    return drivers.map((user) => {
      const userDoc = user as any as UserDocument;
      // Find active assignments for this driver
      const activeAssignments = allRequests.filter(
        (req) => {
          if (!req.driverId) return false;
          
          let driverIdStr: string;
          if (typeof req.driverId === 'object' && req.driverId !== null) {
            driverIdStr = (req.driverId._id || req.driverId.id || req.driverId).toString();
          } else {
            driverIdStr = req.driverId.toString();
          }
          
          const userIdStr = (userDoc._id || userDoc.id).toString();
          return driverIdStr === userIdStr &&
            !req.tripCompleted &&
            (req.status === RequestStatus.ASSIGNED ||
              req.status === RequestStatus.APPROVED ||
              req.tripStarted);
        },
      );

      return {
        _id: (userDoc._id || userDoc.id).toString(),
        name: user.name,
        phone: user.phone || '',
        licenseNumber: (userDoc as any).employeeId || 'N/A', // Use employeeId as licenseNumber for compatibility
        isAvailable: activeAssignments.length === 0,
        email: user.email,
        employeeId: (userDoc as any).employeeId,
      };
    });
  }

  async findAvailableDrivers(
    tripDate?: Date,
    returnDate?: Date,
  ): Promise<any[]> {
    try {
      console.log('[findAvailableDrivers] ===== START =====');
      if (tripDate && returnDate) {
        console.log(`[findAvailableDrivers] Checking availability for trip dates: ${tripDate.toISOString()} to ${returnDate.toISOString()}`);
      }
      
      // Get all users with DRIVER role
      const allUsers = await this.usersService.findAll();
      console.log(`[findAvailableDrivers] Total users: ${allUsers.length}`);
      
      const drivers = allUsers.filter((user) => {
        // Check if user has DRIVER role - handle both enum and string formats
        const roles = user.roles || [];
        
        // Normalize roles to uppercase strings for comparison
        const normalizedRoles = roles.map((role) => {
          if (typeof role === 'string') {
            return role.toUpperCase().trim();
          }
          // If it's an enum, get its string value
          const roleStr = String(role).toUpperCase().trim();
          return roleStr;
        });
        
        // Check if 'DRIVER' is in the normalized roles
        return normalizedRoles.includes('DRIVER');
      });
      
      console.log(`[findAvailableDrivers] Total drivers found: ${drivers.length}`);
      
      if (drivers.length === 0) {
        console.log(`[findAvailableDrivers] No users with DRIVER role found in database`);
        return [];
      }
      
      // Get all vehicle requests to check assignments
      const allRequests = await this.vehicleRequestModel.find().exec();
      console.log(`[findAvailableDrivers] Total requests: ${allRequests.length}`);
      
      // Helper function to check if driver has date conflicts
      const hasDateConflict = async (user: any): Promise<boolean> => {
        if (!tripDate || !returnDate) {
          // If no dates provided, use old logic (check for any active assignment)
          const userDoc = user as any as UserDocument;
          const userIdStr = (userDoc._id || userDoc.id).toString();
          
          const activeAssignments = allRequests.filter((req) => {
            if (!req.driverId) return false;
            
            let driverIdStr: string;
            if (typeof req.driverId === 'object' && req.driverId !== null) {
              driverIdStr = (req.driverId._id || req.driverId.id || req.driverId).toString();
            } else {
              driverIdStr = req.driverId.toString();
            }
            
            const isAssigned = driverIdStr === userIdStr;
            const isActive = !req.tripCompleted &&
              req.status !== RequestStatus.REJECTED &&
              req.status !== RequestStatus.COMPLETED &&
              (req.status === RequestStatus.ASSIGNED ||
                req.status === RequestStatus.APPROVED ||
                req.tripStarted);
            
            return isAssigned && isActive;
          });
          
          return activeAssignments.length > 0;
        } else {
          // Check for date conflicts
          const userDoc = user as any as UserDocument;
          const driverId = (userDoc._id || userDoc.id).toString();
          return await this.hasDriverDateConflict(driverId, tripDate, returnDate);
        }
      };

      // Helper function to calculate active assignments count for a driver
      const getActiveAssignmentsCount = (user: any): number => {
        const userDoc = user as any as UserDocument;
        const userIdStr = (userDoc._id || userDoc.id).toString();
        
        return allRequests.filter((req) => {
          if (!req.driverId) return false;
          
          let driverIdStr: string;
          if (typeof req.driverId === 'object' && req.driverId !== null) {
            driverIdStr = (req.driverId._id || req.driverId.id || req.driverId).toString();
          } else {
            driverIdStr = req.driverId.toString();
          }
          
          const isAssigned = driverIdStr === userIdStr;
          
          // A request is active if:
          // 1. Trip is not completed
          // 2. Status is ASSIGNED or APPROVED (not REJECTED, COMPLETED, etc.)
          // 3. OR trip has started (regardless of status)
          const isActive = !req.tripCompleted &&
            req.status !== RequestStatus.REJECTED &&
            req.status !== RequestStatus.COMPLETED &&
            (req.status === RequestStatus.ASSIGNED ||
              req.status === RequestStatus.APPROVED ||
              req.tripStarted);
          
          return isAssigned && isActive;
        }).length;
      };

      // Filter to only available drivers (no date conflicts) and calculate counts
      const availableDrivers: any[] = [];
      for (const user of drivers) {
        const userDoc = user as any as UserDocument;
        const hasConflict = await hasDateConflict(user);
        
        if (!hasConflict) {
          const activeAssignmentsCount = getActiveAssignmentsCount(user);
          availableDrivers.push({
            _id: (userDoc._id || userDoc.id).toString(),
            name: user.name,
            phone: user.phone || '',
            licenseNumber: (userDoc as any).employeeId || 'N/A',
            isAvailable: true,
            email: user.email,
            employeeId: (userDoc as any).employeeId,
            activeAssignmentsCount: activeAssignmentsCount,
          });
          console.log(`[findAvailableDrivers] Driver ${user.name} is available`);
        } else {
          console.log(`[findAvailableDrivers] Driver ${user.name} has date conflict`);
        }
      }
      
      console.log(`[findAvailableDrivers] Available drivers: ${availableDrivers.length} out of ${drivers.length} total drivers`);
      
      // If no available drivers but we have drivers, log details for debugging
      if (availableDrivers.length === 0 && drivers.length > 0) {
        console.log(`[findAvailableDrivers] ⚠️ WARNING: Found ${drivers.length} driver(s) but none are available. Checking assignments...`);
        drivers.forEach((driver) => {
          const driverDoc = driver as any as UserDocument;
          const driverAssignments = allRequests.filter((req) => {
            if (!req.driverId) return false;
            let driverIdStr: string;
            if (typeof req.driverId === 'object' && req.driverId !== null) {
              driverIdStr = (req.driverId._id || req.driverId.id || req.driverId).toString();
            } else {
              driverIdStr = req.driverId.toString();
            }
            return driverIdStr === (driverDoc._id || driverDoc.id).toString();
          });
          console.log(`[findAvailableDrivers] Driver ${driver.name} has ${driverAssignments.length} total assignment(s)`);
          driverAssignments.forEach((req) => {
            console.log(`[findAvailableDrivers]   - Request ${req._id}: Status=${req.status}, TripStarted=${req.tripStarted}, TripCompleted=${req.tripCompleted}`);
          });
        });
      }
      
      console.log(`[findAvailableDrivers] Returning ${availableDrivers.length} available drivers`);
      console.log('[findAvailableDrivers] Driver details being returned:');
      availableDrivers.forEach((driver, index) => {
        console.log(`  ${index + 1}. ${driver.name} (${driver._id}) - ${driver.email} - ${driver.phone}`);
      });
      console.log('[findAvailableDrivers] ===== END =====');
      return availableDrivers;
    } catch (error) {
      console.error('[findAvailableDrivers] Error:', error);
      throw error;
    }
  }

  async findOneDriver(id: string): Promise<any> {
    // Try to find as user with DRIVER role first
    try {
      const user = await this.usersService.findOne(id);
      const userDoc = user as any as UserDocument;
      if (user.roles.includes(UserRole.DRIVER)) {
        // Get active assignments to determine availability
        const allRequests = await this.vehicleRequestModel.find().exec();
        const activeAssignments = allRequests.filter(
          (req) =>
            req.driverId &&
            req.driverId.toString() === (userDoc._id || userDoc.id).toString() &&
            !req.tripCompleted &&
            (req.status === RequestStatus.ASSIGNED ||
              req.status === RequestStatus.APPROVED ||
              req.tripStarted),
        );

        return {
          _id: (userDoc._id || userDoc.id).toString(),
          name: user.name,
          phone: user.phone || '',
          licenseNumber: (userDoc as any).employeeId || 'N/A',
          isAvailable: activeAssignments.length === 0,
          email: user.email,
          employeeId: (userDoc as any).employeeId,
        };
      }
    } catch (error) {
      // User not found or not a driver, fall through to check Driver model
    }

    // Fallback to Driver model for backward compatibility (if Driver model still exists)
    const driver = await this.driverModel.findById(id).exec();
    if (!driver) {
      throw new NotFoundException('Driver not found');
    }
    return driver;
  }

  async updateDriver(id: string, updateDto: Partial<CreateDriverDto>): Promise<Driver> {
    return this.driverModel.findByIdAndUpdate(id, updateDto, { new: true }).exec();
  }

  /**
   * Add participant to request if not already present
   */
  private addParticipant(
    request: VehicleRequestDocument,
    userId: string,
    role: UserRole,
    action: 'created' | 'approved' | 'rejected' | 'corrected' | 'assigned' | 'fulfilled',
  ): void {
    const participantId = new Types.ObjectId(userId);
    const exists = request.participants.some(
      (p) => p.userId.toString() === participantId.toString(),
    );
    if (!exists) {
      request.participants.push({
        userId: participantId,
        role,
        action,
        timestamp: new Date(),
      });
    } else {
      // Update existing participant's action and timestamp
      const participant = request.participants.find(
        (p) => p.userId.toString() === participantId.toString(),
      );
      if (participant) {
        participant.action = action;
        participant.timestamp = new Date();
      }
    }
  }

  /**
   * Notify all participants of workflow progress
   */
  private async notifyWorkflowProgress(
    request: VehicleRequestDocument,
    action: 'approved' | 'rejected' | 'corrected' | 'assigned' | 'submitted',
    actionBy: { userId: string; name: string; role: string },
    message: string,
  ): Promise<void> {
    try {
      // Get all unique participant IDs
      const participantIds = [
        request.requesterId.toString(),
        ...request.participants.map((p) => p.userId.toString()),
      ];
      const uniqueParticipantIds = [...new Set(participantIds)];

      // Get participant details for the progress payload
      const participants = await Promise.all(
        uniqueParticipantIds.map(async (id) => {
          try {
            const user = await this.usersService.findOne(id);
            const participant = request.participants.find((p) => p.userId.toString() === id);
            return {
              userId: id,
              name: user?.name || 'Unknown',
              role: participant?.role || user?.roles[0] || UserRole.SUPERVISOR,
              action: participant?.action || 'created',
              timestamp: participant?.timestamp || (request as any).createdAt || new Date(),
            };
          } catch {
            return null;
          }
        }),
      );

      const validParticipants = participants.filter((p) => p !== null) as Array<{
        userId: string;
        name: string;
        role: string;
        action: string;
        timestamp: Date;
      }>;

      // Emit workflow progress to all participants
      await this.notificationsService.emitWorkflowProgress(uniqueParticipantIds, {
        requestId: request._id.toString(),
        requestType: RequestType.VEHICLE,
        workflowStage: request.workflowStage,
        status: request.status,
        action,
        actionBy,
        participants: validParticipants,
        message,
      });

      // Also create notification records for all participants
      for (const participantId of uniqueParticipantIds) {
        try {
          await this.notificationsService.createNotification(
            participantId,
            this.getNotificationTypeForAction(action),
            this.getNotificationTitleForAction(action, RequestType.VEHICLE),
            message,
            request._id.toString(),
            RequestType.VEHICLE,
            participantId === actionBy.userId, // Don't send email to action performer
          );
        } catch (error) {
          console.error(`Error creating notification for participant ${participantId}:`, error);
        }
      }
    } catch (error) {
      console.error('Error notifying workflow progress:', error);
    }
  }

  private getNotificationTypeForAction(
    action: 'approved' | 'rejected' | 'corrected' | 'assigned' | 'submitted',
  ): NotificationType {
    switch (action) {
      case 'approved':
        return NotificationType.REQUEST_APPROVED;
      case 'rejected':
        return NotificationType.REQUEST_REJECTED;
      case 'corrected':
        return NotificationType.REQUEST_CORRECTED;
      case 'assigned':
        return NotificationType.REQUEST_ASSIGNED;
      case 'submitted':
        return NotificationType.REQUEST_SUBMITTED;
      default:
        return NotificationType.REQUEST_SUBMITTED;
    }
  }

  private getNotificationTitleForAction(action: string, requestType: RequestType): string {
    switch (action) {
      case 'approved':
        return `${requestType} Request Approved`;
      case 'rejected':
        return `${requestType} Request Rejected`;
      case 'corrected':
        return `Correction Required: ${requestType} Request`;
      case 'assigned':
        return `${requestType} Request Assigned`;
      case 'submitted':
        return `${requestType} Request Submitted`;
      default:
        return `${requestType} Request Updated`;
    }
  }

  // Vehicle Request CRUD
  async createRequest(
    userId: string,
    createVehicleRequestDto: CreateVehicleRequestDto,
  ): Promise<VehicleRequest> {
    const user = await this.usersService.findOne(userId);
    const workflowChain = this.workflowService.getWorkflowChain(user.level, RequestType.VEHICLE);

    // Get head office - all trip requests start from head office
    const headOffice = await this.officesService.findHeadOffice();
    if (!headOffice) {
      throw new BadRequestException('Head office not found. Please create a head office first.');
    }

    const headOfficeDoc = headOffice as any;
    
    // 🔍 DEBUG: Log head office details
    console.log('🏢 [FIND HEAD OFFICE] Office Details:');
    console.log(`   Office Name: ${headOffice.name || 'N/A'}`);
    console.log(`   Office Address: ${headOffice.address || 'N/A'}`);
    console.log(`   Office Coordinates: lat=${headOffice.latitude}, lng=${headOffice.longitude}`);
    console.log(`   Office ID: ${headOfficeDoc._id || headOfficeDoc.id}`);
    
    // Determine start location: use provided start point or default to head office
    const startLatitude = createVehicleRequestDto.startLatitude ?? headOffice.latitude;
    const startLongitude = createVehicleRequestDto.startLongitude ?? headOffice.longitude;
    
    // Process waypoints if provided
    const waypoints = createVehicleRequestDto.waypoints
      ? createVehicleRequestDto.waypoints.map((wp) => ({
          name: wp.name,
          latitude: wp.latitude,
          longitude: wp.longitude,
          order: wp.order,
          reached: false,
          reachedTime: null,
          distanceFromPrevious: null,
          fuelFromPrevious: null,
        }))
      : [];

    const request = new this.vehicleRequestModel({
      ...createVehicleRequestDto,
      requesterId: new Types.ObjectId(userId),
      tripDate: new Date(createVehicleRequestDto.tripDate),
      returnDate: new Date(createVehicleRequestDto.returnDate),
      workflowStage: WorkflowStage.SUBMITTED,
      status: RequestStatus.PENDING,
      requestedDestinationLocation: createVehicleRequestDto.destinationLatitude &&
        createVehicleRequestDto.destinationLongitude
        ? {
            latitude: createVehicleRequestDto.destinationLatitude,
            longitude: createVehicleRequestDto.destinationLongitude,
          }
        : null,
      // Office reference (always head office)
      officeId: new Types.ObjectId(headOfficeDoc._id || headOfficeDoc.id),
      officeLocation: {
        latitude: headOffice.latitude,
        longitude: headOffice.longitude,
      },
      // Start location (can be different from office)
      startLocation: {
        latitude: startLatitude,
        longitude: startLongitude,
      },
      // Drop-off location (optional)
      dropOffLocation: createVehicleRequestDto.dropOffLatitude &&
        createVehicleRequestDto.dropOffLongitude
        ? {
            latitude: createVehicleRequestDto.dropOffLatitude,
            longitude: createVehicleRequestDto.dropOffLongitude,
          }
        : null,
      // Multi-stop support
      waypoints,
      currentStopIndex: 0,
      totalTripDistanceKm: null,
      totalTripFuelLiters: null,
    });

    // 🔍 DEBUG: Log location coordinates when creating request
    console.log('📍 [CREATE REQUEST] Location Coordinates:');
    console.log(`   Office Location: lat=${headOffice.latitude}, lng=${headOffice.longitude}`);
    console.log(`   Office Address: ${headOffice.address || 'N/A'}`);
    console.log(`   Start Location: lat=${startLatitude}, lng=${startLongitude}`);
    console.log(`   Destination Location: lat=${createVehicleRequestDto.destinationLatitude || 'N/A'}, lng=${createVehicleRequestDto.destinationLongitude || 'N/A'}`);
    console.log(`   Destination Address: ${createVehicleRequestDto.destination || 'N/A'}`);

    // Auto-advance workflow stage based on user level
    // Level 14+: SUBMITTED → DGS_REVIEW (skip supervisor)
    // Level < 14: SUBMITTED → SUPERVISOR_REVIEW (requires supervisor approval)
    const nextStage = this.workflowService.getNextStage(WorkflowStage.SUBMITTED, workflowChain);
    if (nextStage) {
      request.workflowStage = nextStage;
      console.log(`[Vehicles Service] createRequest: Auto-advancing request from SUBMITTED to ${nextStage} for user level ${user.level}`);
    }

    // Add requester as participant
    request.participants = [
      {
        userId: new Types.ObjectId(userId),
        role: user.roles[0] || UserRole.SUPERVISOR,
        action: 'created',
        timestamp: new Date(),
      },
    ];

    const savedRequest = await request.save();

    // Notify requester
    try {
      await this.notificationsService.notifyRequestSubmitted(
        userId,
        RequestType.VEHICLE,
        savedRequest._id.toString(),
      );
    } catch (error) {
      console.error('Error sending request submitted notification:', error);
    }

    // Notify next approver(s)
    try {
      const nextStage = savedRequest.workflowStage;
      const approvers = await this.findApproversForStage(nextStage, user.departmentId.toString());
      for (const approver of approvers) {
        await this.notificationsService.notifyApprovalRequired(
          approver._id.toString(),
          user.name,
          RequestType.VEHICLE,
          savedRequest._id.toString(),
        );
      }
    } catch (error) {
      console.error('Error sending approval required notification:', error);
    }

    return savedRequest;
  }

  async findAllRequests(userId?: string, role?: UserRole): Promise<VehicleRequest[]> {
    const query: any = {};
    
    // IMPORTANT: When userId is provided (e.g., for "My Requests"), 
    // ONLY filter by requesterId. Do NOT include driverId to avoid 
    // showing requests where user is only the driver.
    if (userId) {
      query.requesterId = new Types.ObjectId(userId);
      console.log('[Vehicles Service] findAllRequests: Querying with userId:', userId);
      console.log('[Vehicles Service] findAllRequests: Query ObjectId:', query.requesterId.toString());
      
      // Log ALL requests in database to compare requesterIds
      const allRequests = await this.vehicleRequestModel
        .find({})
        .select('_id requesterId createdAt')
        .lean()
        .exec();
      console.log('[Vehicles Service] findAllRequests: Total requests in database:', allRequests.length);
      if (allRequests.length > 0) {
        console.log('[Vehicles Service] findAllRequests: All request requesterIds:');
        allRequests.forEach((req: any, index: number) => {
          const reqId = req.requesterId?.toString() || req.requesterId;
          console.log(`  [${index + 1}] Request ID: ${req._id}, RequesterId: ${reqId}, CreatedAt: ${req.createdAt}`);
        });
      }
      // Explicitly ensure we're NOT including driver assignments
      // This ensures "My Requests" only shows requests the user created
    } else {
      console.log('[Vehicles Service] findAllRequests: No userId provided, returning all requests');
    }

    // IMPORTANT: For "My Requests", we should return ALL requests regardless of status
    // Do NOT filter by status - users should see all their requests (pending, approved, completed, etc.)
    let requests = await this.vehicleRequestModel
      .find(query)
      .populate('requesterId')
      .populate('vehicleId')
      .populate('driverId')
      .sort({ createdAt: -1 })
      .exec();

    console.log('[Vehicles Service] findAllRequests: Found', requests.length, 'requests matching query (all statuses)');
    if (requests.length > 0) {
      const statusCounts = requests.reduce((acc: any, req: any) => {
        const status = req.status || 'UNKNOWN';
        acc[status] = (acc[status] || 0) + 1;
        return acc;
      }, {});
      console.log('[Vehicles Service] findAllRequests: Status breakdown:', JSON.stringify(statusCounts));
    }
    
    // If no requests found with ObjectId query, try string comparison as fallback
    if (requests.length === 0 && userId) {
      console.log('[Vehicles Service] findAllRequests: Trying fallback string comparison query');
      const allRequests = await this.vehicleRequestModel
        .find({})
        .populate('requesterId')
        .populate('vehicleId')
        .populate('driverId')
        .sort({ createdAt: -1 })
        .exec();
      
      requests = allRequests.filter((req) => {
        const reqId = req.requesterId?.toString() || (req.requesterId as any)?._id?.toString() || '';
        const matches = reqId === userId || reqId.toLowerCase() === userId.toLowerCase();
        if (matches) {
          console.log('[Vehicles Service] findAllRequests: Found matching request via string comparison:', req._id.toString(), 'requesterId:', reqId);
        }
        return matches;
      });
      
      console.log('[Vehicles Service] findAllRequests: Found', requests.length, 'requests via string comparison fallback');
    }
    
    if (requests.length > 0) {
      console.log('[Vehicles Service] findAllRequests: First request requesterId:', requests[0].requesterId?.toString());
    } else {
      console.log('[Vehicles Service] findAllRequests: No requests found. User ID being queried:', userId);
      console.log('[Vehicles Service] findAllRequests: NOTE - User ID mismatch detected. Requests may belong to a different user account.');
    }

    return requests;
  }

  async findAllRequestsByRole(userId?: string, userRoles?: UserRole[]): Promise<VehicleRequest[]> {
    const query: any = {};
    
    // If no userId provided, return empty array
    if (!userId) {
      return [];
    }

    const user = await this.usersService.findOne(userId);
    if (!user) {
      return [];
    }

    // If no roles provided, treat as regular user (return only their own requests)
    const roles = userRoles || [];

    // DGS, ADGS, DDGS, TO: Return ALL vehicle requests (all statuses, all stages)
    if (
      roles.includes(UserRole.DGS) ||
      roles.includes(UserRole.ADGS) ||
      roles.includes(UserRole.DDGS) ||
      roles.includes(UserRole.TO)
    ) {
      return this.vehicleRequestModel
        .find({})
        .populate('requesterId')
        .populate('vehicleId')
        .populate('driverId')
        .sort({ createdAt: -1 })
        .exec();
    }

    // SUPERVISOR: level 14+ in same department - Return all vehicle requests from their department
    // Use capability service to check if user can act as supervisor
    if (this.capabilityService.canActAsSupervisor(user, user.roles)) {
      // First, find all requests and populate requesterId, then filter by department
      const allRequests = await this.vehicleRequestModel
        .find({})
        .populate('requesterId')
        .populate('vehicleId')
        .populate('driverId')
        .sort({ createdAt: -1 })
        .exec();

      // Filter by department after population
      return allRequests.filter((request) => {
        const requester = request.requesterId as any;
        return requester && requester.departmentId && requester.departmentId.toString() === user.departmentId.toString();
      });
    }

    // Regular users and other roles: Return only their own requests
    query.requesterId = new Types.ObjectId(userId);
    return this.vehicleRequestModel
      .find(query)
      .populate('requesterId')
      .populate('vehicleId')
      .populate('driverId')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findDriverAssignments(driverId: string): Promise<VehicleRequest[]> {
    return this.vehicleRequestModel
      .find({ driverId: new Types.ObjectId(driverId) })
      .populate('requesterId')
      .populate('vehicleId')
      .populate('driverId')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findPendingApprovals(userId: string, userRoles: UserRole[]): Promise<VehicleRequest[]> {
    try {
      const user = await this.usersService.findOne(userId);
      
      if (!user) {
        console.error('[Vehicles Service] findPendingApprovals: User not found:', userId);
        return [];
      }

      // DGS can see all pending approvals (special case)
      if (userRoles.includes(UserRole.DGS)) {
        const requests = await this.vehicleRequestModel
          .find({
            status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
          })
          .populate('requesterId')
          .populate('vehicleId')
          .populate('driverId')
          .sort({ createdAt: -1 })
          .exec();
        
        console.log('[Vehicles Service] findPendingApprovals: DGS found', requests.length, 'requests (all pending)');
        return requests;
      }

      // Build optimized query using capability service
      const departmentId = this.capabilityService.getDepartmentId(user);
      const stages = this.capabilityService.getPendingApprovalStages(user, userRoles, RequestType.VEHICLE);
      
      console.log('[Vehicles Service] findPendingApprovals: Starting for user:', {
        userId,
        userRoles,
        userLevel: user.level,
        departmentId,
        stages,
      });
      
      if (stages.length === 0) {
        console.log('[Vehicles Service] findPendingApprovals: No stages found for user');
        return [];
      }

      // Build query conditions
      const queryConditions: any[] = [];
      const canActAsSupervisor = this.capabilityService.canActAsSupervisor(user, userRoles);

      for (const stage of stages) {
        if (stage === WorkflowStage.SUPERVISOR_REVIEW && canActAsSupervisor) {
          // Supervisor requests need department matching and include SUBMITTED stage
          if (departmentId) {
            queryConditions.push({
              workflowStage: { $in: [WorkflowStage.SUBMITTED, WorkflowStage.SUPERVISOR_REVIEW] },
              status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
            });
          }
        } else {
          // Role-based stages (DDGS_REVIEW, ADGS_REVIEW, TO_REVIEW)
          queryConditions.push({
            workflowStage: stage,
            status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
          });
        }
      }

      const query = queryConditions.length > 0 ? { $or: queryConditions } : { _id: { $exists: false } };

      console.log('[Vehicles Service] findPendingApprovals: Query conditions built:', {
        queryConditionsCount: queryConditions.length,
        queryConditions: JSON.stringify(queryConditions, null, 2),
        finalQuery: JSON.stringify(query, null, 2),
      });

      // Execute single optimized query
      const allRequests = await this.vehicleRequestModel
        .find(query)
        .populate('requesterId')
        .populate('vehicleId')
        .populate('driverId')
        .sort({ createdAt: -1 })
        .exec();
      
      console.log('[Vehicles Service] findPendingApprovals: Raw query results:', {
        totalFound: allRequests.length,
        requests: allRequests.map(r => ({
          id: r._id.toString(),
          workflowStage: r.workflowStage,
          status: r.status,
          requesterId: r.requesterId ? (typeof r.requesterId === 'string' ? r.requesterId : (r.requesterId as any)._id?.toString()) : null,
        })),
      });

      // Use Map for deduplication (preserves populated fields)
      const requestMap = new Map<string, VehicleRequestDocument>();
      
      // Count requests by stage for logging
      const stageCounts: Record<string, number> = {};

      for (const request of allRequests) {
        const requestId = request._id.toString();
        const requestStage = request.workflowStage;
        
        // Handle supervisor/SUBMITTED requests - need department matching
        if (requestStage === WorkflowStage.SUPERVISOR_REVIEW || requestStage === WorkflowStage.SUBMITTED) {
          if (!canActAsSupervisor) {
            continue; // Skip if user can't act as supervisor
          }
          
          const requester = request.requesterId as any;
          if (!requester) {
            continue; // Skip if requester not populated
          }
          
          const requesterDeptId = this.capabilityService.getDepartmentId(requester);
          
          if (requesterDeptId && departmentId && requesterDeptId === departmentId) {
            // If request is at SUBMITTED stage, only include if requester level < 14
            if (requestStage === WorkflowStage.SUBMITTED) {
              const requesterLevel = (requester as any).level;
              if (requesterLevel != null && requesterLevel >= 14) {
                continue; // Skip - requester doesn't need supervisor approval
              }
            }
            
            requestMap.set(requestId, request);
            const stageKey = requestStage === WorkflowStage.SUBMITTED ? 'SUBMITTED' : 'SUPERVISOR_REVIEW';
            stageCounts[stageKey] = (stageCounts[stageKey] || 0) + 1;
          } else {
            // Department doesn't match - skip this request
            continue;
          }
        } else {
          // Role-based stages - add all
          requestMap.set(requestId, request);
          const stageKey = requestStage || 'UNKNOWN';
          stageCounts[stageKey] = (stageCounts[stageKey] || 0) + 1;
        }
      }

      const finalRequests = Array.from(requestMap.values());
      
      // Detailed logging
      const approverRoles = this.capabilityService.getUserApproverRoles(userRoles);
      
      console.log('[Vehicles Service] findPendingApprovals:');
      console.log('  - User ID:', userId);
      console.log('  - User roles:', userRoles);
      console.log('  - Explicit approver roles:', approverRoles);
      console.log('  - Can act as supervisor:', canActAsSupervisor);
      console.log('  - Pending approval stages:', stages);
      console.log('  - Query conditions:', JSON.stringify(query, null, 2));
      console.log('  - Requests found by stage:', stageCounts);
      console.log('  - Final combined count:', finalRequests.length);

      return finalRequests;
    } catch (error) {
      console.error('[Vehicles Service] findPendingApprovals: Error fetching pending approvals:', error);
      
      // Handle specific error types
      if (error instanceof NotFoundException) {
        console.error('[Vehicles Service] findPendingApprovals: User not found');
        return [];
      }
      
      // For database errors, log and return empty array
      console.error('[Vehicles Service] findPendingApprovals: Database error:', error.message);
      return [];
    }
  }

  async findOneRequest(id: string): Promise<VehicleRequestDocument> {
    const request = await this.vehicleRequestModel
      .findById(id)
      .populate('requesterId')
      .populate('vehicleId')
      .populate('driverId')
      .exec();

    if (!request) {
      throw new NotFoundException('Vehicle request not found');
    }

    // 🔍 DEBUG: Log stored location data when fetching request
    console.log('📋 [FETCH REQUEST] Stored Location Data:');
    console.log(`   Request ID: ${id}`);
    console.log(`   Destination: ${request.destination || 'N/A'}`);
    console.log(`   Office Location: lat=${request.officeLocation?.latitude || 'N/A'}, lng=${request.officeLocation?.longitude || 'N/A'}`);
    console.log(`   Start Location: lat=${request.startLocation?.latitude || 'N/A'}, lng=${request.startLocation?.longitude || 'N/A'}`);
    console.log(`   Requested Destination: lat=${request.requestedDestinationLocation?.latitude || 'N/A'}, lng=${request.requestedDestinationLocation?.longitude || 'N/A'}`);
    console.log(`   Actual Destination: lat=${request.destinationLocation?.latitude || 'N/A'}, lng=${request.destinationLocation?.longitude || 'N/A'}`);
    console.log(`   Return Location: lat=${request.returnLocation?.latitude || 'N/A'}, lng=${request.returnLocation?.longitude || 'N/A'}`);

    return request;
  }

  // Helper function to extract driver ID from request (handles both populated and non-populated)
  private getDriverIdFromRequest(request: VehicleRequestDocument): string | null {
    if (!request.driverId) {
      return null;
    }
    if (typeof request.driverId === 'object' && request.driverId !== null) {
      // Populated object
      return (request.driverId._id || request.driverId.id || request.driverId).toString();
    }
    // Direct ObjectId
    return request.driverId.toString();
  }

  // Helper function to extract vehicle ID from request (handles both populated and non-populated)
  private getVehicleIdFromRequest(request: VehicleRequestDocument): string | null {
    if (!request.vehicleId) {
      return null;
    }
    if (typeof request.vehicleId === 'object' && request.vehicleId !== null) {
      // Populated object
      return (request.vehicleId._id || request.vehicleId.id || request.vehicleId).toString();
    }
    // Direct ObjectId
    return request.vehicleId.toString();
  }

  async approveRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    approveDto: ApproveRequestDto,
  ): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);
    
    // Validate userId before passing to findOne
    if (!userId || typeof userId !== 'string') {
      throw new BadRequestException(`Invalid userId type: ${typeof userId}. Expected string.`);
    }
    
    // Check if userId looks like a stringified object
    const trimmed = userId.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      throw new BadRequestException(
        `Invalid userId: received stringified object. This should have been caught in the controller. userId: ${trimmed.substring(0, 200)}`
      );
    }
    
    const user = await this.usersService.findOne(userId);

    // Get requester to determine correct workflow chain (use requester's level, not approver's)
    // Safely extract requesterId as string (handle both ObjectId and populated object)
    let requesterId: string;
    console.log('[DEBUG] approveRequest - request.requesterId:', request.requesterId, 'type:', typeof request.requesterId);
    
    if (request.requesterId) {
      // If it's already a string
      if (typeof request.requesterId === 'string') {
        requesterId = request.requesterId;
      } 
      // If it's a populated object with _id
      else if (request.requesterId._id) {
        requesterId = typeof request.requesterId._id === 'string' 
          ? request.requesterId._id 
          : request.requesterId._id.toString();
      }
      // If it's an ObjectId with toString method
      else if (request.requesterId.toString && typeof request.requesterId.toString === 'function') {
        requesterId = request.requesterId.toString();
      } 
      else {
        throw new BadRequestException(`Invalid requesterId format: ${JSON.stringify(request.requesterId).substring(0, 200)}`);
      }
    } else {
      throw new BadRequestException('Request missing requesterId');
    }
    
    console.log('[DEBUG] approveRequest - extracted requesterId:', requesterId, 'type:', typeof requesterId);
    const requester = await this.usersService.findOne(requesterId);
    
    // Use requester's level to get the correct workflow chain
    const workflowChain = this.workflowService.getWorkflowChain(requester.level, RequestType.VEHICLE);
    
    // Check if user can act as supervisor and can approve at SUPERVISOR_REVIEW or SUBMITTED stage
    // SUBMITTED is allowed for vehicle requests because they should auto-advance but might still be at SUBMITTED
    // Supervisor must be in the same department as the requester
    const canActAsSupervisor = this.capabilityService.canActAsSupervisor(user, userRoles);
    let canSupervisorApprove = false;
    if (canActAsSupervisor && 
        (request.workflowStage === WorkflowStage.SUPERVISOR_REVIEW || 
         request.workflowStage === WorkflowStage.SUBMITTED)) {
      // Check if supervisor is in the same department as requester
      const supervisorDeptId = this.capabilityService.getDepartmentId(user);
      const requesterDeptId = this.capabilityService.getDepartmentId(requester);
      canSupervisorApprove = supervisorDeptId && requesterDeptId && supervisorDeptId === requesterDeptId;
    }
    
    // Check if this is an admin approval override
    const isAdminApproval = approveDto.isAdminApproval && this.adminRoleService.canApproveAll(userRoles);
    
    const canApprove = isAdminApproval ||
      userRoles.includes(UserRole.ADMIN) || // ADMIN can approve at any stage
      canSupervisorApprove || // Supervisor (level >= 14) can approve at SUPERVISOR_REVIEW or SUBMITTED
      this.workflowService.canApproveAtStage(userRoles, request.workflowStage, workflowChain) ||
      this.workflowService.canDGSOverride(userRoles);

    if (!canApprove) {
      console.log('[DEBUG] approveRequest - Permission denied:', {
        userId,
        userLevel: user.level,
        userRoles,
        workflowStage: request.workflowStage,
        canActAsSupervisor,
        canSupervisorApprove,
        canApproveAtStage: this.workflowService.canApproveAtStage(userRoles, request.workflowStage, workflowChain),
        canDGSOverride: this.workflowService.canDGSOverride(userRoles),
      });
      throw new ForbiddenException('You do not have permission to approve this request');
    }

    // Add approval
    const approval = {
      approverId: new Types.ObjectId(userId),
      role: userRoles[0], // Use first role, or determine based on stage
      status: 'APPROVED' as const,
      comment: approveDto.comment,
      timestamp: new Date(),
    };

    request.approvals.push(approval);

    // Special handling: If DGS approves at SUBMITTED stage, move to DGS_REVIEW
    let nextStage: WorkflowStage | null = null;
    if (userRoles.includes(UserRole.DGS) && request.workflowStage === WorkflowStage.SUBMITTED) {
      nextStage = this.workflowService.getNextStage(WorkflowStage.SUBMITTED, workflowChain);
      if (nextStage) {
        request.workflowStage = nextStage;
      }
    } else {
      // Normal flow: Move to next stage
      nextStage = this.workflowService.getNextStage(request.workflowStage, workflowChain);
      if (nextStage) {
        request.workflowStage = nextStage;
      } else {
        // Workflow complete
        request.status = RequestStatus.APPROVED;
      }
    }

    // Add approver as participant
    this.addParticipant(request, userId, userRoles[0], 'approved');
    const savedRequest = await request.save();

    // Notify all participants of workflow progress
    await this.notifyWorkflowProgress(
      savedRequest,
      'approved',
      {
        userId,
        name: user.name,
        role: userRoles[0],
      },
      `Request approved by ${user.name} (${userRoles[0]}). ${nextStage ? `Moved to ${nextStage} stage.` : 'Request fully approved.'}`,
    );

    // Notify requester (legacy method for backward compatibility)
    try {
      await this.notificationsService.notifyRequestApproved(
        requesterId,
        RequestType.VEHICLE,
        requestId,
      );
    } catch (error) {
      console.error('Error sending request approved notification:', error);
    }

    // If there's a next stage, notify next approver(s)
    if (nextStage) {
      try {
        const approvers = await this.findApproversForStage(nextStage, requester.departmentId.toString());
        for (const approver of approvers) {
          await this.notificationsService.notifyApprovalRequired(
            approver._id.toString(),
            requester.name,
            RequestType.VEHICLE,
            requestId,
          );
        }
      } catch (error) {
        console.error('Error sending approval required notification:', error);
      }
    }

    return savedRequest;
  }

  async rejectRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    rejectDto: RejectRequestDto,
  ): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);
    const user = await this.usersService.findOne(userId);

    // Get requester to determine correct workflow chain (use requester's level, not approver's)
    const requester = await this.usersService.findOne(request.requesterId.toString());
    
    // Use requester's level to get the correct workflow chain
    const workflowChain = this.workflowService.getWorkflowChain(requester.level, RequestType.VEHICLE);
    
    const canApprove =
      this.workflowService.canApproveAtStage(userRoles, request.workflowStage, workflowChain) ||
      this.workflowService.canDGSOverride(userRoles);

    if (!canApprove) {
      throw new ForbiddenException('You do not have permission to reject this request');
    }

    // Add rejection
    const approval = {
      approverId: new Types.ObjectId(userId),
      role: userRoles[0],
      status: 'REJECTED' as const,
      comment: rejectDto.comment,
      timestamp: new Date(),
    };

    request.approvals.push(approval);
    request.status = RequestStatus.REJECTED;

    // Add rejector as participant
    this.addParticipant(request, userId, userRoles[0], 'rejected');
    const savedRequest = await request.save();

    // Notify all participants of workflow progress
    const requesterId = typeof request.requesterId === 'string'
      ? request.requesterId
      : request.requesterId.toString();
    await this.notifyWorkflowProgress(
      savedRequest,
      'rejected',
      {
        userId,
        name: user.name,
        role: userRoles[0],
      },
      `Request rejected by ${user.name} (${userRoles[0]}). ${rejectDto.comment ? `Reason: ${rejectDto.comment}` : 'No reason provided.'}`,
    );

    // Notify requester (legacy method for backward compatibility)
    try {
      await this.notificationsService.notifyRequestRejected(
        requesterId,
        RequestType.VEHICLE,
        requestId,
        rejectDto.comment || 'No comment provided',
      );
    } catch (error) {
      console.error('Error sending request rejected notification:', error);
    }

    return savedRequest;
  }

  /**
   * Cancel a vehicle request
   * Only allowed if:
   * - Workflow stage is SUBMITTED, SUPERVISOR_REVIEW, or DGS_REVIEW (for requester)
   * - No approvals have been made (approvals array is empty)
   * - User is the requester OR Supervisor (for lower level officers) OR DGS (for higher level officers)
   */
  async cancelRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    cancelDto: { reason?: string },
  ): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);
    const user = await this.usersService.findOne(userId);

    // Check if user is the requester
    const isRequester = request.requesterId.toString() === userId;
    const hasNoApprovals = !request.approvals || request.approvals.length === 0;

    // Define allowed stages for requester cancellation
    const allowedStagesForRequester = [
      WorkflowStage.SUBMITTED,
      WorkflowStage.SUPERVISOR_REVIEW,
      WorkflowStage.DGS_REVIEW,
    ];

    let canCancel = false;
    let cancelerRole: UserRole = userRoles[0];

    // Check if requester can cancel (no approvals and stage is allowed)
    if (isRequester && hasNoApprovals && allowedStagesForRequester.includes(request.workflowStage)) {
      canCancel = true;
      cancelerRole = userRoles[0];
    } else if (!isRequester) {
      // For non-requester cancellation, check existing Supervisor/DGS logic
      // Can only cancel if still at SUBMITTED stage
      if (request.workflowStage !== WorkflowStage.SUBMITTED) {
        throw new BadRequestException('Cannot cancel request: workflow has already started');
      }

      // Get requester to check their level
      const requester = await this.usersService.findOne(request.requesterId.toString());
      const requesterLevel = requester.level;

      // Check if user can cancel:
      // - Supervisor can cancel for lower level officers (level < 14)
      // - DGS can cancel for higher level officers (level >= 14)
      const isSupervisor = this.capabilityService.canActAsSupervisor(user, userRoles);
      const isDGS = userRoles.includes(UserRole.DGS);
      const isLowerLevel = requesterLevel < 14;

      if (isLowerLevel && isSupervisor) {
        // Lower level: Supervisor can cancel
        canCancel = true;
      } else if (!isLowerLevel && isDGS) {
        // Higher level: DGS can cancel
        canCancel = true;
      }
    }

    if (!canCancel) {
      if (isRequester) {
        throw new ForbiddenException(
          'You cannot cancel this request. Cancellation is only allowed if no approvals have been made and the request is at SUBMITTED, SUPERVISOR_REVIEW, or DGS_REVIEW stage.'
        );
      } else {
        throw new ForbiddenException(
          'You do not have permission to cancel this request. Only Supervisor can cancel requests from lower level officers, and only DGS can cancel requests from higher level officers.'
        );
      }
    }

    // Add cancellation
    const approval = {
      approverId: new Types.ObjectId(userId),
      role: cancelerRole,
      status: 'REJECTED' as const,
      comment: cancelDto.reason || 'Request cancelled',
      timestamp: new Date(),
    };

    request.approvals.push(approval);
    request.status = RequestStatus.REJECTED;

    // Add canceller as participant (use 'rejected' action type)
    this.addParticipant(request, userId, cancelerRole, 'rejected');
    const savedRequest = await request.save();

    // Notify all participants (use 'rejected' action type)
    const requesterId = typeof request.requesterId === 'string'
      ? request.requesterId
      : request.requesterId.toString();
    
    // Create appropriate notification message
    const notificationMessage = isRequester
      ? `Request cancelled by requester ${user.name}. ${cancelDto.reason ? `Reason: ${cancelDto.reason}` : 'No reason provided.'}`
      : `Request cancelled by ${user.name} (${cancelerRole}). ${cancelDto.reason ? `Reason: ${cancelDto.reason}` : 'No reason provided.'}`;

    await this.notifyWorkflowProgress(
      savedRequest,
      'rejected',
      {
        userId,
        name: user.name,
        role: cancelerRole.toString(),
      },
      notificationMessage,
    );

    return savedRequest;
  }

  async assignVehicle(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    assignDto: AssignVehicleDto,
  ): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);

    // Only TO or DGS can assign
    if (!userRoles.includes(UserRole.TO) && !userRoles.includes(UserRole.DGS)) {
      throw new ForbiddenException('Only Transport Officer or DGS can assign vehicles');
    }

    // DGS can assign even when pending (skips approval workflow)
    // TO can only assign when approved
    const isDGS = userRoles.includes(UserRole.DGS);
    if (!isDGS && request.status !== RequestStatus.APPROVED) {
      throw new BadRequestException('Request must be approved before vehicle assignment');
    }

    // Check vehicle availability
    const vehicle = await this.findOneVehicle(assignDto.vehicleId);
    
    // Check if vehicle is unavailable for non-date reasons (maintenance, etc.)
    if (vehicle.isAvailable === false) {
      throw new BadRequestException('Vehicle is not available (may be in maintenance or have other issues)');
    }

    if (vehicle.isPermanent && vehicle.assignedToUserId) {
      throw new BadRequestException('Permanent vehicle is already assigned');
    }

    // Check for date conflicts with existing assignments
    const vehicleHasConflict = await this.hasVehicleDateConflict(
      assignDto.vehicleId,
      request.tripDate,
      request.returnDate,
      requestId, // Exclude current request from conflict check
    );

    if (vehicleHasConflict) {
      throw new BadRequestException(
        'Vehicle is already assigned to another trip during this date range. Please select a different vehicle or adjust the trip dates.',
      );
    }

    // Check driver availability if provided
    if (assignDto.driverId) {
      const driver = await this.findOneDriver(assignDto.driverId);
      
      // Check if driver is unavailable for non-date reasons
      if (driver.isAvailable === false) {
        throw new BadRequestException('Driver is not available');
      }

      // Check for date conflicts with existing assignments
      const driverHasConflict = await this.hasDriverDateConflict(
        assignDto.driverId,
        request.tripDate,
        request.returnDate,
        requestId, // Exclude current request from conflict check
      );

      if (driverHasConflict) {
        throw new BadRequestException(
          'Driver is already assigned to another trip during this date range. Please select a different driver or adjust the trip dates.',
        );
      }

      request.driverId = new Types.ObjectId(assignDto.driverId);
    }

    request.vehicleId = new Types.ObjectId(assignDto.vehicleId);
    request.status = RequestStatus.ASSIGNED;
    
    // When vehicle is assigned, mark workflow as complete (FULFILLMENT stage)
    // This indicates the approval workflow is done and trip workflow can begin
    request.workflowStage = WorkflowStage.FULFILLMENT;
    
    // Add approval entry showing who assigned the vehicle
    const assignerRole = isDGS ? UserRole.DGS : UserRole.TO;
    request.approvals.push({
      approverId: new Types.ObjectId(userId),
      role: assignerRole,
      status: 'APPROVED',
      comment: 'Vehicle assigned',
      timestamp: new Date(),
    });

    // NOTE: We do NOT mark vehicle/driver as unavailable here anymore
    // They remain available for other trips as long as dates don't conflict
    // The isAvailable flag is only set to false for maintenance/other non-date reasons
    // Date conflicts are checked dynamically when needed

    // Add assigner as participant
    this.addParticipant(request, userId, assignerRole, 'assigned');
    
    // Add driver as participant if assigned
    if (assignDto.driverId) {
      this.addParticipant(request, assignDto.driverId, UserRole.DRIVER, 'assigned');
    }
    
    const savedRequest = await request.save();

    // Prepare assignment details (reuse vehicle already fetched)
    let details = `Vehicle: ${vehicle.plateNumber} (${vehicle.make} ${vehicle.model})`;

    if (assignDto.driverId) {
      const driver = await this.findOneDriver(assignDto.driverId);
      details += `, Driver: ${driver.name}`;

      // Notify driver
      try {
        await this.notificationsService.createNotification(
          assignDto.driverId,
          NotificationType.REQUEST_ASSIGNED,
          'Vehicle Assignment',
          `You have been assigned to vehicle request. Vehicle: ${vehicle.plateNumber}`,
          requestId,
          RequestType.VEHICLE,
        );
      } catch (error) {
        console.error('Error sending driver assignment notification:', error);
      }
    }

    // Notify all participants of workflow progress
    const user = await this.usersService.findOne(userId);
    await this.notifyWorkflowProgress(
      savedRequest,
      'assigned',
      {
        userId,
        name: user.name,
        role: assignerRole,
      },
      `Vehicle assigned by ${user.name} (${assignerRole}). ${details}`,
    );

    // Notify requester (legacy method for backward compatibility)
    try {
      const requesterId = typeof request.requesterId === 'string'
        ? request.requesterId
        : request.requesterId.toString();
      await this.notificationsService.notifyRequestAssigned(
        requesterId,
        RequestType.VEHICLE,
        requestId,
        details,
      );
    } catch (error) {
      console.error('Error sending request assigned notification:', error);
    }

    return savedRequest;
  }

  async correctRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    correctDto: CorrectRequestDto,
  ): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);

    // Get requester to determine correct workflow chain
    const requester = await this.usersService.findOne(request.requesterId.toString());
    
    // Any approver can request corrections
    const workflowChain = this.workflowService.getWorkflowChain(
      requester.level,
      RequestType.VEHICLE,
    );
    const canApprove =
      this.workflowService.canApproveAtStage(userRoles, request.workflowStage, workflowChain) ||
      this.workflowService.canDGSOverride(userRoles);

    if (!canApprove) {
      throw new ForbiddenException('You do not have permission to request corrections');
    }

    // Add correction
    const correction = {
      requestedBy: new Types.ObjectId(userId),
      role: userRoles[0],
      comment: correctDto.comment,
      timestamp: new Date(),
      resolved: false,
    };

    request.corrections.push(correction);
    request.status = RequestStatus.CORRECTED;

    // Update request details if provided
    if (correctDto.tripDate) {
      request.tripDate = new Date(correctDto.tripDate);
    }
    if (correctDto.tripTime) {
      request.tripTime = correctDto.tripTime;
    }
    if (correctDto.destination) {
      request.destination = correctDto.destination;
    }
    if (correctDto.purpose) {
      request.purpose = correctDto.purpose;
    }

    // Add corrector as participant
    this.addParticipant(request, userId, userRoles[0], 'corrected');
    const savedRequest = await request.save();

    // Notify all participants of workflow progress
    const user = await this.usersService.findOne(userId);
    await this.notifyWorkflowProgress(
      savedRequest,
      'corrected',
      {
        userId,
        name: user.name,
        role: userRoles[0],
      },
      `Correction requested by ${user.name} (${userRoles[0]}). ${correctDto.comment || 'No comment provided'}`,
    );

    // Notify requester (legacy method for backward compatibility)
    try {
      const requesterId = typeof request.requesterId === 'string'
        ? request.requesterId
        : request.requesterId.toString();
      await this.notificationsService.notifyCorrectionRequired(
        requesterId,
        RequestType.VEHICLE,
        requestId,
        correctDto.comment || 'No comment provided',
      );
    } catch (error) {
      console.error('Error sending correction required notification:', error);
    }

    return savedRequest;
  }

  async setPriority(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    priority: boolean,
  ): Promise<VehicleRequest> {
    // Only DGS can set priority
    if (!userRoles.includes(UserRole.DGS)) {
      throw new ForbiddenException('Only DGS can set priority');
    }

    const request = await this.findOneRequest(requestId);
    request.priority = priority;
    return request.save();
  }

  async startTrip(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    startTripDto: StartTripDto,
  ): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);

    // Only the assigned driver can start trips
    const driverIdStr = this.getDriverIdFromRequest(request);
    const userIdStr = userId.toString();
    const isDriver = driverIdStr === userIdStr;

    if (!isDriver) {
      console.log(`[startTrip] Driver check failed. Request driverId: ${driverIdStr}, User ID: ${userIdStr}`);
      throw new ForbiddenException('Only the assigned driver can start the trip');
    }

    if (request.status !== RequestStatus.ASSIGNED) {
      throw new BadRequestException('Request must be assigned before starting trip');
    }

    if (request.tripStarted) {
      throw new BadRequestException('Trip has already been started');
    }

    // Record start location (where trip actually begins from)
    // Note: officeLocation should NOT be overwritten - it remains as set during request creation (head office coordinates)
    request.startLocation = {
      latitude: startTripDto.latitude,
      longitude: startTripDto.longitude,
    };
    request.actualDepartureTime = new Date();
    request.tripStarted = true;
    request.status = RequestStatus.ASSIGNED; // Keep as ASSIGNED during trip

    // 🔍 DEBUG: Log location coordinates when starting trip
    console.log('🚀 [START TRIP] Location Coordinates:');
    console.log(`   Request ID: ${requestId}`);
    console.log(`   Office Location: lat=${request.officeLocation?.latitude || 'N/A'}, lng=${request.officeLocation?.longitude || 'N/A'}`);
    console.log(`   Start Location (NEW): lat=${startTripDto.latitude}, lng=${startTripDto.longitude}`);
    console.log(`   Start Location (OLD): lat=${request.startLocation?.latitude || 'N/A'}, lng=${request.startLocation?.longitude || 'N/A'}`);
    console.log(`   Destination Location: lat=${request.requestedDestinationLocation?.latitude || 'N/A'}, lng=${request.requestedDestinationLocation?.longitude || 'N/A'}`);
    console.log(`   Destination Address: ${request.destination || 'N/A'}`);

    const savedRequest = await request.save();

    // Emit WebSocket event
    this.webSocketGateway.emitToRequest(requestId, 'trip:started', {
      requestId,
      location: request.startLocation,
      actualDepartureTime: request.actualDepartureTime,
      scheduledTime: request.tripTime,
    });

    // Also notify requester
    this.webSocketGateway.emitToUser(
      request.requesterId.toString(),
      'trip:started',
      {
        requestId,
        location: request.startLocation,
      },
    );

    return savedRequest;
  }

  async reachDestination(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    reachDestinationDto: ReachDestinationDto,
  ): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);

    // Check if user is the assigned driver or has TO/DGS role
    const driverIdStr = this.getDriverIdFromRequest(request);
    const userIdStr = userId.toString();
    const isDriver = driverIdStr === userIdStr;
    const canReachDestination =
      isDriver || userRoles.includes(UserRole.TO) || userRoles.includes(UserRole.DGS);

    if (!canReachDestination) {
      throw new ForbiddenException('Only the assigned driver or TO/DGS can mark destination reached');
    }

    if (!request.tripStarted) {
      throw new BadRequestException('Trip has not been started yet');
    }

    if (!request.startLocation) {
      throw new BadRequestException('Start location not found');
    }

    // Handle multi-stop trips
    if (reachDestinationDto.stopIndex !== undefined && reachDestinationDto.stopIndex > 0) {
      // This is a waypoint, not the final destination
      return this.reachWaypoint(requestId, userId, userRoles, reachDestinationDto);
    }

    // Check if all waypoints are reached (if multi-stop trip)
    if (request.waypoints && request.waypoints.length > 0) {
      const unreachedWaypoints = request.waypoints.filter((wp) => !wp.reached);
      if (unreachedWaypoints.length > 0) {
        throw new BadRequestException('All waypoints must be reached before marking final destination');
      }
    }

    if (request.destinationReached) {
      throw new BadRequestException('Destination has already been reached');
    }

    // Get the target destination coordinates
    const targetLat = request.requestedDestinationLocation?.latitude as number | undefined;
    const targetLng = request.requestedDestinationLocation?.longitude as number | undefined;

    if (!targetLat || !targetLng) {
      throw new BadRequestException('Destination coordinates not found in request');
    }

    // Check if current location is within 5 meters of destination (accuracy check)
    const distanceToTarget = this.tripTrackingService.calculateDistance(
      reachDestinationDto.latitude,
      reachDestinationDto.longitude,
      targetLat,
      targetLng,
    );

    // 5 meters = 0.005 km
    const ACCURACY_THRESHOLD_KM = 0.005; // 5 meters
    if (distanceToTarget > ACCURACY_THRESHOLD_KM) {
      throw new BadRequestException(
        `You are ${(distanceToTarget * 1000).toFixed(1)} meters away from the destination. Please get within 5 meters to mark destination as reached.`
      );
    }

    // Calculate distance from last location (office or last waypoint)
    let fromLat: number;
    let fromLng: number;

    if (request.waypoints && request.waypoints.length > 0) {
      // Distance from last waypoint to final destination
      const lastWaypoint = request.waypoints[request.waypoints.length - 1];
      fromLat = lastWaypoint.latitude;
      fromLng = lastWaypoint.longitude;
    } else {
      // Distance from office to destination (single-stop trip)
      fromLat = request.startLocation.latitude;
      fromLng = request.startLocation.longitude;
    }

    // 🔍 DEBUG: Log location coordinates when reaching destination
    console.log('🎯 [REACH DESTINATION] Location Coordinates:');
    console.log(`   Request ID: ${requestId}`);
    console.log(`   Office Location: lat=${request.officeLocation?.latitude || 'N/A'}, lng=${request.officeLocation?.longitude || 'N/A'}`);
    console.log(`   Start Location: lat=${request.startLocation?.latitude || 'N/A'}, lng=${request.startLocation?.longitude || 'N/A'}`);
    console.log(`   Target Destination: lat=${targetLat}, lng=${targetLng}`);
    console.log(`   Actual Reached Location: lat=${reachDestinationDto.latitude}, lng=${reachDestinationDto.longitude}`);
    console.log(`   Destination Address: ${request.destination || 'N/A'}`);
    
    // Record destination location (use the actual reached location, not the target)
    request.destinationLocation = {
      latitude: reachDestinationDto.latitude,
      longitude: reachDestinationDto.longitude,
    };
    request.destinationReachedTime = new Date();
    request.destinationReached = true;

    // Calculate distance to final destination
    const distanceToDestination = this.tripTrackingService.calculateDistance(
      fromLat,
      fromLng,
      reachDestinationDto.latitude,
      reachDestinationDto.longitude,
    );

    // Calculate fuel to final destination
    const fuelToDestination = this.tripTrackingService.calculateFuelConsumption(
      distanceToDestination,
    );

    // For single-stop trips, use outboundDistanceKm/outboundFuelLiters
    // For multi-stop trips, calculate total from all legs
    if (request.waypoints && request.waypoints.length > 0) {
      // Multi-stop: sum all waypoint distances + final destination distance
      const waypointDistances = request.waypoints
        .map((wp) => wp.distanceFromPrevious || 0)
        .reduce((sum, dist) => sum + dist, 0);
      request.outboundDistanceKm = waypointDistances + distanceToDestination;

      const waypointFuels = request.waypoints
        .map((wp) => wp.fuelFromPrevious || 0)
        .reduce((sum, fuel) => sum + fuel, 0);
      request.outboundFuelLiters = waypointFuels + fuelToDestination;
    } else {
      // Single-stop: office to destination
      request.outboundDistanceKm = distanceToDestination;
      request.outboundFuelLiters = fuelToDestination;
    }

    const savedRequest = await request.save();

    // Emit WebSocket event
    this.webSocketGateway.emitToRequest(requestId, 'trip:destination:reached', {
      requestId,
      location: request.destinationLocation,
      outboundDistance: request.outboundDistanceKm,
      outboundFuel: request.outboundFuelLiters,
      destinationReachedTime: request.destinationReachedTime,
    });

    // Notify requester
    this.webSocketGateway.emitToUser(
      request.requesterId.toString(),
      'trip:destination:reached',
      {
        requestId,
        location: request.destinationLocation,
      },
    );

    return savedRequest;
  }

  async reachWaypoint(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    reachDestinationDto: ReachDestinationDto,
  ): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);

    // Check if user is the assigned driver or has TO/DGS role
    const driverIdStr = this.getDriverIdFromRequest(request);
    const userIdStr = userId.toString();
    const isDriver = driverIdStr === userIdStr;
    const canReachWaypoint =
      isDriver || userRoles.includes(UserRole.TO) || userRoles.includes(UserRole.DGS);

    if (!canReachWaypoint) {
      throw new ForbiddenException('Only the assigned driver or TO/DGS can mark waypoint reached');
    }

    if (!request.tripStarted) {
      throw new BadRequestException('Trip has not been started yet');
    }

    if (!request.waypoints || request.waypoints.length === 0) {
      throw new BadRequestException('No waypoints defined for this trip');
    }

    const stopIndex = reachDestinationDto.stopIndex || 0;
    if (stopIndex < 1 || stopIndex > request.waypoints.length) {
      throw new BadRequestException('Invalid waypoint index');
    }

    const waypoint = request.waypoints[stopIndex - 1]; // Array is 0-indexed, stopIndex is 1-indexed

    if (waypoint.reached) {
      throw new BadRequestException('This waypoint has already been reached');
    }

    // Check if previous waypoints are reached
    for (let i = 0; i < stopIndex - 1; i++) {
      if (!request.waypoints[i].reached) {
        throw new BadRequestException(`Waypoint ${i + 1} must be reached before waypoint ${stopIndex}`);
      }
    }

    // Calculate distance from previous location
    let fromLat: number;
    let fromLng: number;

    if (stopIndex === 1) {
      // First waypoint: distance from office
      if (!request.startLocation) {
        throw new BadRequestException('Start location not found');
      }
      fromLat = request.startLocation.latitude;
      fromLng = request.startLocation.longitude;
    } else {
      // Subsequent waypoints: distance from previous waypoint
      const previousWaypoint = request.waypoints[stopIndex - 2];
      fromLat = previousWaypoint.latitude;
      fromLng = previousWaypoint.longitude;
    }

    // Calculate distance and fuel from previous location
    const distance = this.tripTrackingService.calculateDistance(
      fromLat,
      fromLng,
      reachDestinationDto.latitude,
      reachDestinationDto.longitude,
    );
    const fuel = this.tripTrackingService.calculateFuelConsumption(distance);

    // Update waypoint
    waypoint.reached = true;
    waypoint.reachedTime = new Date();
    waypoint.distanceFromPrevious = distance;
    waypoint.fuelFromPrevious = fuel;

    // Update current stop index
    request.currentStopIndex = stopIndex;

    const savedRequest = await request.save();

    // Emit WebSocket event
    this.webSocketGateway.emitToRequest(requestId, 'trip:waypoint:reached', {
      requestId,
      waypointIndex: stopIndex,
      waypointName: waypoint.name,
      location: { latitude: reachDestinationDto.latitude, longitude: reachDestinationDto.longitude },
      distance,
      fuel,
    });

    return savedRequest;
  }

  async returnToOffice(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    endTripDto: EndTripDto,
  ): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);

    // Check if user is the assigned driver or has TO/DGS role
    const driverIdStr = this.getDriverIdFromRequest(request);
    const userIdStr = userId.toString();
    const isDriver = driverIdStr === userIdStr;
    const canReturn =
      isDriver || userRoles.includes(UserRole.TO) || userRoles.includes(UserRole.DGS);

    if (!canReturn) {
      throw new ForbiddenException('Only the assigned driver or TO/DGS can mark return to office');
    }

    if (!request.tripStarted) {
      throw new BadRequestException('Trip has not been started yet');
    }

    if (!request.destinationReached) {
      throw new BadRequestException('Destination must be reached before returning to office');
    }

    if (request.tripCompleted) {
      throw new BadRequestException('Trip has already been completed');
    }

    if (!request.destinationLocation || !request.officeLocation) {
      throw new BadRequestException('Destination or office location not found');
    }

    // 🔍 DEBUG: Log location coordinates when returning to office
    console.log('🏢 [RETURN TO OFFICE] Location Coordinates:');
    console.log(`   Request ID: ${requestId}`);
    console.log(`   Office Location: lat=${request.officeLocation?.latitude || 'N/A'}, lng=${request.officeLocation?.longitude || 'N/A'}`);
    console.log(`   Start Location: lat=${request.startLocation?.latitude || 'N/A'}, lng=${request.startLocation?.longitude || 'N/A'}`);
    console.log(`   Destination Location: lat=${request.destinationLocation?.latitude || 'N/A'}, lng=${request.destinationLocation?.longitude || 'N/A'}`);
    console.log(`   Current Location: lat=${endTripDto.latitude}, lng=${endTripDto.longitude}`);
    
    // Check if current location is within 5 meters of office (accuracy check)
    const officeLat = request.officeLocation.latitude as number;
    const officeLng = request.officeLocation.longitude as number;

    const distanceToOffice = this.tripTrackingService.calculateDistance(
      endTripDto.latitude,
      endTripDto.longitude,
      officeLat,
      officeLng,
    );

    // 5 meters = 0.005 km
    const ACCURACY_THRESHOLD_KM = 0.005; // 5 meters
    let warningMessage: string | null = null;
    if (distanceToOffice > ACCURACY_THRESHOLD_KM) {
      // Log warning but allow manual marking
      const distanceMeters = (distanceToOffice * 1000).toFixed(1);
      warningMessage = `You are ${distanceMeters} meters away from the office (recommended: within 5 meters). Manual marking allowed.`;
      console.warn(
        `[returnToOffice] Driver is ${distanceMeters} meters away from office (threshold: 5m). Allowing manual marking.`
      );
    }

    // Record return location (should be office)
    request.returnLocation = {
      latitude: endTripDto.latitude,
      longitude: endTripDto.longitude,
    };
    request.actualReturnTime = new Date();
    request.tripCompleted = true;

    // Calculate return distance (destination back to office)
    const returnDistanceKm = this.tripTrackingService.calculateDistance(
      request.destinationLocation.latitude,
      request.destinationLocation.longitude,
      endTripDto.latitude,
      endTripDto.longitude,
    );
    request.returnDistanceKm = returnDistanceKm;

    // Calculate return fuel consumption
    const returnFuelLiters = this.tripTrackingService.calculateFuelConsumption(returnDistanceKm);
    request.returnFuelLiters = returnFuelLiters;

    // Calculate total distance and fuel (including waypoints if multi-stop)
    let totalOutboundDistance = request.outboundDistanceKm || 0;
    let totalOutboundFuel = request.outboundFuelLiters || 0;

    // If multi-stop trip, sum all waypoint distances/fuels
    if (request.waypoints && request.waypoints.length > 0) {
      const waypointDistances = request.waypoints
        .map((wp) => wp.distanceFromPrevious || 0)
        .reduce((sum, dist) => sum + dist, 0);
      totalOutboundDistance = waypointDistances + (request.outboundDistanceKm || 0);

      const waypointFuels = request.waypoints
        .map((wp) => wp.fuelFromPrevious || 0)
        .reduce((sum, fuel) => sum + fuel, 0);
      totalOutboundFuel = waypointFuels + (request.outboundFuelLiters || 0);
    }

    const totalDistanceKm = totalOutboundDistance + returnDistanceKm;
    request.totalTripDistanceKm = totalDistanceKm;
    request.totalDistanceKm = totalDistanceKm; // Keep for backward compatibility

    const totalFuelLiters = totalOutboundFuel + returnFuelLiters;
    request.totalTripFuelLiters = totalFuelLiters;
    request.totalFuelLiters = totalFuelLiters; // Keep for backward compatibility

    // Update status and make vehicle/driver available again
    request.status = RequestStatus.COMPLETED;

    // Make vehicle available
    if (request.vehicleId) {
      const vehicleIdStr = this.getVehicleIdFromRequest(request);
      if (vehicleIdStr) {
        await this.updateVehicle(vehicleIdStr, { 
          isAvailable: true,
          status: 'available' // Also update status field for frontend display
        });
      }
    }

    // Make driver available
    if (request.driverId) {
      const driverIdStr = this.getDriverIdFromRequest(request);
      if (driverIdStr) {
        await this.updateDriver(driverIdStr, { isAvailable: true });
      }
    }

    const savedRequest = await request.save();

    // Emit WebSocket event
    this.webSocketGateway.emitToRequest(requestId, 'trip:completed', {
      requestId,
      location: request.returnLocation,
      outboundDistance: request.outboundDistanceKm,
      returnDistance: request.returnDistanceKm,
      totalDistance: request.totalDistanceKm,
      outboundFuel: request.outboundFuelLiters,
      returnFuel: request.returnFuelLiters,
      totalFuel: request.totalFuelLiters,
      actualReturnTime: request.actualReturnTime,
      warning: warningMessage, // Include warning if distance exceeds threshold
    });

    // Notify requester
    this.webSocketGateway.emitToUser(
      request.requesterId.toString(),
      'trip:completed',
      {
        requestId,
        totalDistance: request.totalDistanceKm,
        totalFuel: request.totalFuelLiters,
      },
    );

    // Also notify driver when trip completes
    if (request.driverId) {
      const driverIdStr = this.getDriverIdFromRequest(request);
      if (driverIdStr) {
        this.webSocketGateway.emitToUser(
          driverIdStr,
          'trip:completed',
          {
            requestId,
            totalDistance: request.totalDistanceKm,
            totalFuel: request.totalFuelLiters,
          },
        );
      }
    }

    // Return response with warning if applicable
    if (warningMessage) {
      return {
        ...savedRequest.toObject(),
        warning: warningMessage,
      };
    }

    return savedRequest;
  }

  async updateTripLocation(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    updateLocationDto: UpdateLocationDto,
  ): Promise<void> {
    const request = await this.findOneRequest(requestId);

    // Check if user is the assigned driver
    const driverIdStr = this.getDriverIdFromRequest(request);
    const userIdStr = userId.toString();
    const isDriver = driverIdStr === userIdStr;
    if (!isDriver && !userRoles.includes(UserRole.TO) && !userRoles.includes(UserRole.DGS)) {
      throw new ForbiddenException('Only the assigned driver or TO/DGS can update location');
    }

    if (!request.tripStarted) {
      throw new BadRequestException('Trip has not been started yet');
    }

    if (request.tripCompleted) {
      throw new BadRequestException('Trip has already been completed');
    }

    // Emit real-time location update via WebSocket
    this.webSocketGateway.emitToRequest(requestId, 'trip:location:updated', {
      requestId,
      location: {
        latitude: updateLocationDto.latitude,
        longitude: updateLocationDto.longitude,
      },
      timestamp: new Date(),
    });
  }

  async getTripDetails(requestId: string): Promise<VehicleRequest> {
    const request = await this.findOneRequest(requestId);
    return request;
  }

  // Delete all requests (temporary - for testing/cleanup)
  // This deletes ALL request types (vehicle, ICT, store), notifications, and cleans up resources atomically
  async deleteRequest(requestId: string, userId: string, userRoles: UserRole[]): Promise<void> {
    const request = await this.findOneRequest(requestId);
    
    // Check permissions (only DGS or requester can delete)
    const isRequester = request.requesterId.toString() === userId;
    const isDGS = userRoles.includes(UserRole.DGS);
    
    if (!isRequester && !isDGS) {
      throw new ForbiddenException('Only the requester or DGS can delete this request');
    }
    
    // Can't delete if trip has started
    if (request.tripStarted) {
      throw new BadRequestException('Cannot delete a request that has started');
    }
    
    const session = await this.vehicleRequestModel.db.startSession();
    
    try {
      await session.withTransaction(async () => {
        // Free vehicle if assigned
        if (request.vehicleId) {
          await this.vehicleModel.updateOne(
            { _id: request.vehicleId },
            {
              $set: {
                isAvailable: true,
                status: 'available',
                assignedToUserId: null,
              },
            },
            { session }
          ).exec();
        }
        
        // Free driver if assigned
        if (request.driverId) {
          await this.driverModel.updateOne(
            { _id: request.driverId },
            { $set: { isAvailable: true } },
            { session }
          ).exec();
        }
        
        // Delete all notifications related to this request
        await this.notificationModel.deleteMany(
          { requestId: new Types.ObjectId(requestId) },
          { session }
        ).exec();
        
        // Delete the request
        await this.vehicleRequestModel.deleteOne(
          { _id: new Types.ObjectId(requestId) },
          { session }
        ).exec();
      });
    } finally {
      await session.endSession();
    }
  }

  async deleteAllRequests(): Promise<{ 
    message: string; 
    deletedCount: {
      vehicleRequests: number;
      ictRequests: number;
      storeRequests: number;
      notifications: number;
    };
    freedResources: {
      vehicles: number;
      drivers: number;
    };
  }> {
    const session = await this.vehicleRequestModel.db.startSession();
    
    try {
      return await session.withTransaction(async () => {
        // Step 1: Find all vehicle requests with assignments
        const vehicleRequests = await this.vehicleRequestModel
          .find({}, null, { session })
          .exec();

        // Collect vehicle and driver IDs to free up, and all request IDs for notification cleanup
        const vehicleIds = new Set<string>();
        const driverIds = new Set<string>();
        const requestIds = new Set<string>();

        for (const request of vehicleRequests) {
          requestIds.add(request._id.toString());
          
          if (request.vehicleId) {
            const vehicleId = typeof request.vehicleId === 'object' && request.vehicleId !== null
              ? (request.vehicleId._id || request.vehicleId.id || request.vehicleId).toString()
              : request.vehicleId.toString();
            vehicleIds.add(vehicleId);
          }
          
          if (request.driverId) {
            const driverId = typeof request.driverId === 'object' && request.driverId !== null
              ? (request.driverId._id || request.driverId.id || request.driverId).toString()
              : request.driverId.toString();
            driverIds.add(driverId);
          }
        }

        // Step 2: Find all ICT and Store requests
        const ictRequests = await this.ictRequestModel.find({}, null, { session }).exec();
        const storeRequests = await this.storeRequestModel.find({}, null, { session }).exec();

        // Collect ICT and Store request IDs for notification cleanup
        for (const request of ictRequests) {
          requestIds.add(request._id.toString());
        }
        for (const request of storeRequests) {
          requestIds.add(request._id.toString());
        }

        // Step 3: Free up all vehicles (set to available) - use direct update for transaction
        let vehiclesFreed = 0;
        for (const vehicleId of vehicleIds) {
          try {
            await this.vehicleModel.updateOne(
              { _id: new Types.ObjectId(vehicleId) },
              { 
                $set: { 
                  isAvailable: true,
                  status: 'available',
                  assignedToUserId: null
                }
              },
              { session }
            );
            vehiclesFreed++;
          } catch (error) {
            console.error(`Error freeing vehicle ${vehicleId}:`, error);
          }
        }

        // Step 4: Free up all drivers (set to available) - use direct update for transaction
        let driversFreed = 0;
        for (const driverId of driverIds) {
          try {
            await this.driverModel.updateOne(
              { _id: new Types.ObjectId(driverId) },
              { $set: { isAvailable: true } },
              { session }
            );
            driversFreed++;
          } catch (error) {
            console.error(`Error freeing driver ${driverId}:`, error);
          }
        }

        // Step 5: Delete all notifications (related to requests)
        const notificationResult = await this.notificationModel.deleteMany(
          { requestId: { $in: Array.from(requestIds).map(id => new Types.ObjectId(id)) } },
          { session }
        ).exec();

        // Step 6: Delete all requests (within transaction)
        const vehicleResult = await this.vehicleRequestModel.deleteMany({}, { session }).exec();
        const ictResult = await this.ictRequestModel.deleteMany({}, { session }).exec();
        const storeResult = await this.storeRequestModel.deleteMany({}, { session }).exec();

        return {
          message: `All requests deleted successfully. Freed ${vehiclesFreed} vehicle(s) and ${driversFreed} driver(s).`,
          deletedCount: {
            vehicleRequests: vehicleResult.deletedCount || 0,
            ictRequests: ictResult.deletedCount || 0,
            storeRequests: storeResult.deletedCount || 0,
            notifications: notificationResult.deletedCount || 0,
          },
          freedResources: {
            vehicles: vehiclesFreed,
            drivers: driversFreed,
          },
        };
      });
    } finally {
      await session.endSession();
    }
  }

  // Maintenance Operations
  async addMaintenanceReminder(
    vehicleId: string,
    addReminderDto: AddMaintenanceReminderDto,
  ): Promise<VehicleDocument> {
    const vehicle = await this.findOneVehicle(vehicleId);
    const reminder: MaintenanceReminder = {
      ...addReminderDto,
      dueDate: new Date(addReminderDto.dueDate),
      isCompleted: false,
      createdAt: new Date(),
    };
    vehicle.maintenanceReminders.push(reminder);
    return vehicle.save();
  }

  async addMaintenanceLog(
    vehicleId: string,
    addLogDto: AddMaintenanceLogDto,
  ): Promise<VehicleDocument> {
    const vehicle = await this.findOneVehicle(vehicleId);
    const log: MaintenanceLog = {
      ...addLogDto,
      date: new Date(addLogDto.date),
      createdAt: new Date(),
    };
    vehicle.maintenanceLogs.push(log);
    return vehicle.save();
  }

  async reportIssue(
    vehicleId: string,
    userId: string,
    reportIssueDto: ReportVehicleIssueDto,
  ): Promise<VehicleDocument> {
    const vehicle = await this.findOneVehicle(vehicleId);
    const issue: VehicleIssue = {
      ...reportIssueDto,
      reportedDate: new Date(),
      reportedBy: userId,
      status: 'REPORTED',
      createdAt: new Date(),
    };
    vehicle.issues.push(issue);
    return vehicle.save();
  }

  async getMaintenanceHistory(vehicleId: string): Promise<{
    reminders: MaintenanceReminder[];
    logs: MaintenanceLog[];
    issues: VehicleIssue[];
  }> {
    const vehicle = await this.findOneVehicle(vehicleId);
    return {
      reminders: vehicle.maintenanceReminders,
      logs: vehicle.maintenanceLogs,
      issues: vehicle.issues,
    };
  }

  async updateIssueStatus(
    vehicleId: string,
    issueIndex: number,
    status: 'REPORTED' | 'IN_PROGRESS' | 'RESOLVED',
    resolutionNotes?: string,
  ): Promise<VehicleDocument> {
    const vehicle = await this.findOneVehicle(vehicleId);
    if (issueIndex < 0 || issueIndex >= vehicle.issues.length) {
      throw new BadRequestException('Invalid issue index');
    }
    vehicle.issues[issueIndex].status = status;
    if (status === 'RESOLVED') {
      vehicle.issues[issueIndex].resolvedDate = new Date();
      if (resolutionNotes) {
        vehicle.issues[issueIndex].resolutionNotes = resolutionNotes;
      }
    }
    return vehicle.save();
  }

  async completeMaintenanceReminder(
    vehicleId: string,
    reminderIndex: number,
  ): Promise<VehicleDocument> {
    const vehicle = await this.findOneVehicle(vehicleId);
    if (reminderIndex < 0 || reminderIndex >= vehicle.maintenanceReminders.length) {
      throw new BadRequestException('Invalid reminder index');
    }
    vehicle.maintenanceReminders[reminderIndex].isCompleted = true;
    return vehicle.save();
  }

  async deleteVehicle(id: string): Promise<void> {
    const vehicle = await this.vehicleModel.findByIdAndDelete(id).exec();
    if (!vehicle) {
      throw new NotFoundException('Vehicle not found');
    }
  }

  /**
   * Helper method to find approvers for a specific workflow stage
   */
  private async findApproversForStage(
    stage: WorkflowStage,
    departmentId: string,
  ): Promise<UserDocument[]> {
    // Map stage to role
    const roleMap: Record<WorkflowStage, UserRole | null> = {
      [WorkflowStage.SUBMITTED]: null,
      [WorkflowStage.SUPERVISOR_REVIEW]: UserRole.SUPERVISOR,
      [WorkflowStage.DGS_REVIEW]: UserRole.DGS,
      [WorkflowStage.DDGS_REVIEW]: UserRole.DDGS,
      [WorkflowStage.ADGS_REVIEW]: UserRole.ADGS,
      [WorkflowStage.TO_REVIEW]: UserRole.TO,
      [WorkflowStage.DDICT_REVIEW]: UserRole.DDICT,
      [WorkflowStage.SO_REVIEW]: UserRole.SO,
      [WorkflowStage.FULFILLMENT]: null,
    };

    const role = roleMap[stage];
    if (!role) return [];

    // Special handling for supervisors: level 14+ in same department
    // findSupervisorsByDepartment returns ALL level 14+ users (including those with explicit roles)
    // This allows dual capacity - users with explicit roles can also act as supervisors
    if (stage === WorkflowStage.SUPERVISOR_REVIEW) {
      const supervisors = await this.usersService.findSupervisorsByDepartment(departmentId);
      console.log('[Vehicles Service] findApproversForStage: Found', supervisors.length, 'supervisors for department', departmentId);
      return supervisors;
    }

    // Find users with this role
    // For DGS, DDGS, ADGS, TO, DDICT, SO - they might be across departments, so we search all
    if ([UserRole.DGS, UserRole.DDGS, UserRole.ADGS, UserRole.TO, UserRole.DDICT, UserRole.SO].includes(role)) {
      const users = await this.usersService.findAll();
      const roleUsers = users.filter((u) => u.roles.includes(role)) as UserDocument[];
      console.log('[Vehicles Service] findApproversForStage: Found', roleUsers.length, 'users with role', role);
      return roleUsers;
    }

    // For other roles, find by role and department
    const deptUsers = await this.usersService.findByRoleAndDepartment(role, departmentId);
    console.log('[Vehicles Service] findApproversForStage: Found', deptUsers.length, 'users with role', role, 'in department', departmentId);
    return deptUsers;
  }

  /**
   * Find requests where user is a participant
   */
  async findRequestsByParticipant(
    userId: string,
    filters?: {
      status?: RequestStatus;
      action?: 'created' | 'approved' | 'rejected' | 'corrected' | 'assigned' | 'fulfilled';
      workflowStage?: WorkflowStage;
      dateFrom?: Date;
      dateTo?: Date;
    },
  ): Promise<VehicleRequest[]> {
    const query: any = {
      'participants.userId': new Types.ObjectId(userId),
    };

    if (filters?.status) {
      query.status = filters.status;
    }

    if (filters?.workflowStage) {
      query.workflowStage = filters.workflowStage;
    }

    if (filters?.dateFrom || filters?.dateTo) {
      query.createdAt = {};
      if (filters.dateFrom) {
        query.createdAt.$gte = filters.dateFrom;
      }
      if (filters.dateTo) {
        query.createdAt.$lte = filters.dateTo;
      }
    }

    let requests = await this.vehicleRequestModel
      .find(query)
      .populate('requesterId')
      .populate('vehicleId')
      .populate('driverId')
      .sort({ createdAt: -1 })
      .exec();

    // Filter by action if specified
    if (filters?.action) {
      requests = requests.filter((request) =>
        request.participants.some(
          (p) =>
            p.userId.toString() === userId &&
            p.action === filters.action,
        ),
      );
    }

    return requests;
  }

  /**
   * Find request history for role-based users (shows all requests)
   */
  async findRequestHistoryByRole(
    userId: string,
    userRoles: UserRole[],
    filters?: {
      status?: RequestStatus;
      action?: 'created' | 'approved' | 'rejected' | 'corrected' | 'assigned' | 'fulfilled';
      workflowStage?: WorkflowStage;
      dateFrom?: Date;
      dateTo?: Date;
    },
  ): Promise<VehicleRequest[]> {
    const query: any = {};
    // Don't filter by status by default - show all requests for role-based users
    // Users can filter by status if needed via query parameters

    // Allow filtering by specific status
    if (filters?.status) {
      query.status = filters.status;
    }

    if (filters?.workflowStage) {
      query.workflowStage = filters.workflowStage;
    }

    if (filters?.dateFrom || filters?.dateTo) {
      query.createdAt = {};
      if (filters.dateFrom) {
        query.createdAt.$gte = filters.dateFrom;
      }
      if (filters.dateTo) {
        query.createdAt.$lte = filters.dateTo;
      }
    }

    console.log('[Vehicle Service] findRequestHistoryByRole: Query:', JSON.stringify(query));

    let requests = await this.vehicleRequestModel
      .find(query)
      .populate('requesterId')
      .populate('vehicleId')
      .populate('driverId')
      .sort({ createdAt: -1 })
      .exec();

    console.log('[Vehicle Service] findRequestHistoryByRole: Found', requests.length, 'requests');

    // Filter by action if specified (check if user participated with that action)
    if (filters?.action) {
      requests = requests.filter((request) =>
        request.participants.some(
          (p) =>
            p.userId.toString() === userId &&
            p.action === filters.action,
        ),
      );
      console.log('[Vehicle Service] findRequestHistoryByRole: After action filter:', requests.length, 'requests');
    }

    return requests;
  }
}

