import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bottom_sheet_handle.dart';
import '../theme/app_colors.dart';

/// Standard sizes for different bottom sheet types
class BottomSheetSizes {
  static const double small = 0.35; // Quick actions
  static const double medium = 0.6; // Forms
  static const double large = 0.75; // Details
  static const double full = 0.95; // Full-screen modals
  
  static const double minSmall = 0.2;
  static const double minMedium = 0.4;
  static const double minLarge = 0.5;
  static const double minFull = 0.6;
  
  static const double maxSmall = 0.6;
  static const double maxMedium = 0.85;
  static const double maxLarge = 0.95;
  static const double maxFull = 0.98;
}

/// Base wrapper for all bottom sheets with consistent styling
class StandardBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showHandle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final ScrollController? scrollController;
  final Widget? footer;
  final Color? backgroundColor;

  const StandardBottomSheet({
    Key? key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.showCloseButton = true,
    this.onClose,
    this.initialChildSize = BottomSheetSizes.medium,
    this.minChildSize = BottomSheetSizes.minMedium,
    this.maxChildSize = BottomSheetSizes.maxMedium,
    this.scrollController,
    this.footer,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Clamp initialChildSize to ensure it's within valid bounds
    // This prevents DraggableScrollableSheet assertion errors
    final clampedInitialSize = initialChildSize.clamp(minChildSize, maxChildSize);
    
    return DraggableScrollableSheet(
      initialChildSize: clampedInitialSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (context, scrollController) {
        final effectiveScrollController = this.scrollController ?? scrollController;
        
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? (isDark ? AppColors.darkSurface : theme.colorScheme.surface),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle and Header
              if (showHandle || title != null || showCloseButton)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark 
                            ? AppColors.darkBorderDefined.withOpacity(0.5)
                            : AppColors.border.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (showHandle) const BottomSheetHandle(),
                      if (title != null || showCloseButton)
                        Row(
                          children: [
                            if (title != null)
                              Expanded(
                                child: Text(
                                  title!,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        letterSpacing: -0.5,
                                        height: 1.2,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      ),
                                ),
                              ),
                            if (showCloseButton)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 24),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                onPressed: onClose ?? () => Navigator.of(context).pop(),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: effectiveScrollController,
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              ),
              // Footer
              if (footer != null)
                Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: isDark 
                            ? AppColors.darkBorderDefined.withOpacity(0.5)
                            : AppColors.border.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: footer!,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet specifically for forms with submit/cancel actions
class FormBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final String submitText;
  final String? cancelText;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;
  final bool isSubmitEnabled;
  final double initialChildSize;
  final double? minChildSize;
  final double? maxChildSize;
  final ScrollController? scrollController;

  const FormBottomSheet({
    Key? key,
    required this.child,
    this.title,
    this.submitText = 'Submit',
    this.cancelText,
    this.onSubmit,
    this.onCancel,
    this.isLoading = false,
    this.isSubmitEnabled = true,
    this.initialChildSize = BottomSheetSizes.medium,
    this.minChildSize,
    this.maxChildSize,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Automatically determine min/max based on initial size if not provided
    double effectiveMinChildSize;
    double effectiveMaxChildSize;
    
    // Determine constraints based on initial size
    // Check in descending order to match the largest size first
    if (initialChildSize >= BottomSheetSizes.full) {
      // Full screen (0.95+) - use full size constraints
      effectiveMinChildSize = minChildSize ?? BottomSheetSizes.minFull;
      effectiveMaxChildSize = maxChildSize ?? BottomSheetSizes.maxFull;
    } else if (initialChildSize >= BottomSheetSizes.large) {
      // Large size (0.75+) - use large constraints
      effectiveMinChildSize = minChildSize ?? BottomSheetSizes.minLarge;
      effectiveMaxChildSize = maxChildSize ?? BottomSheetSizes.maxLarge;
    } else if (initialChildSize >= BottomSheetSizes.medium) {
      // Medium size (0.6+) - use medium constraints
      effectiveMinChildSize = minChildSize ?? BottomSheetSizes.minMedium;
      effectiveMaxChildSize = maxChildSize ?? BottomSheetSizes.maxMedium;
    } else {
      // Small size (< 0.6) - use small constraints
      effectiveMinChildSize = minChildSize ?? BottomSheetSizes.minSmall;
      effectiveMaxChildSize = maxChildSize ?? BottomSheetSizes.maxSmall;
    }
    
    // Ensure initialChildSize is within bounds (clamp it)
    // This prevents assertion errors in StandardBottomSheet
    final clampedInitialSize = initialChildSize.clamp(
      effectiveMinChildSize, 
      effectiveMaxChildSize
    );
    
    return StandardBottomSheet(
      title: title,
      initialChildSize: clampedInitialSize,
      minChildSize: effectiveMinChildSize,
      maxChildSize: effectiveMaxChildSize,
      scrollController: scrollController,
      footer: SafeArea(
        top: false,
        child: Row(
          children: [
            if (cancelText != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : (onCancel ?? () => Navigator.of(context).pop()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(cancelText!),
                ),
              ),
            if (cancelText != null) const SizedBox(width: 12),
            if (cancelText == null)
              Expanded(
                child: ElevatedButton(
                  onPressed: (isSubmitEnabled && !isLoading && onSubmit != null)
                      ? onSubmit
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(submitText),
                ),
              )
            else
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: (isSubmitEnabled && !isLoading && onSubmit != null)
                      ? onSubmit
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(submitText),
                ),
              ),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Bottom sheet for filter selections
class FilterBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final String applyText;
  final String? clearText;
  final VoidCallback? onApply;
  final VoidCallback? onClear;
  final int? activeFilterCount;
  final double initialChildSize;

  const FilterBottomSheet({
    Key? key,
    required this.child,
    this.title,
    this.applyText = 'Apply Filters',
    this.clearText,
    this.onApply,
    this.onClear,
    this.activeFilterCount,
    this.initialChildSize = BottomSheetSizes.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return StandardBottomSheet(
      title: title != null
          ? (activeFilterCount != null && activeFilterCount! > 0
              ? '$title ($activeFilterCount)'
              : title!)
          : null,
      initialChildSize: initialChildSize,
      minChildSize: BottomSheetSizes.minMedium,
      maxChildSize: BottomSheetSizes.maxMedium,
      footer: SafeArea(
        top: false,
        child: Row(
          children: [
            if (clearText != null && (activeFilterCount == null || activeFilterCount! > 0))
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isDark 
                          ? AppColors.darkBorderDefined
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    clearText!,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            if (clearText != null && (activeFilterCount == null || activeFilterCount! > 0))
              const SizedBox(width: 12),
            if (clearText == null)
              Expanded(
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(applyText),
                ),
              )
            else
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(applyText),
                ),
              ),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Bottom sheet for quick actions
class ActionBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final double initialChildSize;

  const ActionBottomSheet({
    Key? key,
    required this.child,
    this.title,
    this.initialChildSize = BottomSheetSizes.small,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StandardBottomSheet(
      title: title,
      initialChildSize: initialChildSize,
      minChildSize: BottomSheetSizes.minSmall,
      maxChildSize: BottomSheetSizes.maxSmall,
      child: child,
    );
  }
}

/// Bottom sheet for detail views with expandable content
class DetailBottomSheet extends StatelessWidget {
  final Widget collapsedContent;
  final Widget expandedContent;
  final String? title;
  final Widget? actionFooter;
  final double initialChildSize;

  const DetailBottomSheet({
    Key? key,
    required this.collapsedContent,
    required this.expandedContent,
    this.title,
    this.actionFooter,
    this.initialChildSize = BottomSheetSizes.large,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StandardBottomSheet(
      title: title,
      initialChildSize: initialChildSize,
      minChildSize: BottomSheetSizes.minLarge,
      maxChildSize: BottomSheetSizes.maxLarge,
      footer: actionFooter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          collapsedContent,
          const SizedBox(height: 16),
          expandedContent,
        ],
      ),
    );
  }
}

/// Helper function to show a bottom sheet with backdrop blur
Future<T?> showModernBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
    builder: (context) => builder(context),
  );
}

