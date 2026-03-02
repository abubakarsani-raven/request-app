import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/models/request_model.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/logout_confirmation.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_bottom_nav.dart';
import 'dashboard_page.dart';
import 'driver_dashboard_page.dart';
import 'request_list_page.dart';

/// Main shell with bottom nav only. No drawer.
/// Staff: Home, Requests, Create, [Approvals], More. Driver: Trips, More.
class MainShellPage extends StatefulWidget {
  /// Initial tab index (e.g. from deep link).
  final int initialIndex;

  const MainShellPage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  List<BottomNavItem> _buildNavItems(UserModel user, PermissionService perm) {
    if (perm.isDriver(user)) {
      return const [
        BottomNavItem(icon: AppIcons.directions, label: 'Trips'),
        BottomNavItem(icon: AppIcons.profile, label: 'More'),
      ];
    }
    final items = <BottomNavItem>[
      const BottomNavItem(icon: AppIcons.home, label: 'Home'),
      const BottomNavItem(icon: AppIcons.requestList, label: 'Requests'),
      const BottomNavItem(icon: AppIcons.createRequest, label: 'Create'),
    ];
    if (perm.canApproveAnyRequests(user)) {
      items.add(const BottomNavItem(icon: AppIcons.pendingRequests, label: 'Approvals'));
    }
    items.add(const BottomNavItem(icon: AppIcons.moreVert, label: 'More'));
    return items;
  }

  List<Widget> _buildTabBodies(UserModel user, PermissionService perm, int currentTabIndex) {
    if (perm.isDriver(user)) {
      return [
        const DriverDashboardContent(),
        const _MoreTabContent(isDriver: true),
      ];
    }
    int tabIdx = 0;
    final bodies = <Widget>[
      const DashboardContent(),
    ];
    tabIdx++;
    bodies.add(RequestListPage(
      myRequests: false,
      pending: false,
      inShell: true,
      currentTabIndex: currentTabIndex,
      myTabIndex: tabIdx,
    ));
    tabIdx++;
    bodies.add(const _CreateTabContent());
    tabIdx++;
    if (perm.canApproveAnyRequests(user)) {
      bodies.add(RequestListPage(
        pending: true,
        approvedByMe: true,
        inShell: true,
        currentTabIndex: currentTabIndex,
        myTabIndex: tabIdx,
      ));
      tabIdx++;
    }
    bodies.add(const _MoreTabContent(isDriver: false));
    return bodies;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final permissionService = Get.find<PermissionService>();

    return Obx(() {
      final user = authController.user.value;
      if (user == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final items = _buildNavItems(user, permissionService);
      final bodies = _buildTabBodies(user, permissionService, _currentIndex);
      final safeIndex = _currentIndex.clamp(0, bodies.length - 1);

      return Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: bodies,
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: safeIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: items,
        ),
      );
    });
  }
}

/// More menu: list items that push routes or perform actions.
class _MoreTabContent extends StatelessWidget {
  final bool isDriver;

