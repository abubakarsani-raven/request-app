import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../app/presentation/controllers/auth_controller.dart';

/// Middleware to protect routes that require authentication
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    
    // Allow access to splash and login pages without authentication
    if (route == '/' || route == '/login') {
      return null;
    }
    
    // Check if user is authenticated
    if (!authController.isAuthenticated.value) {
      // Redirect to login if not authenticated
      return const RouteSettings(name: '/login');
    }
    
    // Allow access to protected routes
    return null;
  }
}
