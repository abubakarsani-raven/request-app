import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../data/models/request_model.dart';

class StatusBadge extends StatelessWidget {
  final RequestStatus status;
  final String? workflowStage;
  final bool isSmall;
  final bool? isPartiallyFulfilled; // Optional flag to indicate partial fulfillment

  const StatusBadge({
    Key? key,
    required this.status,
    this.workflowStage,
    this.isSmall = false,
    this.isPartiallyFulfilled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check for partially fulfilled status first
    if (isPartiallyFulfilled == true || 
        (status == RequestStatus.approved && 
         workflowStage == 'FULFILLMENT' && 
         isPartiallyFulfilled != false)) {
      final (color, text) = (AppColors.warning, 'Partially Fulfilled');
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 12,
          vertical: isSmall ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: isSmall ? 10 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // Prefer workflow stage if available, otherwise use status
    final (color, text) = workflowStage != null
        ? _getWorkflowStageInfo(workflowStage!)
        : _getStatusInfo(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _getWorkflowStageInfo(String stage) {
    switch (stage.toUpperCase()) {
      case 'SUBMITTED':
        return (AppColors.statusPending, 'Submitted');
      case 'SUPERVISOR_REVIEW':
        return (AppColors.statusPending, 'Supervisor Review');
      case 'DGS_REVIEW':
        return (AppColors.statusPending, 'DGS Review');
      case 'DDGS_REVIEW':
        return (AppColors.statusPending, 'DDGS Review');
      case 'ADGS_REVIEW':
        return (AppColors.statusPending, 'ADGS Review');
      case 'TO_REVIEW':
        return (AppColors.statusPending, 'TO Review');
      case 'ASSIGNED':
        return (AppColors.statusAssigned, 'Assigned');
      default:
        return _getStatusInfo(status);
    }
  }

  (Color, String) _getStatusInfo(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return (AppColors.statusPending, 'Pending');
      case RequestStatus.approved:
        return (AppColors.statusApproved, 'Approved');
      case RequestStatus.rejected:
        return (AppColors.statusRejected, 'Rejected');
      case RequestStatus.corrected:
        return (AppColors.statusCorrected, 'Correction Required');
      case RequestStatus.assigned:
        return (AppColors.statusAssigned, 'Assigned');
      case RequestStatus.fulfilled:
        return (AppColors.statusApproved, 'Fulfilled');
      case RequestStatus.completed:
        return (AppColors.statusCompleted, 'Completed');
    }
  }
}

