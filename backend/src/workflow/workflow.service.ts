import { Injectable } from '@nestjs/common';
import { UserRole, RequestType, WorkflowStage } from '../shared/types';

export interface WorkflowStep {
  stage: WorkflowStage;
  role: UserRole | null;
  description: string;
}

@Injectable()
export class WorkflowService {
  /**
   * Determines the approval workflow chain based on staff level and request type
   * Level 14 and above skip supervisor review and go straight to DGS for all request types
   */
  getWorkflowChain(staffLevel: number, requestType: RequestType): WorkflowStep[] {
    // Level 14+ skip supervisor and go straight to DGS for all requests
    const isSeniorStaff = staffLevel >= 14;

    switch (requestType) {
      case RequestType.VEHICLE:
        return this.getVehicleWorkflow(isSeniorStaff);
      case RequestType.ICT:
        return this.getICTWorkflow(isSeniorStaff);
      case RequestType.STORE:
        return this.getStoreWorkflow(isSeniorStaff);
      default:
        throw new Error(`Unknown request type: ${requestType}`);
    }
  }

  /**
   * Vehicle Request Workflow
   * Lower-Level: Requester → Supervisor → DGS → DDGS → ADGS → TO
   * Senior: Requester → DGS → DDGS → ADGS → TO
   */
  private getVehicleWorkflow(isSeniorStaff: boolean): WorkflowStep[] {
    const steps: WorkflowStep[] = [
      { stage: WorkflowStage.SUBMITTED, role: null, description: 'Request Submitted' },
    ];

    if (!isSeniorStaff) {
      steps.push({
        stage: WorkflowStage.SUPERVISOR_REVIEW,
        role: UserRole.SUPERVISOR,
        description: 'Supervisor Review',
      });
    }

    steps.push(
      { stage: WorkflowStage.DGS_REVIEW, role: UserRole.DGS, description: 'DGS Review' },
      { stage: WorkflowStage.DDGS_REVIEW, role: UserRole.DDGS, description: 'DDGS Review' },
      { stage: WorkflowStage.ADGS_REVIEW, role: UserRole.ADGS, description: 'ADGS Review' },
      { stage: WorkflowStage.TO_REVIEW, role: UserRole.TO, description: 'Transport Officer Assignment' },
    );

    return steps;
  }

  /**
   * ICT Request Workflow
   * Lower-Level: Requester → Supervisor → DDICT → DGS → SO
   * Senior: Requester → DDICT → DGS → SO
   */
  private getICTWorkflow(isSeniorStaff: boolean): WorkflowStep[] {
    const steps: WorkflowStep[] = [
      { stage: WorkflowStage.SUBMITTED, role: null, description: 'Request Submitted' },
    ];

    if (!isSeniorStaff) {
      steps.push({
        stage: WorkflowStage.SUPERVISOR_REVIEW,
        role: UserRole.SUPERVISOR,
        description: 'Supervisor Review',
      });
    }

    steps.push(
      { stage: WorkflowStage.DDICT_REVIEW, role: UserRole.DDICT, description: 'DDICT Review' },
      { stage: WorkflowStage.DGS_REVIEW, role: UserRole.DGS, description: 'DGS Review' },
      { stage: WorkflowStage.SO_REVIEW, role: UserRole.SO, description: 'Store Officer Review' },
      { stage: WorkflowStage.FULFILLMENT, role: UserRole.SO, description: 'Fulfillment' },
    );

    return steps;
  }

  /**
   * Store Request Workflow
   * Lower-Level: Requester → Supervisor → DGS → DDGS → ADGS → SO → Fulfillment
   * Senior: Requester → DGS → DDGS → ADGS → SO → Fulfillment
   * Note: DGS can route directly to SO via routeRequest(directToSO: true), skipping DDGS/ADGS
   */
  private getStoreWorkflow(isSeniorStaff: boolean): WorkflowStep[] {
    const steps: WorkflowStep[] = [
      { stage: WorkflowStage.SUBMITTED, role: null, description: 'Request Submitted' },
    ];

    if (!isSeniorStaff) {
      steps.push({
        stage: WorkflowStage.SUPERVISOR_REVIEW,
        role: UserRole.SUPERVISOR,
        description: 'Supervisor Review',
      });
    }

    steps.push(
      { stage: WorkflowStage.DGS_REVIEW, role: UserRole.DGS, description: 'DGS Review' },
      { stage: WorkflowStage.DDGS_REVIEW, role: UserRole.DDGS, description: 'DDGS Review' },
      { stage: WorkflowStage.ADGS_REVIEW, role: UserRole.ADGS, description: 'ADGS Review' },
      { stage: WorkflowStage.SO_REVIEW, role: UserRole.SO, description: 'Store Officer Review' },
      { stage: WorkflowStage.FULFILLMENT, role: UserRole.SO, description: 'Fulfillment' },
    );

    return steps;
  }

  /**
   * Get the next stage in the workflow
   */
  getNextStage(currentStage: WorkflowStage, workflowChain: WorkflowStep[]): WorkflowStage | null {
    const currentIndex = workflowChain.findIndex((step) => step.stage === currentStage);
    if (currentIndex === -1 || currentIndex === workflowChain.length - 1) {
      return null;
    }
    return workflowChain[currentIndex + 1].stage;
  }

  /**
   * Get the current stage's required role
   */
  getRequiredRoleForStage(stage: WorkflowStage, workflowChain: WorkflowStep[]): UserRole | null {
    const step = workflowChain.find((s) => s.stage === stage);
    return step?.role || null;
  }

  /**
   * Check if a user can approve at a specific stage
   */
  canApproveAtStage(
    userRoles: UserRole[],
    stage: WorkflowStage,
    workflowChain: WorkflowStep[],
  ): boolean {
    const requiredRole = this.getRequiredRoleForStage(stage, workflowChain);
    if (!requiredRole) {
      return false;
    }
    return userRoles.includes(requiredRole);
  }

  /**
   * Check if DGS can override (always true for DGS)
   */
  canDGSOverride(userRoles: UserRole[]): boolean {
    return userRoles.includes(UserRole.DGS);
  }

  /**
   * Check if a request has reached or passed a specific workflow stage
   * Stage order: SUBMITTED → SUPERVISOR_REVIEW → DDICT_REVIEW → DGS_REVIEW → DDGS_REVIEW → ADGS_REVIEW → TO_REVIEW → SO_REVIEW → FULFILLMENT
   */
  hasReachedStage(requestStage: WorkflowStage, targetStage: WorkflowStage): boolean {
    const stageOrder: WorkflowStage[] = [
      WorkflowStage.SUBMITTED,
      WorkflowStage.SUPERVISOR_REVIEW,
      WorkflowStage.DDICT_REVIEW,
      WorkflowStage.DGS_REVIEW,
      WorkflowStage.DDGS_REVIEW,
      WorkflowStage.ADGS_REVIEW,
      WorkflowStage.TO_REVIEW,
      WorkflowStage.SO_REVIEW,
      WorkflowStage.FULFILLMENT,
    ];

    const requestIndex = stageOrder.indexOf(requestStage);
    const targetIndex = stageOrder.indexOf(targetStage);

    // If either stage is not found, return false
    if (requestIndex === -1 || targetIndex === -1) {
      return false;
    }

    // Request has reached or passed the target stage if its index is >= target index
    return requestIndex >= targetIndex;
  }
}

