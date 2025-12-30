import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';

enum EmptyStateType {
  noData,
  noResults,
  networkError,
  permissionDenied,
}

class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final EmptyStateType? type;

  const EmptyState({
    Key? key,
    required this.title,
    this.message,
    IconData? icon,
    this.action,
    this.type,
  }) : icon = icon ?? Icons.inbox_outlined, super(key: key);

  IconData _getEffectiveIcon() {
    if (icon != Icons.inbox_outlined || type == null) {
      return icon;
    }
    switch (type!) {
      case EmptyStateType.noData:
        return Icons.inbox_outlined;
      case EmptyStateType.noResults:
        return Icons.search_off_rounded;
      case EmptyStateType.networkError:
        return Icons.wifi_off_rounded;
      case EmptyStateType.permissionDenied:
        return Icons.lock_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveIcon = _getEffectiveIcon();
    
    return Center(
      child: Padding(
        padding: responsive.getScreenPadding(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              effectiveIcon,
              size: 64 * responsive.fontSizeMultiplier,
              color: isDark 
                  ? AppColors.darkTextDisabled 
                  : AppColors.textDisabled,
            ),
            SizedBox(height: AppConstants.spacingM),
            Text(
              title,
              style: AppTextStyles.h5.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: AppConstants.spacingS),
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark 
                      ? AppColors.darkTextDisabled 
                      : AppColors.textDisabled,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: AppConstants.spacingL),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
