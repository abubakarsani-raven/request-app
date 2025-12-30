import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/animations/sheet_animations.dart';
import '../../../data/models/request_model.dart';
import '../../controllers/request_controller.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../custom_text_field.dart';
import '../../pages/assignment_page.dart';

class ApprovalActionBottomSheet extends StatefulWidget {
  final VehicleRequestModel request;
  final String approvalType; // 'DGS', 'DDGS', 'ADGS', etc.

  const ApprovalActionBottomSheet({
    Key? key,
    required this.request,
    required this.approvalType,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required VehicleRequestModel request,
    required String approvalType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApprovalActionBottomSheet(
        request: request,
        approvalType: approvalType,
      ),
    );
  }

  @override
  State<ApprovalActionBottomSheet> createState() => _ApprovalActionBottomSheetState();
}

class _ApprovalActionBottomSheetState extends State<ApprovalActionBottomSheet> {
  final _commentController = TextEditingController();
  final _requestController = Get.find<RequestController>();
  String _selectedAction = 'approve'; // 'approve', 'reject', 'assign'

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleApproval() async {
    SheetHaptics.mediumImpact();
    
    if (_selectedAction == 'approve') {
      final success = await _requestController.approveRequest(
        widget.request.id,
        comment: _commentController.text,
      );
      if (success) {
        Navigator.of(context).pop();
        CustomToast.success('Request approved successfully');
      } else {
        CustomToast.error(_requestController.error.value);
      }
    } else if (_selectedAction == 'reject') {
      if (_commentController.text.trim().isEmpty) {
        CustomToast.warning('Please provide a reason for rejection');
        return;
      }
      final success = await _requestController.rejectRequest(
        widget.request.id,
        _commentController.text,
      );
      if (success) {
        Navigator.of(context).pop();
        CustomToast.success('Request rejected');
      } else {
        CustomToast.error(_requestController.error.value);
      }
    } else if (_selectedAction == 'assign') {
      Navigator.of(context).pop();
      Get.to(() => AssignmentPage(requestId: widget.request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDGS = widget.approvalType == 'DGS';
    
    return FormBottomSheet(
      title: '${widget.approvalType} Approval',
      submitText: _selectedAction == 'approve' 
          ? 'Approve Request'
          : _selectedAction == 'reject'
              ? 'Reject Request'
              : 'Assign Vehicle',
      cancelText: 'Cancel',
      onSubmit: _handleApproval,
      onCancel: () => Navigator.of(context).pop(),
      isLoading: _requestController.isLoading.value,
      isSubmitEnabled: true,
      initialChildSize: isDGS ? BottomSheetSizes.medium : BottomSheetSizes.small,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDGS) ...[
            Text(
              'Choose how to proceed:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildActionOption(
              'approve',
              'Approve to Next Stage',
              'Continue normal workflow',
              Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              'assign',
              'Assign Vehicle Now',
              'Skip workflow and assign directly',
              Icons.directions_car,
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              'reject',
              'Reject Request',
              'Reject this request',
              Icons.cancel_outlined,
            ),
            const SizedBox(height: 24),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildActionOption(
                    'approve',
                    'Approve',
                    null,
                    Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionOption(
                    'reject',
                    'Reject',
                    null,
                    Icons.cancel_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Comment (Optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _commentController,
            hint: 'Add a comment...',
            maxLines: 3,
            prefixIcon: Icons.comment_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption(
    String value,
    String title,
    String? subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedAction == value;
    final color = value == 'reject' 
        ? AppColors.error 
        : value == 'assign'
            ? AppColors.warning
            : AppColors.success;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = value;
        });
        SheetHaptics.selectionClick();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

