import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../data/models/user_model.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;
  final bool Function(UserModel user)? customCheck;

  const RoleGuard({
    Key? key,
    required this.child,
    this.allowedRoles = const [],
    this.customCheck,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.user.value;
      if (user == null) return const SizedBox.shrink();

      // Custom check takes precedence
      if (customCheck != null) {
        return customCheck!(user) ? child : const SizedBox.shrink();
      }

      // Check allowed roles
      if (allowedRoles.isNotEmpty) {
        final hasRole = user.roles.any((role) => allowedRoles.contains(role.toUpperCase()));
        return hasRole ? child : const SizedBox.shrink();
      }

      return child;
    });
  }
}

