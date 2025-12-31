import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ict_request_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import '../../data/models/ict_request_model.dart';
import '../../data/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/id_utils.dart';

class ICTFulfillmentPage extends StatelessWidget {
  final String requestId;

  const ICTFulfillmentPage({Key? key, required this.requestId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ICTRequestController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadRequest(requestId);
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('ICT Request Fulfillment'),
      ),
      body: Obx(
        () {
          final request = controller.selectedRequest.value;

          if (controller.isLoading.value && request == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (request == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Request not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadRequest(requestId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(
                      status: request.status,
                      workflowStage: request.workflowStage,
                      isPartiallyFulfilled: request.isPartiallyFulfilled(),
                    ),
                    if (request.priority)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.priority_high, size: 16, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Priority',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingXL),
                Text(
                  'Request Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                ...request.items.map((item) {
                  final fulfilled = request.fulfillmentStatus.firstWhere(
                    (f) => IdUtils.areIdsEqual(f['itemId'], item.itemId),
                    orElse: () => {'quantityFulfilled': 0},
                  );
                  final fulfilledQty = fulfilled['quantityFulfilled'] ?? 0;
                  // Use approved quantity if available, otherwise requested quantity
                  final approvedQty = item.approvedQuantity ?? item.requestedQuantity;

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Item ID: ${item.itemId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                '${fulfilledQty}/${approvedQty}',
                                style: TextStyle(
                                  color: fulfilledQty >= approvedQty
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: approvedQty > 0
                                ? fulfilledQty / approvedQty
                                : 0,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              fulfilledQty >= approvedQty
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (request.status == RequestStatus.approved ||
                    request.status == RequestStatus.assigned) ...[
                  const SizedBox(height: AppConstants.spacingXL),
                  CustomButton(
                    text: 'Fulfill Request',
                    icon: Icons.check_circle,
                    onPressed: () => _showFulfillmentDialog(context, controller, request),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFulfillmentDialog(
    BuildContext context,
    ICTRequestController controller,
    ICTRequestModel request,
  ) {
    final fulfillmentData = <String, int>{};
    for (var item in request.items) {
      // Use approved quantity if available, otherwise requested quantity
      final approvedQty = item.approvedQuantity ?? item.requestedQuantity;
      // Calculate remaining to fulfill
      final remaining = approvedQty - item.fulfilledQuantity;
      fulfillmentData[item.itemId] = remaining > 0 ? remaining : 0;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Fulfill Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter fulfillment quantities for each item:'),
            const SizedBox(height: 16),
            ...request.items.map((item) {
              // Use approved quantity if available, otherwise requested quantity
              final approvedQty = item.approvedQuantity ?? item.requestedQuantity;
              final remaining = approvedQty - item.fulfilledQuantity;
              final controller = TextEditingController(
                text: remaining > 0 ? remaining.toString() : '0',
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Item ${item.itemId}',
                    hintText: 'Quantity',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final qty = int.tryParse(value) ?? 0;
                    fulfillmentData[item.itemId] = qty;
                  },
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isFulfilling.value
                  ? null
                  : () async {
                      final success = await controller.fulfillRequest(request.id, fulfillmentData);
                      if (success) {
                        Get.back();
                        Get.snackbar('Success', 'Request fulfilled successfully');
                      } else {
                        Get.snackbar('Error', controller.error.value);
                      }
                    },
              child: controller.isFulfilling.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Fulfill'),
            ),
          ),
        ],
      ),
    );
  }
}

