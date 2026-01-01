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
  final VoidCallback? onFilterTap;

  const CatalogBrowser({
    Key? key,
    required this.onItemsSelected,
    this.selectedItems = const [],
    this.onFilterTap,
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
            // Active Filter Badge (if filter is active and not in AppBar)
            Obx(
              () {
                // Use controller's reactive variable, not local state
                final selectedCategory = controller.selectedCategory.value;
                final hasActiveFilter = selectedCategory.isNotEmpty;
                
                if (hasActiveFilter && widget.onFilterTap == null) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingL,
                      vertical: AppConstants.spacingS,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryLight.withOpacity(0.15)
                          : AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedCategory,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = '';
                            });
                            controller.selectedCategory.value = '';
                            controller.loadCatalogItems();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Catalog Items List
            Expanded(
              child: Obx(
                () {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Show error if catalog items failed to load
                  if (controller.error.isNotEmpty && controller.catalogItems.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: isDark ? AppColors.error : AppColors.error,
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                            Text(
                              'Failed to load catalog items',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingS),
                            Text(
                              controller.error.value,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                            ElevatedButton.icon(
                              onPressed: () => controller.loadCatalogItems(category: _selectedCategory.isEmpty ? null : _selectedCategory),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
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
                          : controller.catalogItems.isEmpty
                              ? 'Catalog items are not available. Please contact administrator.'
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

  void _showModernFilterBottomSheet(
    BuildContext context,
    ICTRequestController controller,
    List<String> categories,
  ) {
    SheetHaptics.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        title: 'Filter Items',
        applyText: 'Apply Filters',
        clearText: _selectedCategory.isNotEmpty ? 'Clear' : null,
        activeFilterCount: _selectedCategory.isNotEmpty ? 1 : 0,
        onApply: () => Navigator.pop(context),
        onClear: () {
          setState(() {
            _selectedCategory = '';
          });
          controller.selectedCategory.value = '';
          controller.loadCatalogItems();
          Navigator.pop(context);
          SheetHaptics.selectionClick();
        },
        initialChildSize: 0.6,
        child: _ModernFilterContent(
          categories: categories,
          selectedCategory: _selectedCategory,
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
            });
            controller.selectedCategory.value = category;
            controller.loadCatalogItems(category: category.isEmpty ? null : category);
            Navigator.pop(context);
            SheetHaptics.selectionClick();
          },
        ),
      ),
    );
  }

  void showFilterBottomSheet(BuildContext context) {
    if (!Get.isRegistered<ICTRequestController>()) return;
    
    final controller = Get.find<ICTRequestController>();
    final categories = controller.categories;
    
    if (categories.isEmpty) return;
    
    _showModernFilterBottomSheet(context, controller, categories);
  }

  Widget _buildItemCard(
    BuildContext context,
    CatalogItemModel item,
    bool isInCart,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAvailable = item.isAvailable && item.quantity > 0;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkSurface,
                    AppColors.darkSurfaceLight,
                  ]
                : [
                    theme.colorScheme.surface,
                    AppColors.surfaceElevation1,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark 
                ? AppColors.darkBorderDefined.withOpacity(0.3)
                : AppColors.border.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isAvailable && !isInCart ? () => _addToCart(item) : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Item Name
                        Text(
                          item.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Description
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark 
                                  ? AppColors.darkTextSecondary 
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Category and Availability in one row
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.primaryLight.withOpacity(0.15)
                                    : AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? AppColors.success.withOpacity(0.12)
                                    : AppColors.error.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isAvailable
                                      ? AppColors.success.withOpacity(0.25)
                                      : AppColors.error.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAvailable
                                        ? AppIcons.check
                                        : AppIcons.cancel,
                                    size: 12,
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right side - Add to Cart Button
                  const SizedBox(width: 10),
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: isInCart
                          ? AppColors.success
                          : isAvailable
                              ? AppColors.primary
                              : (isDark 
                                  ? AppColors.darkSurfaceLight 
                                  : AppColors.surfaceElevation1),
                      borderRadius: BorderRadius.circular(12),
                      border: (!isAvailable && !isInCart)
                          ? Border.all(
                              color: isDark 
                                  ? AppColors.darkBorderDefined 
                                  : AppColors.border,
                              width: 1,
                            )
                          : null,
                      boxShadow: (isAvailable || isInCart)
                          ? [
                              BoxShadow(
                                color: (isInCart ? AppColors.success : AppColors.primary)
                                    .withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isAvailable
                            ? () => _addToCart(item)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isInCart ? AppIcons.check : AppIcons.add,
                                size: 18,
                                color: isInCart || isAvailable
                                    ? Colors.white
                                    : (isDark 
                                        ? AppColors.darkTextDisabled 
                                        : AppColors.textDisabled),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  isInCart ? 'Added' : 'Add',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isInCart || isAvailable
                                        ? Colors.white
                                        : (isDark 
                                            ? AppColors.darkTextDisabled 
                                            : AppColors.textDisabled),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernFilterContent extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const _ModernFilterContent({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Category',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // All Categories option
        _ModernFilterOption(
          label: 'All Categories',
          icon: Icons.apps_rounded,
          isSelected: selectedCategory.isEmpty,
          onTap: () => onCategorySelected(''),
        ),
        const SizedBox(height: 8),
        // Category options
        ...categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ModernFilterOption(
              label: category,
              icon: _getCategoryIcon(category),
              isSelected: selectedCategory == category,
              onTap: () => onCategorySelected(category),
            ),
          );
        }),
      ],
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
}

class _ModernFilterOption extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernFilterOption({
    Key? key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_ModernFilterOption> createState() => _ModernFilterOptionState();
}

class _ModernFilterOptionState extends State<_ModernFilterOption> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primaryLight.withOpacity(0.1),
                    ],
                  )
                : null,
            color: widget.isSelected
                ? null
                : (isDark ? AppColors.darkSurfaceLight : AppColors.surfaceElevation1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary.withOpacity(0.4)
                  : (isDark 
                      ? AppColors.darkBorderDefined.withOpacity(0.3)
                      : AppColors.border.withOpacity(0.2)),
              width: widget.isSelected ? 2 : 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryLight,
                          ],
                        )
                      : null,
                  color: widget.isSelected
                      ? null
                      : (isDark 
                          ? AppColors.darkSurface 
                          : AppColors.surface),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: widget.isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: widget.isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  ),
                ),
              ),
              if (widget.isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}
