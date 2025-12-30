import { Injectable } from '@nestjs/common';
import { UserRole, RequestType, WorkflowStage, RequestStatus } from '../../shared/types';
import { User, UserDocument } from '../../users/schemas/user.schema';
import { Types } from 'mongoose';

// Type that accepts both User and UserDocument
type UserLike = User | UserDocument;

@Injectable()
export class UserCapabilityService {
  /**
   * Get explicit approver roles from user's roles
   * These are roles that have specific workflow stages (DGS, DDGS, ADGS, TO, DDICT, SO)
   */
  getUserApproverRoles(userRoles: UserRole[]): UserRole[] {
    const approverRoles: UserRole[] = [];
    
    if (userRoles.includes(UserRole.DGS)) approverRoles.push(UserRole.DGS);
    if (userRoles.includes(UserRole.DDGS)) approverRoles.push(UserRole.DDGS);
    if (userRoles.includes(UserRole.ADGS)) approverRoles.push(UserRole.ADGS);
    if (userRoles.includes(UserRole.TO)) approverRoles.push(UserRole.TO);
    if (userRoles.includes(UserRole.DDICT)) approverRoles.push(UserRole.DDICT);
    if (userRoles.includes(UserRole.SO)) approverRoles.push(UserRole.SO);
    
    console.log('[Capability Service] User roles:', userRoles);
    console.log('[Capability Service] Explicit approver roles:', approverRoles);
    
    return approverRoles;
  }

  /**
   * Check if user is a "pure" supervisor (level 14+ AND no explicit approver roles)
   * Used when we want to identify supervisors who don't have other approver roles
   */
  isSupervisor(user: UserLike, userRoles: UserRole[]): boolean {
    const approverRoles = this.getUserApproverRoles(userRoles);
    const isPureSupervisor = user.level >= 14 && approverRoles.length === 0;
    
    console.log('[Capability Service] Is pure supervisor:', isPureSupervisor, '(level:', user.level, ', approver roles:', approverRoles.length, ')');
    
    return isPureSupervisor;
  }

  /**
   * Check if user can act as supervisor (level 14+ regardless of other roles)
   * This allows dual capacity - users with explicit roles can also act as supervisors
   */
  canActAsSupervisor(user: UserLike, userRoles: UserRole[]): boolean {
    const canAct = user.level >= 14;
    
    console.log('[Capability Service] Can act as supervisor:', canAct, '(level:', user.level, ')');
    
    return canAct;
  }

  /**
   * Get workflow stages that user should see pending approval requests for
   * Returns stages based on explicit roles first, then supervisor status
   */
  getPendingApprovalStages(
    user: UserLike,
    userRoles: UserRole[],
    requestType: RequestType,
  ): WorkflowStage[] {
    const stages: WorkflowStage[] = [];
    const approverRoles = this.getUserApproverRoles(userRoles);
    const canActAsSupervisor = this.canActAsSupervisor(user, userRoles);

    // DGS can see all pending requests (special case)
    if (userRoles.includes(UserRole.DGS)) {
      console.log('[Capability Service] DGS role detected - will see all pending requests');
      // Return empty array - DGS logic is handled separately in services
      return [];
    }

    // Check explicit approver roles first (priority order)
    if (userRoles.includes(UserRole.DDGS)) {
      if (requestType === RequestType.VEHICLE) {
        stages.push(WorkflowStage.DDGS_REVIEW);
      } else if (requestType === RequestType.ICT || requestType === RequestType.STORE) {
        stages.push(WorkflowStage.DDGS_REVIEW);
        // FULFILLMENT removed - DDGS shouldn't see fulfillment requests in pending approvals
        // FULFILLMENT is for SO (Store Officer) to fulfill, not for DDGS to approve
      }
    }

    if (userRoles.includes(UserRole.ADGS)) {
      if (requestType === RequestType.VEHICLE) {
        stages.push(WorkflowStage.ADGS_REVIEW);
      } else if (requestType === RequestType.ICT || requestType === RequestType.STORE) {
        stages.push(WorkflowStage.ADGS_REVIEW);
        // FULFILLMENT removed - ADGS shouldn't see fulfillment requests in pending approvals
        // FULFILLMENT is for SO (Store Officer) to fulfill, not for ADGS to approve
      }
    }

    if (userRoles.includes(UserRole.TO) && requestType === RequestType.VEHICLE) {
      stages.push(WorkflowStage.TO_REVIEW);
    }

    if (userRoles.includes(UserRole.DDICT) && requestType === RequestType.ICT) {
      stages.push(WorkflowStage.DDICT_REVIEW);
      stages.push(WorkflowStage.FULFILLMENT); // DDICT can see fulfillment for ICT
    }

    if (userRoles.includes(UserRole.SO) && (requestType === RequestType.ICT || requestType === RequestType.STORE)) {
      stages.push(WorkflowStage.SO_REVIEW);
      stages.push(WorkflowStage.FULFILLMENT); // SO can see fulfillment for ICT/Store
    }

    // Add supervisor stage if user can act as supervisor (dual capacity)
    if (canActAsSupervisor) {
      stages.push(WorkflowStage.SUPERVISOR_REVIEW);
    }

    // Remove duplicates
    const uniqueStages = Array.from(new Set(stages));
    
    console.log('[Capability Service] Pending approval stages for', requestType, ':', uniqueStages);
    
    return uniqueStages;
  }

