import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

/// A dialog wrapper that shows loading state during async operations
/// Prevents dialog dismissal and disables buttons during loading
class LoadingDialog {
  /// Shows a dialog with loading state during an async operation
  /// 
  /// [context] - Build context
  /// [dialog] - The dialog widget to show
  /// [operation] - The async operation to execute
  /// [loadingMessage] - Optional message to show during loading
  /// [onSuccess] - Optional callback when operation succeeds
  /// [onError] - Optional callback when operation fails
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget dialog,
    required Future<T> operation,
    String? loadingMessage,
    void Function(T result)? onSuccess,
    void Function(dynamic error)? onError,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isLoading = false;
    T? result;
    dynamic error;

    // Show initial dialog
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return WillPopScope(
            onWillPop: () async => !isLoading,
            child: Stack(
              children: [
                dialog,
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                              if (loadingMessage != null) ...[
                                const SizedBox(height: AppConstants.spacingM),
                                Text(
                                  loadingMessage,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      barrierDismissible: false,
    );

    // Execute operation
    try {
      isLoading = true;
      result = await operation;
      isLoading = false;
      Get.back(); // Close dialog
      
      if (onSuccess != null && result != null) {
        onSuccess(result);
      }
      
      return result;
    } catch (e) {
      isLoading = false;
      error = e;
      Get.back(); // Close dialog
      
      if (onError != null) {
        onError(error);
      }
      
      rethrow;
    }
  }

  /// Shows a simple loading dialog with message
  static void showSimple({
    required BuildContext context,
    required String message,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Hides the loading dialog
  static void hide() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
