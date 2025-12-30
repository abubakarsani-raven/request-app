import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class TripWorkflowTimeline extends StatelessWidget {
  final VehicleRequestModel request;

  const TripWorkflowTimeline({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stages = _getTripStages();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ...stages.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              final isLast = index == stages.length - 1;
              return _buildStageItem(context, stage, isLast);
            }),
          ],
        ),
      ),
    );
  }

  List<TripStageInfo> _getTripStages() {
    final stages = <TripStageInfo>[];

    // Stage 1: Started
    stages.add(TripStageInfo(
      name: 'Started',
      isCompleted: request.tripStarted,
      timestamp: request.tripStarted ? request.actualDepartureTime : null,
      description: 'Trip started from office',
    ));

    // Stage 2: In Progress
    stages.add(TripStageInfo(
      name: 'In Progress',
      isCompleted: request.tripStarted && !request.destinationReached,
      isCurrent: request.tripStarted && !request.destinationReached && !request.tripCompleted,
      timestamp: request.tripStarted ? request.actualDepartureTime : null,
      description: 'Heading to destination',
    ));

    // Stage 3: Destination Reached
    stages.add(TripStageInfo(
      name: 'Destination Reached',
      isCompleted: request.destinationReached,
      isCurrent: request.destinationReached && !request.tripCompleted,
      timestamp: request.destinationReached ? request.destinationReachedTime : null,
      description: 'Arrived at destination',
    ));

    // Stage 4: Returned
    stages.add(TripStageInfo(
      name: 'Returned',
      isCompleted: request.tripCompleted,
      isCurrent: false,
      timestamp: request.tripCompleted ? (request.actualReturnTime ?? request.updatedAt) : null,
      description: 'Returned to office',
    ));

    return stages;
  }

  Widget _buildStageItem(BuildContext context, TripStageInfo stage, bool isLast) {
    final isCompleted = stage.isCompleted;
    final isCurrent = stage.isCurrent ?? false;

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
                  color: isCompleted
                      ? AppColors.success
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.textDisabled,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : isCurrent
                      ? Icon(Icons.radio_button_checked, size: 16, color: Colors.white)
                      : Icon(Icons.radio_button_unchecked, size: 16, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.success : AppColors.textDisabled,
              ),
          ],
        ),
        const SizedBox(width: AppConstants.spacingM),
        // Stage details
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0.0 : AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.name,
                  style: TextStyle(
                    fontWeight: isCompleted || isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? AppColors.success
                        : isCurrent
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                ),
                if (stage.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    stage.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                if (stage.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm').format(stage.timestamp!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
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
}

class TripStageInfo {
  final String name;
  final bool isCompleted;
  final bool? isCurrent;
  final DateTime? timestamp;
  final String? description;

  TripStageInfo({
    required this.name,
    required this.isCompleted,
    this.isCurrent,
    this.timestamp,
    this.description,
  });
}

