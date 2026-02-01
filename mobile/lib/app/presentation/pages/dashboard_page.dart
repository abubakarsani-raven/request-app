import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/auth_controller.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../../data/models/request_model.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/custom_toast.dart';
import '../widgets/app_drawer.dart';
import '../controllers/notification_controller.dart';
import '../widgets/bottom_sheets/create_request_bottom_sheet.dart';
import '../widgets/bottom_sheets/create_ict_request_bottom_sheet.dart';
import '../widgets/bottom_sheets/create_store_request_bottom_sheet.dart';
import 'driver_dashboard_page.dart';
import 'assign_vehicle_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();
  
  @override
  void initState() {
    super.initState();
    // Controllers are now eagerly initialized in InitialBinding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Controllers are already registered in InitialBinding
        final notificationController = Get.find<NotificationController>();
        notificationController.loadUnreadCount();
        
        // Load pending approvals for badge count
        final requestController = Get.find<RequestController>();
        final ictController = Get.find<ICTRequestController>();
        final storeController = Get.find<StoreRequestController>();
        
        requestController.loadPendingApprovals();
        ictController.loadPendingApprovals();
        storeController.loadPendingApprovals();
      } catch (e) {
        print('Error initializing controllers in dashboard: $e');
        // Controllers will be available on next build cycle
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AuthController authController;
    PermissionService permissionService;
    NotificationController notificationController;
    try {
      authController = Get.find<AuthController>();
      permissionService = Get.find<PermissionService>();
      notificationController = Get.find<NotificationController>();
    } catch (_) {
      return AppDrawer(
        controller: _drawerController,
        child: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Obx(() {
      final user = authController.user.value;
      if (user == null) {
        return AppDrawer(
          controller: _drawerController,
          child: Scaffold(
            body: const Center(child: CircularProgressIndicator()),
          ),
        );
      }

      // Driver gets special dashboard
      if (permissionService.isDriver(user)) {
        return DriverDashboardPage();
      }

      return AppDrawer(
        controller: _drawerController,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(AppIcons.menu),
              onPressed: () => _drawerController.showDrawer(),
            ),
            title: const Text('Dashboard'),
            actions: [
              Obx(() {
                // Access the reactive value directly - Obx will rebuild when this changes
                final unreadCount = notificationController.unreadCount.value;
                
                // Debug: Print unread count to verify it's updating
                print('🔔 Notification badge - unreadCount: $unreadCount');
                
                return Container(
                  width: 48,
                  height: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(AppIcons.notificationsOutlined),
                        onPressed: () => Get.toNamed('/notifications'),
                        padding: EdgeInsets.zero,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
          body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                        // Modern Welcome Card - Flat Design
                        Builder(
                          builder: (context) {
                            final theme = Theme.of(context);
                            final isDark = theme.brightness == Brightness.dark;
                            
                            return Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? AppColors.darkSurface 
                                    : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(24),
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
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: isDark 
                                          ? AppColors.darkTextPrimary 
                                          : Colors.white,
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
                                          style: TextStyle(
                                            color: isDark 
                                                ? AppColors.darkTextPrimary 
                                                : Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                            height: 1.3,
                                          ),
                    ),
                                        const SizedBox(height: 6),
                    Text(
                                          'Level ${user.level} • ${permissionService.getPrimaryRole(user)}',
                                          style: TextStyle(
                                            color: isDark 
                                                ? AppColors.darkTextSecondary 
                                                : Colors.white.withOpacity(0.95),
                                            fontSize: 15,
                                            height: 1.5,
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
                                                : Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isDark 
                                                  ? AppColors.darkBorderDefined.withOpacity(0.5)
                                                  : Colors.white.withOpacity(0.25),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: -0.5,
                          height: 1.3,
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

    // Pending Approvals (for approvers including supervisors)
    // Use canApproveAnyRequests to check if user can approve at any stage
    if (permissionService.canApproveAnyRequests(user)) {
      actions.add(
        Obx(() {
          // Safety check: Ensure controllers are registered before accessing
          if (!Get.isRegistered<RequestController>() || 
              !Get.isRegistered<ICTRequestController>() || 
              !Get.isRegistered<StoreRequestController>()) {
            // Return empty widget if controllers not ready yet
            return _buildActionCard(
              context,
              'Pending Approvals',
              Icons.pending_actions,
              AppColors.warning,
              () => Get.toNamed('/requests/pending'),
            );
          }
          
          final requestController = Get.find<RequestController>();
          final ictController = Get.find<ICTRequestController>();
          final storeController = Get.find<StoreRequestController>();
          
          // Access reactive lists directly - this ensures GetX tracks them
          final vehicleRequests = requestController.vehicleRequests;
          final ictRequests = ictController.ictRequests;
          final storeRequests = storeController.storeRequests;
          
          // Calculate total pending approvals count
          // Backend already filters by role, so we just count pending/corrected requests
          int totalPending = 0;
          
          // Count vehicle requests (backend already filtered by role)
          totalPending += vehicleRequests.where((request) {
            return request.status == RequestStatus.pending ||
                request.status == RequestStatus.corrected;
          }).length;
          
          // Count ICT requests (backend already filtered by role)
          totalPending += ictRequests.where((request) {
            return request.status == RequestStatus.pending ||
                request.status == RequestStatus.corrected;
          }).length;
          
          // Count store requests (backend already filtered by role)
          totalPending += storeRequests.where((request) {
            return request.status == RequestStatus.pending ||
                request.status == RequestStatus.corrected;
          }).length;
          
          return _buildActionCard(
            context,
            'Pending Approvals',
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
            borderRadius: BorderRadius.circular(20),
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
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.3,
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
