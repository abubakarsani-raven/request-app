class AppConfig {
  /// Environment: 'production' (Railway) or 'development' (local backend).
  /// Run with dev: flutter run --dart-define=ENV=development
  /// On a physical device, set API_BASE_URL: flutter run --dart-define=ENV=development --dart-define=API_BASE_URL=http://YOUR_IP:4000
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'production');

  /// Override API base URL at build time (for physical device or custom backend).
  /// Example: --dart-define=API_BASE_URL=http://192.168.1.100:4000
  static const String apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) return apiBaseUrlOverride;
    switch (environment) {
      case 'development':
        return 'http://localhost:4000';
      case 'production':
        return 'https://request-app-production.up.railway.app';
      default:
        return 'https://request-app-production.up.railway.app';
    }
  }

  static String get wsBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) {
      final base = apiBaseUrlOverride.replaceFirst(RegExp(r'/api$'), '');
      if (base.startsWith('https://')) return 'wss://${base.substring(8)}';
      if (base.startsWith('http://')) return 'ws://${base.substring(7)}';
      return base;
    }
    switch (environment) {
      case 'development':
        return 'ws://localhost:4000';
      case 'production':
        return 'wss://request-app-production.up.railway.app';
      default:
        return 'wss://request-app-production.up.railway.app';
    }
  }

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}
