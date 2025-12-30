import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../data/models/user_model.dart';
import 'custom_button.dart';

class PermissionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool Function(UserModel user) permissionCheck;
  final Widget? fallback;

  const PermissionButton({
    this.backgroundColor,
    this.textColor,
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    required this.permissionCheck,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.user.value;

    if (user == null || !permissionCheck(user)) {
      return fallback ?? const SizedBox.shrink();
    }

    return CustomButton(
      text: text,
      onPressed: onPressed,
      type: type,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}

