import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_routes.dart';
import '../theme/app_colors.dart';
import '../../app/presentation/controllers/auth_controller.dart';

/// Centralized logout confirmation. On confirm, calls [AuthController.logout]
/// and navigates to [AppRoutes.login]. Use from More menu, Profile, and sidebar.
class LogoutConfirmation {
  LogoutConfirmation._();

  static Future<void> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      if (Get.isRegistered<AuthController>()) {
        await Get.find<AuthController>().logout();
      }
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
