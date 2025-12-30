import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/models/request_model.dart';

class AppSidebar extends StatefulWidget {
  final bool isCollapsed;
  final Function(bool)? onCollapseChanged;

  const AppSidebar({
    Key? key,
    this.isCollapsed = false,
    this.onCollapseChanged,
  }) : super(key: key);

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;
  final Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isCollapsed;
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      widget.onCollapseChanged?.call(_isCollapsed);
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
        return const SizedBox.shrink();
      }

      return Container(
        width: _isCollapsed ? 64 : 256,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            right: BorderSide(
              color: AppColors.surfaceLight,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context, user),
            const Divider(height: 1, thickness: 1),
            // Navigation Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    route: '/dashboard',
                    isActive: Get.currentRoute == '/dashboard',
                  ),
                  if (permissionService.canCreateRequest(user)) ...[
                    _buildGroupHeader('Create Request'),
                    _buildNavItem(
                      context,
                      icon: Icons.directions_car_rounded,
                      title: 'Vehicle Request',
                      route: '/create-request',
                      parameters: {'type': 'vehicle'},
                      isActive: Get.currentRoute == '/create-request' &&
                          Get.parameters['type'] == 'vehicle',
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.computer_rounded,
                      title: 'ICT Request',
                      route: '/create-request',
                      parameters: {'type': 'ict'},
                      isActive: Get.currentRoute == '/create-request' &&
                          Get.parameters['type'] == 'ict',
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.inventory_2_rounded,
                      title: 'Store Request',
                      route: '/create-request',
                      parameters: {'type': 'store'},
                      isActive: Get.currentRoute == '/create-request' &&
                          Get.parameters['type'] == 'store',
                    ),
                  ],
                  _buildGroupHeader('Requests'),
                  _buildNavItem(
                    context,
                    icon: Icons.list_alt_rounded,
                    title: 'My Requests',
                    route: '/requests/my',
                    isActive: Get.currentRoute == '/requests/my',
                  ),
                  if (permissionService.canViewAllRequests(user))
                    _buildNavItem(
                      context,
                      icon: Icons.view_list_rounded,
                      title: 'All Requests',
                      route: '/requests',
                      isActive: Get.currentRoute == '/requests',
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
                      
                      final requestController = Get.find<RequestController>();
                      final ictController = Get.find<ICTRequestController>();
                      final storeController = Get.find<StoreRequestController>();
                      
                      // Calculate total pending approvals count
                      int totalPending = 0;
                      
                      // Filter vehicle requests user can approve
                      if (permissionService.canApprove(user, RequestType.vehicle, 'DGS_REVIEW')) {
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
                      if (permissionService.canApprove(user, RequestType.ict, 'DDICT_REVIEW')) {
                        totalPending += ictController.ictRequests.where((request) {
                          // Only count pending or corrected requests
                          return request.status == RequestStatus.pending ||
                              request.status == RequestStatus.corrected;
                        }).length;
                      }
                      
                      // Filter store requests user can approve (only pending status)
                      if (permissionService.canApprove(user, RequestType.store, 'SO_REVIEW')) {
                        totalPending += storeController.storeRequests.where((request) {
                          // Only count pending or corrected requests
                          return request.status == RequestStatus.pending ||
                              request.status == RequestStatus.corrected;
                        }).length;
                      }
                      
                      return _buildNavItem(
                        context,
                        icon: Icons.pending_actions_rounded,
                        title: 'Pending Approvals',
                        route: '/requests/pending',
                        isActive: Get.currentRoute == '/requests/pending',
                        badge: totalPending > 0 ? totalPending : null,
                      );
                    }),
                  if (permissionService.canAssignVehicle(user)) ...[
                    _buildGroupHeader('Transport'),
                    _buildNavItem(
                      context,
                      icon: Icons.assignment_rounded,
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
                    _buildGroupHeader('Fulfillment'),
                    if (permissionService.canFulfillRequest(
                          user,
                          RequestType.ict,
                        ))
                      _buildNavItem(
                        context,
                        icon: Icons.dashboard_rounded,
                        title: 'Fulfillment Queue',
                        route: '/so-dashboard',
                      ),
                    if (permissionService.canFulfillRequest(
                          user,
                          RequestType.store,
                        ))
                      _buildNavItem(
                        context,
                        icon: Icons.inventory_rounded,
                        title: 'Store Fulfillment',
                        route: '/requests',
                        parameters: {'type': 'store', 'status': 'approved'},
                      ),
                  ],
                  if (permissionService.isDriver(user)) ...[
                    _buildGroupHeader('Driver'),
                    _buildNavItem(
                      context,
                      icon: Icons.directions_car_filled_rounded,
                      title: 'My Trips',
                      route: '/driver/dashboard',
                      isActive: Get.currentRoute == '/driver/dashboard',
                    ),
                  ],
                  _buildGroupHeader('General'),
                  Obx(() => _buildNavItem(
                    context,
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    route: '/notifications',
                    isActive: Get.currentRoute == '/notifications',
                    badge: notificationController.unreadCount.value > 0
                        ? notificationController.unreadCount.value
                        : null,
                  )),
                  _buildNavItem(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    route: '/profile',
                    isActive: Get.currentRoute == '/profile',
                  ),
                ],
              ),
            ),
            // Footer with User
            const Divider(height: 1, thickness: 1),
            _buildUserFooter(context, user, authController),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      padding: EdgeInsets.all(_isCollapsed ? 12 : 16),
      child: _isCollapsed
          ? IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
              onPressed: _toggleCollapse,
              tooltip: 'Expand Sidebar',
            )
          : Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request App',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Management',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  onPressed: _toggleCollapse,
                  tooltip: 'Collapse Sidebar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupHeader(String title) {
    if (_isCollapsed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        top: 16,
        bottom: 8,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary.withOpacity(0.7),
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
    final item = _isCollapsed
        ? _buildCollapsedNavItem(context, icon, title, route, parameters, isActive, badge)
        : _buildExpandedNavItem(context, icon, title, route, parameters, isActive, badge);

    return item;
  }

  Widget _buildCollapsedNavItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    Map<String, String>? parameters,
    bool isActive,
    int? badge,
  ) {
    return Tooltip(
      message: title,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            IconButton(
              icon: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                if (parameters != null) {
                  Get.toNamed(route, parameters: parameters);
                } else {
                  Get.toNamed(route);
                }
              },
              tooltip: title,
            ),
            if (badge != null && badge > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badge > 99 ? '99+' : badge.toString(),
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
        ),
      ),
    );
  }

  Widget _buildExpandedNavItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    Map<String, String>? parameters,
    bool isActive,
    int? badge,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
            fontSize: 14,
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
        onTap: () {
          if (parameters != null) {
            Get.toNamed(route, parameters: parameters);
          } else {
            Get.toNamed(route);
          }
        },
      ),
    );
  }

  Widget _buildUserFooter(
    BuildContext context,
    UserModel user,
    AuthController authController,
  ) {
    if (_isCollapsed) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Tooltip(
          message: user.name,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, size: 20),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') {
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
        } else if (value == 'profile') {
          Get.toNamed('/profile');
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_rounded, size: 20),
              SizedBox(width: 8),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}

