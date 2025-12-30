import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../data/models/user_model.dart';
import '../../data/models/request_model.dart';

class AppDrawer extends StatelessWidget {
  final AdvancedDrawerController controller;
  final Widget child;

  const AppDrawer({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final permissionService = Get.find<PermissionService>();
    final notificationController = Get.find<NotificationController>();

    return AdvancedDrawer(
      controller: controller,
      openRatio: 0.7,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      childDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
      ),
      drawer: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: SafeArea(
              child: Obx(() {
                final user = authController.user.value;
                if (user == null) {
                  return const SizedBox.shrink();
                }

                return Column(
              children: [
                // Header with user info
                _buildHeader(context, user),
                Divider(
                  height: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkDivider
                      : AppColors.divider,
                ),
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(
                        context,
                        icon: AppIcons.dashboard,
                        title: 'Dashboard',
                        route: '/dashboard',
                        isActive: Get.currentRoute == '/dashboard',
                      ),
                      if (permissionService.canCreateRequest(user)) ...[
                        Divider(
                          height: 1, 
                          indent: 16, 
                          endIndent: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
                        _buildSectionHeader(context, 'Create Request'),
                        _buildNavItem(
                          context,
                          icon: AppIcons.vehicle,
                          title: 'Vehicle Request',
                          route: '/create-request',
                          parameters: {'type': 'vehicle'},
                        ),
                        _buildNavItem(
                          context,
                          icon: AppIcons.ict,
                          title: 'ICT Request',
                          route: '/create-request',
                          parameters: {'type': 'ict'},
                        ),
                        _buildNavItem(
                          context,
                          icon: AppIcons.store,
                          title: 'Store Request',
                          route: '/create-request',
                          parameters: {'type': 'store'},
                        ),
                      ],
                      Divider(
                        height: 1, 
                        indent: 16, 
                        endIndent: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkDivider
                            : AppColors.divider,
                      ),
                      _buildSectionHeader(context, 'Requests'),
                      _buildNavItem(
                        context,
                        icon: AppIcons.requests,
                        title: 'My Requests',
                        route: '/requests/my',
                        isActive: Get.currentRoute == '/requests/my',
                      ),
                      if (permissionService.canViewAllRequests(user))
                        _buildNavItem(
                          context,
                          icon: AppIcons.requestList,
                          title: 'All Requests',
                          route: '/requests',
                          isActive: Get.currentRoute == '/requests',
                        ),
                      // Request History Section
                      Divider(
                        height: 1, 
                        indent: 16, 
                        endIndent: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkDivider
                            : AppColors.divider,
                      ),
                      _buildSectionHeader(context, 'Request History'),
                      _buildNavItem(
                        context,
                        icon: AppIcons.ict,
                        title: 'ICT Request History',
                        route: '/requests/ict/history',
                        isActive: Get.currentRoute == '/requests/ict/history',
                      ),
                      _buildNavItem(
                        context,
                        icon: AppIcons.vehicle,
                        title: 'Transport Request History',
                        route: '/requests/transport/history',
                        isActive: Get.currentRoute == '/requests/transport/history',
                      ),
                      _buildNavItem(
                        context,
                        icon: AppIcons.store,
                        title: 'Store Request History',
                        route: '/requests/store/history',
                        isActive: Get.currentRoute == '/requests/store/history',
                      ),
                      if (permissionService.canApprove(
                            user,
                            RequestType.vehicle,
                            'DGS_REVIEW',
                          ) ||
                          permissionService.canApprove(
                            user,
                            RequestType.ict,
                            'DDICT_REVIEW',
                          ) ||
                          permissionService.canApprove(
                            user,
                            RequestType.store,
                            'SO_REVIEW',
                          ))
                        Obx(() {
                          final user = authController.user.value;
                          if (user == null) return const SizedBox.shrink();
                          
                          // Safely get controllers, initialize if not found
                          RequestController? requestController;
                          ICTRequestController? ictController;
                          StoreRequestController? storeController;
                          
                          if (Get.isRegistered<RequestController>()) {
                            requestController = Get.find<RequestController>();
                          }
                          
                          if (Get.isRegistered<ICTRequestController>()) {
                            ictController = Get.find<ICTRequestController>();
                          }
                          
                          if (Get.isRegistered<StoreRequestController>()) {
                            storeController = Get.find<StoreRequestController>();
                          }
                          
                          // Calculate total pending approvals count
                          int totalPending = 0;
                          
                          // Filter vehicle requests user can approve
                          if (permissionService.canApprove(user, RequestType.vehicle, 'DGS_REVIEW') && requestController != null) {
                            totalPending += requestController.vehicleRequests.where((request) {
                              // Exclude requests that are already completed/approved/rejected/assigned
                              if (request.status == RequestStatus.approved ||
                                  request.status == RequestStatus.rejected ||
                                  request.status == RequestStatus.assigned ||
                                  request.status == RequestStatus.completed ||
                                  request.status == RequestStatus.fulfilled) {
                                return false;
                              }
                              
                              // Check if user can approve at this stage
                              final workflowStage = request.workflowStage ?? 'SUBMITTED';
                              return permissionService.canApproveAtStage(user, RequestType.vehicle, workflowStage) ||
                                  (permissionService.isSupervisor(user) &&
                                      request.workflowStage == 'SUPERVISOR_REVIEW' &&
                                      permissionService.isSupervisorForRequest(user, request));
                            }).length;
                          }
                          
                          // Filter ICT requests user can approve (only pending status)
                          if (permissionService.canApprove(user, RequestType.ict, 'DDICT_REVIEW') && ictController != null) {
                            totalPending += ictController.ictRequests.where((request) {
                              // Only count pending or corrected requests
                              return request.status == RequestStatus.pending ||
                                  request.status == RequestStatus.corrected;
                            }).length;
                          }
                          
                          // Filter store requests user can approve (only pending status)
                          if (permissionService.canApprove(user, RequestType.store, 'SO_REVIEW') && storeController != null) {
                            totalPending += storeController.storeRequests.where((request) {
                              // Only count pending or corrected requests
                              return request.status == RequestStatus.pending ||
                                  request.status == RequestStatus.corrected;
                            }).length;
                          }
                          
                          return _buildNavItem(
                            context,
                            icon: AppIcons.pendingRequests,
                            title: 'Pending Approvals',
                            route: '/requests/pending',
                            isActive: Get.currentRoute == '/requests/pending',
                            badge: totalPending > 0 ? totalPending : null,
                          );
                        }),
                      if (permissionService.canAssignVehicle(user)) ...[
                        Divider(
                          height: 1, 
                          indent: 16, 
                          endIndent: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
                        _buildSectionHeader(context, 'Transport'),
                        _buildNavItem(
                          context,
                          icon: AppIcons.assigned,
                          title: 'Assign Vehicles',
                          route: '/requests',
                          parameters: {'type': 'vehicle', 'status': 'approved'},
                        ),
                      ],
                      if (permissionService.canFulfillRequest(
                            user,
                            RequestType.ict,
                          ) ||
                          permissionService.canFulfillRequest(
                            user,
                            RequestType.store,
                          )) ...[
                        Divider(
                          height: 1, 
                          indent: 16, 
                          endIndent: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
                        _buildSectionHeader(context, 'Fulfillment'),
                        if (permissionService.canFulfillRequest(
                              user,
                              RequestType.ict,
                            ))
                          _buildNavItem(
                            context,
                            icon: AppIcons.check,
                            title: 'ICT Fulfillment',
                            route: '/requests',
                            parameters: {'type': 'ict', 'status': 'approved'},
                          ),
                        if (permissionService.canFulfillRequest(
                              user,
                              RequestType.store,
                            ))
                          _buildNavItem(
                            context,
                            icon: AppIcons.inventory,
                            title: 'Store Fulfillment',
                            route: '/requests',
                            parameters: {'type': 'store', 'status': 'approved'},
                          ),
                      ],
                      if (permissionService.isDriver(user)) ...[
                        Divider(
                          height: 1, 
                          indent: 16, 
                          endIndent: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                        ),
                        _buildSectionHeader(context, 'Driver'),
                        _buildNavItem(
                          context,
                          icon: AppIcons.vehicleFilled,
                          title: 'My Trips',
                          route: '/driver/dashboard',
                          isActive: Get.currentRoute == '/driver/dashboard',
                        ),
                      ],
                      Divider(
                        height: 1, 
                        indent: 16, 
                        endIndent: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkDivider
                            : AppColors.divider,
                      ),
                      Obx(() => _buildNavItem(
                        context,
                        icon: AppIcons.notifications,
                        title: 'Notifications',
                        route: '/notifications',
                        isActive: Get.currentRoute == '/notifications',
                        badge: notificationController.unreadCount.value > 0
                            ? notificationController.unreadCount.value
                            : null,
                      )),
                      _buildNavItem(
                        context,
                        icon: AppIcons.user,
                        title: 'Profile',
                        route: '/profile',
                        isActive: Get.currentRoute == '/profile',
                      ),
                      Divider(
                        height: 1, 
                        indent: 16, 
                        endIndent: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkDivider
                            : AppColors.divider,
                      ),
                      _buildSectionHeader(context, 'Settings'),
                      _buildDemoModeToggle(context),
                    ],
                  ),
                ),
                // Footer with logout
                Divider(
                  height: 1,
                  color: isDark 
                      ? AppColors.darkDivider 
                      : AppColors.divider,
                ),
                _buildLogoutButton(context, authController),
              ],
            );
          }),
        ),
      );
        },
      ),
      child: child,
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.roles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.roles.take(3).map((role) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.spacingL,
        top: AppConstants.spacingM,
        bottom: AppConstants.spacingS,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark 
              ? AppColors.darkTextSecondary.withOpacity(0.7)
              : AppColors.textSecondary.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    Map<String, String>? parameters,
    bool isActive = false,
    int? badge,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isActive 
            ? primaryColor 
            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive 
              ? primaryColor 
              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        ),
      ),
      trailing: badge != null && badge > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge > 99 ? '99+' : badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      selected: isActive,
      selectedTileColor: primaryColor.withOpacity(0.1),
      onTap: () {
        controller.hideDrawer();
        if (parameters != null) {
          Get.toNamed(route, parameters: parameters);
        } else {
          Get.toNamed(route);
        }
      },
    );
  }

  Widget _buildDemoModeToggle(BuildContext context) {
    final isDemoMode = RxBool(StorageService.isDemoModeEnabled());
    
    return Obx(() {
      return ListTile(
        leading: Icon(
          Icons.science_rounded,
          color: isDemoMode.value ? AppColors.warning : AppColors.textSecondary,
        ),
        title: const Text('Demo Mode'),
        subtitle: Text(
          isDemoMode.value
              ? 'Location checks disabled for testing'
              : 'Enable to bypass location validation',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Switch(
          value: isDemoMode.value,
          onChanged: (value) {
            StorageService.setDemoMode(value);
            isDemoMode.value = value;
            Get.snackbar(
              'Demo Mode',
              value ? 'Enabled - Location checks disabled' : 'Disabled - Location checks enabled',
              backgroundColor: value ? AppColors.warning.withOpacity(0.2) : AppColors.success.withOpacity(0.2),
              colorText: value ? AppColors.warning : AppColors.success,
            );
          },
          activeColor: AppColors.warning,
        ),
      );
    });
  }

  Widget _buildLogoutButton(BuildContext context, AuthController authController) {
    return ListTile(
      leading: const Icon(
        AppIcons.logout,
        color: AppColors.error,
      ),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        controller.hideDrawer();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  authController.logout();
                  Get.offAllNamed('/login');
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );
  }
}
