import '../config/app_config.dart';

class ApiConstants {
  // API Base URL - automatically switches between production and development
  // Use --dart-define=ENV=production for Railway backend
  // Use --dart-define=ENV=development for local backend
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String profileEndpoint = '/users/profile';
  static const String dashboardEndpoint = '/users/dashboard';
  
  // Vehicle endpoints
  static const String vehicleRequests = '/vehicles/requests';
  static const String vehicles = '/vehicles/vehicles';
  static const String drivers = '/vehicles/drivers';
  
  // ICT endpoints
  static const String ictRequests = '/ict/requests';
  static const String ictItems = '/ict/items';
  
  // Store endpoints
  static const String storeRequests = '/store/requests';
  static const String storeItems = '/store/items';
  
  // Notifications
  static const String notifications = '/notifications';
  static const String registerToken = '/notifications/register-token';
}

