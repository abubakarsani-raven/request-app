import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/animations/sheet_animations.dart';
import '../custom_text_field.dart';
import '../../controllers/store_request_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../../data/models/inventory_item_model.dart';

/// Bottom sheet for creating Store requests
class CreateStoreRequestBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>>? initialItems;

  const CreateStoreRequestBottomSheet({Key? key, this.initialItems}) : super(key: key);

  /// Helper method to show the bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateStoreRequestBottomSheet(),
    );
  }

  /// Helper method to show the bottom sheet with pre-filled items (for repeating requests)
  static Future<void> showWithItems(BuildContext context, List<Map<String, dynamic>> items) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateStoreRequestBottomSheet(initialItems: items),
    );
  }

  @override
  State<CreateStoreRequestBottomSheet> createState() => _CreateStoreRequestBottomSheetState();
}

class _CreateStoreRequestBottomSheetState extends State<CreateStoreRequestBottomSheet> {
  final _storeController = Get.find<StoreRequestController>();
  final List<Map<String, dynamic>> _selectedItems = [];
  final List<TextEditingController> _quantityControllers = [];

  @override
  void initState() {
    super.initState();
    // Load inventory items when bottom sheet opens
    _storeController.loadInventoryItems();
    
    // If initial items provided (for repeating requests), pre-fill them
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillItems(widget.initialItems!);
      });
    } else {
      // Add one empty item row
      _addItemRow();
    }
  }

  void _prefillItems(List<Map<String, dynamic>> items) {
    setState(() {
      _selectedItems.clear();
      _quantityControllers.clear();
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        _selectedItems.add({
          'itemId': item['itemId'],
          'quantity': item['quantity'],
        });
        _quantityControllers.add(TextEditingController(text: item['quantity'].toString()));
        
        // Set the selected item after inventory loads
        final index = i;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index < _selectedItems.length) {
            final inventoryItem = _storeController.inventoryItems.firstWhereOrNull(
              (inventoryItem) => inventoryItem.id == item['itemId'],
            );
            if (inventoryItem != null) {
              _updateItem(index, inventoryItem);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      _selectedItems.add({
        'itemId': null,
        'quantity': 0,
      });
      _quantityControllers.add(TextEditingController(text: '1'));
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      if (index < _selectedItems.length) {
        _selectedItems.removeAt(index);
      }
      if (index < _quantityControllers.length) {
        _quantityControllers[index].dispose();
        _quantityControllers.removeAt(index);
      }
    });
  }

  void _updateItem(int index, InventoryItemModel? item) {
    setState(() {
      if (index < _selectedItems.length) {
        _selectedItems[index]['itemId'] = item?.id;
      }
    });
  }

  void _updateQuantity(int index, String value) {
    final quantity = int.tryParse(value) ?? 0;
    setState(() {
      if (index < _selectedItems.length) {
        _selectedItems[index]['quantity'] = quantity;
      }
    });
  }

  List<Map<String, dynamic>> _getValidItems() {
    return _selectedItems
        .where((item) => item['itemId'] != null && (item['quantity'] as int) > 0)
        .map((item) => {
              'itemId': item['itemId'],
              'quantity': item['quantity'],
            })
        .toList();
  }

  Future<void> _submitRequest() async {
    SheetHaptics.mediumImpact();
    
    final validItems = _getValidItems();
    if (validItems.isEmpty) {
      CustomToast.warning('Please select at least one item with quantity', title: 'Missing Items');
      return;
    }

    final success = await _storeController.createStoreRequest(validItems);
    if (success) {
      try {
        final notificationController = Get.find<NotificationController>();
        await notificationController.loadNotifications(unreadOnly: false);
        await notificationController.loadUnreadCount();
      } catch (e) {
        print('Error refreshing notifications: $e');
      }
      Navigator.of(context).pop();
      CustomToast.success('Store request created successfully', title: 'Success');
    } else {
      CustomToast.error(
        _storeController.error.value.isNotEmpty
            ? _storeController.error.value
            : 'Failed to create request',
        title: 'Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBottomSheet(
      title: 'Create Store Request',
      submitText: 'Submit Request',
      cancelText: 'Cancel',
      onSubmit: _submitRequest,
      onCancel: () => Navigator.of(context).pop(),
      isLoading: _storeController.isLoading.value,
      isSubmitEnabled: _getValidItems().isNotEmpty,
      initialChildSize: BottomSheetSizes.full,
      child: Obx(() {
        if (_storeController.isLoading.value && _storeController.inventoryItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            ...List.generate(_selectedItems.length, (index) {
              return _buildItemRow(index);
            }),
            const SizedBox(height: AppConstants.spacingM),
            OutlinedButton.icon(
              onPressed: _addItemRow,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildItemRow(int index) {
    final selectedItemId = _selectedItems[index]['itemId'] as String?;
    InventoryItemModel? selectedItem;
    if (selectedItemId != null) {
      selectedItem = _storeController.inventoryItems.firstWhereOrNull(
        (item) => item.id == selectedItemId,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<InventoryItemModel?>(
                  value: selectedItem,
                  decoration: InputDecoration(
                    labelText: 'Select Item',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  hint: const Text('Choose an item'),
                  items: [
                    const DropdownMenuItem<InventoryItemModel?>(
                      value: null,
                      child: Text('-- Select Item --'),
                    ),
                    ..._storeController.inventoryItems.map((item) {
                      // Check if item is already selected in another row
                      final isSelectedElsewhere = _selectedItems
                          .asMap()
                          .entries
                          .where((e) => e.key != index)
                          .any((e) => e.value['itemId'] == item.id);
                      
                      return DropdownMenuItem<InventoryItemModel?>(
                        value: item,
                        enabled: !isSelectedElsewhere,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: isSelectedElsewhere ? Colors.grey : null,
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: (item) => _updateItem(index, item),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an item';
                    }
                    return null;
                  },
                ),
              ),
              if (_selectedItems.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _removeItemRow(index),
                ),
            ],
          ),
          if (selectedItem != null) ...[
            const SizedBox(height: AppConstants.spacingS),
            Text(
              selectedItem.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: AppConstants.spacingM),
          CustomTextField(
            label: 'Quantity',
            controller: _quantityControllers[index],
            prefixIcon: Icons.numbers,
            keyboardType: TextInputType.number,
            onChanged: (value) => _updateQuantity(index, value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter quantity';
              }
              final qty = int.tryParse(value);
              if (qty == null || qty <= 0) {
                return 'Quantity must be greater than 0';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

