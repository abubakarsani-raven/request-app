import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class TripProgressWidget extends StatelessWidget {
  final VehicleRequestModel request;

  const TripProgressWidget({Key? key, required this.request}) : super(key: key);

  double _calculateProgress() {
    if (!request.tripStarted) return 0.0;
    if (request.tripCompleted) return 1.0;
    if (request.destinationReached) return 0.75;
    return 0.5; // In progress
  }

  List<TripStageInfo> _getTripStages() {
    final stages = <TripStageInfo>[];

    // Stage 1: Started
    stages.add(TripStageInfo(
      name: 'Started',
      isCompleted: request.tripStarted,
      timestamp: request.tripStarted ? request.actualDepartureTime : null,
      description: 'Trip started from office',
      icon: Icons.play_arrow,
    ));

    // Stage 2: In Progress
    stages.add(TripStageInfo(
      name: 'In Progress',
      isCompleted: request.tripStarted && !request.destinationReached,
      isCurrent: request.tripStarted && !request.destinationReached && !request.tripCompleted,
      timestamp: request.tripStarted ? request.actualDepartureTime : null,
      description: 'Heading to destination',
      icon: Icons.directions_car,
    ));

    // Stage 3: Destination Reached
    stages.add(TripStageInfo(
      name: 'Destination Reached',
      isCompleted: request.destinationReached,
      isCurrent: request.destinationReached && !request.tripCompleted,
      timestamp: request.destinationReached ? request.destinationReachedTime : null,
      description: 'Arrived at destination',
      icon: Icons.location_on,
    ));

    // Stage 4: Returned
    stages.add(TripStageInfo(
      name: 'Returned',
      isCompleted: request.tripCompleted,
      isCurrent: false,
      timestamp: request.tripCompleted ? (request.actualReturnTime ?? request.updatedAt) : null,
      description: 'Returned to office',
      icon: Icons.home,
    ));

    return stages;
  }

  Color _getProgressColor() {
    if (!request.tripStarted) return AppColors.textDisabled;
    if (request.tripCompleted) return AppColors.success;
    if (request.destinationReached) return AppColors.accent;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = _calculateProgress();
    final progressColor = _getProgressColor();
    final stages = _getTripStages();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: progressColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Trip Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDark 
                    ? AppColors.darkBorderDefined 
                    : AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            // Timeline
            ...stages.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              final isLast = index == stages.length - 1;
              return _buildStageItem(context, stage, isLast, progressColor, isDark);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStageItem(
    BuildContext context,
    TripStageInfo stage,
    bool isLast,
    Color progressColor,
    bool isDark,
  ) {
    final isCompleted = stage.isCompleted;
    final isCurrent = stage.isCurrent ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : isCurrent
                        ? progressColor
                        : AppColors.textDisabled,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success
                      : isCurrent
                          ? progressColor
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
                Row(
                  children: [
                    Icon(
                      stage.icon,
                      size: 16,
                      color: isCompleted
                          ? AppColors.success
                          : isCurrent
                              ? progressColor
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Expanded(
                      child: Text(
                        stage.name,
                        style: TextStyle(
                          fontWeight: isCompleted || isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted
                              ? AppColors.success
                              : isCurrent
                                  ? progressColor
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
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
  final IconData icon;

  TripStageInfo({
    required this.name,
    required this.isCompleted,
    this.isCurrent,
    this.timestamp,
    this.description,
    required this.icon,
  });
}
