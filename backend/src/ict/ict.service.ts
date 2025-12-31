import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ICTItem, ICTItemDocument } from './schemas/ict-item.schema';
import { ICTRequest, ICTRequestDocument } from './schemas/ict-request.schema';
import { StockHistory, StockHistoryDocument, StockOperation } from './schemas/stock-history.schema';
import { CreateICTRequestDto } from './dto/create-ict-request.dto';
import { CreateICTItemDto } from './dto/create-ict-item.dto';
import { UpdateICTItemDto } from './dto/update-ict-item.dto';
import { UpdateQuantityDto, QuantityOperation } from './dto/update-quantity.dto';
import { FulfillRequestDto } from './dto/fulfill-request.dto';
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
import * as QRCode from 'qrcode';

@Injectable()
export class ICTService {
  constructor(
    @InjectModel(ICTItem.name) private ictItemModel: Model<ICTItemDocument>,
    @InjectModel(ICTRequest.name) private ictRequestModel: Model<ICTRequestDocument>,
    @InjectModel(StockHistory.name) private stockHistoryModel: Model<StockHistoryDocument>,
    @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
    private workflowService: WorkflowService,
    private usersService: UsersService,
    private notificationsService: NotificationsService,
    private capabilityService: UserCapabilityService,
    private adminRoleService: AdminRoleService,
  ) {}

  // ICT Item CRUD
  async createItem(createICTItemDto: CreateICTItemDto): Promise<ICTItem> {
    const item = new this.ictItemModel(createICTItemDto);
    return item.save();
  }

  async findAllItems(category?: string): Promise<ICTItem[]> {
    const query: any = {};
    if (category) {
      query.category = category;
    }
    return this.ictItemModel.find(query).exec();
  }

  async findAvailableItems(category?: string): Promise<ICTItem[]> {
    const query: any = { isAvailable: true, quantity: { $gt: 0 } };
    if (category) {
      query.category = category;
    }
    return this.ictItemModel.find(query).exec();
  }

  async findOneItem(id: string): Promise<ICTItemDocument> {
    const item = await this.ictItemModel.findById(id).exec();
    if (!item) {
      throw new NotFoundException('ICT item not found');
    }
    return item;
  }

  async updateItem(id: string, updateDto: UpdateICTItemDto): Promise<ICTItem> {
    const item = await this.findOneItem(id);
    Object.assign(item, updateDto);
    return item.save();
  }

  async updateItemAvailability(id: string, isAvailable: boolean): Promise<ICTItem> {
    const item = await this.findOneItem(id);
    item.isAvailable = isAvailable;
    return item.save();
  }

  async updateItemQuantity(
    id: string,
    updateQuantityDto: UpdateQuantityDto,
    userId: string,
  ): Promise<ICTItem> {
    const item = await this.findOneItem(id);
    const previousQuantity = item.quantity;
    let newQuantity: number;

    switch (updateQuantityDto.operation) {
      case QuantityOperation.ADD:
        newQuantity = previousQuantity + updateQuantityDto.quantity;
        break;
      case QuantityOperation.REMOVE:
        newQuantity = previousQuantity - updateQuantityDto.quantity;
        if (newQuantity < 0) {
          throw new BadRequestException('Insufficient quantity. Cannot remove more than available.');
        }
        break;
      case QuantityOperation.ADJUST:
        newQuantity = updateQuantityDto.quantity;
        if (newQuantity < 0) {
          throw new BadRequestException('Quantity cannot be negative.');
        }
        break;
      default:
        throw new BadRequestException('Invalid operation');
    }

    const changeAmount = newQuantity - previousQuantity;
    item.quantity = newQuantity;

    // Update availability based on quantity
    if (newQuantity === 0) {
      item.isAvailable = false;
    } else if (previousQuantity === 0 && newQuantity > 0) {
      item.isAvailable = true;
    }

    await item.save();

    // Create stock history entry
    const stockHistory = new this.stockHistoryModel({
      itemId: new Types.ObjectId(id),
      previousQuantity,
      newQuantity,
      changeAmount,
      operation: this.mapQuantityOperationToStockOperation(updateQuantityDto.operation),
      reason: updateQuantityDto.reason,
      performedBy: new Types.ObjectId(userId),
    });
    await stockHistory.save();

    // Check for low stock and send notification if needed
    await this.checkAndNotifyLowStock(item);

    return item;
  }

  private mapQuantityOperationToStockOperation(
    operation: QuantityOperation,
  ): StockOperation {
    switch (operation) {
      case QuantityOperation.ADD:
        return StockOperation.ADD;
      case QuantityOperation.REMOVE:
        return StockOperation.REMOVE;
      case QuantityOperation.ADJUST:
        return StockOperation.ADJUST;
      default:
        return StockOperation.ADJUST;
    }
  }

  async getStockHistory(itemId: string): Promise<StockHistory[]> {
    return this.stockHistoryModel
      .find({ itemId: new Types.ObjectId(itemId) })
      .populate('performedBy', 'name email')
      .populate('requestId', '_id')
      .sort({ createdAt: -1 })
      .exec();
  }

  async getLowStockItems(): Promise<ICTItem[]> {
    return this.ictItemModel
      .find({
        $expr: {
          $lte: ['$quantity', '$lowStockThreshold'],
        },
        isAvailable: true,
      })
      .exec();
  }

  async bulkCreateItems(items: CreateICTItemDto[]): Promise<{ created: number; errors: any[] }> {
    const errors: any[] = [];
    let created = 0;

    for (let i = 0; i < items.length; i++) {
      try {
        await this.createItem(items[i]);
        created++;
      } catch (error: any) {
        errors.push({
          index: i,
          item: items[i],
          error: error.message,
        });
      }
    }

    return { created, errors };
  }

  async deleteItem(id: string): Promise<void> {
    const item = await this.findOneItem(id);

    // Check if item is referenced in any active requests
    const activeRequests = await this.ictRequestModel.find({
      'items.itemId': new Types.ObjectId(id),
      status: { $in: [RequestStatus.PENDING, RequestStatus.APPROVED] },
    }).exec();

    if (activeRequests.length > 0) {
      throw new BadRequestException(
        `Cannot delete item. It is referenced in ${activeRequests.length} active request(s).`,
      );
    }

    // Soft delete by setting isAvailable to false and quantity to 0
    // Or hard delete if preferred
    item.isAvailable = false;
    item.quantity = 0;
    await item.save();

    // Alternatively, hard delete:
    // await this.ictItemModel.findByIdAndDelete(id).exec();
  }

