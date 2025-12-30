import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_request_controller.dart';
import '../../data/models/inventory_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

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

    return Column(
      children: [
        // Category Filter
        Obx(
          () => controller.categories.isNotEmpty
              ? Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
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
                            onSelected: (selected) {
                              controller.selectedCategory.value = '';
                              controller.loadInventoryItems();
                            },
                          ),
                        );
                      }
                      final category = controller.categories[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(right: AppConstants.spacingS),
                        child: FilterChip(
                          label: Text(category),
                          selected: controller.selectedCategory.value == category,
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
                return const Center(
                  child: Text('No inventory items available'),
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
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${item.category}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
                                  icon: const Icon(Icons.remove),
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
                                Text('${selectedItem['quantity']}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
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
                              icon: const Icon(Icons.add),
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
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontSize: 12),
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

