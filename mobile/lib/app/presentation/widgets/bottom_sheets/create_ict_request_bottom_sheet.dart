import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/animations/sheet_animations.dart';
import '../custom_text_field.dart';
import '../../controllers/ict_request_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../../data/models/catalog_item_model.dart';
import 'dart:async';

/// Bottom sheet for creating ICT requests
class CreateICTRequestBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>>? initialItems;

  const CreateICTRequestBottomSheet({Key? key, this.initialItems}) : super(key: key);

  /// Helper method to show the bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateICTRequestBottomSheet(),
    );
  }

  /// Helper method to show the bottom sheet with pre-filled items (for repeating requests)
  static Future<void> showWithItems(BuildContext context, List<Map<String, dynamic>> items) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateICTRequestBottomSheet(initialItems: items),
    );
  }

  @override
  State<CreateICTRequestBottomSheet> createState() => _CreateICTRequestBottomSheetState();
}

class _CreateICTRequestBottomSheetState extends State<CreateICTRequestBottomSheet> {
  final _ictController = Get.find<ICTRequestController>();
  final List<Map<String, dynamic>> _selectedItems = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _searchControllers = [];
  final List<FocusNode> _searchFocusNodes = [];
  final List<bool> _showDropdowns = [];

  @override
  void initState() {
    super.initState();
    // Load catalog items when bottom sheet opens
    _ictController.loadCatalogItems();
    
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
      _searchControllers.clear();
      _searchFocusNodes.clear();
      _showDropdowns.clear();
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        _selectedItems.add({
          'itemId': item['itemId'],
          'quantity': item['quantity'],
        });
        _quantityControllers.add(TextEditingController(text: item['quantity'].toString()));
        _searchControllers.add(TextEditingController());
        _searchFocusNodes.add(FocusNode());
        _showDropdowns.add(false);
        
        // Set the selected item after catalog loads
        final index = i;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index < _selectedItems.length) {
            final catalogItem = _ictController.catalogItems.firstWhereOrNull(
              (catalogItem) => catalogItem.id == item['itemId'],
            );
            if (catalogItem != null) {
              _updateItem(index, catalogItem);
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
    for (var controller in _searchControllers) {
      controller.dispose();
    }
    for (var focusNode in _searchFocusNodes) {
      focusNode.dispose();
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
      _searchControllers.add(TextEditingController());
      _searchFocusNodes.add(FocusNode());
      _showDropdowns.add(false);
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
      if (index < _searchControllers.length) {
        _searchControllers[index].dispose();
        _searchControllers.removeAt(index);
      }
      if (index < _searchFocusNodes.length) {
        _searchFocusNodes[index].dispose();
        _searchFocusNodes.removeAt(index);
      }
      if (index < _showDropdowns.length) {
        _showDropdowns.removeAt(index);
      }
    });
  }