  /**
   * Add participant to request if not already present
   */
  private addParticipant(
    request: ICTRequestDocument,
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

  private async checkAndNotifyLowStock(item: ICTItemDocument): Promise<void> {
    if (item.quantity <= item.lowStockThreshold && item.isAvailable) {
      // Get users who should be notified (DDICT, DGS, SO)
      const users = await this.usersService.findAll();
      const notifiedUsers = users.filter((user) =>
        user.roles.some((role) =>
          [UserRole.DDICT, UserRole.DGS, UserRole.SO].includes(role),
        ),
      );

      for (const user of notifiedUsers) {
        try {
          const userId = (user as any)._id?.toString() || (user as any).id?.toString();
          if (!userId) continue;
          
          await this.notificationsService.createNotification(
            userId,
            NotificationType.LOW_STOCK,
            'Low Stock Alert',
            `Item "${item.name}" is running low. Current quantity: ${item.quantity}, Threshold: ${item.lowStockThreshold}`,
            undefined,
            RequestType.ICT,
            true,
          );
        } catch (error) {
          const userId = (user as any)._id?.toString() || (user as any).id?.toString();
          console.error(`Error sending low stock notification to user ${userId}:`, error);
        }
      }
    }
  }

  // ICT Request CRUD
  async createRequest(
    userId: string,
    createICTRequestDto: CreateICTRequestDto,
  ): Promise<ICTRequest> {
    console.log('[ICT Service] createRequest: Creating request with userId:', userId);
    console.log('[ICT Service] createRequest: userId type:', typeof userId);
    console.log('[ICT Service] createRequest: userId length:', userId?.length);
    
    const user = await this.usersService.findOne(userId);
    // UserDocument extends Document which has _id, cast to access it
    const userDoc = user as any;
    const userIdFromDoc = userDoc._id?.toString() || userDoc.id?.toString() || userId;
    console.log('[ICT Service] createRequest: User found - ID:', userIdFromDoc, 'Email:', user.email, 'Name:', user.name);
    const workflowChain = this.workflowService.getWorkflowChain(user.level, RequestType.ICT);

    // Validate all items exist and allow partial fulfillment
    const requestItems = [];
    for (const itemDto of createICTRequestDto.items) {
      const item = await this.findOneItem(itemDto.itemId);
      
      // Check if item exists
      if (!item) {
        throw new BadRequestException(`Item with ID ${itemDto.itemId} not found`);
      }
      
      // Allow request even if item is not available or quantity is insufficient
      // The request will be created and can be fulfilled partially later
      const availableQuantity = item.isAvailable ? item.quantity : 0;
      const requestQuantity = itemDto.quantity;
      
      // Log if partial fulfillment is needed
      if (!item.isAvailable) {
        console.log(`[ICT Service] createRequest: Item ${item.name} is not available, but request will be created for future fulfillment`);
      } else if (availableQuantity < requestQuantity) {
        console.log(`[ICT Service] createRequest: Item ${item.name} - Requested: ${requestQuantity}, Available: ${availableQuantity}, Will be fulfilled partially`);
      }

      requestItems.push({
        itemId: new Types.ObjectId(itemDto.itemId),
        quantity: requestQuantity, // Store the requested quantity
        requestedQuantity: requestQuantity, // Keep track of what was requested
        fulfilledQuantity: 0, // Will be updated during fulfillment
        isAvailable: item.isAvailable, // Track availability status
      });
    }

    const requesterObjectId = new Types.ObjectId(userId);
    console.log('[ICT Service] createRequest: Storing requesterId as ObjectId:', requesterObjectId.toString());
    
    const request = new this.ictRequestModel({
      comment: createICTRequestDto.notes,
      requesterId: requesterObjectId,
      items: requestItems,
      workflowStage: WorkflowStage.SUBMITTED,
      status: RequestStatus.PENDING,
    });

    // Auto-advance to next stage: SUBMITTED → DDICT_REVIEW (for level 14+) or SUPERVISOR_REVIEW (for level < 14)
    // This allows requests to immediately be available for the next approver
    const nextStage = this.workflowService.getNextStage(WorkflowStage.SUBMITTED, workflowChain);
    if (nextStage) {
      request.workflowStage = nextStage;
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
        RequestType.ICT,
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
        await this.notificationsService.notifyApprovalRequired(
          approver._id.toString(),
          user.name,
          RequestType.ICT,
          finalRequest._id.toString(),
        );
      }
    } catch (error) {
      console.error('Error sending approval required notification:', error);
    }

    return finalRequest;
  }

