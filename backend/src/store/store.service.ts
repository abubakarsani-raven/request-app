import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { StoreItem, StoreItemDocument } from './schemas/store-item.schema';
import { StoreRequest, StoreRequestDocument } from './schemas/store-request.schema';
import { CreateStoreRequestDto } from './dto/create-store-request.dto';
import { CreateStoreItemDto } from './dto/create-store-item.dto';
import { FulfillRequestDto } from './dto/fulfill-request.dto';
import { RouteRequestDto } from './dto/route-request.dto';
import { ApproveRequestDto } from '../vehicles/dto/approve-request.dto';
import { RejectRequestDto } from '../vehicles/dto/reject-request.dto';
import { WorkflowService } from '../workflow/workflow.service';
import { UsersService } from '../users/users.service';
import { NotificationsService } from '../notifications/notifications.service';
import { RequestStatus, WorkflowStage, RequestType, UserRole, NotificationType } from '../shared/types';
import { UserDocument } from '../users/schemas/user.schema';
import { Notification, NotificationDocument } from '../notifications/schemas/notification.schema';
import { UserCapabilityService } from '../common/services/user-capability.service';
import { AdminRoleService } from '../common/services/admin-role.service';

@Injectable()
export class StoreService {
  constructor(
    @InjectModel(StoreItem.name) private storeItemModel: Model<StoreItemDocument>,
    @InjectModel(StoreRequest.name) private storeRequestModel: Model<StoreRequestDocument>,
    @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
    private workflowService: WorkflowService,
    private usersService: UsersService,
    private notificationsService: NotificationsService,
    private capabilityService: UserCapabilityService,
    private adminRoleService: AdminRoleService,
  ) {}

  // Store Item CRUD
  async createItem(createStoreItemDto: CreateStoreItemDto): Promise<StoreItem> {
    const item = new this.storeItemModel(createStoreItemDto);
    return item.save();
  }

  async findAllItems(): Promise<StoreItem[]> {
    return this.storeItemModel.find().exec();
  }

  async findAvailableItems(): Promise<StoreItem[]> {
    return this.storeItemModel.find({ isAvailable: true, quantity: { $gt: 0 } }).exec();
  }

  async findOneItem(id: string): Promise<StoreItemDocument> {
    const item = await this.storeItemModel.findById(id).exec();
    if (!item) {
      throw new NotFoundException('Store item not found');
    }
    return item;
  }

  async updateItem(id: string, updateDto: Partial<CreateStoreItemDto>): Promise<StoreItem> {
    return this.storeItemModel.findByIdAndUpdate(id, updateDto, { new: true }).exec();
  }

  async updateItemAvailability(id: string, isAvailable: boolean): Promise<StoreItem> {
    const item = await this.findOneItem(id);
    item.isAvailable = isAvailable;
    return item.save();
  }