  const _MoreTabContent({required this.isDriver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();
    final permissionService = Get.find<PermissionService>();

    return SafeArea(
      child: Obx(() {
        final user = authController.user.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final canAssign = permissionService.canAssignVehicle(user);
        final canFulfillICT = permissionService.canFulfillRequest(user, RequestType.ict);
        final canFulfillStore = permissionService.canFulfillRequest(user, RequestType.store);
        final showFulfillment = canFulfillICT || canFulfillStore;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Text(
                  'More',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _ListTile(
                  icon: AppIcons.profile,
                  title: 'Profile',
                  onTap: () => Get.toNamed(AppRoutes.profile),
                ),
                _ListTile(
                  icon: AppIcons.notificationsOutlined,
                  title: 'Notifications',
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                ),
                _SectionLabel('Requests'),
                _ListTile(
                  icon: AppIcons.myRequests,
                  title: 'My Requests',
                  onTap: () => Get.toNamed(AppRoutes.myRequests),
                ),
                _ListTile(
                  icon: AppIcons.createRequest,
                  title: 'Vehicle Request',
                  onTap: () => Get.toNamed(AppRoutes.createRequest, parameters: {'type': 'vehicle'}),
                ),
                _ListTile(
                  icon: AppIcons.ict,
                  title: 'ICT Request',
                  onTap: () => Get.toNamed(AppRoutes.createRequest, parameters: {'type': 'ict'}),
                ),
                _ListTile(
                  icon: AppIcons.store,
                  title: 'Store Request',
                  onTap: () => Get.toNamed(AppRoutes.createRequest, parameters: {'type': 'store'}),
                ),
                if (!isDriver) ...[
                  _SectionLabel('Work'),
                  _ListTile(
                    icon: AppIcons.pendingRequests,
                    title: 'Approvals',
                    onTap: () => Get.toNamed(AppRoutes.approvals),
                  ),
                  if (canAssign)
                    _ListTile(
                      icon: Icons.assignment_rounded,
                      title: 'Assign Vehicles',
                      onTap: () => Get.toNamed(AppRoutes.assignVehicles),
                    ),
                  if (showFulfillment)
                    _ListTile(
                      icon: AppIcons.dashboard,
                      title: 'Fulfillment Queue',
                      onTap: () => Get.toNamed(AppRoutes.soDashboard),
                    ),
                  _SectionLabel('History'),
                  _ListTile(
                    icon: AppIcons.ict,
                    title: 'ICT History',
                    onTap: () => Get.toNamed(AppRoutes.ictRequestHistory),
                  ),
                  _ListTile(
                    icon: AppIcons.vehicle,
                    title: 'Transport History',
                    onTap: () => Get.toNamed(AppRoutes.transportRequestHistory),
                  ),
                  _ListTile(
                    icon: AppIcons.store,
                    title: 'Store History',
                    onTap: () => Get.toNamed(AppRoutes.storeRequestHistory),
                  ),
                ],
                if (isDriver) ...[
                  _SectionLabel('History'),
                  _ListTile(
                    icon: AppIcons.ict,
                    title: 'ICT History',
                    onTap: () => Get.toNamed(AppRoutes.ictRequestHistory),
                  ),
                  _ListTile(
                    icon: AppIcons.vehicle,
                    title: 'Transport History',
                    onTap: () => Get.toNamed(AppRoutes.transportRequestHistory),
                  ),
                  _ListTile(
                    icon: AppIcons.store,
                    title: 'Store History',
                    onTap: () => Get.toNamed(AppRoutes.storeRequestHistory),
                  ),
                ],
                const Divider(height: 1),
                _ListTile(
                  icon: AppIcons.logout,
                  title: 'Logout',
                  onTap: () => LogoutConfirmation.show(context),
                ),
              ]),
            ),
          ],
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppConstants.spacingL, AppConstants.spacingL, AppConstants.spacingL, AppConstants.spacingXS),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Create tab: type chooser; navigates to /create-request with type.
class _CreateTabContent extends StatelessWidget {
  const _CreateTabContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Request',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            _CreateOption(
              icon: AppIcons.vehicle,
              label: 'Vehicle Request',
              onTap: () => Get.toNamed(AppRoutes.createRequest, parameters: {'type': 'vehicle'}),
            ),
            const SizedBox(height: AppConstants.spacingS),
            _CreateOption(
              icon: AppIcons.ict,
              label: 'ICT Request',
              onTap: () => Get.toNamed(AppRoutes.createRequest, parameters: {'type': 'ict'}),
            ),
            const SizedBox(height: AppConstants.spacingS),
            _CreateOption(
              icon: AppIcons.store,
              label: 'Store Request',
              onTap: () => Get.toNamed(AppRoutes.createRequest, parameters: {'type': 'store'}),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CreateOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.spacingM,
            horizontal: AppConstants.spacingL,
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: AppConstants.spacingM),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Icon(AppIcons.chevronRight, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ListTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        AppIcons.chevronRight,
        size: AppIcons.sizeSmall,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
