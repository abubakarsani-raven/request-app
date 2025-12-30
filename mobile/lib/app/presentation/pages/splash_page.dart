import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              // Animated Logo
              RepaintBoundary(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
              size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
            ),
              const SizedBox(height: 40),
              // Animated Text
              RepaintBoundary(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: const Text(
              'Request Management',
              style: TextStyle(
                      fontSize: 28,
                fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
              ),
            ),
              const SizedBox(height: 48),
              // Modern Loading Indicator
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}

