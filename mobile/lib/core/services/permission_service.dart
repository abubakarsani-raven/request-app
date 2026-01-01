import 'package:get/get.dart';
import '../../app/data/models/user_model.dart';
import '../../app/data/models/request_model.dart';
import '../utils/id_utils.dart';

enum UserRole {
  dgs,
  ddgs,
  adgs,
  to,
  ddict,
  so,
  supervisor,
  driver,
  regular,
}

class PermissionService extends GetxService {
  UserRole? _parseRole(String role) {
    switch (role.toUpperCase()) {
      case 'DGS':
        return UserRole.dgs;
      case 'DDGS':
        return UserRole.ddgs;
      case 'ADGS':
        return UserRole.adgs;
      case 'TO':
        return UserRole.to;
      case 'DDICT':
        return UserRole.ddict;
      case 'SO':
        return UserRole.so;
      case 'SUPERVISOR':
        return UserRole.supervisor;
      case 'DRIVER':
        return UserRole.driver;
      default:
        return UserRole.regular;
    }
  }

  List<UserRole> _getUserRoles(UserModel user) {
    return user.roles.map((role) => _parseRole(role) ?? UserRole.regular).toList();
  }

  bool canApprove(UserModel user, RequestType type, String workflowStage) {
    // Use canApproveAtStage which has the updated logic (explicit roles first, then supervisor)
    return canApproveAtStage(user, type, workflowStage);
  }

