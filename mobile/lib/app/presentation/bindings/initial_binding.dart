import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/notification_service.dart' as local_notification_service;
import '../../../core/services/fcm_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/request_service.dart';
import '../../data/services/ict_request_service.dart';
import '../../data/services/store_request_service.dart';
import '../../data/services/assignment_service.dart';
import '../../data/services/notification_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../controllers/trip_controller.dart';
import '../controllers/assignment_controller.dart';
import '../controllers/driver_controller.dart';
import '../controllers/notification_controller.dart';
import '../../../core/controllers/theme_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core Services
    Get.put(ApiService(), permanent: true);
    Get.put(WebSocketService(), permanent: true);
    Get.put(PermissionService(), permanent: true);
    Get.put(local_notification_service.LocalNotificationService(), permanent: true);
    Get.put(FCMService(), permanent: true);
    
    // Theme Controller (already initialized in main, just ensure it exists)
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(), permanent: true);
    }
    
    // Data Services
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => RequestService(), fenix: true);
    Get.lazyPut(() => ICTRequestService(), fenix: true);
    Get.lazyPut(() => StoreRequestService(), fenix: true);
    Get.lazyPut(() => AssignmentService(), fenix: true);
    Get.lazyPut(() => NotificationService(), fenix: true);
    
    // Controllers
    // Critical controllers: Initialize eagerly to avoid timing issues
    // These are accessed in dashboard and other key pages regardless of user permissions
    Get.put(AuthController(), permanent: false);
    Get.put(RequestController(), permanent: false);
    Get.put(ICTRequestController(), permanent: false);
    Get.put(StoreRequestController(), permanent: false);
    Get.put(NotificationController(), permanent: false);
    
    // Less critical controllers: Keep lazy initialization
    Get.lazyPut(() => TripController(), fenix: true);
    Get.lazyPut(() => AssignmentController(), fenix: true);
    Get.lazyPut(() => DriverController(), fenix: true);
  }
}

