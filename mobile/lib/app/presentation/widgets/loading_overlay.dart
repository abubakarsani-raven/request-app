import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import 'loading_indicator.dart';

/// A comprehensive loading overlay component that can wrap any widget
/// and show a loading state with optional message and interaction blocking
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final bool blockInteraction;
  final Color? backgroundColor;
  final Color? spinnerColor;

  const LoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.message,
    this.blockInteraction = true,
    this.backgroundColor,
    this.spinnerColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: GestureDetector(
              onTap: blockInteraction ? () {} : null,
              child: Container(
                color: backgroundColor ??
                    (isDark
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.8)),
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            spinnerColor ??
                                (isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary),
                          ),
                        ),
                        if (message != null) ...[
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            message!,
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
          ),
      ],
    );
  }
}
