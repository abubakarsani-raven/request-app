import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/request_card.dart';
import 'request_detail_page.dart';
import 'ict_request_detail_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/skeleton_loader.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/constants/app_constants.dart';

class ApprovalQueuePage extends StatelessWidget {
  final String? requestType;
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();

  ApprovalQueuePage({Key? key, this.requestType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final permissionService = Get.find<PermissionService>();
    final user = authController.user.value;

    if (user == null) {
      return AppDrawer(
        controller: _drawerController,
        child: Scaffold(
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
          ),
          title: const Text('Pending Approvals'),
        ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Vehicle'),
                Tab(text: 'ICT'),
                Tab(text: 'Store'),
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
      ),
      ),
    );
  }

  Widget _buildVehicleApprovals(
    BuildContext context,
    dynamic user,
    PermissionService permissionService,
  ) {
    final requestController = Get.put(RequestController());

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
            return RequestCard(
              request: request,
              source: RequestDetailSource.pendingApprovals,
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
            return Card(
              margin: const EdgeInsets.all(AppConstants.spacingM),
              child: ListTile(
                title: Text('ICT Request #${request.id.substring(0, 8)}'),
                subtitle: Text('${request.items.length} items'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to ICT request detail with source
                  Get.to(() => ICTRequestDetailPage(
                    requestId: request.id,
                    source: RequestDetailSource.pendingApprovals,
                  ));
                },
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
    final storeController = Get.put(StoreRequestController());

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
            return Card(
              margin: const EdgeInsets.all(AppConstants.spacingM),
              child: ListTile(
                title: Text('Store Request #${request.id.substring(0, 8)}'),
                subtitle: Text('${request.items.length} items'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Get.toNamed('/store/requests/${request.id}');
                },
              ),
            );
          },
        );
      },
    );
  }
}

