class AppConfig {
  // Set to 'production' for Railway, 'development' for local
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'production');
  
  static String get apiBaseUrl {
    switch (environment) {
      case 'development':
        return 'http://192.168.1.185:4000';
      case 'production':
        return 'https://request-app-production.up.railway.app';
      default:
        return 'https://request-app-production.up.railway.app';
    }
  }
  
  static String get wsBaseUrl {
    switch (environment) {
      case 'development':
        return 'ws://192.168.1.185:4000';
      case 'production':
        return 'wss://request-app-production.up.railway.app';
      default:
        return 'wss://request-app-production.up.railway.app';
    }
  }
  
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}