  /**
   * Build optimized MongoDB query for pending approvals
   * Returns a query object with $or conditions for all relevant stages
   */
  buildPendingApprovalsQuery(
    user: UserLike,
    userRoles: UserRole[],
    requestType: RequestType,
    departmentId?: Types.ObjectId | string,
  ): any {
    // DGS sees all pending requests (special case)
    if (userRoles.includes(UserRole.DGS)) {
      const query = {
        status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
      };
      
      console.log('[Capability Service] DGS query (all pending requests):', query);
      
      return query;
    }

    const stages = this.getPendingApprovalStages(user, userRoles, requestType);
    
    if (stages.length === 0) {
      console.log('[Capability Service] No stages found - returning empty query');
      return { _id: { $exists: false } }; // Return query that matches nothing
    }

    const queryConditions: any[] = [];
    const departmentIdStr = departmentId?.toString() || user.departmentId?.toString();

    for (const stage of stages) {
      if (stage === WorkflowStage.SUPERVISOR_REVIEW) {
        // Supervisor requests need department matching
        if (departmentIdStr) {
          queryConditions.push({
            workflowStage: stage,
            'requesterId.departmentId': new Types.ObjectId(departmentIdStr),
            status: { $in: [RequestStatus.PENDING, RequestStatus.CORRECTED] },
          });
        }
      } else if (stage === WorkflowStage.FULFILLMENT) {
        // FULFILLMENT stage needs special handling (for ICT/Store with unfulfilled items)
        // This will be handled in the service layer after fetching
        queryConditions.push({
          status: RequestStatus.APPROVED,
          workflowStage: stage,
        });
      } else {
        // Regular role-based stages
        queryConditions.push({
          workflowStage: stage,
        });
      }
    }

    const query = queryConditions.length > 0 ? { $or: queryConditions } : { _id: { $exists: false } };
    
    console.log('[Capability Service] Built query for', requestType, ':', JSON.stringify(query, null, 2));
    
    return query;
  }

  /**
   * Get department ID from user (handles both ObjectId and string formats)
   */
  getDepartmentId(user: UserLike): string | null {
    if (!user.departmentId) {
      return null;
    }

    if (typeof user.departmentId === 'string') {
      return user.departmentId;
    }

    if (user.departmentId instanceof Types.ObjectId) {
      return user.departmentId.toString();
    }

    if (user.departmentId && typeof user.departmentId === 'object' && (user.departmentId as any)._id) {
      const deptId = (user.departmentId as any)._id;
      if (deptId instanceof Types.ObjectId) {
        return deptId.toString();
      }
      return deptId.toString();
    }

    return null;
  }
}