  async findAllRequests(userId?: string): Promise<ICTRequest[]> {
    const query: any = {};
    if (userId) {
      // Try both ObjectId and string comparison to handle any format issues
      try {
        query.requesterId = new Types.ObjectId(userId);
        console.log('[ICT Service] findAllRequests: Querying with userId:', userId);
        console.log('[ICT Service] findAllRequests: Query ObjectId:', query.requesterId.toString());
      } catch (e) {
        // If ObjectId conversion fails, try string comparison
        console.log('[ICT Service] findAllRequests: ObjectId conversion failed, using string:', userId);
        query.requesterId = userId;
      }
      
      // Log ALL requests in database to compare requesterIds
      const allRequests = await this.ictRequestModel
        .find({})
        .select('_id requesterId createdAt')
        .lean()
        .exec();
      console.log('[ICT Service] findAllRequests: Total requests in database:', allRequests.length);
      if (allRequests.length > 0) {
        console.log('[ICT Service] findAllRequests: All request requesterIds:');
        allRequests.forEach((req: any, index: number) => {
          const reqId = req.requesterId?.toString() || req.requesterId;
          const matches = reqId === userId || reqId === query.requesterId?.toString();
          console.log(`  [${index + 1}] Request ID: ${req._id}, RequesterId: ${reqId}, CreatedAt: ${req.createdAt}, Matches: ${matches}`);
        });
      }
    } else {
      console.log('[ICT Service] findAllRequests: No userId provided, returning all requests');
    }

    // IMPORTANT: For "My Requests", we should return ALL requests regardless of status
    // Do NOT filter by status - users should see all their requests (pending, approved, completed, etc.)
    let requests = await this.ictRequestModel
      .find(query)
      .populate('requesterId')
      .populate('items.itemId')
      .sort({ createdAt: -1 })
      .exec();

    console.log('[ICT Service] findAllRequests: Found', requests.length, 'requests matching query (all statuses)');
    if (requests.length > 0) {
      const statusCounts = requests.reduce((acc: any, req: any) => {
        const status = req.status || 'UNKNOWN';
        acc[status] = (acc[status] || 0) + 1;
        return acc;
      }, {});
      console.log('[ICT Service] findAllRequests: Status breakdown:', JSON.stringify(statusCounts));
    }
    
    // If no requests found with ObjectId query, try fallback methods
    if (requests.length === 0 && userId) {
      console.log('[ICT Service] findAllRequests: Trying fallback queries');
      const allRequests = await this.ictRequestModel
        .find({})
        .populate('requesterId')
        .populate('items.itemId')
        .sort({ createdAt: -1 })
        .exec();
      
      // Fallback 1: String comparison on requesterId
      let stringMatched = allRequests.filter((req) => {
        const reqId = req.requesterId?.toString() || (req.requesterId as any)?._id?.toString() || '';
        const matches = reqId === userId || reqId.toLowerCase() === userId.toLowerCase();
        if (matches) {
          console.log('[ICT Service] findAllRequests: Found matching request via string comparison:', req._id.toString(), 'requesterId:', reqId);
        }
        return matches;
      });
      
      // Fallback 2: Check participants array for user with 'created' action
      // This handles cases where requesterId might be wrong but participant tracking is correct
      const participantMatched = allRequests.filter((req) => {
        if (!req.participants || req.participants.length === 0) return false;
        const userObjectId = new Types.ObjectId(userId);
        const isCreator = req.participants.some(
          (p) => p.userId.toString() === userObjectId.toString() && p.action === 'created'
        );
        if (isCreator) {
          console.log('[ICT Service] findAllRequests: Found matching request via participants (created):', req._id.toString());
        }
        return isCreator;
      });
      
      // Combine both fallback results, removing duplicates
      const allMatched = [...stringMatched, ...participantMatched];
      const uniqueMatched = allMatched.filter((req, index, self) => 
        index === self.findIndex((r) => r._id.toString() === req._id.toString())
      );
      
      requests = uniqueMatched;
      console.log('[ICT Service] findAllRequests: Found', requests.length, 'requests via fallback methods (string:', stringMatched.length, 'participants:', participantMatched.length, ')');
    }
    
    if (requests.length > 0) {
      console.log('[ICT Service] findAllRequests: First request requesterId:', requests[0].requesterId?.toString());
    } else {
      console.log('[ICT Service] findAllRequests: No requests found. User ID being queried:', userId);
      console.log('[ICT Service] findAllRequests: Query used:', JSON.stringify(query));
      console.log('[ICT Service] findAllRequests: NOTE - User ID mismatch detected. Requests may belong to a different user account.');
      
      // Check if there are requests with a very similar user ID (might be same user, different session)
      const similarUserId = userId.slice(0, -1) + (userId.slice(-1) === 'f' ? 'b' : 'f');
      console.log('[ICT Service] findAllRequests: Checking for similar user ID:', similarUserId);
      const similarRequests = await this.ictRequestModel
        .find({ requesterId: new Types.ObjectId(similarUserId) })
        .select('_id requesterId createdAt')
        .lean()
        .exec();
      if (similarRequests.length > 0) {
        console.log('[ICT Service] findAllRequests: Found', similarRequests.length, 'requests with similar user ID:', similarUserId);
        console.log('[ICT Service] findAllRequests: This might indicate the user created requests with a different account or session.');
      }
    }

    // Auto-advance requests stuck at SUBMITTED
    for (const request of requests) {
      await this.autoAdvanceStuckRequest(request);
    }

    return requests;
  }

  async findAllRequestsByRole(userId?: string, userRoles?: UserRole[]): Promise<ICTRequest[]> {
    // If no userId provided, return empty array
    if (!userId) {
      console.log('[ICT Service] findAllRequestsByRole: No userId provided');
      return [];
    }

    const user = await this.usersService.findOne(userId);
    if (!user) {
      console.log('[ICT Service] findAllRequestsByRole: User not found for userId:', userId);
      return [];
    }

    // If no roles provided, treat as regular user (return only their own requests)
    const roles = userRoles || [];
    console.log('[ICT Service] findAllRequestsByRole: userId:', userId, 'roles:', roles);

    // DGS: Return ALL ICT requests (all statuses, all stages)
    if (roles.includes(UserRole.DGS)) {
      console.log('[ICT Service] findAllRequestsByRole: DGS role detected, returning all requests');
      const requests = await this.ictRequestModel
        .find({})
        .populate('requesterId')
        .populate('items.itemId')
        .sort({ createdAt: -1 })
        .exec();

      console.log('[ICT Service] findAllRequestsByRole: Found', requests.length, 'requests for DGS');
      
      // Auto-advance requests stuck at SUBMITTED
      for (const request of requests) {
        await this.autoAdvanceStuckRequest(request);
      }

      return requests;
    }

    // DDICT: Return ALL ICT requests (all statuses, all stages)
    if (roles.includes(UserRole.DDICT)) {
      console.log('[ICT Service] findAllRequestsByRole: DDICT role detected, returning all requests');
      const requests = await this.ictRequestModel
        .find({})
        .populate('requesterId')
        .populate('items.itemId')
        .sort({ createdAt: -1 })
        .exec();

      console.log('[ICT Service] findAllRequestsByRole: Found', requests.length, 'requests for DDICT');

      // Auto-advance requests stuck at SUBMITTED
      for (const request of requests) {
        await this.autoAdvanceStuckRequest(request);
      }

      return requests;
    }

    // SO: Return all ICT requests that have reached SO_REVIEW or later stages
    if (roles.includes(UserRole.SO)) {
      const allRequests = await this.ictRequestModel
        .find({})
        .populate('requesterId')
        .populate('items.itemId')
        .sort({ createdAt: -1 })
        .exec();

      // Auto-advance requests stuck at SUBMITTED
      for (const request of allRequests) {
        await this.autoAdvanceStuckRequest(request);
      }

      // Filter requests that have reached SO_REVIEW or later
      return allRequests.filter((request) =>
        this.workflowService.hasReachedStage(request.workflowStage, WorkflowStage.SO_REVIEW),
      );
    }

    // SUPERVISOR: level 14+ in same department - Return all ICT requests from their department that have reached SUPERVISOR_REVIEW or later
    // Use capability service to check if user can act as supervisor
    if (this.capabilityService.canActAsSupervisor(user, user.roles)) {
      // First, find all requests and populate requesterId, then filter by department
      const allRequests = await this.ictRequestModel
        .find({})
        .populate('requesterId')
        .populate('items.itemId')
        .sort({ createdAt: -1 })
        .exec();

      // Auto-advance requests stuck at SUBMITTED
      for (const request of allRequests) {
        await this.autoAdvanceStuckRequest(request);
      }

      // Filter by department and workflow stage
      return allRequests.filter((request) => {
        const requester = request.requesterId as any;
        const requesterDeptId = this.capabilityService.getDepartmentId(requester);
        const userDeptId = this.capabilityService.getDepartmentId(user);
        const isFromDepartment = requesterDeptId && userDeptId && requesterDeptId === userDeptId;
        const hasReachedStage = this.workflowService.hasReachedStage(request.workflowStage, WorkflowStage.SUPERVISOR_REVIEW);
        return isFromDepartment && hasReachedStage;
      });
    }

    // Regular users and other roles: Return only their own requests
    console.log('[ICT Service] findAllRequestsByRole: Regular user or no matching role, returning own requests');
    const query: any = { requesterId: new Types.ObjectId(userId) };
    const requests = await this.ictRequestModel
      .find(query)
      .populate('requesterId')
      .populate('items.itemId')
      .sort({ createdAt: -1 })
      .exec();

    console.log('[ICT Service] findAllRequestsByRole: Found', requests.length, 'requests for user:', userId);

    // Auto-advance requests stuck at SUBMITTED
    for (const request of requests) {
      await this.autoAdvanceStuckRequest(request);
    }

    return requests;
  }

