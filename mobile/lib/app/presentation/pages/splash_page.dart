import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<AuthController>()) Get.forceAppUpdate();
      });
      return _buildSplashBody(context);
    }
    final authController = Get.find<AuthController>();

    // Check authentication immediately (no artificial delay)
    // checkAuth is async, so we handle it in a post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await authController.checkAuth();
      
      // Small delay to show splash animation (minimum 500ms for UX)
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (authController.isAuthenticated.value) {
        authController.loadProfile();
        // Route to role-specific dashboard
        final user = authController.user.value;
        if (user != null) {
          if (Get.isRegistered<PermissionService>()) {
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
          Get.offAllNamed('/dashboard');
        }
      } else {
        Get.offAllNamed('/login');
      }
    });

    return _buildSplashBody(context);
  }

  static Widget _buildSplashBody(BuildContext context) {
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
                    padding: EdgeInsets.all(AppConstants.spacingXL - 2),
                    decoration: BoxDecoration(
                      color: AppColors.textOnPrimary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.directions_car_rounded,
                      size: 80,
                      color: AppColors.textOnPrimary,
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
                  child: Text(
                    'Request Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
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
                  color: AppColors.textOnPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.spacingS),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
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