  /**
   * Add participant to request if not already present
   */
  private addParticipant(
    request: StoreRequestDocument,
    userId: string,
    role: UserRole,
    action: 'created' | 'approved' | 'rejected' | 'corrected' | 'fulfilled',
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

  // Store Request CRUD
  async createRequest(
    userId: string,
    createStoreRequestDto: CreateStoreRequestDto,
  ): Promise<StoreRequest> {
    const user = await this.usersService.findOne(userId);
    const workflowChain = this.workflowService.getWorkflowChain(user.level, RequestType.STORE);

    // Validate all items exist and are available
    const requestItems = [];
    for (const itemDto of createStoreRequestDto.items) {
      const item = await this.findOneItem(itemDto.itemId);
      if (!item.isAvailable || item.quantity < itemDto.quantity) {
        throw new BadRequestException(
          `Item ${item.name} is not available in requested quantity`,
        );
      }

      requestItems.push({
        itemId: new Types.ObjectId(itemDto.itemId),
        quantity: itemDto.quantity,
        requestedQuantity: itemDto.quantity,
        fulfilledQuantity: 0,
        isAvailable: item.isAvailable,
      });
    }

    const request = new this.storeRequestModel({
      requesterId: new Types.ObjectId(userId),
      items: requestItems,
      workflowStage: WorkflowStage.SUBMITTED,
      status: RequestStatus.PENDING,
      directToSO: false, // Default, DGS will decide
    });

    // Auto-advance for senior staff (level >= 14): SUBMITTED → DGS_REVIEW
    // This allows senior staff requests to immediately be available for DGS review, skipping supervisor
    if (user.level >= 14) {
      const nextStage = this.workflowService.getNextStage(WorkflowStage.SUBMITTED, workflowChain);
      if (nextStage) {
        request.workflowStage = nextStage;
      }
    }

    // Add requester as participant
    if (!user.roles || user.roles.length === 0) {
      throw new BadRequestException('User must have at least one role to create requests');
    }
    this.addParticipant(request, userId, user.roles[0], 'created');

    // Generate QR code
    const savedRequest = await request.save();
    const qrCode = await this.generateQRCode(savedRequest._id.toString());
    savedRequest.qrCode = qrCode;
    const finalRequest = await savedRequest.save();

    // Notify requester
    try {
      await this.notificationsService.notifyRequestSubmitted(
        userId,
        RequestType.STORE,
        finalRequest._id.toString(),
      );
    } catch (error) {
      console.error('Error sending request submitted notification:', error);
    }

    // Notify next approver(s)
    try {
      const nextStage = finalRequest.workflowStage;
      const approvers = await this.findApproversForStage(nextStage, user.departmentId.toString());
      for (const approver of approvers) {
        // Add approver to participants so they receive workflow progress notifications
        // Use 'created' as placeholder action - will be updated to 'approved' when they approve
        this.addParticipant(finalRequest, approver._id.toString(), approver.roles[0] || UserRole.SUPERVISOR, 'created');
        
        await this.notificationsService.notifyApprovalRequired(
          approver._id.toString(),
          user.name,
          RequestType.STORE,
          finalRequest._id.toString(),
        );
      }
      // Save after adding participants
      await finalRequest.save();
    } catch (error) {
      console.error('Error sending approval required notification:', error);
    }

    return finalRequest;
  }

  async findAllRequests(userId?: string): Promise<StoreRequest[]> {
    const query: any = {};
    if (userId) {
      query.requesterId = new Types.ObjectId(userId);
      console.log('[Store Service] findAllRequests: Querying with userId:', userId);
      console.log('[Store Service] findAllRequests: Query ObjectId:', query.requesterId.toString());
      
      // Log ALL requests in database to compare requesterIds
      const allRequests = await this.storeRequestModel
        .find({})
        .select('_id requesterId createdAt')
        .lean()
        .exec();
      console.log('[Store Service] findAllRequests: Total requests in database:', allRequests.length);
      if (allRequests.length > 0) {
        console.log('[Store Service] findAllRequests: All request requesterIds:');
        allRequests.forEach((req: any, index: number) => {
          const reqId = req.requesterId?.toString() || req.requesterId;
          console.log(`  [${index + 1}] Request ID: ${req._id}, RequesterId: ${reqId}, CreatedAt: ${req.createdAt}`);
        });
      }
    } else {
      console.log('[Store Service] findAllRequests: No userId provided, returning all requests');
    }

    // IMPORTANT: For "My Requests", we should return ALL requests regardless of status
    // Do NOT filter by status - users should see all their requests (pending, approved, completed, etc.)
    let requests = await this.storeRequestModel
      .find(query)
      .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
      .populate('items.itemId')
      .sort({ createdAt: -1 })
      .exec();

    console.log('[Store Service] findAllRequests: Found', requests.length, 'requests matching query (all statuses)');
    if (requests.length > 0) {
      const statusCounts = requests.reduce((acc: any, req: any) => {
        const status = req.status || 'UNKNOWN';
        acc[status] = (acc[status] || 0) + 1;
        return acc;
      }, {});
      console.log('[Store Service] findAllRequests: Status breakdown:', JSON.stringify(statusCounts));
    }
    
    // If no requests found with ObjectId query, try string comparison as fallback
    if (requests.length === 0 && userId) {
      console.log('[Store Service] findAllRequests: Trying fallback string comparison query');
      const allRequests = await this.storeRequestModel
        .find({})
        .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
        .populate('items.itemId')
        .sort({ createdAt: -1 })
        .exec();
      
      requests = allRequests.filter((req) => {
        const reqId = req.requesterId?.toString() || (req.requesterId as any)?._id?.toString() || '';
        const matches = reqId === userId || reqId.toLowerCase() === userId.toLowerCase();
        if (matches) {
          console.log('[Store Service] findAllRequests: Found matching request via string comparison:', req._id.toString(), 'requesterId:', reqId);
        }
        return matches;
      });
      
      console.log('[Store Service] findAllRequests: Found', requests.length, 'requests via string comparison fallback');
    }
    
    if (requests.length > 0) {
      console.log('[Store Service] findAllRequests: First request requesterId:', requests[0].requesterId?.toString());
    } else {
      console.log('[Store Service] findAllRequests: No requests found. User ID being queried:', userId);
      console.log('[Store Service] findAllRequests: NOTE - User ID mismatch detected. Requests may belong to a different user account.');
    }

    return requests;
  }

  async findAllRequestsByRole(userId?: string, userRoles?: UserRole[]): Promise<StoreRequest[]> {
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

    // DGS, ADGS, DDGS, SO: Return ALL store requests (all statuses, all stages)
    if (
      roles.includes(UserRole.DGS) ||
      roles.includes(UserRole.ADGS) ||
      roles.includes(UserRole.DDGS) ||
      roles.includes(UserRole.SO)
    ) {
      return this.storeRequestModel
        .find({})
        .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
        .populate('items.itemId')
        .sort({ createdAt: -1 })
        .exec();
    }

    // SUPERVISOR: level 14+ in same department - Return all store requests from their department
    // Use capability service to check if user can act as supervisor
    if (this.capabilityService.canActAsSupervisor(user, user.roles)) {
      // First, find all requests and populate requesterId, then filter by department
      const allRequests = await this.storeRequestModel
        .find({})
        .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
        .populate('items.itemId')
        .sort({ createdAt: -1 })
        .exec();

      // Filter by department after population
      return allRequests.filter((request) => {
        const requester = request.requesterId as any;
        const requesterDeptId = this.capabilityService.getDepartmentId(requester);
        const userDeptId = this.capabilityService.getDepartmentId(user);
        return requesterDeptId && userDeptId && requesterDeptId === userDeptId;
      });
    }

    // Regular users and other roles: Return only their own requests
    const query: any = { requesterId: new Types.ObjectId(userId) };
    return this.storeRequestModel
      .find(query)
      .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
      .populate('items.itemId')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findPendingApprovals(userId: string, userRoles: UserRole[]): Promise<StoreRequest[]> {
    try {
      const user = await this.usersService.findOne(userId);
      
      if (!user) {
        console.error('[Store Service] findPendingApprovals: User not found:', userId);
        return [];
      }

      // DGS can see all pending approvals (special case)
      if (userRoles.includes(UserRole.DGS)) {
        const requests = await this.storeRequestModel
          .find({
            status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
          })
          .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
          .sort({ createdAt: -1 })
          .exec();
        
        console.log('[Store Service] findPendingApprovals: DGS found', requests.length, 'requests (all pending)');
        return requests;
      }

      // Build optimized query using capability service
      const departmentId = this.capabilityService.getDepartmentId(user);
      const stages = this.capabilityService.getPendingApprovalStages(user, userRoles, RequestType.STORE);
      
      if (stages.length === 0) {
        console.log('[Store Service] findPendingApprovals: No stages found for user');
        return [];
      }

      // Build query conditions
      const queryConditions: any[] = [];
      const canActAsSupervisor = this.capabilityService.canActAsSupervisor(user, userRoles);

      for (const stage of stages) {
        if (stage === WorkflowStage.SUPERVISOR_REVIEW && canActAsSupervisor) {
          // Supervisor requests need department matching
          if (departmentId) {
            queryConditions.push({
              workflowStage: stage,
              status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
            });
          }
        } else if (stage === WorkflowStage.FULFILLMENT) {
          // FULFILLMENT stage needs special handling (will filter for unfulfilled items after query)
          queryConditions.push({
            status: RequestStatus.APPROVED,
            workflowStage: stage,
          });
        } else {
          // Role-based stages (DDGS_REVIEW, ADGS_REVIEW, SO_REVIEW)
          queryConditions.push({
            workflowStage: stage,
            status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
          });
        }
      }

      const query = queryConditions.length > 0 ? { $or: queryConditions } : { _id: { $exists: false } };

      // Execute single optimized query
      const allRequests = await this.storeRequestModel
        .find(query)
        .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
        .sort({ createdAt: -1 })
        .exec();

      // Use Map for deduplication (preserves populated fields)
      const requestMap = new Map<string, StoreRequestDocument>();
      
      // Count requests by stage for logging
      const stageCounts: Record<string, number> = {};

      for (const request of allRequests) {
        const requestId = request._id.toString();
        const requestStage = request.workflowStage;
        
        // Handle supervisor requests - need department matching
        if (requestStage === WorkflowStage.SUPERVISOR_REVIEW) {
          if (!canActAsSupervisor) {
            continue; // Skip if user can't act as supervisor
          }
          
          const requester = request.requesterId as any;
          if (!requester) {
            continue; // Skip if requester not populated
          }
          
          const requesterDeptId = this.capabilityService.getDepartmentId(requester);
          
          if (requesterDeptId && departmentId && requesterDeptId === departmentId) {
            requestMap.set(requestId, request);
            stageCounts[WorkflowStage.SUPERVISOR_REVIEW] = (stageCounts[WorkflowStage.SUPERVISOR_REVIEW] || 0) + 1;
          }
        } else if (requestStage === WorkflowStage.FULFILLMENT) {
          // Filter FULFILLMENT requests to only include those with unfulfilled items
          const hasUnfulfilledItems = request.items.some((item) => {
            return item.fulfilledQuantity < item.requestedQuantity;
          });
          
          if (hasUnfulfilledItems) {
            requestMap.set(requestId, request);
            stageCounts[WorkflowStage.FULFILLMENT] = (stageCounts[WorkflowStage.FULFILLMENT] || 0) + 1;
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
      
      console.log('[Store Service] findPendingApprovals:');
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
      console.error('[Store Service] findPendingApprovals: Error fetching pending approvals:', error);
      
      // Handle specific error types
      if (error instanceof NotFoundException) {
        console.error('[Store Service] findPendingApprovals: User not found');
        return [];
      }
      
      // For database errors, log and return empty array
      console.error('[Store Service] findPendingApprovals: Database error:', error.message);
      return [];
    }
  }

  async findOneRequest(id: string): Promise<StoreRequestDocument> {
    const request = await this.storeRequestModel
      .findById(id)
      .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
      .populate('items.itemId')
      .exec();

    if (!request) {
      throw new NotFoundException('Store request not found');
    }

    return request;
  }

  async approveRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    approveDto: ApproveRequestDto,
  ): Promise<StoreRequest> {
    const request = await this.findOneRequest(requestId);
    const user = await this.usersService.findOne(userId);

    // Check if this is an admin approval override
    const isAdminApproval = approveDto.isAdminApproval && this.adminRoleService.canApproveAll(userRoles);
    
    const workflowChain = this.workflowService.getWorkflowChain(user.level, RequestType.STORE);
    const canApprove = isAdminApproval ||
      this.workflowService.canApproveAtStage(userRoles, request.workflowStage, workflowChain) ||
      this.workflowService.canDGSOverride(userRoles);

    if (!canApprove) {
      throw new ForbiddenException('You do not have permission to approve this request');
    }

    const approval = {
      approverId: new Types.ObjectId(userId),
      role: userRoles[0],
      status: 'APPROVED' as const,
      comment: approveDto.comment,
      timestamp: new Date(),
    };

    request.approvals.push(approval);
    
    // Add approver as participant
    this.addParticipant(request, userId, userRoles[0], 'approved');

    // Advance to next stage (chain includes DGS → DDGS → ADGS → SO → FULFILLMENT; DGS can skip to SO via routeRequest)
    let nextStage = this.workflowService.getNextStage(request.workflowStage, workflowChain);
    if (nextStage) {
      request.workflowStage = nextStage;
      // When moving to FULFILLMENT, set status APPROVED so SO can fulfill
      if (nextStage === WorkflowStage.FULFILLMENT) {
        request.status = RequestStatus.APPROVED;
      }
    } else {
      request.status = RequestStatus.APPROVED;
    }

    const savedRequest = await request.save();

    // Get requester
    const requester = await this.usersService.findOne(request.requesterId.toString());

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
        request.requesterId.toString(),
        RequestType.STORE,
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
          // Add approver to participants so they receive workflow progress notifications
          // Use 'created' as placeholder action - will be updated to 'approved' when they approve
          this.addParticipant(savedRequest, approver._id.toString(), approver.roles[0] || UserRole.SUPERVISOR, 'created');
          
          await this.notificationsService.notifyApprovalRequired(
            approver._id.toString(),
            requester.name,
            RequestType.STORE,
            requestId,
          );
        }
        // Save after adding participants
        await savedRequest.save();
      } catch (error) {
        console.error('Error sending approval required notification:', error);
      }
    }

    return savedRequest;
  }

  async routeRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    routeDto: RouteRequestDto,
  ): Promise<StoreRequest> {
    // Only DGS can route
    if (!userRoles.includes(UserRole.DGS)) {
      throw new ForbiddenException('Only DGS can route requests');
    }

    const request = await this.findOneRequest(requestId);

    if (request.workflowStage !== WorkflowStage.DGS_REVIEW) {
      throw new BadRequestException('Request is not at DGS review stage');
    }

    request.directToSO = routeDto.directToSO;

    if (routeDto.directToSO) {
      // Route directly to SO
      request.workflowStage = WorkflowStage.SO_REVIEW;
    } else {
      // Route through DDGS → ADGS → SO
      request.workflowStage = WorkflowStage.DDGS_REVIEW;
    }

    return request.save();
  }