  async findPendingApprovals(userId: string, userRoles: UserRole[]): Promise<ICTRequest[]> {
    try {
      const user = await this.usersService.findOne(userId);
      
      if (!user) {
        console.error('[ICT Service] findPendingApprovals: User not found:', userId);
        return [];
      }

      // DGS can see all pending approvals and partially fulfilled requests (special case)
      if (userRoles.includes(UserRole.DGS)) {
        const requests = await this.ictRequestModel
          .find({
            $or: [
              {
                status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
              },
              {
                status: RequestStatus.APPROVED,
                workflowStage: WorkflowStage.FULFILLMENT,
              },
            ],
          })
          .populate('requesterId')
          .populate('items.itemId')
          .sort({ createdAt: -1 })
          .exec();
        
        // Filter to only include requests with unfulfilled items for FULFILLMENT stage
        const filteredRequests = requests.filter((request) => {
          if (request.workflowStage === WorkflowStage.FULFILLMENT) {
            return request.items.some((item) => {
              const targetQuantity = item.approvedQuantity ?? item.requestedQuantity;
              return item.fulfilledQuantity < targetQuantity;
            });
          }
          return true; // Keep all non-FULFILLMENT requests
        });
        
        console.log('[ICT Service] findPendingApprovals: DGS found', filteredRequests.length, 'requests (all pending + unfulfilled)');
        return filteredRequests;
      }

      // Build optimized query using capability service
      const departmentId = this.capabilityService.getDepartmentId(user);
      const stages = this.capabilityService.getPendingApprovalStages(user, userRoles, RequestType.ICT);
      
      if (stages.length === 0) {
        console.log('[ICT Service] findPendingApprovals: No stages found for user');
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
          // Role-based stages (DDGS_REVIEW, ADGS_REVIEW, DDICT_REVIEW, SO_REVIEW)
          queryConditions.push({
            workflowStage: stage,
            status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
          });
        }
      }

      const query = queryConditions.length > 0 ? { $or: queryConditions } : { _id: { $exists: false } };

      // Execute single optimized query
      const allRequests = await this.ictRequestModel
        .find(query)
        .populate('requesterId')
        .populate('items.itemId')
        .sort({ createdAt: -1 })
        .exec();

      // Use Map for deduplication (preserves populated fields)
      const requestMap = new Map<string, ICTRequestDocument>();
      
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
            const targetQuantity = item.approvedQuantity ?? item.requestedQuantity;
            return item.fulfilledQuantity < targetQuantity;
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
      
      console.log('[ICT Service] findPendingApprovals:');
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
      console.error('[ICT Service] findPendingApprovals: Error fetching pending approvals:', error);
      
      // Handle specific error types
      if (error instanceof NotFoundException) {
        console.error('[ICT Service] findPendingApprovals: User not found');
        return [];
      }
      
      // For database errors, log and return empty array
      console.error('[ICT Service] findPendingApprovals: Database error:', error.message);
      return [];
    }
  }

  async findOneRequest(id: string, skipAutoAdvance: boolean = false): Promise<ICTRequestDocument> {
    const request = await this.ictRequestModel
      .findById(id)
      .populate('requesterId')
      .populate('items.itemId')
      .exec();

    if (!request) {
      throw new NotFoundException('ICT request not found');
    }

    // Auto-advance requests stuck at SUBMITTED (skip during approval to avoid race conditions)
    if (!skipAutoAdvance) {
      await this.autoAdvanceStuckRequest(request);
    }

    return request;
  }

  async approveRequest(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    approveDto: ApproveRequestDto,
  ): Promise<ICTRequest> {
    // Skip auto-advance during approval to avoid race conditions
    const request = await this.findOneRequest(requestId, true);
    
    // Get requester to determine workflow chain (workflow is based on requester's level, not approver's)
    let requester: any;
    const requesterIdValue: any = request.requesterId;
    
    // Helper function to safely extract ID from various formats
    const extractRequesterId = (value: any): string | null => {
      if (!value) return null;
      
      // If it's already a string and looks like a valid ObjectId
      if (typeof value === 'string') {
        const trimmed = value.trim();
        if (/^[0-9a-fA-F]{24}$/.test(trimmed)) {
          return trimmed;
        }
        return null;
      }
      
      // If it's an ObjectId
      if (value instanceof Types.ObjectId) {
        return value.toString();
      }
      
      // If it's an object, try to extract _id
      if (typeof value === 'object') {
        // Check if it's a populated Mongoose document with _id
        if (value._id) {
          if (value._id instanceof Types.ObjectId) {
            return value._id.toString();
          }
          if (typeof value._id === 'string') {
            const trimmed = value._id.trim();
            if (/^[0-9a-fA-F]{24}$/.test(trimmed)) {
              return trimmed;
            }
          }
        }
        
        // Try id property
        if (value.id) {
          if (value.id instanceof Types.ObjectId) {
            return value.id.toString();
          }
          if (typeof value.id === 'string') {
            const trimmed = value.id.trim();
            if (/^[0-9a-fA-F]{24}$/.test(trimmed)) {
              return trimmed;
            }
          }
        }
        
        // If it has level property, it's populated - try to get _id from it
        if ('level' in value && value._id) {
          if (value._id instanceof Types.ObjectId) {
            return value._id.toString();
          }
          if (typeof value._id === 'string') {
            const trimmed = value._id.trim();
            if (/^[0-9a-fA-F]{24}$/.test(trimmed)) {
              return trimmed;
            }
          }
        }
      }
      
      return null;
    };
    
    // Check if requesterId is already populated (has level property)
    if (requesterIdValue && typeof requesterIdValue === 'object' && 'level' in requesterIdValue) {
      // Already populated as User object
      requester = requesterIdValue;
    } else {
      // Not populated, extract ID and fetch it
      const requesterId = extractRequesterId(requesterIdValue);
      
      if (!requesterId) {
        console.error('[DEBUG] Failed to extract requesterId from:', requesterIdValue, 'type:', typeof requesterIdValue);
        throw new BadRequestException('Cannot extract valid requester ID from request. Please ensure the request has a valid requester.');
      }
      
      console.log('[DEBUG] Extracted requesterId:', requesterId);
      requester = await this.usersService.findOne(requesterId);
      
      if (!requester) {
        throw new NotFoundException('Requester not found');
      }
    }

    // Check if this is an admin approval override
    const isAdminApproval = approveDto.isAdminApproval && this.adminRoleService.canApproveAll(userRoles);
    
    // Workflow chain is determined by requester's level, not approver's level
    const workflowChain = this.workflowService.getWorkflowChain(requester.level, RequestType.ICT);
    
    // If admin approval, bypass workflow stage check
    const canApprove = isAdminApproval || this.workflowService.canApproveAtStage(
      userRoles,
      request.workflowStage,
      workflowChain,
    );

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

    // Get requester for notifications (if not already fetched)
    if (!requester) {
      const requesterId = request.requesterId instanceof Types.ObjectId 
        ? request.requesterId.toString() 
        : (request.requesterId as any)?._id?.toString() || String(request.requesterId || '');
      requester = await this.usersService.findOne(requesterId);
    }

    // Get approver user for notifications
    const approverUser = await this.usersService.findOne(userId);
    if (!approverUser) {
      throw new NotFoundException('Approver user not found');
    }

    const nextStage = this.workflowService.getNextStage(request.workflowStage, workflowChain);

    // Special handling: When SO approves at SO_REVIEW, move to FULFILLMENT stage
    if (request.workflowStage === WorkflowStage.SO_REVIEW && userRoles.includes(UserRole.SO)) {
      request.workflowStage = WorkflowStage.FULFILLMENT;
      request.status = RequestStatus.APPROVED; // Status remains APPROVED until fulfillment
    } else if (nextStage) {
      request.workflowStage = nextStage;
    } else {
      request.status = RequestStatus.APPROVED;
    }

    const savedRequest = await request.save();

    // Notify all participants of workflow progress
    await this.notifyWorkflowProgress(
      savedRequest,
      'approved',
      {
        userId,
        name: approverUser.name,
        role: userRoles[0],
      },
      `Request approved by ${approverUser.name} (${userRoles[0]}). ${nextStage ? `Moved to ${nextStage} stage.` : 'Request fully approved.'}`,
    );

    // Notify requester (legacy method for backward compatibility)
    try {
      await this.notificationsService.notifyRequestApproved(
        request.requesterId.toString(),
        RequestType.ICT,
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
            RequestType.ICT,
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
  ): Promise<ICTRequest> {
    const request = await this.findOneRequest(requestId);
    
    // Get requester to determine workflow chain (workflow is based on requester's level, not approver's)
    let requester: any;
    const requesterIdValue: any = request.requesterId;
    
    // Check if requesterId is already populated (has level property)
    if (requesterIdValue && typeof requesterIdValue === 'object' && 'level' in requesterIdValue) {
      // Already populated as User object
      requester = requesterIdValue;
    } else {
      // Not populated, extract ID and fetch it
      let requesterId: string;
      if (requesterIdValue instanceof Types.ObjectId) {
        requesterId = requesterIdValue.toString();
      } else if (requesterIdValue && typeof requesterIdValue === 'object' && requesterIdValue._id) {
        requesterId = requesterIdValue._id.toString();
      } else if (requesterIdValue && typeof requesterIdValue === 'string') {
        requesterId = requesterIdValue;
      } else {
        requesterId = String(requesterIdValue || '');
      }
      
      if (!requesterId || requesterId === 'undefined' || requesterId === 'null' || requesterId.trim() === '') {
        throw new BadRequestException('Invalid requester ID in request');
      }
      
      requester = await this.usersService.findOne(requesterId);
      if (!requester) {
        throw new NotFoundException('Requester not found');
      }
    }

    // Workflow chain is determined by requester's level, not approver's level
    const workflowChain = this.workflowService.getWorkflowChain(requester.level, RequestType.ICT);
    const canApprove = this.workflowService.canApproveAtStage(
      userRoles,
      request.workflowStage,
      workflowChain,
    );

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

    // Get approver user for notifications
    const approverUser = await this.usersService.findOne(userId);
    if (!approverUser) {
      throw new NotFoundException('Approver user not found');
    }

    const savedRequest = await request.save();

    // Notify all participants of workflow progress
    await this.notifyWorkflowProgress(
      savedRequest,
      'rejected',
      {
        userId,
        name: approverUser.name,
        role: userRoles[0],
      },
      `Request rejected by ${approverUser.name} (${userRoles[0]}). ${rejectDto.comment ? `Reason: ${rejectDto.comment}` : 'No reason provided.'}`,
    );

    // Notify requester (legacy method for backward compatibility)
    try {
      await this.notificationsService.notifyRequestRejected(
        request.requesterId.toString(),
        RequestType.ICT,
        requestId,
        rejectDto.comment || 'No comment provided',
      );
    } catch (error) {
      console.error('Error sending request rejected notification:', error);
    }

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
    
    const session = await this.ictRequestModel.db.startSession();
    
    try {
      await session.withTransaction(async () => {
        // Delete all notifications related to this request
        await this.notificationModel.deleteMany(
          { requestId: new Types.ObjectId(requestId) },
          { session }
        ).exec();
        
        // Delete the request
        await this.ictRequestModel.deleteOne(
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
  ): Promise<ICTRequest> {
    // Only Store Officer (SO) can fulfill ICT requests
    if (!userRoles.includes(UserRole.SO)) {
      throw new ForbiddenException('Only Store Officer can fulfill requests');
    }

    // Validate fulfillment items array is not empty
    if (!fulfillDto.items || fulfillDto.items.length === 0) {
      throw new BadRequestException(
        'Please specify at least one item to fulfill. The fulfillment items list cannot be empty.'
      );
    }

    const request = await this.findOneRequest(requestId);

    // Validate fulfillment can happen at FULFILLMENT or SO_REVIEW stage
    if (request.workflowStage !== WorkflowStage.FULFILLMENT && 
        request.workflowStage !== WorkflowStage.SO_REVIEW) {
      throw new BadRequestException(
        'Request must be at SO_REVIEW or FULFILLMENT stage before items can be fulfilled.'
      );
    }

    if (request.status !== RequestStatus.APPROVED && request.status !== RequestStatus.PENDING) {
      throw new BadRequestException(
        `Request must be approved before fulfillment. Current status: ${request.status}`
      );
    }

    // Process fulfillment for each item
    for (const fulfillmentItem of fulfillDto.items) {
      // Normalize both IDs to strings for comparison (handle ObjectId, populated object, or string)
      const requestItem = request.items.find((item) => {
        let itemIdStr: string;
        
        // Handle different cases: ObjectId, populated object, or string
        if (item.itemId instanceof Types.ObjectId) {
          itemIdStr = item.itemId.toString();
        } else if (item.itemId && typeof item.itemId === 'object' && '_id' in item.itemId) {
          // Handle populated object: extract _id
          const populatedItem = item.itemId as any;
          itemIdStr = populatedItem._id instanceof Types.ObjectId 
            ? populatedItem._id.toString() 
            : String(populatedItem._id || '');
        } else {
          itemIdStr = String(item.itemId || '');
        }
        
        // fulfillmentItem.itemId is always a string from the DTO
        const fulfillmentIdStr = String(fulfillmentItem.itemId || '');
        return itemIdStr === fulfillmentIdStr;
      });

      if (!requestItem) {
        throw new NotFoundException(
          `The item you're trying to fulfill (${fulfillmentItem.itemId}) is not part of this request. Please check the item ID and try again.`
        );
      }

      const item = await this.findOneItem(fulfillmentItem.itemId);

      // Validate quantity
      if (fulfillmentItem.quantityFulfilled <= 0) {
        throw new BadRequestException(
          `Quantity to fulfill must be greater than 0 for item ${item.name || fulfillmentItem.itemId}.`
        );
      }

      // Use approved quantity if available, otherwise requested quantity
      const approvedQty = requestItem.approvedQuantity ?? requestItem.requestedQuantity;
      const remainingToFulfill = approvedQty - requestItem.fulfilledQuantity;

      // Validate that fulfillment doesn't exceed approved quantity
      if (fulfillmentItem.quantityFulfilled > remainingToFulfill) {
        throw new BadRequestException(
          `Cannot fulfill more than the approved quantity for item "${item.name || fulfillmentItem.itemId}". Approved: ${approvedQty}, Already fulfilled: ${requestItem.fulfilledQuantity}, Remaining: ${remainingToFulfill}, Attempted: ${fulfillmentItem.quantityFulfilled}`
        );
      }

      // Check availability - allow partial fulfillment if stock is insufficient
      // If requested quantity exceeds available stock, fulfill only what's available
      const actualQuantityToFulfill = Math.min(fulfillmentItem.quantityFulfilled, item.quantity);
      
      if (actualQuantityToFulfill <= 0) {
        throw new BadRequestException(
          `Cannot fulfill "${item.name || 'this item'}": No stock available. The item is currently out of stock (0 units available). Please wait for stock to be replenished or contact the store officer.`
        );
      }

      // If requested quantity exceeds available stock, log a warning but proceed with partial fulfillment
      if (fulfillmentItem.quantityFulfilled > item.quantity) {
        console.log(
          `[ICT Service] Partial fulfillment: Requested ${fulfillmentItem.quantityFulfilled} for item "${item.name || fulfillmentItem.itemId}", but only ${item.quantity} available. Fulfilling ${actualQuantityToFulfill}.`
        );
      }

      // Update item quantity
      const previousQuantity = item.quantity;
      item.quantity -= actualQuantityToFulfill;
      await item.save();

      // Create stock history entry for fulfillment
      const stockHistory = new this.stockHistoryModel({
        itemId: new Types.ObjectId(fulfillmentItem.itemId),
        previousQuantity,
        newQuantity: item.quantity,
        changeAmount: -actualQuantityToFulfill,
        operation: StockOperation.FULFILLMENT,
        reason: `Fulfilled request ${requestId}${actualQuantityToFulfill < fulfillmentItem.quantityFulfilled ? ` (partial: ${actualQuantityToFulfill}/${fulfillmentItem.quantityFulfilled})` : ''}`,
        performedBy: new Types.ObjectId(userId),
        requestId: new Types.ObjectId(requestId),
      });
      await stockHistory.save();

      // Check for low stock after fulfillment
      await this.checkAndNotifyLowStock(item);

      // Update request item fulfillment with actual quantity fulfilled
      requestItem.fulfilledQuantity += actualQuantityToFulfill;
      requestItem.isAvailable = item.quantity > 0;

      // Record fulfillment status with actual quantity fulfilled
      request.fulfillmentStatus.push({
        itemId: new Types.ObjectId(fulfillmentItem.itemId),
        quantityFulfilled: actualQuantityToFulfill,
        fulfilledAt: new Date(),
        fulfilledBy: new Types.ObjectId(userId),
      });
    }

    // Move workflow stage to FULFILLMENT when items are being fulfilled
    // Only update if currently at SO_REVIEW (or keep at FULFILLMENT if already there)
    if (request.workflowStage === WorkflowStage.SO_REVIEW) {
      request.workflowStage = WorkflowStage.FULFILLMENT;
    }
    // If already at FULFILLMENT, keep it there

    // Check if all items are fully fulfilled
    // Use approvedQuantity if exists (DDICT adjusted), otherwise use requestedQuantity
    const allFulfilled = request.items.every(
      (item) => {
        const targetQuantity = item.approvedQuantity ?? item.requestedQuantity;
        return item.fulfilledQuantity >= targetQuantity;
      },
    );

    if (allFulfilled) {
      request.status = RequestStatus.FULFILLED;
      // Workflow stage is at FULFILLMENT, status FULFILLED indicates completion
    } else {
      request.status = RequestStatus.PARTIAL_FULFILLMENT; // Partial fulfillment
      // Workflow stage is at FULFILLMENT for partial fulfillments too
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
        'ICT Request Fulfilled',
        `Your ICT request has been ${allFulfilled ? 'fully fulfilled' : 'partially fulfilled'}.`,
        requestId,
        RequestType.ICT,
      );
    } catch (error) {
      console.error('Error sending fulfillment notification:', error);
    }

    return savedRequest;
  }

  /**
   * Find all requests with unfulfilled items
   */
  async findUnfulfilledRequests(): Promise<ICTRequest[]> {
    const requests = await this.ictRequestModel
      .find({
        status: { $in: [RequestStatus.APPROVED, RequestStatus.PENDING] },
        workflowStage: { $in: [WorkflowStage.SO_REVIEW, WorkflowStage.FULFILLMENT] },
      })
      .populate('requesterId', 'name email')
      .populate('items.itemId')
      .sort({ createdAt: -1 })
      .exec();

    // Filter to only include requests with unfulfilled items
    // Use approvedQuantity if exists (DDICT adjusted), otherwise use requestedQuantity
    return requests.filter((request) => {
      return request.items.some(
        (item) => {
          const targetQuantity = item.approvedQuantity ?? item.requestedQuantity;
          return item.fulfilledQuantity < targetQuantity;
        },
      );
    });
  }

  /**
   * Notify requester about item availability
   */
  async notifyRequester(
    requestId: string,
    userId: string,
    message?: string,
  ): Promise<void> {
    const request = await this.findOneRequest(requestId);
    const user = await this.usersService.findOne(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Only SO can notify requesters
    if (!user.roles.includes(UserRole.SO)) {
      throw new ForbiddenException('Only Store Officer can notify requesters');
    }

    // Request must be at SO_REVIEW or FULFILLMENT workflow stage
    if (request.workflowStage !== WorkflowStage.SO_REVIEW && 
        request.workflowStage !== WorkflowStage.FULFILLMENT) {
      throw new BadRequestException(
        'Request must be at SO_REVIEW or FULFILLMENT workflow stage'
      );
    }

    const requesterId = request.requesterId instanceof Types.ObjectId
      ? request.requesterId.toString()
      : (request.requesterId as any)?._id?.toString() || String(request.requesterId || '');

    const defaultMessage = `Your ICT request (${requestId.substring(0, 8)}...) has items available for fulfillment. Please check the request status.`;
    const notificationMessage = message || defaultMessage;

    // Create notification for requester
    await this.notificationsService.createNotification(
      requesterId,
      NotificationType.APPROVAL_REQUIRED, // Using APPROVAL_REQUIRED as it's a status update notification
      'Items Available for Fulfillment',
      notificationMessage,
      requestId,
      RequestType.ICT,
    );

    // Also send email notification
    try {
      const requester = await this.usersService.findOne(requesterId);
      if (requester && requester.email) {
        // The notification service should handle email sending
        // This is already done in createNotification if email is enabled
      }
    } catch (error) {
      console.error('Error sending email notification:', error);
    }
  }

  /**
   * Notify all participants of workflow progress
   */
  private async notifyWorkflowProgress(
    request: ICTRequestDocument,
    action: 'approved' | 'rejected' | 'fulfilled',
    actionBy: { userId: string; name: string; role: string },
    message: string,
  ): Promise<void> {
    try {
      // Get requester and all approvers
      const participantIds = [
        request.requesterId.toString(),
        ...request.approvals.map((a) => a.approverId.toString()),
      ];
      const uniqueParticipantIds = [...new Set(participantIds)];

      // Emit workflow progress to all participants
      await this.notificationsService.emitWorkflowProgress(uniqueParticipantIds, {
        requestId: request._id.toString(),
        requestType: RequestType.ICT,
        workflowStage: request.workflowStage,
        status: request.status,
        action,
        actionBy,
        participants: [],
        message,
      });

      // Also create notification records for all participants
      for (const participantId of uniqueParticipantIds) {
        try {
          await this.notificationsService.createNotification(
            participantId,
            this.getNotificationTypeForAction(action),
            this.getNotificationTitleForAction(action, RequestType.ICT),
            message,
            request._id.toString(),
            RequestType.ICT,
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
  ): Promise<ICTRequest> {
    // Only DDICT can set priority for ICT requests
    if (!userRoles.includes(UserRole.DDICT)) {
      throw new ForbiddenException('Only DDICT can set priority for ICT requests');
    }

    const request = await this.findOneRequest(requestId);
    request.priority = priority;
    return request.save();
  }

  async updateRequestItems(
    requestId: string,
    userId: string,
    userRoles: UserRole[],
    updateItemsDto: { items: Array<{ itemId: string; quantity: number }> },
  ): Promise<ICTRequest> {
    // Only DDICT can adjust request item quantities at DDICT_REVIEW stage
    if (!userRoles.includes(UserRole.DDICT)) {
      throw new ForbiddenException('Only DDICT can adjust request item quantities');
    }

    const request = await this.findOneRequest(requestId);
    
    // Only allow adjustment at DDICT_REVIEW stage
    if (request.workflowStage !== WorkflowStage.DDICT_REVIEW) {
      throw new BadRequestException('Request items can only be adjusted at DDICT_REVIEW stage');
    }

    // Validate that request is still pending
    if (request.status !== RequestStatus.PENDING && request.status !== RequestStatus.CORRECTED) {
      throw new BadRequestException('Cannot adjust items for a request that is not pending');
    }

    const quantityChanges: any[] = [];
    const changedItems: string[] = [];

    // Validate all items exist and are available in the requested quantities
    for (const updateItem of updateItemsDto.items) {
      const item = await this.findOneItem(updateItem.itemId);
      if (!item.isAvailable || item.quantity < updateItem.quantity) {
        throw new BadRequestException(
          `Item ${item.name} is not available in requested quantity (available: ${item.quantity}, requested: ${updateItem.quantity})`,
        );
      }

      // Find the corresponding item in the request
      // Normalize itemId comparison (handle ObjectId, populated object, or string)
      const requestItem = request.items.find((ri) => {
        let itemIdStr: string;
        
        // Handle different cases: ObjectId, populated object, or string
        if (ri.itemId instanceof Types.ObjectId) {
          itemIdStr = ri.itemId.toString();
        } else if (ri.itemId && typeof ri.itemId === 'object' && '_id' in ri.itemId) {
          // Handle populated object: extract _id
          const populatedItem = ri.itemId as any;
          itemIdStr = populatedItem._id instanceof Types.ObjectId 
            ? populatedItem._id.toString() 
            : String(populatedItem._id || '');
        } else {
          itemIdStr = String(ri.itemId || '');
        }
        
        // updateItem.itemId is always a string from the DTO
        const updateIdStr = String(updateItem.itemId || '');
        return itemIdStr === updateIdStr;
      });
      
      if (!requestItem) {
        throw new BadRequestException(`Item ${item.name} not found in request`);
      }

      // Track changes - compare approvedQuantity if exists, otherwise requestedQuantity
      const previousQuantity = requestItem.approvedQuantity ?? requestItem.requestedQuantity;
      if (previousQuantity !== updateItem.quantity) {
        quantityChanges.push({
          itemId: new Types.ObjectId(updateItem.itemId),
          itemName: item.name,
          previousQuantity,
          newQuantity: updateItem.quantity,
          changedBy: new Types.ObjectId(userId),
          changedAt: new Date(),
        });
        changedItems.push(item.name);
      }
    }

    // Update request items - set approvedQuantity (keep original requestedQuantity)
    for (const updateItem of updateItemsDto.items) {
      // Normalize itemId comparison (handle ObjectId, populated object, or string)
      const requestItem = request.items.find((ri) => {
        let itemIdStr: string;
        
        // Handle different cases: ObjectId, populated object, or string
        if (ri.itemId instanceof Types.ObjectId) {
          itemIdStr = ri.itemId.toString();
        } else if (ri.itemId && typeof ri.itemId === 'object' && '_id' in ri.itemId) {
          // Handle populated object: extract _id
          const populatedItem = ri.itemId as any;
          itemIdStr = populatedItem._id instanceof Types.ObjectId 
            ? populatedItem._id.toString() 
            : String(populatedItem._id || '');
        } else {
          itemIdStr = String(ri.itemId || '');
        }
        
        // updateItem.itemId is always a string from the DTO
        const updateIdStr = String(updateItem.itemId || '');
        return itemIdStr === updateIdStr;
      });
      
      if (requestItem) {
        // Keep original requestedQuantity, set approvedQuantity
        requestItem.approvedQuantity = updateItem.quantity;
        // Update quantity field to match approvedQuantity for consistency
        requestItem.quantity = updateItem.quantity;
        // Reset fulfilled quantity if it was already fulfilled (since quantity changed)
        if (requestItem.fulfilledQuantity > updateItem.quantity) {
          requestItem.fulfilledQuantity = 0;
        }
      }
    }

    // Add quantity changes to history
    if (quantityChanges.length > 0) {
      if (!request.quantityChanges) {
        request.quantityChanges = [];
      }
      request.quantityChanges.push(...quantityChanges);
      // Add corrector as participant when quantities are adjusted
      this.addParticipant(request, userId, userRoles[0], 'corrected');
    }

    const savedRequest = await request.save();

    // Send notification to requester if quantities were changed
    if (quantityChanges.length > 0) {
      const requesterId = request.requesterId instanceof Types.ObjectId
        ? request.requesterId.toString()
        : (request.requesterId as any)?._id?.toString() || String(request.requesterId || '');

      const itemsList = changedItems.join(', ');
      const notificationMessage = `Your ICT request quantities have been adjusted by DDICT. Changed items: ${itemsList}. Please review the updated quantities.`;

      await this.notificationsService.createNotification(
        requesterId,
        NotificationType.REQUEST_UPDATED,
        'Request Quantities Adjusted',
        notificationMessage,
        requestId,
        RequestType.ICT,
      );

      // Also send email notification
      try {
        const requester = await this.usersService.findOne(requesterId);
        if (requester && requester.email) {
          // Email is handled by the notification service if enabled
        }
      } catch (error) {
        console.error('Error sending email notification:', error);
      }
    }

    return savedRequest;
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
  ): Promise<ICTRequest[]> {
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

    let requests = await this.ictRequestModel
      .find(query)
      .populate('requesterId')
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
   * Find request history for role-based users (shows all requests, not just completed/fulfilled)
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
  ): Promise<ICTRequest[]> {
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

    console.log('[ICT Service] findRequestHistoryByRole: Query:', JSON.stringify(query));
    
    let requests = await this.ictRequestModel
      .find(query)
      .populate('requesterId')
      .populate('items.itemId')
      .sort({ createdAt: -1 })
      .exec();

    console.log('[ICT Service] findRequestHistoryByRole: Found', requests.length, 'requests');

    // Filter by action if specified (check if user participated with that action)
    if (filters?.action) {
      requests = requests.filter((request) =>
        request.participants.some(
          (p) =>
            p.userId.toString() === userId &&
            p.action === filters.action,
        ),
      );
      console.log('[ICT Service] findRequestHistoryByRole: After action filter:', requests.length, 'requests');
    }

    return requests;
  }

  /**
   * Auto-advance requests that are stuck at SUBMITTED stage
   * This fixes requests created before the auto-advance logic was added
   */
  private async autoAdvanceStuckRequest(request: ICTRequestDocument): Promise<void> {
    // Only process requests stuck at SUBMITTED with PENDING status
    if (request.workflowStage !== WorkflowStage.SUBMITTED || request.status !== RequestStatus.PENDING) {
      return;
    }

    // Get requester - handle both populated and unpopulated requesterId
    let requester: any;
    const requesterIdValue: any = request.requesterId;
    
    // Check if requesterId is already populated (has level property) or is an ObjectId
    if (requesterIdValue && typeof requesterIdValue === 'object' && 'level' in requesterIdValue) {
      // Already populated as User object
      requester = requesterIdValue;
    } else {
      // Not populated, extract ID and fetch it
      let requesterId: string;
      if (requesterIdValue instanceof Types.ObjectId) {
        requesterId = requesterIdValue.toString();
      } else if (requesterIdValue && typeof requesterIdValue === 'object' && requesterIdValue._id) {
        requesterId = requesterIdValue._id.toString();
      } else if (requesterIdValue && typeof requesterIdValue === 'string') {
        requesterId = requesterIdValue;
      } else {
        requesterId = String(requesterIdValue || '');
      }
      
      if (!requesterId || requesterId === 'undefined' || requesterId === 'null') {
        console.error('Cannot auto-advance: invalid requesterId', requesterIdValue);
        return;
      }
      
      requester = await this.usersService.findOne(requesterId);
      if (!requester) {
        console.error('Cannot auto-advance: requester not found', requesterId);
        return;
      }
    }

    // Get workflow chain based on requester's level
    const workflowChain = this.workflowService.getWorkflowChain(requester.level, RequestType.ICT);
    
    // Get next stage after SUBMITTED
    const nextStage = this.workflowService.getNextStage(WorkflowStage.SUBMITTED, workflowChain);
    
    if (nextStage) {
      request.workflowStage = nextStage;
      await request.save();
      
      // Notify next approver(s) about the request
      try {
        const departmentId = requester.departmentId?.toString() || 
                             (requester.departmentId instanceof Types.ObjectId ? requester.departmentId.toString() : requester.departmentId);
        if (departmentId) {
          const approvers = await this.findApproversForStage(nextStage, departmentId);
          for (const approver of approvers) {
            await this.notificationsService.notifyApprovalRequired(
              approver._id.toString(),
              requester.name,
              RequestType.ICT,
              request._id.toString(),
            );
          }
        }
      } catch (error) {
        console.error('Error sending approval required notification after auto-advance:', error);
      }
    }
  }

  private async generateQRCode(requestId: string): Promise<string> {
    const qrData = `ICT-${requestId}-${Date.now()}`;
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
      console.log('[ICT Service] findApproversForStage: Found', supervisors.length, 'supervisors for department', departmentId);
      return supervisors;
    }

    // Find users with this role
    // For DGS, DDGS, ADGS, TO, DDICT, SO - they might be across departments, so we search all
    if ([UserRole.DGS, UserRole.DDGS, UserRole.ADGS, UserRole.TO, UserRole.DDICT, UserRole.SO].includes(role)) {
      const users = await this.usersService.findAll();
      const roleUsers = users.filter((u) => u.roles.includes(role)) as UserDocument[];
      console.log('[ICT Service] findApproversForStage: Found', roleUsers.length, 'users with role', role);
      return roleUsers;
    }

    // For other roles, find by role and department
    const deptUsers = await this.usersService.findByRoleAndDepartment(role, departmentId);
    console.log('[ICT Service] findApproversForStage: Found', deptUsers.length, 'users with role', role, 'in department', departmentId);
    return deptUsers;
  }
}

