import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:intl/intl.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_badge.dart';
import '../../data/models/ict_request_model.dart';
import '../../data/models/request_model.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import 'ict_request_detail_page.dart';

class SODashboardPage extends StatelessWidget {
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();

  SODashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Get.find() - controller already registered in InitialBinding
    final ictController = Get.find<ICTRequestController>();
    final authController = Get.find<AuthController>();
    final permissionService = Get.find<PermissionService>();

    // Load unfulfilled requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ictController.loadUnfulfilledRequests();
    });

    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
          ),
          title: const Text('Fulfillment Queue'),
        ),
        body: Obx(() {
          final user = authController.user.value;
          if (user == null || !permissionService.canFulfillRequest(user, RequestType.ict)) {
            return const Center(
              child: Text(
                'You do not have permission to view this page',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          if (ictController.isLoading.value) {
            return Column(
              children: [
                // Statistics Cards Skeleton
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: const Row(
                    children: [
                      Expanded(
                        child: SkeletonStatCard(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SkeletonStatCard(),
                      ),
                    ],
                  ),
                ),
                // Requests List Skeleton
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SkeletonCard(),
                    ),
                  ),
                ),
              ],
            );
          }

          if (ictController.error.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading requests',
                    style: TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ictController.error.value,
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ictController.loadUnfulfilledRequests(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final requests = ictController.unfulfilledRequests;

          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                   SizedBox(height: 16),
                  Text(
                    'All requests fulfilled!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                   SizedBox(height: 8),
                  Text(
                    'There are no unfulfilled items at this time.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          // Calculate statistics
          int totalUnfulfilledItems = 0;
          int totalPendingRequests = 0;
          for (var request in requests) {
            totalPendingRequests++;
            for (var item in request.items) {
              // Use approved quantity if available, otherwise requested quantity
              final approvedQty = item.approvedQuantity ?? item.requestedQuantity;
              final remaining = approvedQty - item.fulfilledQuantity;
              if (remaining > 0) {
                totalUnfulfilledItems += remaining;
              }
            }
          }

          return Column(
            children: [
              // Statistics Cards
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Pending Requests',
                        totalPendingRequests.toString(),
                        Icons.pending_actions,
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Unfulfilled Items',
                        totalUnfulfilledItems.toString(),
                        Icons.inventory_2,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Requests List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildRequestCard(context, request, ictController);
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    ICTRequestModel request,
    ICTRequestController controller,
  ) {
    // Calculate unfulfilled items using approved quantity
    final unfulfilledItems = request.items
        .where((item) {
          final approvedQty = item.approvedQuantity ?? item.requestedQuantity;
          return item.fulfilledQuantity < approvedQty;
        })
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Get.to(() => ICTRequestDetailPage(requestId: request.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request #${request.id.substring(0, 8)}...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${DateFormat('MMM dd, yyyy').format(request.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Unfulfilled Items:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...unfulfilledItems.map((item) {
                // Use approved quantity if available, otherwise requested quantity
                final approvedQty = item.approvedQuantity ?? item.requestedQuantity;
                final remaining = approvedQty - item.fulfilledQuantity;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName ?? 'Item ${item.itemId.substring(0, 8)}...',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        'Remaining: $remaining',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.to(() => ICTRequestDetailPage(requestId: request.id));
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (request.workflowStage == 'FULFILLMENT')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(() => ICTRequestDetailPage(requestId: request.id));
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Fulfill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



