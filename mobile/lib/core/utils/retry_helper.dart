import '../utils/app_logger.dart';

/// Helper utility for retrying failed operations with exponential backoff
class RetryHelper {
  /// Execute a function with retry logic
  /// 
  /// [fn] - The function to execute
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry in seconds (default: 1)
  /// [maxDelay] - Maximum delay between retries in seconds (default: 10)
  /// [tag] - Tag for logging (optional)
  static Future<T> retry<T>({
    required Future<T> Function() fn,
    int maxRetries = 3,
    int initialDelay = 1,
    int maxDelay = 10,
    String? tag,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt <= maxRetries) {
      try {
        return await fn();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempt++;

        if (attempt > maxRetries) {
          AppLogger.error(
            'Max retries ($maxRetries) reached${tag != null ? ' for $tag' : ''}',
            lastException,
            null,
            tag ?? 'Retry',
          );
          rethrow;
        }

        // Exponential backoff: 1s, 2s, 4s, etc., capped at maxDelay
        final delaySeconds = (initialDelay * (1 << (attempt - 1))).clamp(1, maxDelay);
        final delay = Duration(seconds: delaySeconds);

        AppLogger.warning(
          'Retry attempt $attempt/$maxRetries after ${delaySeconds}s${tag != null ? ' for $tag' : ''}',
          tag ?? 'Retry',
        );

        await Future.delayed(delay);
      }
    }

    throw lastException ?? Exception('Failed after $maxRetries attempts');
  }

  /// Retry with custom retry condition
  /// 
  /// Only retries if [shouldRetry] returns true for the exception
  static Future<T> retryIf<T>({
    required Future<T> Function() fn,
    required bool Function(dynamic error) shouldRetry,
    int maxRetries = 3,
    int initialDelay = 1,
    int maxDelay = 10,
    String? tag,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt <= maxRetries) {
      try {
        return await fn();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // Check if we should retry this error
        if (!shouldRetry(e)) {
          AppLogger.debug(
            'Error not retryable${tag != null ? ' for $tag' : ''}: $e',
            tag ?? 'Retry',
          );
          rethrow;
        }

        attempt++;

        if (attempt > maxRetries) {
          AppLogger.error(
            'Max retries ($maxRetries) reached${tag != null ? ' for $tag' : ''}',
            lastException,
            null,
            tag ?? 'Retry',
          );
          rethrow;
        }

        // Exponential backoff
        final delaySeconds = (initialDelay * (1 << (attempt - 1))).clamp(1, maxDelay);
        final delay = Duration(seconds: delaySeconds);

        AppLogger.warning(
          'Retry attempt $attempt/$maxRetries after ${delaySeconds}s${tag != null ? ' for $tag' : ''}',
          tag ?? 'Retry',
        );

        await Future.delayed(delay);
      }
    }

    throw lastException ?? Exception('Failed after $maxRetries attempts');
  }
}
