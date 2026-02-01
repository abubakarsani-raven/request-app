class AppConfig {
  // Set to 'production' for Railway, 'development' for local
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'production');

  /// Override API base URL at build time, e.g. --dart-define=API_BASE_URL=http://192.168.1.1:4000
  static const String apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) return apiBaseUrlOverride;
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
    if (apiBaseUrlOverride.isNotEmpty) {
      final base = apiBaseUrlOverride;
      if (base.startsWith('https://')) return 'wss://${base.substring(8)}';
      if (base.startsWith('http://')) return 'ws://${base.substring(7)}';
      return base;
    }
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
