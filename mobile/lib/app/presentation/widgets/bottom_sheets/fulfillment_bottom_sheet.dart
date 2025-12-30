import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/animations/sheet_animations.dart';
import '../../../data/models/store_request_model.dart';
import '../../../data/models/ict_request_model.dart';
import '../../controllers/store_request_controller.dart';
import '../../controllers/ict_request_controller.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../custom_text_field.dart';

class FulfillmentBottomSheet extends StatefulWidget {
  final dynamic request; // StoreRequestModel or ICTRequestModel
  final String requestType; // 'store' or 'ict'

  const FulfillmentBottomSheet({
    Key? key,
    required this.request,
    required this.requestType,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required dynamic request,
    required String requestType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FulfillmentBottomSheet(
        request: request,
        requestType: requestType,
      ),
    );
  }

  @override
  State<FulfillmentBottomSheet> createState() => _FulfillmentBottomSheetState();
}

class _FulfillmentBottomSheetState extends State<FulfillmentBottomSheet> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, int> _fulfillmentData = {};
  final _storeController = Get.find<StoreRequestController>();
  final _ictController = Get.find<ICTRequestController>();

  @override
  void initState() {
    super.initState();
    if (widget.requestType == 'store') {
      final storeRequest = widget.request as StoreRequestModel;
      for (var item in storeRequest.items) {
        _controllers[item.itemId] = TextEditingController(
          text: item.requestedQuantity.toString(),
        );
        _fulfillmentData[item.itemId] = item.requestedQuantity;
      }
    } else {
      final ictRequest = widget.request as ICTRequestModel;
      for (var item in ictRequest.items) {
        _controllers[item.itemId] = TextEditingController(
          text: item.requestedQuantity.toString(),
        );
        _fulfillmentData[item.itemId] = item.requestedQuantity;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isLoading {
    if (widget.requestType == 'store') {
      return _storeController.isLoading.value;
    } else {
      return _ictController.isLoading.value;
    }
  }

  Future<void> _submitFulfillment() async {
    SheetHaptics.mediumImpact();
    
    if (widget.requestType == 'store') {
      final success = await _storeController.fulfillRequest(
        widget.request.id,
        _fulfillmentData,
      );
      if (success) {
        Navigator.of(context).pop();
        CustomToast.success('Request fulfilled successfully');
      } else {
        CustomToast.error(_storeController.error.value);
      }
    } else {
      final success = await _ictController.fulfillRequest(
        widget.request.id,
        _fulfillmentData,
      );
      if (success) {
        Navigator.of(context).pop();
        CustomToast.success('Request fulfilled successfully');
      } else {
        CustomToast.error(_ictController.error.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.requestType == 'store'
        ? (widget.request as StoreRequestModel).items
        : (widget.request as ICTRequestModel).items;

    return FormBottomSheet(
      title: 'Fulfill Request',
      submitText: 'Fulfill Request',
      cancelText: 'Cancel',
      onSubmit: _submitFulfillment,
      onCancel: () => Navigator.of(context).pop(),
      isLoading: _isLoading,
      isSubmitEnabled: true,
      initialChildSize: BottomSheetSizes.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter fulfillment quantities for each item:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final itemId = item.itemId;
            final controller = _controllers[itemId]!;
            
            // Get approved quantity for ICT requests, requested quantity for store requests
            int approvedOrRequestedQty;
            String quantityLabel;
            if (widget.requestType == 'ict') {
              // For ICT requests, use approvedQuantity if available, otherwise requestedQuantity
              approvedOrRequestedQty = item.approvedQuantity ?? item.requestedQuantity;
              quantityLabel = 'Approved: $approvedOrRequestedQty';
            } else {
              // For store requests, use requestedQuantity (store requests don't have approvedQuantity)
              approvedOrRequestedQty = item.requestedQuantity;
              quantityLabel = 'Requested: $approvedOrRequestedQty';
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item: $itemId',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: controller,
                          label: 'Quantity',
                          hint: 'Enter quantity',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.inventory_2_outlined,
                          onChanged: (value) {
                            final qty = int.tryParse(value) ?? 0;
                            _fulfillmentData[itemId] = qty;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          quantityLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

