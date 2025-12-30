import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/presentation/controllers/auth_controller.dart';
import '../core/services/permission_service.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    // Check authentication after a brief delay
    Future.delayed(const Duration(seconds: 2), () {
      if (authController.isAuthenticated.value) {
        authController.loadProfile();
        // Route to role-specific dashboard
        final user = authController.user.value;
        if (user != null) {
          final permissionService = Get.find<PermissionService>();
          if (permissionService.isDriver(user)) {
            Get.offAllNamed('/driver/dashboard');
          } else {
            Get.offAllNamed('/dashboard');
          }
        } else {
          Get.offAllNamed('/dashboard');
        }
      } else {
        Get.offAllNamed('/login');
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Request Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

