import 'package:get/get.dart';
import '../utils/app_logger.dart';
import '../../app/data/services/request_service.dart';
import '../../app/data/services/ict_request_service.dart';
import '../../app/data/services/store_request_service.dart';
import '../../app/data/models/request_model.dart';
import '../../app/data/models/ict_request_model.dart';
import '../../app/data/models/store_request_model.dart';

/// Optimized request fetching service with best practices:
/// - Parallel loading
/// - Caching with TTL
/// - Retry logic with exponential backoff
/// - Error handling
class RequestFetchService extends GetxService {
  final RequestService _requestService = Get.find<RequestService>();
  final ICTRequestService _ictService = Get.find<ICTRequestService>();
  final StoreRequestService _storeService = Get.find<StoreRequestService>();

  // Cache with TTL (Time To Live)
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Fetch all request types in parallel
  Future<RequestFetchResult> fetchAllRequests({
    required bool myRequests,
    required bool pending,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'all_${myRequests}_$pending';
    
    // Check cache first (unless force refresh)
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      AppLogger.debug('Returning cached requests', 'RequestFetch');
      return _cache[cacheKey]!.data;
    }

    try {
      AppLogger.info('Fetching all requests in parallel (myRequests: $myRequests, pending: $pending)', 'RequestFetch');
      
      // Fetch all request types in parallel for 3x faster loading
      final results = await Future.wait([
        _fetchWithRetry(() => _requestService.getVehicleRequests(
          myRequests: myRequests,
          pending: pending,
        )),
        _fetchWithRetry(() => _ictService.getICTRequests(
          myRequests: myRequests,
          pending: pending,
        )),
        _fetchWithRetry(() => _storeService.getStoreRequests(
          myRequests: myRequests,
          pending: pending,
        )),
      ]);

      final result = RequestFetchResult(
        vehicleRequests: results[0] as List<VehicleRequestModel>,
        ictRequests: results[1] as List<ICTRequestModel>,
        storeRequests: results[2] as List<StoreRequestModel>,
      );

      AppLogger.info(
        'Fetched ${result.totalCount} total requests (${result.vehicleRequests.length} vehicle, ${result.ictRequests.length} ICT, ${result.storeRequests.length} store)',
        'RequestFetch',
      );

      // Cache the result
      _cache[cacheKey] = _CacheEntry(
        data: result,
        timestamp: DateTime.now(),
      );

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching all requests', e, stackTrace, 'RequestFetch');
      
      // Return cached data if available, even if expired (graceful degradation)
      if (_cache.containsKey(cacheKey)) {
        AppLogger.warning('Returning stale cache due to error', 'RequestFetch');
        return _cache[cacheKey]!.data;
      }
      
      rethrow;
    }
  }

  /// Fetch with exponential backoff retry
  Future<List<T>> _fetchWithRetry<T>(
    Future<List<T>> Function() fetchFn, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await fetchFn();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          AppLogger.error('Max retries ($maxRetries) reached for request fetch', e, null, 'RequestFetch');
          rethrow;
        }
        
        // Exponential backoff: 1s, 2s, 4s
        final delay = Duration(seconds: 1 << (attempt - 1));
        AppLogger.warning('Retry attempt $attempt after ${delay.inSeconds}s', 'RequestFetch');
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Failed to fetch after $maxRetries attempts');
  }

  /// Check if cache entry is still valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    
    final entry = _cache[key]!;
    final age = DateTime.now().difference(entry.timestamp);
    return age < _cacheTTL;
  }

  /// Clear cache for a specific key or all cache
  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
      AppLogger.debug('Cache cleared for key: $key', 'RequestFetch');
    } else {
      _cache.clear();
      AppLogger.debug('All cache cleared', 'RequestFetch');
    }
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    if (_cache.isEmpty) {
      return {'entries': 0, 'message': 'Cache is empty'};
    }
    
    final timestamps = _cache.values.map((e) => e.timestamp).toList();
    return {
      'entries': _cache.length,
      'keys': _cache.keys.toList(),
      'oldest': timestamps.reduce((a, b) => a.isBefore(b) ? a : b).toString(),
      'newest': timestamps.reduce((a, b) => a.isAfter(b) ? a : b).toString(),
    };
  }
}

/// Result container for all request types
class RequestFetchResult {
  final List<VehicleRequestModel> vehicleRequests;
  final List<ICTRequestModel> ictRequests;
  final List<StoreRequestModel> storeRequests;

  RequestFetchResult({
    required this.vehicleRequests,
    required this.ictRequests,
    required this.storeRequests,
  });

  int get totalCount => vehicleRequests.length + ictRequests.length + storeRequests.length;
  
  bool get isEmpty => vehicleRequests.isEmpty && ictRequests.isEmpty && storeRequests.isEmpty;
}

/// Cache entry with timestamp
class _CacheEntry {
  final RequestFetchResult data;
  final DateTime timestamp;

  _CacheEntry({
    required this.data,
    required this.timestamp,
  });
}
