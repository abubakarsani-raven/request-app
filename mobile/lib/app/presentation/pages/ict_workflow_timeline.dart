import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/ict_request_model.dart';
import '../../data/models/request_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ICTWorkflowTimeline extends StatelessWidget {
  final ICTRequestModel request;

  const ICTWorkflowTimeline({
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
        color: isDark 
            ? AppColors.darkSurface 
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: isDark 
              ? AppColors.darkBorderDefined.withOpacity(0.5)
              : AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primary, size: 20),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Workflow Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),
            ...stages.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              final isCompleted = index < currentStageIndex;
              final isCurrent = index == currentStageIndex;
              final isPending = index > currentStageIndex;

              return _buildStageItem(
                context,
                theme: theme,
                isDark: isDark,
                stage: stage,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isPending: isPending,
                isLast: index == stages.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStageItem(
    BuildContext context, {
    required ThemeData theme,
    required bool isDark,
    required WorkflowStageInfo stage,
    required bool isCompleted,
    required bool isCurrent,
    required bool isPending,
    required bool isLast,
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
                        : AppColors.textDisabled,
                border: Border.all(
                  color: isDark 
                      ? AppColors.darkSurface 
                      : theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: AppColors.textOnPrimary)
                  : isCurrent
                      ? const Icon(Icons.radio_button_checked, size: 14, color: AppColors.textOnPrimary)
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted
                    ? AppColors.success
                    : (isDark 
                        ? AppColors.darkBorderDefined.withOpacity(0.5)
                        : AppColors.border.withOpacity(0.3)),
              ),
          ],
        ),
        const SizedBox(width: AppConstants.spacingM),
        // Stage content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppConstants.spacingM),
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
                                  ? theme.colorScheme.primary
                                  : isCompleted
                                      ? (isDark 
                                          ? AppColors.darkTextPrimary 
                                          : AppColors.textPrimary)
                                      : (isDark 
                                          ? AppColors.darkTextSecondary 
                                          : AppColors.textSecondary),
                            ),
                      ),
                    ),
                    if (stage.timeAgo != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingS,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        ),
                        child: Text(
                          stage.timeAgo!,
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
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
                if (stage.approverName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Approved by: ${stage.approverName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
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
    
    // Correct ICT workflow stages (matching backend):
    // For level 14+: SUBMITTED → DDICT_REVIEW → DGS_REVIEW → SO_REVIEW → FULFILLMENT
    // For level < 14: SUBMITTED → SUPERVISOR_REVIEW → DDICT_REVIEW → DGS_REVIEW → SO_REVIEW → FULFILLMENT
    final workflowStages = [
      'SUBMITTED',
      'SUPERVISOR_REVIEW',  // Only shown if request hasn't skipped it (level 14+ skip this)
      'DDICT_REVIEW',
      'DGS_REVIEW',
      'SO_REVIEW',
      'FULFILLMENT',
    ];

    DateTime? previousTimestamp = request.createdAt;

    for (final stage in workflowStages) {
      // Skip SUPERVISOR_REVIEW if request is already at DDICT_REVIEW or later
      // This handles the case where senior staff (level 14+) skip supervisor
      if (stage == 'SUPERVISOR_REVIEW') {
        final currentStage = request.workflowStage ?? 'SUBMITTED';
        if (currentStage == 'DDICT_REVIEW' || 
            currentStage == 'DGS_REVIEW' || 
            currentStage == 'SO_REVIEW' || 
            currentStage == 'FULFILLMENT') {
          continue; // Skip supervisor stage if already past it
        }
      }
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
      String? timeAgo;

      if (approval != null && approval.approverId.isNotEmpty) {
        stageTimestamp = approval.timestamp;
        approverName = 'Role: ${approval.role}';
        if (previousTimestamp != null) {
          final diff = stageTimestamp.difference(previousTimestamp);
          if (diff.isNegative) {
            duration = null; // Don't show wrong inter-step time if order is off
          } else {
            duration = _formatDuration(diff);
          }
        }
        timeAgo = _formatTimeAgo(stageTimestamp);
        previousTimestamp = stageTimestamp;
      } else if (stage == request.workflowStage) {
        // Current stage - use updatedAt
        stageTimestamp = request.updatedAt;
        if (previousTimestamp != null) {
          final diff = stageTimestamp.difference(previousTimestamp);
          if (!diff.isNegative) {
            duration = _formatDuration(diff);
          }
        }
        timeAgo = _formatTimeAgo(stageTimestamp);
        previousTimestamp = stageTimestamp;
      } else if (_isStageBeforeCurrent(stage, request.workflowStage ?? 'SUBMITTED')) {
        if (previousTimestamp != null) {
          stageTimestamp = previousTimestamp.add(const Duration(hours: 1));
          final diff = stageTimestamp.difference(previousTimestamp);
          duration = _formatDuration(diff);
          timeAgo = _formatTimeAgo(stageTimestamp);
          previousTimestamp = stageTimestamp;
        }
      }

      stages.add(WorkflowStageInfo(
        name: _formatStageName(stage),
        stage: stage,
        timestamp: stageTimestamp,
        approverName: approverName,
        duration: duration,
        timeAgo: timeAgo,
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
      case 'DDICT':
        return 'DDICT_REVIEW';
      case 'DGS':
        return 'DGS_REVIEW';
      case 'SO':
        return 'SO_REVIEW';
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
      case 'DDICT_REVIEW':
        return 'DDICT Review';
      case 'DGS_REVIEW':
        return 'DGS Review';
      case 'SO_REVIEW':
        return 'Store Officer Review';
      case 'FULFILLMENT':
        return 'Fulfillment';
      default:
        return stage;
    }
  }

  bool _isStageBeforeCurrent(String stage, String currentStage) {
    final stages = [
      'SUBMITTED',
      'SUPERVISOR_REVIEW',
      'DDICT_REVIEW',
      'DGS_REVIEW',
      'SO_REVIEW',
      'FULFILLMENT',
    ];
    final stageIndex = stages.indexOf(stage);
    final currentIndex = stages.indexOf(currentStage);
    return stageIndex >= 0 && currentIndex >= 0 && stageIndex < currentIndex;
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Just now';
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

  /// Relative time from [dateTime] to now (e.g. "1 month ago", "Just now"). Correct for current date.
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.isNegative) {
      return 'Just now';
    }
    if (diff.inDays > 365) {
      final years = diff.inDays ~/ 365;
      return years == 1 ? '1 year ago' : '$years years ago';
    }
    if (diff.inDays >= 30) {
      final months = diff.inDays ~/ 30;
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    if (diff.inDays >= 7) {
      final weeks = diff.inDays ~/ 7;
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    if (diff.inDays > 0) {
      return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    }
    if (diff.inHours > 0) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inMinutes > 0) {
      return diff.inMinutes == 1 ? '1 min ago' : '${diff.inMinutes} mins ago';
    }
    return 'Just now';
  }
}

class WorkflowStageInfo {
  final String name;
  final String stage;
  final DateTime? timestamp;
  final String? approverName;
  /// Time between this stage and the previous (e.g. "1h 0m"). May be null.
  final String? duration;
  /// Time ago from now (e.g. "1 month ago", "Just now"). Correct for current date.
  final String? timeAgo;

  WorkflowStageInfo({
    required this.name,
    required this.stage,
    this.timestamp,
    this.approverName,
    this.duration,
    this.timeAgo,
  });
}

