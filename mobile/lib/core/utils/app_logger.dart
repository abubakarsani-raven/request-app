/// Simple logging utility to replace print statements
/// Provides log levels and optional filtering for production builds
class AppLogger {
  static const bool _enableDebug = true; // Set to false in production
  static const bool _enableInfo = true;
  static const bool _enableWarning = true;
  static const bool _enableError = true;

  /// Log debug messages (development only)
  static void debug(String message, [String? tag]) {
    if (_enableDebug) {
      final prefix = tag != null ? '🐛 [$tag]' : '🐛 [DEBUG]';
      print('$prefix $message');
    }
  }

  /// Log informational messages
  static void info(String message, [String? tag]) {
    if (_enableInfo) {
      final prefix = tag != null ? 'ℹ️ [$tag]' : 'ℹ️ [INFO]';
      print('$prefix $message');
    }
  }

  /// Log warning messages
  static void warning(String message, [String? tag]) {
    if (_enableWarning) {
      final prefix = tag != null ? '⚠️ [$tag]' : '⚠️ [WARN]';
      print('$prefix $message');
    }
  }

  /// Log error messages
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    if (_enableError) {
      final prefix = tag != null ? '❌ [$tag]' : '❌ [ERROR]';
      print('$prefix $message');
      if (error != null) {
        print('$prefix Error: $error');
      }
      if (stackTrace != null) {
        print('$prefix StackTrace: $stackTrace');
      }
    }
  }

  /// Log API requests (sanitized)
  static void apiRequest(String method, String path, [Map<String, dynamic>? sanitizedData]) {
    if (_enableDebug) {
      print('📤 [API Request] $method $path');
      if (sanitizedData != null) {
        print('📦 [Request Data] $sanitizedData');
      }
    }
  }

  /// Log API responses (sanitized)
  static void apiResponse(int statusCode, String method, String path, [Map<String, dynamic>? sanitizedData]) {
    if (_enableDebug) {
      print('✅ [API Response] $statusCode $method $path');
      if (sanitizedData != null) {
        print('📥 [Response Data] $sanitizedData');
      }
    }
  }

  /// Log API errors
  static void apiError(String method, String path, String error, [int? statusCode]) {
    if (_enableError) {
      print('❌ [API Error] $method $path');
      if (statusCode != null) {
        print('❌ [Status Code] $statusCode');
      }
      print('❌ [Error Message] $error');
    }
  }
}
