class ApiConstants {
  // IMPORTANT: For physical Android devices, replace 'localhost' with your computer's local IP address
  // Find your IP: macOS: ipconfig getifaddr en0 | Linux: hostname -I | Windows: ipconfig
  // Example: 'http://192.168.1.185:4000'
  static const String baseUrl = 'http://192.168.1.185:4000'; // Change localhost to your computer's IP for physical devices
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

