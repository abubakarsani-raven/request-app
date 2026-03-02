import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/presentation/controllers/auth_controller.dart';
import '../app/presentation/widgets/custom_button.dart';
import '../app/presentation/widgets/app_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_icons.dart';
import '../core/controllers/theme_controller.dart';
import '../core/utils/logout_confirmation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>()) {
      return AppScaffold(
        title: 'Profile',
        showBackButton: true,
        body: const Center(child: Text('Loading...')),
      );
    }
    final authController = Get.find<AuthController>();

    return AppScaffold(
      title: 'Profile',
      showBackButton: true,
      body: Obx(
        () {
          final user = authController.user.value;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          if (!Get.isRegistered<ThemeController>()) {
            return _buildProfileContent(context, user, null);
          }
          final themeController = Get.find<ThemeController>();
          return _buildProfileContent(context, user, themeController);
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    dynamic user,
    ThemeController? themeController,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingXL,
      ),
      children: [
        // User card with avatar and clear hierarchy
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            side: BorderSide(
              color: (isDark ? AppColors.darkBorder : AppColors.border)
                  .withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusL),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(user.name),
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: AppTextStyles.h5.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (user.email != null && user.email.toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                user.email,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.spacingL),
                Container(
                  height: 1,
                  color: (isDark ? AppColors.darkBorder : AppColors.borderLight)
                      .withOpacity(0.6),
                ),
                SizedBox(height: AppConstants.spacingM),
                _profileRow(
                  context,
                  'Level',
                  '${user.level}',
                  colorScheme,
                ),
                SizedBox(height: AppConstants.spacingS),
                _profileRow(
                  context,
                  'Roles',
                  user.roles.join(', '),
                  colorScheme,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppConstants.spacingL),
        if (themeController != null) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              side: BorderSide(
                color: (isDark ? AppColors.darkBorder : AppColors.border)
                    .withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Obx(() {
              final isDarkMode = themeController.isDarkMode;
              return SwitchListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingXS,
                ),
                title: Text(
                  'Dark Mode',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    isDarkMode
                        ? 'Dark theme is enabled'
                        : 'Light theme is enabled',
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                value: isDarkMode,
                onChanged: (_) => themeController.toggleTheme(),
                secondary: Icon(
                  isDarkMode ? AppIcons.darkMode : AppIcons.lightMode,
                  color: isDarkMode
                      ? AppColors.warning
                      : colorScheme.primary,
                  size: AppIcons.sizeDefault,
                ),
              );
            }),
          ),
          SizedBox(height: AppConstants.spacingXL),
        ],
        CustomButton(
          text: 'Logout',
          icon: AppIcons.logout,
          backgroundColor: AppColors.error,
          textColor: AppColors.textOnPrimary,
          onPressed: () => LogoutConfirmation.show(context),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      if (s.length >= 2) return s.substring(0, 2).toUpperCase();
      return s.toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _profileRow(
    BuildContext context,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            '$label:',
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
