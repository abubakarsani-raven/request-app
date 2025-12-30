import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/driver_controller.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_drawer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../../data/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import 'trip_tracking_page.dart';

class DriverDashboardPage extends StatelessWidget {
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();

  DriverDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final driverController = Get.put(DriverController());
    final theme = Theme.of(context);

    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              AppIcons.menu,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => _drawerController.showDrawer(),
          ),
          title: Text(
            'Driver Dashboard',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => driverController.loadAssignedTrips(),
          color: theme.colorScheme.primary,
          child: Obx(
            () {
              if (driverController.isLoading.value && driverController.assignedTrips.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  children: [
                    const SkeletonCard(height: 150),
                    const SizedBox(height: AppConstants.spacingM),
                    const SkeletonCard(height: 150),
                    const SizedBox(height: AppConstants.spacingM),
                    const SkeletonCard(height: 150),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                children: [
                  // Active Trips
                  if (driverController.activeTrips.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Active Trips'),
                    const SizedBox(height: AppConstants.spacingM),
                    ...driverController.activeTrips.asMap().entries.map((entry) {
                      final index = entry.key;
                      final trip = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < driverController.activeTrips.length - 1
                              ? AppConstants.spacingM
                              : AppConstants.spacingXL,
                        ),
                        child: _buildTripCard(
                          context,
                          trip,
                          isActive: true,
                        ),
                      );
                    }),
                  ],

                  // Pending Trips
                  if (driverController.pendingTrips.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Pending Trips'),
                    const SizedBox(height: AppConstants.spacingM),
                    ...driverController.pendingTrips.asMap().entries.map((entry) {
                      final index = entry.key;
                      final trip = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < driverController.pendingTrips.length - 1
                              ? AppConstants.spacingM
                              : AppConstants.spacingXL,
                        ),
                        child: _buildTripCard(
                          context,
                          trip,
                          isActive: false,
                        ),
                      );
                    }),
                  ],

                  // Completed Trips
                  if (driverController.completedTrips.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Completed Trips'),
                    const SizedBox(height: AppConstants.spacingM),
                    ...driverController.completedTrips.take(5).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final trip = entry.value;
                      final isLast = index == (driverController.completedTrips.take(5).length - 1);
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: isLast ? 0 : AppConstants.spacingM,
                        ),
                        child: _buildTripCard(
                          context,
                          trip,
                          isActive: false,
                          isCompleted: true,
                        ),
                      );
                    }),
                  ],

                  if (driverController.assignedTrips.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingXXL),
                      child: EmptyState(
                        title: 'No Assigned Trips',
                        message: 'You will see your assigned trips here',
                        type: EmptyStateType.noData,
                        icon: AppIcons.vehicleFilled,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    VehicleRequestModel trip, {
    required bool isActive,
    bool isCompleted = false,
  }) {
    final driverController = Get.find<DriverController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark 
              ? AppColors.darkBorderDefined.withOpacity(0.5)
              : AppColors.border.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () async {
          // Navigate to trip page and refresh when returning
          final result = await Get.to(() => TripTrackingPage(requestId: trip.id));
          // Refresh trips when returning from trip page (especially if trip was completed)
          if (result == true || result == null) {
            driverController.loadAssignedTrips();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      trip.destination,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isCompleted
                            ? (isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.textSecondary)
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  StatusBadge(status: trip.status),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              // Scheduled Date/Time
              Row(
                children: [
                  Icon(
                    AppIcons.calendar,
                    size: AppIcons.sizeSmall,
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppConstants.spacingXS),
                  Text(
                    '${dateFormat.format(trip.tripDate)} at ${trip.tripTime}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXS),
              // Purpose
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    AppIcons.info,
                    size: AppIcons.sizeSmall,
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppConstants.spacingXS),
                  Expanded(
                    child: Text(
                      trip.purpose,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Active Trip Indicator
              if (isActive) ...[
                const SizedBox(height: AppConstants.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.location,
                        size: AppIcons.sizeSmall,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppConstants.spacingXS),
                      Text(
                        'Trip in Progress',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Completed Indicator
              if (isCompleted && trip.actualReturnTime != null) ...[
                const SizedBox(height: AppConstants.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.textSecondary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.textSecondary).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.check,
                        size: AppIcons.sizeSmall,
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppConstants.spacingXS),
                      Text(
                        'Completed ${dateFormat.format(trip.actualReturnTime!)}',
                        style: TextStyle(
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

