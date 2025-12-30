import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/animations/sheet_animations.dart';
import '../controllers/trip_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapControlButtons extends StatelessWidget {
  final GoogleMapController? mapController;
  final VoidCallback? onCenterLocation;
  final VoidCallback? onShowFullRoute;

  const MapControlButtons({
    Key? key,
    this.mapController,
    this.onCenterLocation,
    this.onShowFullRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      top: AppConstants.spacingXL + 60, // Below navigation panel
      right: AppConstants.spacingM,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Center on Current Location
          if (onCenterLocation != null)
            _buildControlButton(
              context,
              icon: Icons.my_location,
              tooltip: 'Center on Current Location',
              onTap: () {
                SheetHaptics.lightImpact();
                onCenterLocation!();
              },
              isDark: isDark,
            ),
          
          const SizedBox(height: AppConstants.spacingS),
          
          // Show Full Route
          if (onShowFullRoute != null)
            _buildControlButton(
              context,
              icon: Icons.fit_screen,
              tooltip: 'Show Full Route',
              onTap: () {
                SheetHaptics.lightImpact();
                onShowFullRoute!();
              },
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefined : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Icon(
            icon,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
