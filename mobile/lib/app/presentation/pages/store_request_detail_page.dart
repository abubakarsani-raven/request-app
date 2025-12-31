import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/store_request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_drawer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/loading_overlay.dart';
import '../../data/models/store_request_model.dart';
import '../../data/models/request_model.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_toast.dart';
import 'request_detail_page.dart'; // For RequestDetailSource enum

class StoreRequestDetailPage extends StatelessWidget {
  final String requestId;
  final RequestDetailSource? source;
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();

  StoreRequestDetailPage({
    Key? key,
    required this.requestId,
    this.source,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storeController = Get.put(StoreRequestController());
    final authController = Get.find<AuthController>();

    // Load request details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      storeController.loadRequest(requestId);
    });

    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
          ),
          title: const Text('Store Request Details'),
        ),
        body: LoadingOverlay(
          isLoading: storeController.isApproving.value ||
                     storeController.isRejecting.value ||
                     storeController.isFulfilling.value ||
                     storeController.isReloading.value,
          message: storeController.isApproving.value
              ? 'Approving request...'
              : storeController.isRejecting.value
                  ? 'Rejecting request...'
                  : storeController.isFulfilling.value
                      ? 'Fulfilling request...'
                      : 'Loading...',
          child: Obx(
            () {
              final request = storeController.selectedRequest.value;

              if (storeController.isLoading.value && request == null) {
                return ListView(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  children: [
                    const SkeletonCard(height: 200),
                    const SizedBox(height: AppConstants.spacingL),
                    const SkeletonText(width: double.infinity, height: 20, lines: 3),
                    const SizedBox(height: AppConstants.spacingL),
                    const SkeletonCard(height: 150),
                  ],
                );
              }

              if (request == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Request not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => storeController.loadRequest(requestId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Priority
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.3),
                              width: 1,
                            ),
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
                  const SizedBox(height: AppConstants.spacingXXL),

                  // Request Information
                  _buildDetailSection(
                    context,
                    'Request Information',
                    [
                      _buildDetailRow('Request Date', DateFormat('MMM dd, yyyy hh:mm a').format(request.createdAt)),
                      if (request.directToSO)
                        _buildDetailRow('Route', 'Direct to Store Officer'),
                    ],
                  ),

                  // Requested Items
                  const SizedBox(height: AppConstants.spacingXXL),
                  _buildItemsSection(context, request),

                  // Workflow Timeline
                  const SizedBox(height: AppConstants.spacingXXL),
                  _buildWorkflowSection(context, request),

                  const SizedBox(height: AppConstants.spacingXXL),

                  // Action Buttons
                  _buildActionButtons(context, request, authController, storeController),
                ],
              ),
            );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
                height: 1.3,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.darkSurface 
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? AppColors.darkBorderDefined.withOpacity(0.5)
                  : AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isDark 
                        ? AppColors.darkTextPrimary 
                        : AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsSection(BuildContext context, StoreRequestModel request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requested Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
                height: 1.3,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.darkSurface 
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? AppColors.darkBorderDefined.withOpacity(0.5)
                  : AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: request.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final requested = item.requestedQuantity;
              final fulfilled = item.fulfilledQuantity;
              final remaining = requested - fulfilled;
              final isFulfilled = remaining == 0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark 
                          ? AppColors.darkBorderDefined.withOpacity(0.5)
                          : AppColors.border.withOpacity(0.3),
                      width: index < request.items.length - 1 ? 1 : 0,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name and badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName ?? 'Item ID: ${item.itemId.substring(0, 8)}...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isDark 
                                  ? AppColors.darkTextPrimary 
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFulfilled ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFulfilled ? 'Fulfilled' : 'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              color: isFulfilled ? AppColors.success : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quantity information
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Requested: $requested',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Fulfilled: $fulfilled',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Remaining: $remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: remaining > 0 ? AppColors.warning : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowSection(BuildContext context, StoreRequestModel request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workflowStage = request.workflowStage ?? 'SUBMITTED';
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkSurface 
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? AppColors.darkBorderDefined.withOpacity(0.5)
              : AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Workflow Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Current Stage: ${_formatWorkflowStage(workflowStage)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark 
                    ? AppColors.darkTextPrimary 
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWorkflowStage(String stage) {
    switch (stage) {
      case 'SUBMITTED':
        return 'Submitted';
      case 'SUPERVISOR_REVIEW':
        return 'Supervisor Review';
      case 'DDGS_REVIEW':
        return 'DDGS Review';
      case 'ADGS_REVIEW':
        return 'ADGS Review';
      case 'SO_REVIEW':
        return 'Store Officer Review';
      case 'FULFILLMENT':
        return 'Fulfillment';
      default:
        return stage;
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    StoreRequestModel request,
    AuthController authController,
    StoreRequestController storeController,
  ) {
    final user = authController.user.value;
    final permissionService = Get.find<PermissionService>();
    if (user == null) return const SizedBox();

    // Only Store Officer (SO) can fulfill Store requests at FULFILLMENT or SO_REVIEW stage
    final canFulfill = permissionService.canFulfillRequest(user, RequestType.store) &&
        (request.workflowStage == 'FULFILLMENT' || request.workflowStage == 'SO_REVIEW') &&
        (request.status == RequestStatus.approved || request.status == RequestStatus.pending);

    // Check if user can approve at the current workflow stage
    final workflowStage = request.workflowStage ?? 'SUBMITTED';
    final canApproveAtStage = permissionService.canApprove(
      user,
      RequestType.store,
      workflowStage,
    );
    
    final canApprove = canApproveAtStage &&
        (request.status == RequestStatus.pending || request.status == RequestStatus.corrected);

    return Column(
      children: [
        if (canFulfill) ...[
          CustomButton(
            text: 'Fulfill Request',
            icon: Icons.check_circle,
            isLoading: storeController.isFulfilling.value,
            onPressed: storeController.isFulfilling.value
                ? null
                : () => _showFulfillmentDialog(context, storeController, request),
          ),
          const SizedBox(height: AppConstants.spacingM),
        ],
        if (canApprove) ...[
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Approve',
                  icon: Icons.check,
                  type: ButtonType.primary,
                  isLoading: storeController.isApproving.value,
                  onPressed: storeController.isApproving.value
                      ? null
                      : () => _showApproveDialog(context, storeController, request.id),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: CustomButton(
                  text: 'Reject',
                  icon: Icons.close,
                  type: ButtonType.outlined,
                  backgroundColor: AppColors.error,
                  textColor: AppColors.error,
                  isLoading: storeController.isRejecting.value,
                  onPressed: storeController.isRejecting.value
                      ? null
                      : () => _showRejectDialog(context, storeController, request.id),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showFulfillmentDialog(
    BuildContext context,
    StoreRequestController controller,
    StoreRequestModel request,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fulfillmentControllers = <String, TextEditingController>{};
    
    for (var item in request.items) {
      final remaining = item.requestedQuantity - item.fulfilledQuantity;
      fulfillmentControllers[item.itemId] = TextEditingController(
        text: remaining > 0 ? remaining.toString() : '0',
      );
    }

    Get.dialog(
      WillPopScope(
        onWillPop: () async => !controller.isFulfilling.value,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Fulfill Request',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(request.items.length, (index) {
                      final item = request.items[index];
                      final remaining = item.requestedQuantity - item.fulfilledQuantity;
                      final controller = fulfillmentControllers[item.itemId]!;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName ?? 'Item ID: ${item.itemId.substring(0, 8)}...',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Text(
                                  'Requested: ${item.requestedQuantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Fulfilled: ${item.fulfilledQuantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Remaining: $remaining',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: remaining > 0 ? AppColors.warning : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Quantity to Fulfill',
                                labelStyle: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? AppColors.darkSurfaceLight : theme.colorScheme.surface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          for (var controller in fulfillmentControllers.values) {
                            controller.dispose();
                          }
                          Get.back();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isFulfilling.value
                              ? null
                              : () async {
                                  final fulfillmentData = <String, int>{};
                                  for (var entry in fulfillmentControllers.entries) {
                                    final qty = int.tryParse(entry.value.text) ?? 0;
                                    if (qty < 0) {
                                      CustomToast.error('Quantities cannot be negative');
                                      return;
                                    }
                                    fulfillmentData[entry.key] = qty;
                                  }

                                  for (var controller in fulfillmentControllers.values) {
                                    controller.dispose();
                                  }

                                  final success = await controller.fulfillRequest(request.id, fulfillmentData);
                                  if (success) {
                                    Get.back();
                                    CustomToast.success('Request fulfilled successfully');
                                    await controller.loadRequest(request.id);
                                  } else {
                                    CustomToast.error(controller.error.value);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
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
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    ).then((_) {
      for (var controller in fulfillmentControllers.values) {
        controller.dispose();
      }
    });
  }

  void _showApproveDialog(
    BuildContext context,
    StoreRequestController controller,
    String requestId,
  ) {
    final commentController = TextEditingController();
    bool isDisposed = false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => !controller.isApproving.value,
        child: Dialog(
          backgroundColor: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Approve Request',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => controller.isApproving.value
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Approving request...',
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : TextField(
                              controller: commentController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Comment (Optional)',
                                labelStyle: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? AppColors.darkSurfaceLight : theme.colorScheme.surface,
                              ),
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: controller.isApproving.value
                                ? null
                                : () {
                                    Get.back();
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isApproving.value
                                  ? null
                                  : () async {
                                      final comment = commentController.text.trim();
                                      setState(() {}); // Trigger rebuild
                                      final success = await controller.approveRequest(
                                        requestId,
                                        comment: comment.isEmpty ? null : comment,
                                        reloadPending: true,
                                      );
                                      if (success) {
                                        Get.back();
                                        CustomToast.success('Request approved successfully');
                                      } else {
                                        setState(() {}); // Trigger rebuild
                                        CustomToast.error(controller.error.value);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: controller.isApproving.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Approve'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ).then((_) {
      // Ensure controller is disposed only once when dialog is dismissed
      if (!isDisposed) {
        isDisposed = true;
        commentController.dispose();
      }
    });
  }

  void _showRejectDialog(
    BuildContext context,
    StoreRequestController controller,
    String requestId,
  ) {
    final commentController = TextEditingController();
    bool isDisposed = false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => !controller.isRejecting.value,
        child: Dialog(
          backgroundColor: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Reject Request',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => controller.isRejecting.value
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Rejecting request...',
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : TextField(
                              controller: commentController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Reason for Rejection',
                                labelStyle: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? AppColors.darkSurfaceLight : theme.colorScheme.surface,
                              ),
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: controller.isRejecting.value
                                ? null
                                : () {
                                    Get.back();
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isRejecting.value
                                  ? null
                                  : () async {
                                      final comment = commentController.text.trim();
                                      if (comment.isEmpty) {
                                        CustomToast.error('Please provide a reason for rejection');
                                        return;
                                      }
                                      setState(() {}); // Trigger rebuild
                                      final success = await controller.rejectRequest(requestId, comment);
                                      if (success) {
                                        Get.back();
                                        CustomToast.success('Request rejected');
                                      } else {
                                        setState(() {}); // Trigger rebuild
                                        CustomToast.error(controller.error.value);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                              child: controller.isRejecting.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Reject'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ).then((_) {
      // Ensure controller is disposed only once when dialog is dismissed
      if (!isDisposed) {
        isDisposed = true;
        commentController.dispose();
      }
    });
  }
}
