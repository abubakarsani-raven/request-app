import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/request_model.dart';
import '../../../core/theme/app_colors.dart';

/// Visual workflow progress indicator showing all stages and participants
class WorkflowProgressIndicator extends StatelessWidget {
  final VehicleRequestModel request;

  const WorkflowProgressIndicator({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stages = _getWorkflowStages();
    final currentStageIndex = _getCurrentStageIndex(stages);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
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
                      fontSize: 16,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
              participant: _getParticipantForStage(stage),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStageItem(
    BuildContext context, {
    required Map<String, dynamic> stage,
    required bool isCompleted,
    required bool isCurrent,
    required bool isPending,
    Map<String, dynamic>? participant,
  }) {
    final stageName = stage['name'] as String;
    final stageDescription = stage['description'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stage indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.success
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.border,
                  border: Border.all(
                    color: isCurrent ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : isCurrent
                        ? const Icon(Icons.radio_button_checked, color: Colors.white, size: 18)
                        : const Icon(Icons.radio_button_unchecked, color: Colors.white, size: 18),
              ),
              if (!isPending)
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted ? AppColors.success : AppColors.border,
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Stage details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stageName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCurrent
                        ? AppColors.primary
                        : isCompleted
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
                if (stageDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    stageDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (participant != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        participant['name'] as String? ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (participant['timestamp'] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${DateFormat('MMM dd, HH:mm').format(participant['timestamp'] as DateTime)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getWorkflowStages() {
    final stages = <Map<String, dynamic>>[];

    // Add stages based on workflow stage
    stages.add({
      'name': 'Submitted',
      'description': 'Request submitted',
      'stage': 'SUBMITTED',
    });

    if (request.workflowStage != null) {
      final workflowStage = request.workflowStage!;
      
      if (workflowStage.contains('SUPERVISOR')) {
        stages.add({
          'name': 'Supervisor Review',
          'description': 'Awaiting supervisor approval',
          'stage': 'SUPERVISOR_REVIEW',
        });
      }

      if (workflowStage.contains('DGS')) {
        stages.add({
          'name': 'DGS Review',
          'description': 'Awaiting DGS approval',
          'stage': 'DGS_REVIEW',
        });
      }

      if (workflowStage.contains('DDGS')) {
        stages.add({
          'name': 'DDGS Review',
          'description': 'Awaiting DDGS approval',
          'stage': 'DDGS_REVIEW',
        });
      }

      if (workflowStage.contains('ADGS')) {
        stages.add({
          'name': 'ADGS Review',
          'description': 'Awaiting ADGS approval',
          'stage': 'ADGS_REVIEW',
        });
      }

      if (workflowStage.contains('TO')) {
        stages.add({
          'name': 'Transport Officer',
          'description': 'Vehicle assignment',
          'stage': 'TO_REVIEW',
        });
      }

      if (workflowStage.contains('FULFILLMENT')) {
        stages.add({
          'name': 'Fulfillment',
          'description': 'Request fulfilled',
          'stage': 'FULFILLMENT',
        });
      }
    }

    // Add completion stage if approved or completed
    if (request.status == RequestStatus.approved ||
        request.status == RequestStatus.assigned ||
        request.status == RequestStatus.completed ||
        request.status == RequestStatus.fulfilled) {
      stages.add({
        'name': 'Completed',
        'description': 'Request completed',
        'stage': 'COMPLETED',
      });
    }

    return stages;
  }

  int _getCurrentStageIndex(List<Map<String, dynamic>> stages) {
    if (request.status == RequestStatus.rejected) {
      // Find the last completed stage before rejection
      for (int i = stages.length - 1; i >= 0; i--) {
        if (stages[i]['stage'] == request.workflowStage) {
          return i;
        }
      }
      return 0;
    }

    // Find current stage
    for (int i = 0; i < stages.length; i++) {
      if (stages[i]['stage'] == request.workflowStage) {
        return i;
      }
    }

    // Default to first stage if not found
    return 0;
  }

  Map<String, dynamic>? _getParticipantForStage(Map<String, dynamic> stage) {
    // Try to find participant from approvals
    if (request.approvals.isNotEmpty) {
      for (var approval in request.approvals) {
        // Match approval role to stage
        final stageName = stage['name'] as String;
        if (stageName.contains('Supervisor') && approval.role.toString().contains('SUPERVISOR')) {
          return {
            'name': 'Approved by Supervisor',
            'timestamp': approval.timestamp,
            'action': approval.status,
          };
        }
        if (stageName.contains('DGS') && approval.role.toString().contains('DGS')) {
          return {
            'name': 'Approved by DGS',
            'timestamp': approval.timestamp,
            'action': approval.status,
          };
        }
        // Add more matches as needed
      }
    }

    return null;
  }
}

