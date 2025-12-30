import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_request_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import '../../data/models/store_request_model.dart';
import '../../data/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/id_utils.dart';

class StoreFulfillmentPage extends StatelessWidget {
  final String requestId;

  const StoreFulfillmentPage({Key? key, required this.requestId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoreRequestController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadRequest(requestId);
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Store Request Fulfillment'),
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
                                '${fulfilledQty}/${item.requestedQuantity}',
                                style: TextStyle(
                                  color: fulfilledQty >= item.requestedQuantity
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: item.requestedQuantity > 0
                                ? fulfilledQty / item.requestedQuantity
                                : 0,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              fulfilledQty >= item.requestedQuantity
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (request.qrCode != null) ...[
                  const SizedBox(height: AppConstants.spacingXL),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        children: [
                          const Text(
                            'QR Code',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request.qrCode!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
    StoreRequestController controller,
    StoreRequestModel request,
  ) {
    final fulfillmentData = <String, int>{};
    for (var item in request.items) {
      fulfillmentData[item.itemId] = item.requestedQuantity;
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
              final controller = TextEditingController(
                text: item.requestedQuantity.toString(),
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
          ElevatedButton(
            onPressed: () async {
              final success = await controller.fulfillRequest(request.id, fulfillmentData);
              if (success) {
                Get.back();
                Get.snackbar('Success', 'Request fulfilled successfully');
              } else {
                Get.snackbar('Error', controller.error.value);
              }
            },
            child: const Text('Fulfill'),
          ),
        ],
      ),
    );
  }
}

