import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/controllers/theme_controller.dart';
import 'core/utils/orientation_service.dart';
import 'app/presentation/pages/splash_page.dart';
import 'app/presentation/pages/login_page.dart';
import 'app/presentation/pages/dashboard_page.dart';
import 'app/presentation/pages/request_list_page.dart';
import 'app/presentation/pages/request_detail_page.dart';
import 'app/presentation/pages/trip_tracking_page.dart';
import 'app/presentation/pages/create_request_page.dart';
import 'app/presentation/pages/ict_fulfillment_page.dart';
import 'app/presentation/pages/store_fulfillment_page.dart';
import 'app/presentation/pages/driver_dashboard_page.dart';
import 'app/presentation/pages/assignment_page.dart';
import 'app/presentation/pages/approval_queue_page.dart';
import 'app/presentation/pages/assign_vehicle_list_page.dart';
import 'app/presentation/pages/qr_scanner_page.dart';
import 'app/presentation/pages/ict_request_history_page.dart';
import 'app/presentation/pages/transport_request_history_page.dart';
import 'app/presentation/pages/store_request_history_page.dart';
import 'app/presentation/pages/store_request_detail_page.dart';
import 'app/presentation/bindings/initial_binding.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  // Initialize Firebase using FlutterFire CLI generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Continue even if Firebase fails (for development)
  }
  
  // Lock app to portrait orientation only
  await OrientationService.lockToPortrait();
  
  // Initialize theme controller early
  Get.put(ThemeController(), permanent: true);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get theme controller (already initialized in main)
    final themeController = Get.find<ThemeController>();
    
    return Obx(() => GetMaterialApp(
      title: 'Request Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode.value,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const SplashPage(),
        ),
        GetPage(
          name: '/login',
          page: () => LoginPage(),
        ),
        GetPage(
          name: '/dashboard',
          page: () => const DashboardPage(),
        ),
        GetPage(
          name: '/requests',
          page: () => const RequestListPage(),
        ),
        GetPage(
          name: '/requests/my',
          page: () => const RequestListPage(myRequests: true),
        ),
        GetPage(
          name: '/requests/pending',
          page: () => const RequestListPage(pending: true),
        ),
        GetPage(
          name: '/requests/:id',
          page: () {
            final id = Get.parameters['id'];
            if (id == null || id.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Request ID is required'),
                ),
              );
            }
            return RequestDetailPage(requestId: id);
          },
        ),
        GetPage(
          name: '/trip/:id',
          page: () {
            final id = Get.parameters['id'];
            if (id == null || id.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Trip ID is required'),
                ),
              );
            }
            return TripTrackingPage(requestId: id);
          },
        ),
        GetPage(
          name: '/create-request',
          page: () => CreateRequestPage(type: Get.parameters['type'] ?? 'vehicle'),
        ),
        GetPage(
          name: '/ict/fulfill/:id',
          page: () {
            final id = Get.parameters['id'];
            if (id == null || id.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Request ID is required'),
                ),
              );
            }
            return ICTFulfillmentPage(requestId: id);
          },
        ),
        GetPage(
          name: '/store/requests/:id',
          page: () {
            final id = Get.parameters['id'];
            if (id == null || id.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Request ID is required'),
                ),
              );
            }
            return StoreRequestDetailPage(requestId: id);
          },
        ),
        GetPage(
          name: '/store/fulfill/:id',
          page: () {
            final id = Get.parameters['id'];
            if (id == null || id.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Request ID is required'),
                ),
              );
            }
            return StoreFulfillmentPage(requestId: id);
          },
        ),
        GetPage(
          name: '/assign/:id',
          page: () {
            final id = Get.parameters['id'];
            if (id == null || id.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Request ID is required'),
                ),
              );
            }
            return AssignmentPage(requestId: id);
          },
        ),
        GetPage(
          name: '/driver/dashboard',
          page: () => DriverDashboardPage(),
        ),
        GetPage(
          name: '/approvals',
          page: () => ApprovalQueuePage(),
        ),
        GetPage(
          name: '/assign-vehicles',
          page: () => const AssignVehicleListPage(),
        ),
        GetPage(
          name: '/profile',
          page: () => const ProfileScreen(),
        ),
        GetPage(
          name: '/notifications',
          page: () => const NotificationsScreen(),
        ),
        GetPage(
          name: '/qr-scanner',
          page: () => const QRScannerPage(),
        ),
        GetPage(
          name: '/requests/ict/history',
          page: () => const ICTRequestHistoryPage(),
        ),
        GetPage(
          name: '/requests/transport/history',
          page: () => const TransportRequestHistoryPage(),
        ),
        GetPage(
          name: '/requests/store/history',
          page: () => const StoreRequestHistoryPage(),
        ),
      ],
    ));
  }
}
