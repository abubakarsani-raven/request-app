import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/request_model.dart';
import '../../../core/theme/app_colors.dart';

class WorkflowTimeline extends StatelessWidget {
  final VehicleRequestModel request;

  const WorkflowTimeline({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stages = _getWorkflowStages();
    final currentStageIndex = _getCurrentStageIndex(stages);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? AppColors.darkBorderDefined.withOpacity(0.5)
              : AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Workflow Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...stages.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              final isCompleted = index < currentStageIndex;
              final isCurrent = index == currentStageIndex;
              final isPending = index > currentStageIndex;

              return _buildStageItem(
                context,
                stage: stage,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isPending: isPending,
                isLast: index == stages.length - 1,
                isDark: isDark,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStageItem(
    BuildContext context, {
    required WorkflowStageInfo stage,
    required bool isCompleted,
    required bool isCurrent,
    required bool isPending,
    required bool isLast,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : isCurrent
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextDisabled : AppColors.textDisabled),
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check, size: 14, color: isDark ? AppColors.darkSurface : Colors.white)
                  : isCurrent
                      ? Icon(Icons.radio_button_checked,
                          size: 14, color: isDark ? AppColors.darkSurface : Colors.white)
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted
                    ? AppColors.success
                    : (isDark 
                        ? AppColors.darkBorderDefined.withOpacity(0.3)
                        : AppColors.border.withOpacity(0.3)),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Stage content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stage.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? AppColors.primary
                                  : isCompleted
                                      ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                      ),
                    ),
                    if (stage.duration != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stage.duration!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (stage.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy hh:mm a').format(stage.timestamp!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                  ),
                ],
                if (stage.approverName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Approved by: ${stage.approverName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<WorkflowStageInfo> _getWorkflowStages() {
    final stages = <WorkflowStageInfo>[];
    final workflowStages = [
      'SUBMITTED',
      'SUPERVISOR_REVIEW',
      'DGS_REVIEW',
      'DDGS_REVIEW',
      'ADGS_REVIEW',
      'TO_REVIEW',
      'FULFILLMENT', // DGS Assigned Vehicle stage
    ];

    DateTime? previousTimestamp = request.createdAt;

    for (final stage in workflowStages) {
      // Find approval for this stage
      WorkflowApproval? approval;
      try {
        approval = request.approvals.firstWhere(
          (a) => _getStageForRole(a.role) == stage && a.status == 'APPROVED',
        );
      } catch (e) {
        // No approval found for this stage
      }

      DateTime? stageTimestamp;
      String? approverName;
      String? duration;

      // Check if vehicle was assigned (FULFILLMENT stage with vehicleId set)
      if (stage == 'FULFILLMENT' && request.vehicleId != null) {
        // Find approval for assignment (DGS or TO)
        WorkflowApproval? assignmentApproval;
        try {
          assignmentApproval = request.approvals.firstWhere(
            (a) => (a.role == 'DGS' || a.role == 'TO') && 
                   a.comment?.toLowerCase().contains('vehicle assigned') == true,
          );
        } catch (e) {
          // No specific assignment approval found, but vehicle is assigned
        }
        
        if (assignmentApproval != null) {
          stageTimestamp = assignmentApproval.timestamp;
          approverName = '${assignmentApproval.role} Assigned Vehicle';
          if (previousTimestamp != null) {
            final diff = stageTimestamp.difference(previousTimestamp);
            duration = _formatDuration(diff);
          }
          previousTimestamp = stageTimestamp;
        } else if (request.workflowStage == 'FULFILLMENT') {
          // Vehicle is assigned but no approval entry yet - use updatedAt
          stageTimestamp = request.updatedAt;
          approverName = 'Vehicle Assigned';
          if (previousTimestamp != null) {
            final diff = stageTimestamp.difference(previousTimestamp);
            duration = _formatDuration(diff);
          }
          previousTimestamp = stageTimestamp;
        }
      } else if (approval != null && approval.approverId.isNotEmpty) {
        stageTimestamp = approval.timestamp;
        approverName = 'Role: ${approval.role}';
        if (previousTimestamp != null) {
          final diff = stageTimestamp.difference(previousTimestamp);
          duration = _formatDuration(diff);
        }
        previousTimestamp = stageTimestamp;
      } else if (stage == request.workflowStage) {
        // Current stage - use updatedAt or createdAt
        stageTimestamp = request.updatedAt;
        if (previousTimestamp != null) {
          final diff = stageTimestamp.difference(previousTimestamp);
          duration = _formatDuration(diff);
        }
        previousTimestamp = stageTimestamp;
      } else if (_isStageBeforeCurrent(stage, request.workflowStage ?? 'SUBMITTED')) {
        // Stage is before current but no approval found - might be skipped
        // Use estimated time based on createdAt
        if (previousTimestamp != null) {
          // Estimate: assume 1 hour per stage if no timestamp
          stageTimestamp = previousTimestamp.add(const Duration(hours: 1));
          final diff = stageTimestamp.difference(previousTimestamp);
          duration = _formatDuration(diff);
          previousTimestamp = stageTimestamp;
        }
      }

      stages.add(WorkflowStageInfo(
        name: _formatStageName(stage),
        stage: stage,
        timestamp: stageTimestamp,
        approverName: approverName,
        duration: duration,
      ));
    }

    return stages;
  }

  int _getCurrentStageIndex(List<WorkflowStageInfo> stages) {
    if (request.workflowStage == null) return 0;
    return stages.indexWhere(
          (s) => s.stage == request.workflowStage,
        ) >= 0
        ? stages.indexWhere((s) => s.stage == request.workflowStage)
        : stages.length - 1;
  }

  String _getStageForRole(String role) {
    switch (role.toUpperCase()) {
      case 'SUPERVISOR':
        return 'SUPERVISOR_REVIEW';
      case 'DGS':
        return 'DGS_REVIEW';
      case 'DDGS':
        return 'DDGS_REVIEW';
      case 'ADGS':
        return 'ADGS_REVIEW';
      case 'TO':
        return 'TO_REVIEW';
      default:
        return '';
    }
  }

  String _formatStageName(String stage) {
    switch (stage) {
      case 'SUBMITTED':
        return 'Submitted';
      case 'SUPERVISOR_REVIEW':
        return 'Supervisor Review';
      case 'DGS_REVIEW':
        return 'DGS Review';
      case 'DDGS_REVIEW':
        return 'DDGS Review';
      case 'ADGS_REVIEW':
        return 'ADGS Review';
      case 'TO_REVIEW':
        return 'Transport Officer Review';
      case 'ASSIGNED':
        return 'Assigned';
      case 'FULFILLMENT':
        return 'DGS Assigned Vehicle';
      default:
        return stage;
    }
  }

  bool _isStageBeforeCurrent(String stage, String currentStage) {
    final stages = [
      'SUBMITTED',
      'SUPERVISOR_REVIEW',
      'DGS_REVIEW',
      'DDGS_REVIEW',
      'ADGS_REVIEW',
      'TO_REVIEW',
      'ASSIGNED',
    ];
    final stageIndex = stages.indexOf(stage);
    final currentIndex = stages.indexOf(currentStage);
    return stageIndex >= 0 && currentIndex >= 0 && stageIndex < currentIndex;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}

class WorkflowStageInfo {
  final String name;
  final String stage;
  final DateTime? timestamp;
  final String? approverName;
  final String? duration;

  WorkflowStageInfo({
    required this.name,
    required this.stage,
    this.timestamp,
    this.approverName,
    this.duration,
  });
}