  void _updateItem(int index, CatalogItemModel? item) {
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

    final success = await _ictController.createICTRequest(validItems);
    if (success) {
      try {
        final notificationController = Get.find<NotificationController>();
        await notificationController.loadNotifications(unreadOnly: false);
        await notificationController.loadUnreadCount();
      } catch (e) {
        print('Error refreshing notifications: $e');
      }
      Navigator.of(context).pop();
      CustomToast.success('ICT request created successfully', title: 'Success');
    } else {
      CustomToast.error(
        _ictController.error.value.isNotEmpty
            ? _ictController.error.value
            : 'Failed to create request',
        title: 'Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FormBottomSheet(
      title: 'Create ICT Request',
      submitText: 'Submit Request',
      cancelText: 'Cancel',
      onSubmit: _submitRequest,
      onCancel: () => Navigator.of(context).pop(),
      isLoading: _ictController.isLoading.value,
      isSubmitEnabled: _getValidItems().isNotEmpty,
      initialChildSize: BottomSheetSizes.full,
      child: Obx(() {
        if (_ictController.isLoading.value && _ictController.catalogItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return GestureDetector(
          onTap: () {
            // Close all dropdowns when tapping outside
            for (int i = 0; i < _showDropdowns.length; i++) {
              if (_showDropdowns[i]) {
                setState(() {
                  _showDropdowns[i] = false;
                });
                _searchFocusNodes[i].unfocus();
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Items',
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              ...List.generate(_selectedItems.length, (index) {
                return _buildItemRow(index);
              }),
              const SizedBox(height: AppConstants.spacingM),
              OutlinedButton.icon(
                onPressed: _addItemRow,
                icon: Icon(
                  Icons.add,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
                label: Text(
                  'Add Item',
                  style: TextStyle(
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: BorderSide(
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildItemRow(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedItemId = _selectedItems[index]['itemId'] as String?;
    CatalogItemModel? selectedItem;
    if (selectedItemId != null) {
      selectedItem = _ictController.catalogItems.firstWhereOrNull(
        (item) => item.id == selectedItemId,
      );
    }

    // Filter items based on search query
    final searchQuery = _searchControllers[index].text.toLowerCase();
    final availableItems = _ictController.catalogItems.where((item) {
      // Check if item is already selected in another row
      final isSelectedElsewhere = _selectedItems
          .asMap()
          .entries
          .where((e) => e.key != index)
          .any((e) => e.value['itemId'] == item.id);
      
      // Filter by search query
      final matchesSearch = searchQuery.isEmpty || 
          item.name.toLowerCase().contains(searchQuery) ||
          item.description.toLowerCase().contains(searchQuery);
      
      return !isSelectedElsewhere && matchesSearch;
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? AppColors.darkBorderDefined.withOpacity(0.5)
              : AppColors.border.withOpacity(0.3),
        ),
      ),
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
                      'Select Item',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDropdowns[index] = !_showDropdowns[index];
                          if (_showDropdowns[index]) {
                            _searchFocusNodes[index].requestFocus();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceLight : AppColors.surfaceElevation1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                                ? AppColors.darkBorderDefined
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedItem?.name ?? '-- Select Item --',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedItem != null
                                      ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  fontWeight: selectedItem != null ? FontWeight.w500 : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Icon(
                              _showDropdowns[index] ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Searchable dropdown
                    if (_showDropdowns[index])
                      GestureDetector(
                        onTap: () {}, // Prevent tap from propagating
                        child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                                ? AppColors.darkBorderDefined.withOpacity(0.5)
                                : AppColors.border.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Search field
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                controller: _searchControllers[index],
                                focusNode: _searchFocusNodes[index],
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search items...',
                                  hintStyle: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  suffixIcon: _searchControllers[index].text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            size: 18,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          ),
                                          onPressed: () {
                                            _searchControllers[index].clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: isDark ? AppColors.darkSurfaceLight : AppColors.surfaceElevation1,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark 
                                          ? AppColors.darkBorderDefined
                                          : AppColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark 
                                          ? AppColors.darkBorderDefined
                                          : AppColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                            // Scrollable list
                            Flexible(
                              child: availableItems.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        searchQuery.isEmpty
                                            ? 'No items available'
                                            : 'No items found',
                                        style: TextStyle(
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: availableItems.length,
                                      padding: EdgeInsets.zero,
                                      itemBuilder: (context, itemIndex) {
                                        final item = availableItems[itemIndex];
                                        return InkWell(
                                          onTap: () {
                                            _updateItem(index, item);
                                            _searchControllers[index].clear();
                                            setState(() {
                                              _showDropdowns[index] = false;
                                            });
                                            _searchFocusNodes[index].unfocus();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: isDark 
                                                      ? AppColors.darkBorderDefined.withOpacity(0.3)
                                                      : AppColors.border.withOpacity(0.2),
                                                  width: itemIndex < availableItems.length - 1 ? 1 : 0,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.name,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                          color: isDark 
                                                              ? AppColors.darkTextPrimary 
                                                              : AppColors.textPrimary,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (item.description.isNotEmpty) ...[
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          item.description,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isDark 
                                                                ? AppColors.darkTextSecondary 
                                                                : AppColors.textSecondary,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_selectedItems.length > 1)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline, 
                    color: AppColors.error,
                  ),
                  onPressed: () => _removeItemRow(index),
                ),
            ],
          ),
          if (selectedItem != null) ...[
            const SizedBox(height: AppConstants.spacingS),
            Text(
              selectedItem.description,
              style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

