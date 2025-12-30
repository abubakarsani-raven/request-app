import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/trip_controller.dart';
import '../../data/models/route_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Expandable list of all navigation steps
class DirectionsList extends StatefulWidget {
  final bool isReturnRoute;

  const DirectionsList({
    Key? key,
    this.isReturnRoute = false,
  }) : super(key: key);

  @override
  State<DirectionsList> createState() => _DirectionsListState();
}

class _DirectionsListState extends State<DirectionsList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripController>();

    return Obx(() {
      final route = widget.isReturnRoute ? controller.returnRoute.value : controller.currentRoute.value;
      final steps = controller.navigationSteps;
      final currentIndex = controller.currentStepIndex.value;

      if (route == null || steps.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Row(
                  children: [
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Directions (${steps.length} steps)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      route.formattedDistance,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Steps list
            if (_isExpanded)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    final isCurrent = index == currentIndex;
                    final isPast = index < currentIndex;

                    return _buildStepItem(
                      context,
                      step,
                      index + 1,
                      isCurrent,
                      isPast,
                      () {
                        controller.currentStepIndex.value = index;
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildStepItem(
    BuildContext context,
    RouteStep step,
    int stepNumber,
    bool isCurrent,
    bool isPast,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withOpacity(0.1)
              : isPast
                  ? AppColors.textSecondary.withOpacity(0.05)
                  : Colors.transparent,
          border: isCurrent
              ? Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary
                    : isPast
                        ? AppColors.textSecondary.withOpacity(0.3)
                        : AppColors.surface,
                shape: BoxShape.circle,
                border: isCurrent
                    ? null
                    : Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: isCurrent
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            // Step content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.cleanInstruction,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isPast
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: isPast ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${step.distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${step.duration.toStringAsFixed(0)} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Icon(
                Icons.navigation,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

