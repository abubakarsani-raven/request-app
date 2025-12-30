import '../config/app_config.dart';

class AppConstants {
  // API Configuration
  // Use --dart-define=ENV=production for Railway backend
  // Use --dart-define=ENV=development for local backend
  static String get apiBaseUrl => AppConfig.apiBaseUrl;
  static String get wsBaseUrl => AppConfig.wsBaseUrl;
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String storageTokenKey = 'auth_token';
  static const String storageUserKey = 'user_data';
  static const String storageFcmTokenKey = 'fcm_token';
  
  // Location
  static const double defaultLatitude = 40.7128; // NYC default
  static const double defaultLongitude = -74.0060;
  static const double defaultZoom = 14.0;
  
  // Trip Tracking
  static const int locationUpdateInterval = 15; // seconds
  static const double geofenceRadius = 100; // meters
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Spacing - Updated for minimal flat design
  static const double spacingXS = 4.0;
  static const double spacingS = 12.0; // Updated from 8px
  static const double spacingM = 24.0; // Updated from 16px
  static const double spacingL = 24.0; // Updated from 16px
  static const double spacingXL = 32.0; // Updated from 24px
  static const double spacingXXL = 48.0; // Updated from 32px
  
  // Border Radius - Updated for minimal flat design
  static const double radiusS = 8.0; // Updated from 4px
  static const double radiusM = 12.0; // Updated from 8px
  static const double radiusL = 16.0; // Updated from 12px
  static const double radiusXL = 24.0; // Updated from 16px
}

