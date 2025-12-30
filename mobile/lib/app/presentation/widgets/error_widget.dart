import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/responsive.dart';
import 'custom_button.dart';

enum ErrorType {
  network,
  server,
  unknown,
  permission,
}

class AppErrorWidget extends StatelessWidget {
  final String title;
  final String? message;
  final ErrorType? type;
  final VoidCallback? onRetry;
  final Widget? customAction;

  const AppErrorWidget({
    Key? key,
    required this.title,
    this.message,
    this.type,
    this.onRetry,
    this.customAction,
  }) : super(key: key);

  static IconData _getErrorIcon(ErrorType? type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.server:
        return AppIcons.error;
      case ErrorType.permission:
        return AppIcons.lock;
      default:
        return AppIcons.error;
    }
  }

  static String _getDefaultMessage(ErrorType? type) {
    switch (type) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.server:
        return 'Something went wrong on our end. Please try again later.';
      case ErrorType.permission:
        return 'You don\'t have permission to perform this action.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);
    final isDark = theme.brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.darkStatusRejected : AppColors.error;
    
    return Center(
      child: Padding(
        padding: responsive.getScreenPadding(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(type),
              size: 64 * responsive.fontSizeMultiplier,
              color: errorColor,
            ),
            SizedBox(height: AppConstants.spacingM),
            Text(
              title,
              style: AppTextStyles.h5.copyWith(
                color: isDark 
                    ? AppColors.darkTextPrimary 
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: AppConstants.spacingS),
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (type != null) ...[
              SizedBox(height: AppConstants.spacingS),
              Text(
                _getDefaultMessage(type),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null || customAction != null) ...[
              SizedBox(height: AppConstants.spacingL),
              customAction ?? CustomButton(
                text: 'Retry',
                icon: AppIcons.refresh,
                onPressed: onRetry,
                type: ButtonType.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
