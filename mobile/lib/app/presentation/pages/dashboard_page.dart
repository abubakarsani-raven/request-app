import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../../data/models/request_model.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/custom_toast.dart';
import '../controllers/notification_controller.dart';
import '../widgets/bottom_sheets/create_request_bottom_sheet.dart';
import '../widgets/bottom_sheets/create_ict_request_bottom_sheet.dart';
import '../widgets/bottom_sheets/create_store_request_bottom_sheet.dart';
import 'assign_vehicle_list_page.dart';

/// Content-only widget for the Home tab in MainShellPage. No scaffold, no drawer.
class DashboardContent extends StatefulWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.find<NotificationController>().loadUnreadCount();
        Get.find<RequestController>().loadPendingApprovals();
        Get.find<ICTRequestController>().loadPendingApprovals();
        Get.find<StoreRequestController>().loadPendingApprovals();
      } catch (e) {
        print('Error initializing controllers in dashboard: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final permissionService = Get.find<PermissionService>();
    final notificationController = Get.find<NotificationController>();

    return Obx(() {
      final user = authController.user.value;
      if (user == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: title + notification
              Row(
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    final unreadCount = notificationController.unreadCount.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(AppIcons.notificationsOutlined),
                          onPressed: () => Get.toNamed('/notifications'),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(AppConstants.spacingXS),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.textOnPrimary, width: 2),
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Center(
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: AppColors.textOnPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              // Modern Welcome Card - Flat Design
                        Builder(
                          builder: (context) {
                            final theme = Theme.of(context);
                            final isDark = theme.brightness == Brightness.dark;
                            
                            return Container(
                              padding: EdgeInsets.all(AppConstants.spacingL + 4),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? AppColors.darkSurface 
                                    : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                                border: Border.all(
                                  color: isDark 
                                      ? AppColors.darkBorderDefined.withOpacity(0.5)
                                      : AppColors.primaryDark.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                    color: (isDark ? AppColors.darkTextPrimary : AppColors.textOnPrimary).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textOnPrimary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                                          user.name,
                                          style: AppTextStyles.h3.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.textOnPrimary,
                                            fontSize: 24,
                                          ),
                    ),
                                        const SizedBox(height: 6),
                    Text(
                                          'Level ${user.level} • ${permissionService.getPrimaryRole(user)}',
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textOnPrimary.withOpacity(0.95),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                                ],
                    ),
                    if (user.roles.isNotEmpty) ...[
                                const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                                  runSpacing: 10,
                        children: user.roles
                            .map(
                                        (role) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkSurfaceLight.withOpacity(0.5)
                                                : AppColors.textOnPrimary.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(AppConstants.radiusL),
                                            border: Border.all(
                                              color: isDark
                                                  ? AppColors.darkBorderDefined.withOpacity(0.5)
                                                  : AppColors.textOnPrimary.withOpacity(0.25),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            role,
                                            style: TextStyle(
                                              color: isDark 
                                                  ? AppColors.darkTextPrimary 
                                                  : Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
                            );
                          },
                        ),
              const SizedBox(height: AppConstants.spacingXXL),
              // Role-Specific Quick Actions
              Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  
                  return Text(
                    'Quick Actions',
                    style: AppTextStyles.h3.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                  );
                },
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildRoleBasedActions(context, user, permissionService),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRoleBasedActions(
    BuildContext context,
    dynamic user,
    PermissionService permissionService,
  ) {
    final actions = <Widget>[];

    // Create Request (all except drivers)
    if (permissionService.canCreateRequest(user)) {
      actions.addAll([
        _buildActionCard(
          context,
          'Vehicle Request',
          Icons.directions_car,
          AppColors.primary,
          () => CreateRequestBottomSheet.show(context, 'vehicle'),
        ),
        _buildActionCard(
          context,
          'ICT Request',
          Icons.computer,
          AppColors.success,
          () => CreateICTRequestBottomSheet.show(context),
        ),
        _buildActionCard(
          context,
          'Store Request',
          Icons.inventory,
          AppColors.warning,
          () => CreateStoreRequestBottomSheet.show(context),
        ),
      ]);
    }

    // My Requests
    actions.add(
      _buildActionCard(
        context,
        'My Requests',
        Icons.list,
        AppColors.secondary,
        () => Get.toNamed('/requests/my'),
      ),
    );

    // Pending Requests (for approvers including supervisors)
    if (permissionService.canApproveAnyRequests(user)) {
      actions.add(
        Obx(() {
          if (!Get.isRegistered<RequestController>() ||
              !Get.isRegistered<ICTRequestController>() ||
              !Get.isRegistered<StoreRequestController>()) {
            return _buildActionCard(
              context,
              'Pending Requests',
              Icons.pending_actions,
              AppColors.warning,
              () => Get.toNamed('/requests/pending'),
            );
          }
          final requestController = Get.find<RequestController>();
          final ictController = Get.find<ICTRequestController>();
          final storeController = Get.find<StoreRequestController>();
          final vehicleRequests = requestController.vehicleRequests;
          final ictRequests = ictController.ictRequests;
          final storeRequests = storeController.storeRequests;
          int totalPending = 0;
          totalPending += vehicleRequests.where((r) =>
              r.status == RequestStatus.pending || r.status == RequestStatus.corrected).length;
          totalPending += ictRequests.where((r) =>
              r.status == RequestStatus.pending || r.status == RequestStatus.corrected).length;
          totalPending += storeRequests.where((r) =>
              r.status == RequestStatus.pending || r.status == RequestStatus.corrected).length;
          return _buildActionCard(
            context,
            'Pending Requests',
            Icons.pending_actions,
            AppColors.warning,
            () => Get.toNamed('/requests/pending'),
            badge: totalPending > 0 ? totalPending : null,
          );
        }),
      );
    }

    // Vehicle Assignment (TO/DGS)
    if (permissionService.canAssignVehicle(user)) {
      actions.add(
        _buildActionCard(
          context,
          'Assign Vehicles',
          Icons.assignment,
          AppColors.info,
          () => Get.to(() => AssignVehicleListPage()),
        ),
      );
    }

    // Fulfillment Queue (SO)
    if (permissionService.canFulfillRequest(user, RequestType.ict) ||
        permissionService.canFulfillRequest(user, RequestType.store)) {
      actions.add(
        _buildActionCard(
          context,
          'Fulfillment Queue',
          Icons.check_circle,
          AppColors.success,
          () => Get.toNamed('/requests?type=ict&status=approved'),
        ),
      );
    }

    // All Requests (for managers)
    if (permissionService.canViewAllRequests(user)) {
      actions.add(
        _buildActionCard(
          context,
          'All Requests',
          Icons.view_list,
          AppColors.info,
          () => Get.toNamed('/requests'),
        ),
      );
    }

    // Delete All Requests (DGS only - temporary)
    final isDGS = user.roles.any((role) => role.toUpperCase() == 'DGS');
    if (isDGS) {
      actions.add(
        _buildActionCard(
          context,
          'Delete All Requests',
          Icons.delete_forever,
          AppColors.error,
          () {
            _showDeleteAllDialog(context);
          },
        ),
      );
    }

    // Ensure even number of items for symmetry
    final evenActions = actions.length % 2 == 0 
        ? actions 
        : [...actions, SizedBox.shrink()]; // Add empty widget if odd
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppConstants.spacingM,
      mainAxisSpacing: AppConstants.spacingM,
      childAspectRatio: 1.05,
      children: evenActions,
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Requests'),
        content: const Text(
          'Are you sure you want to delete ALL requests (Vehicle, ICT, and Store)?\n\n'
          'This will:\n'
          '• Delete all vehicle, ICT, and store requests\n'
          '• Delete all related notifications\n'
          '• Set all vehicles and drivers to available\n'
          '• Preserve offices and users\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Safety check: Ensure controllers are registered before accessing
              if (!Get.isRegistered<RequestController>() || 
                  !Get.isRegistered<ICTRequestController>() || 
                  !Get.isRegistered<StoreRequestController>() ||
                  !Get.isRegistered<NotificationController>()) {
                CustomToast.error('Controllers not initialized. Please try again.');
                return;
              }
              
              final requestController = Get.find<RequestController>();
              final ictController = Get.find<ICTRequestController>();
              final storeController = Get.find<StoreRequestController>();
              final notificationController = Get.find<NotificationController>();
              
              final result = await requestController.deleteAllRequests();
              if (result) {
                // Clear all local state
                ictController.ictRequests.clear();
                storeController.storeRequests.clear();
                
                // Reload unread count
                await notificationController.loadUnreadCount();
                
                CustomToast.success('All requests deleted successfully');
              } else {
                CustomToast.error('Failed to delete requests');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int? badge,
  }) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            ),
          );
        },
        child: _SimpleActionCard(
          title: title,
          icon: icon,
          color: color,
          onTap: onTap,
          badge: badge,
        ),
      ),
    );
  }
}

class _SimpleActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const _SimpleActionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.darkSurface 
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusL + 4),
            border: Border.all(
              color: isDark 
                  ? AppColors.darkBorderDefined.withOpacity(0.3)
                  : AppColors.border.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppConstants.radiusL + 4),
              child: Padding(
                padding: EdgeInsets.all(AppConstants.spacingL - 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Badge
        if (badge != null && badge! > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                badge! > 99 ? '99+' : badge!.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
