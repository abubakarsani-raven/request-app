import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/unified_request_card.dart';
import 'request_detail_page.dart';
import '../../data/models/request_model.dart';
import '../../../core/config/request_module_config.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/constants/app_constants.dart';

class ApprovalQueuePage extends StatelessWidget {
  final String? requestType;
  /// When true, used as tab content in MainShellPage (no app bar).
  final bool inShell;

  ApprovalQueuePage({Key? key, this.requestType, this.inShell = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final permissionService = Get.find<PermissionService>();
    final user = authController.user.value;

    if (user == null) {
      if (inShell) {
        return const Center(child: CircularProgressIndicator());
      }
      return AppScaffold(
        title: 'Pending Approvals',
        showBackButton: true,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final body = DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: [
                for (final type in RequestModuleConfig.allTypes)
                  Tab(text: RequestModuleConfig.label(type)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildVehicleApprovals(context, user, permissionService),
                  _buildICTApprovals(context, user, permissionService),
                  _buildStoreApprovals(context, user, permissionService),
                ],
              ),
            ),
          ],
        ),
    );

    if (inShell) return body;
    return AppScaffold(
      title: 'Pending Approvals',
      showBackButton: true,
      body: body,
    );
  }

  Widget _buildVehicleApprovals(
    BuildContext context,
    dynamic user,
    PermissionService permissionService,
  ) {
    // Use Get.find() - controller already registered in InitialBinding
    final requestController = Get.find<RequestController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use role-specific endpoint for pending approvals
      requestController.loadPendingApprovals();
    });

    return Obx(
      () {
        if (requestController.isLoading.value && requestController.vehicleRequests.isEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            itemCount: 3,
            itemBuilder: (context, index) => const SkeletonCard(),
          );
        }

        // Backend already filters by role and workflow stage correctly
        // Trust the backend results - no additional filtering needed
        if (requestController.vehicleRequests.isEmpty) {
          return const EmptyState(
            title: 'No Requests Found',
            message: 'You have no pending approvals.',
            icon: Icons.check_circle_outline,
          );
        }

        return ListView.builder(
          itemCount: requestController.vehicleRequests.length,
          itemBuilder: (context, index) {
            final request = requestController.vehicleRequests[index];
            return UnifiedRequestCard(
              type: RequestType.vehicle,
              request: request,
              source: RequestDetailSource.pendingApprovals,
              onReturn: () => requestController.loadPendingApprovals(),
            );
          },
        );
      },
    );
  }

  Widget _buildICTApprovals(
    BuildContext context,
    dynamic user,
    PermissionService permissionService,
  ) {
    final ictController = Get.put(ICTRequestController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use pending approvals endpoint which handles role-based filtering
      ictController.loadPendingApprovals();
    });

    return Obx(
      () {
        if (ictController.isLoading.value && ictController.ictRequests.isEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            itemCount: 3,
            itemBuilder: (context, index) => const SkeletonCard(),
          );
        }

        // Backend already filters by role and workflow stage correctly
        // Trust the backend results - no additional filtering needed
        if (ictController.ictRequests.isEmpty) {
          return const EmptyState(
            title: 'No Requests Found',
            message: 'You have no pending approvals.',
            icon: Icons.check_circle_outline,
          );
        }

        return ListView.builder(
          itemCount: ictController.ictRequests.length,
          itemBuilder: (context, index) {
            final request = ictController.ictRequests[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
              child: UnifiedRequestCard(
                type: RequestType.ict,
                request: request,
                source: RequestDetailSource.pendingApprovals,
                onReturn: () => ictController.loadPendingApprovals(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStoreApprovals(
    BuildContext context,
    dynamic user,
    PermissionService permissionService,
  ) {
    // Use Get.find() - controller already registered in InitialBinding
    final storeController = Get.find<StoreRequestController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use pending approvals endpoint which handles role-based filtering
      storeController.loadPendingApprovals();
    });

    return Obx(
      () {
        if (storeController.isLoading.value && storeController.storeRequests.isEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            itemCount: 3,
            itemBuilder: (context, index) => const SkeletonCard(),
          );
        }

        // Backend already filters by role and workflow stage correctly
        // Trust the backend results - no additional filtering needed
        if (storeController.storeRequests.isEmpty) {
          return const EmptyState(
            title: 'No Requests Found',
            message: 'You have no pending approvals.',
            icon: Icons.check_circle_outline,
          );
        }

        return ListView.builder(
          itemCount: storeController.storeRequests.length,
          itemBuilder: (context, index) {
            final request = storeController.storeRequests[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
              child: UnifiedRequestCard(
                type: RequestType.store,
                request: request,
                source: RequestDetailSource.pendingApprovals,
                onReturn: () => storeController.loadPendingApprovals(),
              ),
            );
          },
        );
      },
    );
  }
}