  async rejectRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    rejectDto: RejectRequestDto,
  ): Promise<StoreRequest> {
    const request = await this.findOneRequest(requestId);
    const user = await this.usersService.findOne(userId);

    const workflowChain = this.workflowService.getWorkflowChain(user.level, RequestType.STORE);
    const canApprove =
      this.workflowService.canApproveAtStage(userRoles, request.workflowStage, workflowChain) ||
      this.workflowService.canDGSOverride(userRoles);

    if (!canApprove) {
      throw new ForbiddenException('You do not have permission to reject this request');
    }

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
        request.requesterId.toString(),
        RequestType.STORE,
        requestId,
        rejectDto.comment || 'No comment provided',
      );
    } catch (error) {
      console.error('Error sending request rejected notification:', error);
    }

    return savedRequest;
  }

  /**
   * Cancel a store request
   * Only allowed if:
   * - Workflow stage is SUBMITTED (workflow hasn't started)
   * - User is Supervisor (for lower level officers) or DGS (for higher level officers)
   */
  async cancelRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    cancelDto: { reason?: string },
  ): Promise<StoreRequest> {
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

    // Create appropriate notification message
    const notificationMessage = isRequester
      ? `Request cancelled by requester ${user.name}. ${cancelDto.reason ? `Reason: ${cancelDto.reason}` : 'No reason provided.'}`
      : `Request cancelled by ${user.name} (${cancelerRole}). ${cancelDto.reason ? `Reason: ${cancelDto.reason}` : 'No reason provided.'}`;

    // Notify all participants (use 'rejected' action type)
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

  async deleteRequest(requestId: string, userId: string, userRoles: UserRole[]): Promise<void> {
    const request = await this.findOneRequest(requestId);
    
    // Check permissions (only DGS or requester can delete)
    const isRequester = request.requesterId.toString() === userId;
    const isDGS = userRoles.includes(UserRole.DGS);
    
    if (!isRequester && !isDGS) {
      throw new ForbiddenException('Only the requester or DGS can delete this request');
    }
    
    // Can't delete if already fulfilled
    if (request.status === RequestStatus.FULFILLED) {
      throw new BadRequestException('Cannot delete a request that has been fulfilled');
    }
    
    const session = await this.storeRequestModel.db.startSession();
    
    try {
      await session.withTransaction(async () => {
        // Delete all notifications related to this request
        await this.notificationModel.deleteMany(
          { requestId: new Types.ObjectId(requestId) },
          { session }
        ).exec();
        
        // Delete the request
        await this.storeRequestModel.deleteOne(
          { _id: new Types.ObjectId(requestId) },
          { session }
        ).exec();
      });
    } finally {
      await session.endSession();
    }
  }

  async fulfillRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    fulfillDto: FulfillRequestDto,
  ): Promise<StoreRequest> {
    // Only SO can fulfill
    if (!userRoles.includes(UserRole.SO)) {
      throw new ForbiddenException('Only Store Officer can fulfill requests');
    }

    const request = await this.findOneRequest(requestId);

    if (request.status !== RequestStatus.APPROVED) {
      throw new BadRequestException('Request must be approved before fulfillment');
    }

    // Process fulfillment for each item
    for (const fulfillmentItem of fulfillDto.items) {
      const requestItem = request.items.find(
        (item) => item.itemId.toString() === fulfillmentItem.itemId,
      );

      if (!requestItem) {
        throw new NotFoundException(`Item ${fulfillmentItem.itemId} not found in request`);
      }

      const item = await this.findOneItem(fulfillmentItem.itemId);

      // Check availability
      if (item.quantity < fulfillmentItem.quantityFulfilled) {
        throw new BadRequestException(
          `Insufficient quantity for item ${item.name}. Available: ${item.quantity}`,
        );
      }

      // Update item quantity
      item.quantity -= fulfillmentItem.quantityFulfilled;
      await item.save();

      // Update request item fulfillment
      requestItem.fulfilledQuantity += fulfillmentItem.quantityFulfilled;
      requestItem.isAvailable = item.quantity > 0;

      // Record fulfillment status
      request.fulfillmentStatus.push({
        itemId: new Types.ObjectId(fulfillmentItem.itemId),
        quantityFulfilled: fulfillmentItem.quantityFulfilled,
        fulfilledAt: new Date(),
        fulfilledBy: new Types.ObjectId(userId),
      });
    }

    // Check if all items are fully fulfilled
    const allFulfilled = request.items.every(
      (item) => item.fulfilledQuantity >= item.requestedQuantity,
    );

    if (allFulfilled) {
      request.status = RequestStatus.FULFILLED;
    } else {
      request.status = RequestStatus.PARTIAL_FULFILLMENT; // Partial fulfillment
    }
    
    // Add fulfiller as participant
    this.addParticipant(request, userId, userRoles[0], 'fulfilled');

    const savedRequest = await request.save();

    // Notify requester of fulfillment
    const user = await this.usersService.findOne(userId);
    await this.notifyWorkflowProgress(
      savedRequest,
      'fulfilled',
      {
        userId,
        name: user.name,
        role: userRoles[0],
      },
      `Request ${allFulfilled ? 'fully fulfilled' : 'partially fulfilled'} by ${user.name} (${userRoles[0]}).`,
    );

    // Notify requester (legacy method)
    try {
      await this.notificationsService.createNotification(
        request.requesterId.toString(),
        NotificationType.REQUEST_FULFILLED,
        'Store Request Fulfilled',
        `Your Store request has been ${allFulfilled ? 'fully fulfilled' : 'partially fulfilled'}.`,
        requestId,
        RequestType.STORE,
      );
    } catch (error) {
      console.error('Error sending fulfillment notification:', error);
    }

    return savedRequest;
  }

  /**
   * Notify all participants of workflow progress
   */
  private async notifyWorkflowProgress(
    request: StoreRequestDocument,
    action: 'approved' | 'rejected' | 'fulfilled',
    actionBy: { userId: string; name: string; role: string },
    message: string,
  ): Promise<void> {
    try {
      // Get all unique participant IDs (use participants array like Vehicle service)
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
        requestType: RequestType.STORE,
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
            this.getNotificationTitleForAction(action, RequestType.STORE),
            message,
            request._id.toString(),
            RequestType.STORE,
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
    action: 'approved' | 'rejected' | 'fulfilled',
  ): NotificationType {
    switch (action) {
      case 'approved':
        return NotificationType.REQUEST_APPROVED;
      case 'rejected':
        return NotificationType.REQUEST_REJECTED;
      case 'fulfilled':
        return NotificationType.REQUEST_FULFILLED;
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
      case 'fulfilled':
        return `${requestType} Request Fulfilled`;
      default:
        return `${requestType} Request Update`;
    }
  }

  async setPriority(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    priority: boolean,
  ): Promise<StoreRequest> {
    // Only DGS can set priority for store requests
    if (!userRoles.includes(UserRole.DGS)) {
      throw new ForbiddenException('Only DGS can set priority for store requests');
    }

    const request = await this.findOneRequest(requestId);
    request.priority = priority;
    return request.save();
  }

  private async generateQRCode(requestId: string): Promise<string> {
    const qrData = `STORE-${requestId}-${Date.now()}`;
    return qrData; // In production, generate actual QR code image
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
      console.log('[Store Service] findApproversForStage: Found', supervisors.length, 'supervisors for department', departmentId);
      return supervisors;
    }

    // Find users with this role
    // For DGS, DDGS, ADGS, TO, DDICT, SO - they might be across departments, so we search all
    if ([UserRole.DGS, UserRole.DDGS, UserRole.ADGS, UserRole.TO, UserRole.DDICT, UserRole.SO].includes(role)) {
      const users = await this.usersService.findAll();
      const roleUsers = users.filter((u) => u.roles.includes(role)) as UserDocument[];
      console.log('[Store Service] findApproversForStage: Found', roleUsers.length, 'users with role', role);
      return roleUsers;
    }

    // For other roles, find by role and department
    const deptUsers = await this.usersService.findByRoleAndDepartment(role, departmentId);
    console.log('[Store Service] findApproversForStage: Found', deptUsers.length, 'users with role', role, 'in department', departmentId);
    return deptUsers;
  }

  /**
   * Find requests where user is a participant
   */
  async findRequestsByParticipant(
    userId: string,
    filters?: {
      status?: RequestStatus;
      action?: 'created' | 'approved' | 'rejected' | 'corrected' | 'fulfilled';
      workflowStage?: WorkflowStage;
      dateFrom?: Date;
      dateTo?: Date;
    },
  ): Promise<StoreRequest[]> {
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

    let requests = await this.storeRequestModel
      .find(query)
      .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
      .populate('items.itemId')
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
      action?: 'created' | 'approved' | 'rejected' | 'corrected' | 'fulfilled';
      workflowStage?: WorkflowStage;
      dateFrom?: Date;
      dateTo?: Date;
    },
  ): Promise<StoreRequest[]> {
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

    console.log('[Store Service] findRequestHistoryByRole: Query:', JSON.stringify(query));

    let requests = await this.storeRequestModel
      .find(query)
      .populate({ path: 'requesterId', populate: { path: 'departmentId', select: 'name' } })
      .populate('items.itemId')
      .sort({ createdAt: -1 })
      .exec();

    console.log('[Store Service] findRequestHistoryByRole: Found', requests.length, 'requests');

    // Filter by action if specified (check if user participated with that action)
    if (filters?.action) {
      requests = requests.filter((request) =>
        request.participants.some(
          (p) =>
            p.userId.toString() === userId &&
            p.action === filters.action,
        ),
      );
      console.log('[Store Service] findRequestHistoryByRole: After action filter:', requests.length, 'requests');
    }

    return requests;
  }
}