  bool canAssignVehicle(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.to) || roles.contains(UserRole.dgs);
  }

  bool canFulfillRequest(UserModel user, RequestType type) {
    final roles = _getUserRoles(user);
    // SO can fulfill ICT and Store requests
    return roles.contains(UserRole.so) && 
           (type == RequestType.ict || type == RequestType.store);
  }

  bool canSetPriority(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.dgs);
  }

  bool canViewAllRequests(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.dgs) || 
           roles.contains(UserRole.to) ||
           roles.contains(UserRole.ddict) ||
           roles.contains(UserRole.so);
  }

  bool canStartTrip(UserModel user, dynamic requestOrDriverId) {
    final roles = _getUserRoles(user);
    
    // Only drivers can start trips
    if (!roles.contains(UserRole.driver)) {
      return false;
    }
    
    // If requestOrDriverId is a VehicleRequestModel, check assignment
    if (requestOrDriverId is VehicleRequestModel) {
      // Driver can start trip only if they are assigned to this request
      return requestOrDriverId.driverId == user.id;
    }
    
    // Legacy support: if it's a String (driverId), check match
    if (requestOrDriverId is String?) {
      return requestOrDriverId == user.id;
    }
    
    return false;
  }

  bool canCreateRequest(UserModel user) {
    // All authenticated users (including drivers) can create requests
    // Drivers are staff members and should be able to create all request types
    return true;
  }

  bool canViewDashboard(UserModel user) {
    return true; // All authenticated users can view dashboard
  }

  bool canManageVehicles(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.to) || roles.contains(UserRole.dgs);
  }

  bool canManageDrivers(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.to) || roles.contains(UserRole.dgs);
  }

  bool canScanQR(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.so);
  }

  bool isDriver(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.driver);
  }

  bool isTO(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.to);
  }

  bool isDGS(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.dgs);
  }

  bool isSO(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.so);
  }

  /// Check if user is a "pure" supervisor (level 14+ AND no explicit approver roles)
  /// Matches backend isSupervisor logic
  bool isSupervisor(UserModel user) {
    final roles = _getUserRoles(user);
    // Check if user has explicit approver roles
    final hasApproverRole = roles.contains(UserRole.dgs) ||
        roles.contains(UserRole.ddgs) ||
        roles.contains(UserRole.adgs) ||
        roles.contains(UserRole.to) ||
        roles.contains(UserRole.ddict) ||
        roles.contains(UserRole.so);
    
    final isPureSupervisor = user.level >= 14 && !hasApproverRole;
    print('[Permission Service] isSupervisor: level ${user.level}, hasApproverRole: $hasApproverRole, isPureSupervisor: $isPureSupervisor');
    return isPureSupervisor;
  }

  /// Check if user can act as supervisor (level 14+ regardless of roles)
  /// This allows dual capacity - users with explicit roles can also act as supervisors
  /// Matches backend canActAsSupervisor logic
  bool canActAsSupervisor(UserModel user) {
    final canAct = user.level >= 14;
    print('[Permission Service] canActAsSupervisor: level ${user.level}, canAct: $canAct');
    return canAct;
  }

  String getPrimaryRole(UserModel user) {
    final roles = _getUserRoles(user);
    if (roles.contains(UserRole.dgs)) return 'DGS';
    if (roles.contains(UserRole.to)) return 'TO';
    if (roles.contains(UserRole.driver)) return 'DRIVER';
    if (roles.contains(UserRole.so)) return 'SO';
    if (roles.contains(UserRole.ddict)) return 'DDICT';
    if (roles.contains(UserRole.ddgs)) return 'DDGS';
    if (roles.contains(UserRole.adgs)) return 'ADGS';
    // Supervisor is level 14+ (not a role, but a level-based designation)
    if (user.level >= 14) return 'SUPERVISOR';
    return 'STAFF';
  }

  // New comprehensive permission methods

  /// Check if user can view a specific request
  bool canViewRequest(UserModel user, dynamic request) {
    final roles = _getUserRoles(user);
    
    // DGS, TO, DDICT, SO can view all requests of their type
    if (roles.contains(UserRole.dgs)) return true;
    
    // TO can view all vehicle requests
    if (roles.contains(UserRole.to) && request is VehicleRequestModel) {
      return true;
    }
    
    // DDICT can view ICT requests
    if (roles.contains(UserRole.ddict)) {
      // Check if request is ICT type (would need ICTRequestModel check)
      return true; // Simplified - would need type checking
    }
    
    // SO can view ICT/Store requests
    if (roles.contains(UserRole.so)) {
      return true; // Simplified - would need type checking
    }
    
    // Supervisor (level 14+) can view department requests
    if (user.level >= 14) {
      // Check if request is from user's department
      // This would need request.requesterDepartmentId field
      return true; // Simplified
    }
    
    // Regular staff can view their own requests
    if (request is VehicleRequestModel && request.requesterId == user.id) {
      return true;
    }
    
    return false;
  }

  /// Get list of request types/stages user can approve
  List<Map<String, dynamic>> getPendingApprovalsForUser(UserModel user) {
    final roles = _getUserRoles(user);
    final approvals = <Map<String, dynamic>>[];
    
    if (roles.contains(UserRole.dgs)) {
      // DGS can approve all types at all stages
      approvals.addAll([
        {'type': RequestType.vehicle, 'stage': 'DGS_REVIEW'},
        {'type': RequestType.vehicle, 'stage': 'DDGS_REVIEW'},
        {'type': RequestType.vehicle, 'stage': 'ADGS_REVIEW'},
        {'type': RequestType.ict, 'stage': 'DGS_REVIEW'},
        {'type': RequestType.store, 'stage': 'DGS_REVIEW'},
      ]);
    }
    
    // Supervisor (level 14+) can approve at SUPERVISOR_REVIEW stage
    // Note: Level 14+ users skip supervisor approval for their own requests
    if (user.level >= 14) {
      approvals.add({
        'type': RequestType.vehicle,
        'stage': 'SUPERVISOR_REVIEW',
      });
      approvals.add({
        'type': RequestType.ict,
        'stage': 'SUPERVISOR_REVIEW',
      });
      approvals.add({
        'type': RequestType.store,
        'stage': 'SUPERVISOR_REVIEW',
      });
    }
    
    if (roles.contains(UserRole.ddgs)) {
      approvals.add({
        'type': RequestType.vehicle,
        'stage': 'DDGS_REVIEW',
      });
      approvals.add({
        'type': RequestType.ict,
        'stage': 'DDGS_REVIEW',
      });
      approvals.add({
        'type': RequestType.store,
        'stage': 'DDGS_REVIEW',
      });
    }
    
    if (roles.contains(UserRole.adgs)) {
      approvals.add({
        'type': RequestType.vehicle,
        'stage': 'ADGS_REVIEW',
      });
      approvals.add({
        'type': RequestType.ict,
        'stage': 'ADGS_REVIEW',
      });
      approvals.add({
        'type': RequestType.store,
        'stage': 'ADGS_REVIEW',
      });
    }
    
    if (roles.contains(UserRole.ddict)) {
      approvals.add({
        'type': RequestType.ict,
        'stage': 'DDICT_REVIEW',
      });
    }
    
    return approvals;
  }

  /// Granular approval check at specific stage
  /// Matches backend logic: explicit roles take priority, then supervisor status
  bool canApproveAtStage(UserModel user, RequestType type, String workflowStage) {
    final roles = _getUserRoles(user);
    
    // DGS can approve at any stage for vehicle requests, but only at DGS_REVIEW for ICT requests
    if (roles.contains(UserRole.dgs)) {
      if (type == RequestType.ict) {
        final canApprove = workflowStage == 'DGS_REVIEW';
        print('[Permission Service] canApproveAtStage: DGS can approve ICT at DGS_REVIEW: $canApprove');
        return canApprove;
      }
      // For vehicle requests, DGS can approve at any stage
      print('[Permission Service] canApproveAtStage: DGS can approve vehicle at any stage');
      return true;
    }
    
    // Check explicit approver roles FIRST (priority order)
    // DDGS can approve at DDGS_REVIEW
    if (roles.contains(UserRole.ddgs) && workflowStage == 'DDGS_REVIEW') {
      print('[Permission Service] canApproveAtStage: DDGS can approve at DDGS_REVIEW');
      return true;
    }
    
    // ADGS can approve at ADGS_REVIEW
    if (roles.contains(UserRole.adgs) && workflowStage == 'ADGS_REVIEW') {
      print('[Permission Service] canApproveAtStage: ADGS can approve at ADGS_REVIEW');
      return true;
    }
    
    // TO can approve vehicle requests at TO_REVIEW
    if (roles.contains(UserRole.to) && 
        type == RequestType.vehicle && 
        workflowStage == 'TO_REVIEW') {
      print('[Permission Service] canApproveAtStage: TO can approve at TO_REVIEW');
      return true;
    }
    
    // DDICT can approve ICT requests at DDICT_REVIEW
    if (roles.contains(UserRole.ddict) && 
        type == RequestType.ict && 
        workflowStage == 'DDICT_REVIEW') {
      print('[Permission Service] canApproveAtStage: DDICT can approve at DDICT_REVIEW');
      return true;
    }
    
    // SO can approve ICT/Store requests at SO_REVIEW
    if (roles.contains(UserRole.so) && 
        (type == RequestType.ict || type == RequestType.store) &&
        workflowStage == 'SO_REVIEW') {
      print('[Permission Service] canApproveAtStage: SO can approve at SO_REVIEW');
      return true;
    }
    
    // THEN check supervisor status (allows dual capacity)
    // Supervisor (level 14+) can approve at SUPERVISOR_REVIEW or SUBMITTED (for vehicle requests)
    // SUBMITTED is allowed for vehicle requests because they should auto-advance but might still be at SUBMITTED
    if (user.level >= 14) {
      if (type == RequestType.vehicle) {
        final canApprove = workflowStage == 'SUPERVISOR_REVIEW' || workflowStage == 'SUBMITTED';
        print('[Permission Service] canApproveAtStage: Supervisor (level ${user.level}) can approve vehicle at SUPERVISOR_REVIEW/SUBMITTED: $canApprove');
        return canApprove;
      }
      final canApprove = workflowStage == 'SUPERVISOR_REVIEW';
      print('[Permission Service] canApproveAtStage: Supervisor (level ${user.level}) can approve at SUPERVISOR_REVIEW: $canApprove');
      return canApprove;
    }
    
    print('[Permission Service] canApproveAtStage: User cannot approve at stage $workflowStage');
    return false;
  }

  /// Check if supervisor can approve this request (department match)
  /// Supervisor is level 14+ in the same department as the requester
  /// Uses canActAsSupervisor to allow dual capacity
  bool isSupervisorForRequest(UserModel user, dynamic request) {
    // User must be able to act as supervisor (level 14+)
    if (!canActAsSupervisor(user)) {
      print('[Permission Service] isSupervisorForRequest: User cannot act as supervisor');
      return false;
    }
    
    // Check if request is from user's department
    // This would need request.requesterDepartmentId field
    // For now, simplified check
    if (request is VehicleRequestModel) {
      // Would need to check request.requesterDepartmentId == user.departmentId
      // For now, return true if user can act as supervisor
      print('[Permission Service] isSupervisorForRequest: User can act as supervisor for vehicle request');
      return true; // Simplified - department check would be done in backend
    }
    
    return false;
  }

  /// Check if DGS can assign vehicle at current stage
  bool canDGSAssignVehicle(UserModel user, dynamic request) {
    final roles = _getUserRoles(user);
    if (!roles.contains(UserRole.dgs)) return false;
    
    if (request is VehicleRequestModel) {
      // DGS can assign at DGS_REVIEW stage or any stage
      return request.status == RequestStatus.approved || 
             request.status == RequestStatus.pending;
    }
    
    return false;
  }

  /// Check if user can view department requests
  /// Supervisor is level 14+ in the same department
  /// Uses canActAsSupervisor to allow dual capacity
  bool canViewDepartmentRequests(UserModel user) {
    return canActAsSupervisor(user);
  }

  /// Get list of request types user can see
  List<RequestType> getVisibleRequestTypes(UserModel user) {
    final roles = _getUserRoles(user);
    
    if (roles.contains(UserRole.dgs)) {
      return [RequestType.vehicle, RequestType.ict, RequestType.store];
    }
    
    if (roles.contains(UserRole.to)) {
      return [RequestType.vehicle];
    }
    
    if (roles.contains(UserRole.ddict)) {
      return [RequestType.ict];
    }
    
    if (roles.contains(UserRole.so)) {
      return [RequestType.ict, RequestType.store];
    }
    
    // All other roles can see all types
    return [RequestType.vehicle, RequestType.ict, RequestType.store];
  }

  /// Check if user can approve any requests (at any stage for any request type)
  /// This is used to determine if "Pending Approvals" menu should be shown
  bool canApproveAnyRequests(UserModel user) {
    final roles = _getUserRoles(user);
    
    // DGS can approve everything
    if (roles.contains(UserRole.dgs)) {
      return true;
    }
    
    // Check if user has any explicit approver roles
    if (roles.contains(UserRole.ddgs) ||
        roles.contains(UserRole.adgs) ||
        roles.contains(UserRole.to) ||
        roles.contains(UserRole.ddict) ||
        roles.contains(UserRole.so)) {
      return true;
    }
    
    // Check if user can act as supervisor (level 14+)
    if (canActAsSupervisor(user)) {
      return true;
    }
    
    return false;
  }

  /// Get workflow stages user can see for a request type
  List<String> getVisibleWorkflowStages(UserModel user, RequestType type) {
    final roles = _getUserRoles(user);
    final stages = <String>[];
    
    if (roles.contains(UserRole.dgs)) {
      // DGS can see all stages
      return [
        'SUBMITTED',
        'SUPERVISOR_REVIEW',
        'DGS_REVIEW',
        'DDGS_REVIEW',
        'ADGS_REVIEW',
        'TO_REVIEW',
        'DDICT_REVIEW',
        'SO_REVIEW',
        'FULFILLMENT',
      ];
    }
    
    // Supervisor (level 14+) can see SUPERVISOR_REVIEW stage
    // Note: Level 14+ users skip supervisor approval for their own requests
    if (user.level >= 14) {
      stages.add('SUPERVISOR_REVIEW');
    }
    
    if (roles.contains(UserRole.ddgs)) {
      stages.add('DDGS_REVIEW');
    }
    
    if (roles.contains(UserRole.adgs)) {
      stages.add('ADGS_REVIEW');
    }
    
    if (roles.contains(UserRole.ddict) && type == RequestType.ict) {
      stages.add('DDICT_REVIEW');
    }
    
    if (roles.contains(UserRole.to) && type == RequestType.vehicle) {
      stages.add('TO_REVIEW');
    }
    
    if (roles.contains(UserRole.so) && 
        (type == RequestType.ict || type == RequestType.store)) {
      stages.add('SO_REVIEW');
    }
    
    return stages;
  }

  /// Check if user can view fuel/distance estimates (DGS, TO, DDGS, ADGS, Driver)
  bool canViewFuelDistanceEstimate(UserModel user) {
    final roles = _getUserRoles(user);
    return roles.contains(UserRole.dgs) ||
           roles.contains(UserRole.to) ||
           roles.contains(UserRole.ddgs) ||
           roles.contains(UserRole.adgs) ||
           roles.contains(UserRole.driver);
  }


  /// Check if user can end trip (Driver only, unless override)
  bool canEndTrip(UserModel user, dynamic request) {
    final roles = _getUserRoles(user);
    
    // Driver can end trip if they are assigned
    if (roles.contains(UserRole.driver)) {
      if (request is VehicleRequestModel) {
        return request.driverId == user.id;
      }
      return false;
    }
    
    // DGS and TO can end trips (override) - but typically only driver should
    return roles.contains(UserRole.dgs) || roles.contains(UserRole.to);
  }

  /// Check if user can cancel a request
  /// Rules:
  /// - Requester can cancel if no approvals exist and stage is in allowed stages
  /// - Allowed stages for requester: SUBMITTED, SUPERVISOR_REVIEW, DGS_REVIEW (Vehicle/Store) or DDICT_REVIEW (ICT)
  /// - Store/Vehicle: Supervisor (for lower level) or DGS (for higher level)
  /// - ICT: Supervisor (for lower level) or DDICT (for higher level)
  bool canCancelRequest(UserModel user, RequestType type, dynamic request) {
    final workflowStage = request.workflowStage ?? 'SUBMITTED';
    final roles = _getUserRoles(user);
    
    // Check if user is the requester
    final isRequester = IdUtils.areIdsEqual(request.requesterId, user.id);
    final hasNoApprovals = request.approvals == null || request.approvals.isEmpty;

    // Define allowed stages for requester cancellation based on request type
    final allowedStages = type == RequestType.ict
        ? ['SUBMITTED', 'SUPERVISOR_REVIEW', 'DDICT_REVIEW']
        : ['SUBMITTED', 'SUPERVISOR_REVIEW', 'DGS_REVIEW'];

    // Allow requester to cancel if no approvals exist and stage is allowed
    if (isRequester && hasNoApprovals && allowedStages.contains(workflowStage)) {
      return true;
    }

    // For non-requester cancellation, check existing Supervisor/DGS/DDICT logic
    // Can only cancel if still at SUBMITTED stage
    if (workflowStage != 'SUBMITTED') {
      return false;
    }
    
    // Get requester level (if available)
    int? requesterLevel;
    if (request.requesterId is Map) {
      requesterLevel = (request.requesterId as Map)['level'] as int?;
    }
    
    // If we can't determine requester level, we can't determine if user can cancel
    // In this case, we'll check if user has the appropriate role
    if (requesterLevel == null) {
      // For Store/Vehicle: DGS can cancel
      if (type == RequestType.store || type == RequestType.vehicle) {
        return roles.contains(UserRole.dgs) || canActAsSupervisor(user);
      }
      // For ICT: DDICT can cancel
      if (type == RequestType.ict) {
        return roles.contains(UserRole.ddict) || canActAsSupervisor(user);
      }
      return false;
    }

    final isLowerLevel = requesterLevel < 14;
    final isSupervisor = canActAsSupervisor(user);
    final isDGS = roles.contains(UserRole.dgs);
    final isDDICT = roles.contains(UserRole.ddict);

    if (type == RequestType.store || type == RequestType.vehicle) {
      // Store/Vehicle: Supervisor (lower level) or DGS (higher level)
      if (isLowerLevel && isSupervisor) {
        return true;
      }
      if (!isLowerLevel && isDGS) {
        return true;
      }
    } else if (type == RequestType.ict) {
      // ICT: Supervisor (lower level) or DDICT (higher level)
      if (isLowerLevel && isSupervisor) {
        return true;
      }
      if (!isLowerLevel && isDDICT) {
        return true;
      }
    }

    return false;
  }
}

