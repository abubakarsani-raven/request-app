/// Centralized route constants to avoid hardcoded strings throughout the app
class AppRoutes {
  // Root routes
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String driverDashboard = '/driver/dashboard';
  
  // Request routes
  static const String requests = '/requests';
  static const String myRequests = '/requests/my';
  static const String pendingRequests = '/requests/pending';
  static String requestDetail(String id) => '/requests/$id';
  
  // Trip routes
  static String tripTracking(String id) => '/trip/$id';
  
  // Create request routes
  static const String createRequest = '/create-request';
  static String createRequestWithType(String type) => '/create-request?type=$type';
  
  // ICT routes
  static String ictFulfillment(String id) => '/ict/fulfill/$id';
  static const String ictRequestHistory = '/requests/ict/history';
  
  // Store routes
  static String storeRequestDetail(String id) => '/store/requests/$id';
  static String storeFulfillment(String id) => '/store/fulfill/$id';
  static const String storeRequestHistory = '/requests/store/history';
  
  // Transport routes
  static const String transportRequestHistory = '/requests/transport/history';
  
  // Assignment routes
  static String assignment(String id) => '/assign/$id';
  static const String assignVehicles = '/assign-vehicles';
  
  // Other routes
  static const String approvals = '/approvals';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String qrScanner = '/qr-scanner';
}
