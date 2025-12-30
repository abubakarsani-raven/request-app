import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/trip_controller.dart';
import '../../data/models/route_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Navigation panel showing current step, distance, ETA, and traffic
class NavigationPanel extends StatelessWidget {
  final bool isReturnRoute;

  const NavigationPanel({
    Key? key,
    this.isReturnRoute = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripController>();

    return Obx(() {
      final route = isReturnRoute ? controller.returnRoute.value : controller.currentRoute.value;
      final isDemoMode = StorageService.isDemoModeEnabled();

      if (route == null) {
        return const SizedBox.shrink();
      }

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM, vertical: AppConstants.spacingS),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM, vertical: AppConstants.spacingM),
        decoration: BoxDecoration(
          color: isDark 
              ? AppColors.darkSurface.withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? AppColors.darkBorderDefined.withOpacity(0.3)
                : AppColors.borderLight.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Demo mode indicator (compact)
            if (isDemoMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science, size: 12, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      'Demo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            if (isDemoMode) const SizedBox(width: AppConstants.spacingS),
            
            // Distance
            _buildCompactInfoItem(
              context,
              Icons.straighten,
              'Distance',
              route.formattedDistance,
            ),
            
            // ETA
            _buildCompactInfoItem(
              context,
              Icons.access_time,
              'ETA',
              route.formattedDuration,
            ),
            
            // Traffic
            _buildCompactTrafficIndicator(route.trafficLevel),
          ],
        ),
      );
    });
  }

  Widget _buildCompactInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textSecondary,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTrafficIndicator(TrafficLevel level) {
    Color color;
    String label;
    IconData icon;

    switch (level) {
      case TrafficLevel.free:
        color = AppColors.success;
        label = 'Free';
        icon = Icons.check_circle;
        break;
      case TrafficLevel.moderate:
        color = AppColors.warning;
        label = 'Moderate';
        icon = Icons.warning;
        break;
      case TrafficLevel.heavy:
        color = AppColors.error;
        label = 'Heavy';
        icon = Icons.error;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Traffic',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

