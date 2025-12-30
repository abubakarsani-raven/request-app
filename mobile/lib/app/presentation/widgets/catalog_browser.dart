import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ict_request_controller.dart';
import '../../data/models/catalog_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../core/animations/sheet_animations.dart';
import '../widgets/empty_state.dart';
import '../pages/ict_request_items_page.dart';

class CatalogBrowser extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onItemsSelected;
  final List<Map<String, dynamic>> selectedItems;

  const CatalogBrowser({
    Key? key,
    required this.onItemsSelected,
    this.selectedItems = const [],
  }) : super(key: key);

  @override
  State<CatalogBrowser> createState() => _CatalogBrowserState();
}

class _CatalogBrowserState extends State<CatalogBrowser> {
  List<Map<String, dynamic>> _cart = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = ''; // Local state for selected category

  @override
  void initState() {
    super.initState();
    _cart = List<Map<String, dynamic>>.from(widget.selectedItems);
    _searchController.addListener(_onSearchChanged);
    
    // Ensure controller is initialized before accessing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Get.isRegistered<ICTRequestController>()) {
        final controller = Get.find<ICTRequestController>();
        setState(() {
          _selectedCategory = controller.selectedCategory.value;
        });
        
        // Listen to controller changes to keep in sync
        ever(controller.selectedCategory, (category) {
          if (mounted) {
            setState(() {
              _selectedCategory = category;
            });
          }
        });
      }
    });
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(CatalogItemModel item) {
    setState(() {
      final existingIndex = _cart.indexWhere(
        (cartItem) => cartItem['itemId'] == item.id,
      );

      if (existingIndex != -1) {
        // Item already in cart, increase quantity
        _cart[existingIndex]['quantity'] = (_cart[existingIndex]['quantity'] as int) + 1;
      } else {
        // Add new item to cart
        _cart.add({
          'itemId': item.id,
          'quantity': 1,
        });
      }
    });

    widget.onItemsSelected(_cart);
    CustomToast.success('${item.name} added to request');
  }

  void _openCart() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ICTRequestItemsPage(
          selectedItems: _cart,
        ),
      ),
    );

    // If request was submitted successfully, clear the cart
    if (result == true) {
      setState(() {
        _cart = [];
      });
      widget.onItemsSelected(_cart);
    }
  }

  int _getCartItemCount() {
    return _cart.length;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered before accessing
    if (!Get.isRegistered<ICTRequestController>()) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final controller = Get.find<ICTRequestController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: AppConstants.spacingL,
                right: AppConstants.spacingL,
                bottom: AppConstants.spacingM,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark 
                        ? AppColors.darkBorderDefined.withOpacity(0.5)
                        : AppColors.border.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: TextStyle(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    AppIcons.search,
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            AppIcons.close,
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark 
                          ? AppColors.darkBorderDefined.withOpacity(0.5)
                          : AppColors.border.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark 
                          ? AppColors.darkBorderDefined.withOpacity(0.5)
                          : AppColors.border.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark 
                      ? AppColors.darkSurface 
                      : theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingM,
                  ),
                ),
              ),
            ),
            // Category Filter Button
            Obx(
              () {
                final categories = controller.categories;
                
                if (categories.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingM,
                    horizontal: AppConstants.spacingL,
                  ),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.darkSurface 
                        : theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark 
                            ? AppColors.darkBorderDefined.withOpacity(0.5)
                            : AppColors.border.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCategoryFilterBottomSheet(context, controller, categories),
                          icon: Icon(
                            Icons.filter_list_rounded,
                            size: 20,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          label: Text(
                            _selectedCategory.isEmpty ? 'All Categories' : _selectedCategory,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingM,
                              vertical: AppConstants.spacingM,
                            ),
                            side: BorderSide(
                              color: isDark 
                                  ? AppColors.darkBorderDefined
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      if (_selectedCategory.isNotEmpty) ...[
                        const SizedBox(width: AppConstants.spacingS),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = '';
                            });
                            controller.selectedCategory.value = '';
                            controller.loadCatalogItems();
                          },
                          icon: Icon(
                            Icons.clear,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          tooltip: 'Clear filter',
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            // Catalog Items List
            Expanded(
              child: Obx(
                () {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filter items by search query
                  final filteredItems = controller.catalogItems.where((item) {
                    if (_searchQuery.isEmpty) {
                      return true;
                    }
                    final query = _searchQuery.toLowerCase();
                    return item.name.toLowerCase().contains(query) ||
                        item.description.toLowerCase().contains(query) ||
                        item.category.toLowerCase().contains(query);
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return EmptyState(
                      title: _searchQuery.isNotEmpty
                          ? 'No items found'
                          : 'No items available',
                      message: _searchQuery.isNotEmpty
                          ? 'Try a different search term'
                          : 'Try selecting a different category',
                      type: _searchQuery.isNotEmpty
                          ? EmptyStateType.noResults
                          : EmptyStateType.noData,
                      icon: _searchQuery.isNotEmpty
                          ? AppIcons.search
                          : AppIcons.inventory,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isInCart = _cart.any(
                        (cartItem) => cartItem['itemId'] == item.id,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                        child: _buildItemCard(context, item, isInCart),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        // Floating Items Button
        if (_getCartItemCount() > 0)
          Positioned(
            bottom: AppConstants.spacingL,
            right: AppConstants.spacingL,
            child: FloatingActionButton.extended(
              onPressed: _openCart,
              backgroundColor: theme.colorScheme.primary,
              icon: Stack(
                children: [
                  Icon(
                    AppIcons.inventory,
                    color: theme.colorScheme.onPrimary,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${_getCartItemCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              label: Text(
                'Items (${_getCartItemCount()})',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCategoryFilterBottomSheet(
    BuildContext context,
    ICTRequestController controller,
    List<String> categories,
  ) {
    SheetHaptics.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StandardBottomSheet(
        title: 'Select Category',
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        child: Column(
          children: [
            // All Categories option
            _buildCategoryOption(
              context: context,
              label: 'All',
              icon: Icons.apps_rounded,
              isSelected: _selectedCategory.isEmpty,
              onTap: () {
                setState(() {
                  _selectedCategory = '';
                });
                controller.selectedCategory.value = '';
                controller.loadCatalogItems();
                Navigator.pop(context);
                SheetHaptics.selectionClick();
              },
            ),
            const Divider(height: 1),
            // Category options
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  
                  return Column(
                    children: [
                      _buildCategoryOption(
                        context: context,
                        label: category,
                        icon: _getCategoryIcon(category),
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                          controller.selectedCategory.value = category;
                          controller.loadCatalogItems(category: category);
                          Navigator.pop(context);
                          SheetHaptics.selectionClick();
                        },
                      ),
                      if (index < categories.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          color: isSelected
              ? (isDark 
                  ? AppColors.primaryLight.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1))
              : Colors.transparent,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.primaryLight : AppColors.primary)
                      : (isDark 
                          ? AppColors.darkSurfaceLight 
                          : AppColors.surfaceElevation1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? (isDark ? AppColors.darkSurface : Colors.white)
                      : (isDark 
                          ? AppColors.darkTextPrimary 
                          : AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isDark 
                        ? AppColors.darkTextPrimary 
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('printer') || lowerCategory.contains('print')) {
      return Icons.print_rounded;
    } else if (lowerCategory.contains('laptop') || lowerCategory.contains('computer')) {
      return Icons.laptop_mac_rounded;
    } else if (lowerCategory.contains('phone') || lowerCategory.contains('mobile')) {
      return Icons.phone_android_rounded;
    } else if (lowerCategory.contains('monitor') || lowerCategory.contains('screen') || lowerCategory.contains('display')) {
      return Icons.monitor_rounded;
    } else if (lowerCategory.contains('network') || lowerCategory.contains('router')) {
      return Icons.router_rounded;
    } else if (lowerCategory.contains('cable') || lowerCategory.contains('wire')) {
      return Icons.cable_rounded;
    } else if (lowerCategory.contains('keyboard') || lowerCategory.contains('mouse') || lowerCategory.contains('accessories')) {
      return Icons.mouse_rounded;
    } else if (lowerCategory.contains('toner') || lowerCategory.contains('cartridge')) {
      return Icons.auto_fix_high_rounded;
    } else if (lowerCategory.contains('storage') || lowerCategory.contains('hard drive')) {
      return Icons.storage_rounded;
    } else {
      return Icons.category_rounded;
    }
  }


  Widget _buildItemCard(
    BuildContext context,
    CatalogItemModel item,
    bool isInCart,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAvailable = item.isAvailable && item.quantity > 0;
    
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
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
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Description
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      item.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingS),
                  // Category and Availability in one row
                  Wrap(
                    spacing: AppConstants.spacingS,
                    runSpacing: AppConstants.spacingXS,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingS,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark 
                              ? AppColors.primaryLight 
                              : AppColors.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark 
                                ? AppColors.primaryLight 
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable
                                ? AppIcons.check
                                : AppIcons.cancel,
                            size: 14,
                            color: isAvailable
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              fontSize: 11,
                              color: isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right side - Add to Cart Button
            const SizedBox(width: AppConstants.spacingS),
            SizedBox(
              width: 90,
              child: OutlinedButton(
                onPressed: isAvailable
                    ? () => _addToCart(item)
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingS,
                    horizontal: AppConstants.spacingS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isInCart
                        ? AppColors.success
                        : (isAvailable 
                            ? theme.colorScheme.primary 
                            : (isDark 
                                ? AppColors.darkBorderDefined 
                                : AppColors.border)),
                    width: 1.5,
                  ),
                  backgroundColor: isInCart
                      ? AppColors.success.withOpacity(0.1)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInCart ? AppIcons.check : AppIcons.add,
                      size: AppIcons.sizeSmall,
                      color: isInCart
                          ? AppColors.success
                          : (isAvailable 
                              ? theme.colorScheme.primary 
                              : (isDark 
                                  ? AppColors.darkTextDisabled 
                                  : AppColors.textDisabled)),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        isInCart ? 'Added' : 'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isInCart
                              ? AppColors.success
                              : (isAvailable 
                                  ? theme.colorScheme.primary 
                                  : (isDark 
                                      ? AppColors.darkTextDisabled 
                                      : AppColors.textDisabled)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
