import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final bool useTheme;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.color,
    this.useTheme = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = useTheme 
        ? (color ?? theme.colorScheme.primary)
        : (color ?? AppColors.primary);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.spacingM),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: useTheme 
                    ? theme.colorScheme.onSurface.withOpacity(0.6)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

