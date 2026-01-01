import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_request_controller.dart';
import '../../data/models/inventory_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/empty_state.dart';

class InventoryBrowser extends StatelessWidget {
  final Function(List<Map<String, dynamic>>) onItemsSelected;
  final List<Map<String, dynamic>> selectedItems;

  const InventoryBrowser({
    Key? key,
    required this.onItemsSelected,
    this.selectedItems = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoreRequestController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Category Filter
        Obx(
          () => controller.categories.isNotEmpty
              ? Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark 
                            ? AppColors.darkBorderDefined.withOpacity(0.5)
                            : AppColors.border.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppConstants.spacingS),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: controller.selectedCategory.value.isEmpty,
                            selectedColor: isDark 
                                ? AppColors.primaryLight.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.2),
                            checkmarkColor: isDark ? AppColors.primaryLight : AppColors.primary,
                            labelStyle: TextStyle(
                              color: controller.selectedCategory.value.isEmpty
                                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            ),
                            onSelected: (selected) {
                              controller.selectedCategory.value = '';
                              controller.loadInventoryItems();
                            },
                          ),
                        );
                      }
                      final category = controller.categories[index - 1];
                      final isSelected = controller.selectedCategory.value == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppConstants.spacingS),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: isDark 
                              ? AppColors.primaryLight.withOpacity(0.2)
                              : AppColors.primary.withOpacity(0.2),
                          checkmarkColor: isDark ? AppColors.primaryLight : AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                          onSelected: (selected) {
                            controller.selectedCategory.value = category;
                            controller.loadInventoryItems(category: category);
                          },
                        ),
                      );
                    },
                  ),
                )
              : const SizedBox(),
        ),
        // Inventory Items List
        Expanded(
          child: Obx(
            () {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.inventoryItems.isEmpty) {
                return EmptyState(
                  title: 'No inventory items available',
                  message: 'Try selecting a different category',
                  type: EmptyStateType.noData,
                  icon: Icons.inventory_2_outlined,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                itemCount: controller.inventoryItems.length,
                itemBuilder: (context, index) {
                  final item = controller.inventoryItems[index];
                  final isSelected = selectedItems.any(
                    (selected) => selected['itemId'] == item.id,
                  );
                  final selectedItem = selectedItems.firstWhere(
                    (selected) => selected['itemId'] == item.id,
                    orElse: () => {'itemId': item.id, 'quantity': 0},
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
                    color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark 
                            ? AppColors.darkBorderDefined.withOpacity(0.5)
                            : AppColors.border.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        item.name,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${item.category}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Available: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.isAvailable && item.quantity > 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.remove,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                  onPressed: () {
                                    final newItems = List<Map<String, dynamic>>.from(selectedItems);
                                    final itemIndex = newItems.indexWhere(
                                      (selected) => selected['itemId'] == item.id,
                                    );
                                    if (itemIndex != -1) {
                                      if (newItems[itemIndex]['quantity'] > 1) {
                                        newItems[itemIndex]['quantity']--;
                                      } else {
                                        newItems.removeAt(itemIndex);
                                      }
                                      onItemsSelected(newItems);
                                    }
                                  },
                                ),
                                Text(
                                  '${selectedItem['quantity']}',
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                  onPressed: () {
                                    if (selectedItem['quantity'] < item.quantity) {
                                      final newItems = List<Map<String, dynamic>>.from(selectedItems);
                                      final itemIndex = newItems.indexWhere(
                                        (selected) => selected['itemId'] == item.id,
                                      );
                                      if (itemIndex != -1) {
                                        newItems[itemIndex]['quantity']++;
                                      } else {
                                        newItems.add({
                                          'itemId': item.id,
                                          'quantity': 1,
                                        });
                                      }
                                      onItemsSelected(newItems);
                                    }
                                  },
                                ),
                              ],
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.add,
                                color: item.isAvailable && item.quantity > 0
                                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                    : (isDark ? AppColors.darkTextDisabled : AppColors.textDisabled),
                              ),
                              onPressed: item.isAvailable && item.quantity > 0
                                  ? () {
                                      final newItems = List<Map<String, dynamic>>.from(selectedItems);
                                      newItems.add({
                                        'itemId': item.id,
                                        'quantity': 1,
                                      });
                                      onItemsSelected(newItems);
                                    }
                                  : null,
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Selected Items Summary
        if (selectedItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: isDark 
                      ? AppColors.darkBorderDefined.withOpacity(0.5)
                      : AppColors.border.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Items: ${selectedItems.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...selectedItems.map((item) {
                  final inventoryItem = controller.inventoryItems.firstWhere(
                    (i) => i.id == item['itemId'],
                    orElse: () => InventoryItemModel(
                      id: '',
                      name: 'Unknown',
                      description: '',
                      category: '',
                      quantity: 0,
                      isAvailable: false,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${inventoryItem.name}: ${item['quantity']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

