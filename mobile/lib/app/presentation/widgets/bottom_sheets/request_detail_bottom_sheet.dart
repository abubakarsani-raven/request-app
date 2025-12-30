import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../data/models/request_model.dart' show VehicleRequestModel, RequestType;
import '../../controllers/request_controller.dart';
import '../status_badge.dart';
import '../workflow_timeline.dart';
import '../workflow_progress_indicator.dart';
import 'approval_action_bottom_sheet.dart';
import '../../../../core/services/permission_service.dart';
import '../../controllers/auth_controller.dart';

class RequestDetailBottomSheet extends StatelessWidget {
  final String requestId;
  final VehicleRequestModel? request;

  const RequestDetailBottomSheet({
    Key? key,
    required this.requestId,
    this.request,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String requestId,
    VehicleRequestModel? request,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestDetailBottomSheet(
        requestId: requestId,
        request: request,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<RequestController>();
    
    // Load request if not provided
    if (request == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        requestController.loadRequest(requestId);
      });
    }

    return Obx(() {
      final currentRequest = request ?? requestController.selectedRequest.value;
      
      if (currentRequest == null && requestController.isLoading.value) {
        return DetailBottomSheet(
          title: 'Request Details',
          collapsedContent: const Center(child: CircularProgressIndicator()),
          expandedContent: const SizedBox(),
          initialChildSize: BottomSheetSizes.large,
        );
      }

      if (currentRequest == null) {
        return DetailBottomSheet(
          title: 'Request Details',
          collapsedContent: const Center(child: Text('Request not found')),
          expandedContent: const SizedBox(),
          initialChildSize: BottomSheetSizes.large,
        );
      }

      final authController = Get.find<AuthController>();
      final permissionService = Get.find<PermissionService>();
      final user = authController.user.value;

      return DetailBottomSheet(
        title: 'Request Details',
        initialChildSize: BottomSheetSizes.large,
        collapsedContent: _buildSummary(context, currentRequest),
        expandedContent: _buildFullDetails(context, currentRequest, user, permissionService),
        actionFooter: user != null
            ? _buildActionFooter(context, currentRequest, user, permissionService)
            : null,
      );
    });
  }

  Widget _buildSummary(BuildContext context, VehicleRequestModel request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.destination,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              StatusBadge(
                status: request.status,
                workflowStage: request.workflowStage,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Trip Date: ${DateFormat('MMM dd, yyyy').format(request.tripDate)}',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFullDetails(
    BuildContext context,
    VehicleRequestModel request,
    dynamic user,
    PermissionService permissionService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Request Information
        _buildDetailSection(
          context,
          'Request Information',
          [
            _buildDetailRow('Destination', request.destination),
            _buildDetailRow('Purpose', request.purpose),
            _buildDetailRow('Trip Date', DateFormat('MMM dd, yyyy').format(request.tripDate)),
            _buildDetailRow('Trip Time', request.tripTime),
            _buildDetailRow('Return Date', DateFormat('MMM dd, yyyy').format(request.returnDate)),
          ],
        ),
        const SizedBox(height: 16),
        // Workflow Progress Indicator
        WorkflowProgressIndicator(
          request: request,
        ),
      ],
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActionFooter(
    BuildContext context,
    VehicleRequestModel request,
    dynamic user,
    PermissionService permissionService,
  ) {
    final actions = <Widget>[];

    // Approval actions - simplified for now
    final workflowStage = request.workflowStage ?? '';
    if (workflowStage.isNotEmpty && permissionService.canApprove(user, RequestType.vehicle, workflowStage)) {
      actions.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ApprovalActionBottomSheet.show(
                context: context,
                request: request,
                approvalType: workflowStage,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Approve'),
          ),
        ),
      );
    }

    if (actions.isEmpty) return null;

    return Row(children: actions);
  }
}

