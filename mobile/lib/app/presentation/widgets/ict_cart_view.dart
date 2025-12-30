import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ict_request_controller.dart';
import '../../data/models/catalog_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../../../core/widgets/custom_toast.dart';

class ICTCartView extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) onCartUpdated;
  final Function(String? notes) onSubmit;

  const ICTCartView({
    Key? key,
    required this.cartItems,
    required this.onCartUpdated,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ICTCartView> createState() => _ICTCartViewState();
}

class _ICTCartViewState extends State<ICTCartView> {
  final _notesController = TextEditingController();

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }

    final updatedCart = List<Map<String, dynamic>>.from(widget.cartItems);
    updatedCart[index]['quantity'] = newQuantity;
    widget.onCartUpdated(updatedCart);
  }

  void _removeItem(int index) {
    final updatedCart = List<Map<String, dynamic>>.from(widget.cartItems);
    updatedCart.removeAt(index);
    widget.onCartUpdated(updatedCart);
    CustomToast.info('Item removed from cart');
  }

  int _getTotalItems() {
    return widget.cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ICTRequestController>();

    if (widget.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'No items selected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Add items from the catalog to create a request',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Request Items (${widget.cartItems.length} ${widget.cartItems.length == 1 ? 'item' : 'items'})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Text(
                      'Total: ${_getTotalItems()} ${_getTotalItems() == 1 ? 'item' : 'items'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable Content with Items and Notes
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Request Items List
                      ...widget.cartItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cartItem = entry.value;
                        final itemId = cartItem['itemId'] as String;
                        final quantity = cartItem['quantity'] as int;

                        // Find the catalog item
                        final catalogItem = controller.catalogItems.firstWhereOrNull(
                          (item) => item.id == itemId,
                        );

                        if (catalogItem == null) {
                          return const SizedBox.shrink();
                        }

                        return _buildCartItemCard(
                          context,
                          catalogItem,
                          quantity,
                          index,
                        );
                      }),
                      // Notes Field
                      const SizedBox(height: AppConstants.spacingM),
                      CustomTextField(
                        label: 'Notes (Optional)',
                        controller: _notesController,
                        prefixIcon: Icons.note_outlined,
                        maxLines: 3,
                        hint: 'Add any additional notes or comments...',
                      ),
                      // Extra padding at bottom for keyboard
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                    ],
                  ),
                ),
              ),
              // Submit Button (Fixed at bottom)
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Obx(
                  () => CustomButton(
                    text: 'Submit Request',
                    icon: Icons.send,
                    onPressed: controller.isLoading.value
                        ? null
                        : () => widget.onSubmit(_notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim()),
                    isLoading: controller.isLoading.value,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CatalogItemModel item,
    int quantity,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item Name and Remove Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Category Badge (inline)
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _removeItem(index),
                  tooltip: 'Remove item',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            // Description (compact)
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Quantity Controls (compact)
            const SizedBox(height: AppConstants.spacingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => _updateQuantity(index, quantity - 1),
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.border.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$quantity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: item.isAvailable && item.quantity > quantity
                          ? () => _updateQuantity(index, quantity + 1)
                          : null,
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            // Availability Warning (compact)
            if (!item.isAvailable || item.quantity < quantity) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      !item.isAvailable
                          ? 'Item is currently unavailable'
                          : 'Requested quantity exceeds available stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

