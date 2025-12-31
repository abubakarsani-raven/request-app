import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_drawer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/loading_overlay.dart';
import '../../data/models/ict_request_model.dart';
import '../../data/models/request_model.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_toast.dart';
import 'ict_workflow_timeline.dart';
import 'request_detail_page.dart'; // For RequestDetailSource enum

class ICTRequestDetailPage extends StatelessWidget {
  final String requestId;
  final RequestDetailSource? source;
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();

  ICTRequestDetailPage({
    Key? key,
    required this.requestId,
    this.source,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ictController = Get.put(ICTRequestController());
    final authController = Get.find<AuthController>();

    // Load request details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ictController.loadRequest(requestId);
    });

    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
          ),
          title: const Text('ICT Request Details'),
        ),
        body: LoadingOverlay(
          isLoading: ictController.isApproving.value ||
                     ictController.isRejecting.value ||
                     ictController.isFulfilling.value ||
                     ictController.isUpdating.value ||
                     ictController.isReloading.value,
          message: ictController.isApproving.value
              ? 'Approving request...'
              : ictController.isRejecting.value
                  ? 'Rejecting request...'
                  : ictController.isFulfilling.value
                      ? 'Fulfilling request...'
                      : ictController.isUpdating.value
                          ? 'Updating request...'
                          : 'Loading...',
          child: Obx(
            () {
              final request = ictController.selectedRequest.value;

              if (ictController.isLoading.value && request == null) {
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
                        onPressed: () => ictController.loadRequest(requestId),
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
                      if (request.comment != null && request.comment!.isNotEmpty)
                        _buildDetailRow('Notes', request.comment!),
                    ],
                  ),

                  // Requested Items
                  const SizedBox(height: AppConstants.spacingXXL),
                  _buildItemsSection(context, request),

                  // Quantity Changes History (if any)
                  if (request.quantityChanges.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingXXL),
                    _buildQuantityChangesSection(context, request),
                  ],

                  // Workflow Timeline
                  const SizedBox(height: AppConstants.spacingXXL),
                  ICTWorkflowTimeline(request: request),

                  const SizedBox(height: AppConstants.spacingXXL),

                  // Action Buttons
                  _buildActionButtons(context, request, authController, ictController),
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

  Widget _buildStatChip(String label, String value, Color color) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsSection(BuildContext context, ICTRequestModel request) {
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
              final approved = item.approvedQuantity ?? requested;
              final fulfilled = item.fulfilledQuantity;
              final remaining = approved - fulfilled;
              final isFulfilled = remaining == 0;
              final wasAdjusted = item.approvedQuantity != null && item.approvedQuantity != item.requestedQuantity;

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
                        if (wasAdjusted) ...[
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 11, color: AppColors.warning),
                                const SizedBox(width: 3),
                                Text(
                                  'Adjusted',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                    if (wasAdjusted) ...[
                      Row(
                        children: [
                          Text(
                            'Requested: ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$requested',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Approved: ',
                            style: TextStyle(
                              color: isDark 
                                  ? AppColors.darkTextSecondary 
                                  : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$approved',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            'Approved: ',
                            style: TextStyle(
                              color: isDark 
                                  ? AppColors.darkTextSecondary 
                                  : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$approved',
                            style: TextStyle(
                              color: isDark 
                                  ? AppColors.darkTextPrimary 
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Fulfillment status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatChip('Fulfilled', '$fulfilled', isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary),
                        _buildStatChip('Remaining', '$remaining', remaining > 0 ? AppColors.warning : AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    LinearProgressIndicator(
                      value: approved > 0 ? fulfilled / approved : 0,
                      minHeight: 6,
                      backgroundColor: isDark 
                          ? AppColors.darkBorderDefined.withOpacity(0.3)
                          : AppColors.border.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFulfilled ? AppColors.success : AppColors.primary,
                      ),
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

  Widget _buildActionButtons(
    BuildContext context,
    ICTRequestModel request,
    AuthController authController,
    ICTRequestController ictController,
  ) {
    final user = authController.user.value;
    final permissionService = Get.find<PermissionService>();
    if (user == null) return const SizedBox();

    // Only Store Officer (SO) can fulfill ICT requests at FULFILLMENT or SO_REVIEW stage
    final canFulfill = permissionService.canFulfillRequest(user, RequestType.ict) &&
    (request.workflowStage == 'FULFILLMENT' || request.workflowStage == 'SO_REVIEW') &&
    (request.status == RequestStatus.approved || request.status == RequestStatus.pending);

    // Check if user can approve at the current workflow stage
    final workflowStage = request.workflowStage ?? 'SUBMITTED';
    final canApproveAtStage = permissionService.canApprove(
      user,
      RequestType.ict,
      workflowStage,
    );
    
    // Helper function to get workflow stage for a role
    String getStageForRole(String role) {
      switch (role.toUpperCase()) {
        case 'SUPERVISOR':
          return 'SUPERVISOR_REVIEW';
        case 'DDICT':
          return 'DDICT_REVIEW';
        case 'DGS':
          return 'DGS_REVIEW';
        case 'SO':
          return 'SO_REVIEW';
        default:
          return '';
      }
    }
    
    // Also check if user has already approved at this stage (prevent duplicate approvals)
    final userHasApproved = request.approvals.any((approval) {
      final approvalRole = approval.role.toUpperCase();
      final userRoles = user.roles.map((r) => r.toUpperCase()).toList();
      
      // Check if any of user's roles match the approval role
      if (!userRoles.contains(approvalRole) || approval.status != 'APPROVED') {
        return false;
      }
      
      // Remove the special handling for DGS that allows approval at any stage
      // DGS should only be considered as having approved if they approved at DGS_REVIEW
      if (approvalRole == 'DGS') {
        return getStageForRole(approvalRole) == workflowStage;
      }
      
      // For other roles, check if approval was at the correct stage
      return getStageForRole(approvalRole) == workflowStage;
    });
    
    // User can approve if they have permission at the current stage and haven't already approved
    final canApprove = canApproveAtStage &&
        !userHasApproved &&
        (request.status == RequestStatus.pending || request.status == RequestStatus.corrected);
    
    // Check if user can notify requester (SO only, at FULFILLMENT or SO_REVIEW stage)
    final canNotify = user.roles.any((role) => role.toUpperCase() == 'SO') &&
        (workflowStage == 'FULFILLMENT' || workflowStage == 'SO_REVIEW') &&
        (request.status == RequestStatus.approved || request.status == RequestStatus.pending);

    // DDICT can adjust quantities at DDICT_REVIEW stage
    final canAdjustQuantities = user.roles.any((role) => role.toUpperCase() == 'DDICT') &&
        workflowStage == 'DDICT_REVIEW' &&
        (request.status == RequestStatus.pending || request.status == RequestStatus.corrected);

    return Column(
      children: [
        if (canFulfill) ...[
          CustomButton(
            text: 'Fulfill Request',
            icon: Icons.check_circle,
            isLoading: ictController.isFulfilling.value,
            onPressed: ictController.isFulfilling.value
                ? null
                : () => _showFulfillmentDialog(context, ictController, request),
          ),
          const SizedBox(height: AppConstants.spacingM),
        ],
        if (canAdjustQuantities) ...[
          CustomButton(
            text: 'Adjust Quantities',
            icon: Icons.edit,
            type: ButtonType.outlined,
            isLoading: ictController.isUpdating.value,
            onPressed: ictController.isUpdating.value
                ? null
                : () => _showAdjustQuantitiesDialog(context, ictController, request),
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
                  isLoading: ictController.isApproving.value,
                  onPressed: ictController.isApproving.value
                      ? null
                      : () => _showApproveDialog(context, ictController, request.id),
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
                  isLoading: ictController.isRejecting.value,
                  onPressed: ictController.isRejecting.value
                      ? null
                      : () => _showRejectDialog(context, ictController, request.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
        ],
        if (canNotify) ...[
          CustomButton(
            text: 'Notify Requester',
            icon: Icons.notifications,
            type: ButtonType.outlined,
            onPressed: () => _showNotifyDialog(context, ictController, request.id),
          ),
        ],
      ],
    );
  }

  void _showFulfillmentDialog(
    BuildContext context,
    ICTRequestController controller,
    ICTRequestModel request,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fulfillmentControllers = <String, TextEditingController>{};
    
    for (var item in request.items) {
      // Use approved quantity if available, otherwise requested quantity
      final approvedQty = item.approvedQuantity ?? item.requestedQuantity;
      final remaining = approvedQty - item.fulfilledQuantity;
      fulfillmentControllers[item.itemId] = TextEditingController(
        text: remaining > 0 ? remaining.toString() : '0',
      );
    }

    Get.dialog(
      Dialog(
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
                      // Use approved quantity if available, otherwise requested quantity
                      final approvedQty = item.approvedQuantity ?? item.requestedQuantity;
                      final remaining = approvedQty - item.fulfilledQuantity;
                      final controller = fulfillmentControllers[item.itemId]!;
                      final availableQty = item.availableQuantity ?? 0;
                      
                      return StatefulBuilder(
                        builder: (context, setState) {
                          final requestedQty = int.tryParse(controller.text) ?? 0;
                          final exceedsAvailable = requestedQty > availableQty && availableQty > 0;
                          final isPartialFulfillment = requestedQty > 0 && requestedQty < remaining && remaining > 0;

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
                                // Show available quantity prominently
                                if (availableQty > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: exceedsAvailable 
                                          ? (isDark ? AppColors.error.withOpacity(0.2) : AppColors.error.withOpacity(0.1))
                                          : (isDark ? AppColors.success.withOpacity(0.2) : AppColors.success.withOpacity(0.1)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: exceedsAvailable 
                                            ? AppColors.error.withOpacity(0.5)
                                            : AppColors.success.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          exceedsAvailable ? Icons.warning : Icons.inventory_2,
                                          size: 16,
                                          color: exceedsAvailable ? AppColors.error : AppColors.success,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Available in Stock: $availableQty',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: exceedsAvailable ? AppColors.error : AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // Show approved quantity information
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Text(
                                      'Approved: $approvedQty',
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
                                if (exceedsAvailable) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Requested quantity ($requestedQty) exceeds available stock ($availableQty)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (isPartialFulfillment) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.warning.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Partial Fulfillment: You are fulfilling $requestedQty out of $remaining remaining. This will result in a partially fulfilled request.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'Quantity to Fulfill',
                                    hintText: availableQty > 0 ? 'Max: $availableQty' : 'Enter quantity',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: exceedsAvailable 
                                            ? AppColors.error 
                                            : (isPartialFulfillment 
                                                ? AppColors.warning 
                                                : (isDark ? AppColors.darkBorderDefined : AppColors.border)),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: exceedsAvailable 
                                            ? AppColors.error 
                                            : (isPartialFulfillment 
                                                ? AppColors.warning 
                                                : (isDark ? AppColors.darkBorderDefined : AppColors.border)),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: exceedsAvailable 
                                            ? AppColors.error 
                                            : (isPartialFulfillment 
                                                ? AppColors.warning 
                                                : AppColors.primary),
                                        width: 2,
                                      ),
                                    ),
                                    errorText: exceedsAvailable ? 'Exceeds available stock' : null,
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                  onChanged: (value) {
                                    setState(() {}); // Rebuild to update warning
                                  },
                                ),
                              ],
                            ),
                          );
                        },
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
                        onPressed: () => Get.back(),
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
                                    if (qty > 0) {
                                      fulfillmentData[entry.key] = qty;
                                    }
                                  }

                                  if (fulfillmentData.isEmpty) {
                                    CustomToast.error('Please specify quantities to fulfill');
                                    return;
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
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
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
    );
  }

  void _showApproveDialog(BuildContext context, ICTRequestController controller, String requestId) {
    final commentController = TextEditingController();
    bool isDisposed = false;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => !controller.isApproving.value,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Approve Request'),
              content: controller.isApproving.value
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Approving request...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    )
                  : TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment (Optional)',
                        hintText: 'Add a comment...',
                      ),
                      maxLines: 3,
                    ),
              actions: [
                TextButton(
                  onPressed: controller.isApproving.value
                      ? null
                      : () {
                          Get.back();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: controller.isApproving.value
                      ? null
                      : () async {
                          final comment = commentController.text.isEmpty ? null : commentController.text;
                          // Check if we came from pending approvals page
                          final cameFromPendingApprovals = source == RequestDetailSource.pendingApprovals;
                          setState(() {}); // Trigger rebuild to show loading
                          final success = await controller.approveRequest(
                            requestId,
                            comment: comment,
                            reloadPending: cameFromPendingApprovals,
                          );
                          if (success) {
                            Get.back();
                            CustomToast.success('Request approved successfully');
                            await controller.loadRequest(requestId);
                          } else {
                            setState(() {}); // Trigger rebuild to hide loading
                            CustomToast.error(controller.error.value);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
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
              ],
            );
          },
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      // Ensure controller is disposed only once when dialog is dismissed
      if (!isDisposed) {
        isDisposed = true;
        commentController.dispose();
      }
    });
  }

  void _showRejectDialog(BuildContext context, ICTRequestController controller, String requestId) {
    final commentController = TextEditingController();
    bool isDisposed = false;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => !controller.isRejecting.value,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reject Request'),
              content: controller.isRejecting.value
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Rejecting request...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    )
                  : TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Reason *',
                        hintText: 'Please provide a reason for rejection...',
                      ),
                      maxLines: 3,
                    ),
              actions: [
                TextButton(
                  onPressed: controller.isRejecting.value
                      ? null
                      : () {
                          Get.back();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: controller.isRejecting.value
                      ? null
                      : () async {
                          if (commentController.text.isEmpty) {
                            CustomToast.error('Please provide a reason');
                            return;
                          }
                          final comment = commentController.text;
                          setState(() {}); // Trigger rebuild to show loading
                          final success = await controller.rejectRequest(requestId, comment);
                          if (success) {
                            Get.back();
                            CustomToast.success('Request rejected');
                            await controller.loadRequest(requestId);
                          } else {
                            setState(() {}); // Trigger rebuild to hide loading
                            CustomToast.error(controller.error.value);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textOnPrimary,
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
              ],
            );
          },
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      // Ensure controller is disposed only once when dialog is dismissed
      if (!isDisposed) {
        isDisposed = true;
        commentController.dispose();
      }
    });
  }

  void _showNotifyDialog(BuildContext context, ICTRequestController controller, String requestId) {
    final messageController = TextEditingController();
    bool isDisposed = false;

    Get.dialog(
      AlertDialog(
        title: const Text('Notify Requester'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send a notification to the requester about item availability.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Add a custom message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = messageController.text.isEmpty ? null : messageController.text;
              final success = await controller.notifyRequester(
                requestId,
                message: message,
              );
              if (success) {
                Get.back();
                CustomToast.success('Requester notified successfully');
              } else {
                CustomToast.error(controller.error.value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Send Notification'),
          ),
        ],
      ),
    ).then((_) {
      // Ensure controller is disposed only once when dialog is dismissed
      if (!isDisposed) {
        isDisposed = true;
        messageController.dispose();
      }
    });
  }

  Widget _buildQuantityChangesSection(BuildContext context, ICTRequestModel request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity Changes History',
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
                height: 1.3,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? AppColors.darkBorderDefined.withOpacity(0.5)
                  : AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: request.quantityChanges.asMap().entries.map((entry) {
              final index = entry.key;
              final change = entry.value;
              final wasIncreased = change.newQuantity > change.previousQuantity;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark 
                          ? AppColors.darkBorderDefined.withOpacity(0.5)
                          : AppColors.border.withOpacity(0.3),
                      width: index < request.quantityChanges.length - 1 ? 1 : 0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Change indicator
                    Container(
                      width: 4,
                      height: 50,
                      decoration: BoxDecoration(
                        color: wasIncreased ? AppColors.success : AppColors.error,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  change.itemName ?? 'Item ID: ${change.itemId.substring(0, 8)}...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (wasIncreased ? AppColors.success : AppColors.error).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  wasIncreased ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 12,
                                  color: wasIncreased ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${change.previousQuantity}',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward, 
                                size: 12, 
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${change.newQuantity}',
                                style: TextStyle(
                                  color: wasIncreased ? AppColors.success : AppColors.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a').format(change.changedAt),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
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

  void _showAdjustQuantitiesDialog(
    BuildContext context,
    ICTRequestController controller,
    ICTRequestModel request,
  ) {
    final quantityControllers = <String, TextEditingController>{};
    bool areDisposed = false;
    for (var item in request.items) {
      // Use approvedQuantity if exists, otherwise requestedQuantity
      final currentQuantity = item.approvedQuantity ?? item.requestedQuantity;
      quantityControllers[item.itemId] = TextEditingController(
        text: currentQuantity.toString(),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Get.dialog(
      WillPopScope(
        onWillPop: () async => !controller.isUpdating.value,
        child: Dialog(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Adjust Quantities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark 
                            ? AppColors.darkTextPrimary 
                            : AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Adjust approved quantities. Original requested quantities will be preserved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: request.items.length,
                    itemBuilder: (context, index) {
                      final item = request.items[index];
                      final controller = quantityControllers[item.itemId]!;
                      final wasAdjusted = item.approvedQuantity != null && item.approvedQuantity != item.requestedQuantity;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? AppColors.darkSurfaceLight 
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                                ? AppColors.darkBorderDefined.withOpacity(0.5)
                                : AppColors.border.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName ?? 'Item ID: ${item.itemId.substring(0, 8)}...',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark 
                                    ? AppColors.darkTextPrimary 
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Requested: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark 
                                        ? AppColors.darkTextSecondary 
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${item.requestedQuantity}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark 
                                        ? AppColors.darkTextSecondary 
                                        : AppColors.textSecondary,
                                    decoration: wasAdjusted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                if (wasAdjusted) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '→ ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark 
                                          ? AppColors.darkTextSecondary 
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${item.approvedQuantity}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: controller,
                              style: TextStyle(
                                color: isDark 
                                    ? AppColors.darkTextPrimary 
                                    : AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Approved Quantity',
                                labelStyle: TextStyle(
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.textSecondary,
                                ),
                                hintText: 'Enter quantity',
                                hintStyle: TextStyle(
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark 
                                        ? AppColors.darkBorderDefined.withOpacity(0.5)
                                        : AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark 
                                        ? AppColors.darkBorderDefined.withOpacity(0.5)
                                        : AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark 
                                    ? AppColors.darkSurface 
                                    : theme.colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: isDark 
                              ? AppColors.darkTextPrimary 
                              : AppColors.textPrimary,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isUpdating.value
                              ? null
                              : () async {
                                  final itemsData = <String, int>{};
                                  for (var entry in quantityControllers.entries) {
                                    final qty = int.tryParse(entry.value.text) ?? 0;
                                    if (qty <= 0) {
                                      CustomToast.error('All quantities must be greater than 0');
                                      return;
                                    }
                                    itemsData[entry.key] = qty;
                                  }

                                  final success = await controller.updateRequestItems(request.id, itemsData);
                                  if (success) {
                                    Get.back();
                                    CustomToast.success('Quantities updated successfully');
                                    await controller.loadRequest(request.id);
                                  } else {
                                    CustomToast.error(controller.error.value);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          child: controller.isUpdating.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Update'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    ).then((_) {
      // Ensure all controllers are disposed only once when dialog is dismissed
      if (!areDisposed) {
        areDisposed = true;
        for (var controller in quantityControllers.values) {
          controller.dispose();
        }
      }
    });
  }
}

