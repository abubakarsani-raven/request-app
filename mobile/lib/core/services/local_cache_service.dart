import 'dart:convert';
import 'storage_service.dart';

/// Persistent cache for request lists and optional detail data.
/// Uses GetStorage; entries have a timestamp for TTL.
class LocalCacheService {
  static const Duration listCacheTTL = Duration(hours: 24);
  static const Duration detailCacheTTL = Duration(hours: 1);

  static const String _prefixList = 'cache_list_';
  static const String _prefixDetail = 'cache_detail_';
  static const String _suffixTs = '_ts';

  // List cache keys: vehicle|ict|store, my|all, pending
  static String listKey(String type, bool myRequests, bool pending) {
    return '${_prefixList}${type}_my${myRequests}_pending$pending';
  }

  /// Key for "approved by me" list (approval history).
  static String listKeyApprovedByMe(String type) {
    return '${_prefixList}${type}_approvedByMe';
  }

  static String detailKey(String type, String id) {
    return '${_prefixDetail}${type}_$id';
  }

  /// Write a request list (raw JSON list from API).
  static Future<void> writeRequestList(
    String key,
    List<dynamic> rawList,
  ) async {
    await StorageService.write(key, rawList);
    await StorageService.write('$key$_suffixTs', DateTime.now().toIso8601String());
  }

  /// Read request list and timestamp. Returns null if missing or expired.
  static CacheEntry<List<Map<String, dynamic>>>? readRequestList(
    String key, {
    Duration ttl = listCacheTTL,
  }) {
    final raw = StorageService.read<dynamic>(key);
    final tsStr = StorageService.read<String>('$key$_suffixTs');
    if (raw == null || tsStr == null) return null;
    List<Map<String, dynamic>> list;
    if (raw is List) {
      list = raw.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
    } else if (raw is String) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
      } catch (_) {
        return null;
      }
    } else {
      return null;
    }
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(tsStr);
    } catch (_) {
      return null;
    }
    if (DateTime.now().difference(timestamp) > ttl) return null;
    return CacheEntry(data: list, timestamp: timestamp);
  }

  /// Write a single request detail (raw JSON map from API).
  static Future<void> writeRequestDetail(String key, Map<String, dynamic> raw) async {
    await StorageService.write(key, raw);
    await StorageService.write('$key$_suffixTs', DateTime.now().toIso8601String());
  }

  /// Read request detail and timestamp. Returns null if missing or expired.
  static CacheEntry<Map<String, dynamic>>? readRequestDetail(
    String key, {
    Duration ttl = detailCacheTTL,
  }) {
    final raw = StorageService.read<dynamic>(key);
    final tsStr = StorageService.read<String>('$key$_suffixTs');
    if (raw == null || tsStr == null) return null;
    Map<String, dynamic> map;
    if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    } else if (raw is String) {
      try {
        map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        return null;
      }
    } else {
      return null;
    }
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(tsStr);
    } catch (_) {
      return null;
    }
    if (DateTime.now().difference(timestamp) > ttl) return null;
    return CacheEntry(data: map, timestamp: timestamp);
  }

  /// Remove a cache entry (e.g. on logout).
  static Future<void> remove(String key) async {
    await StorageService.remove(key);
    await StorageService.remove('$key$_suffixTs');
  }

  /// Clear all list cache entries (e.g. on logout). Call with known list keys if needed.
  static Future<void> clearListCache(List<String> keys) async {
    for (final key in keys) {
      await remove(key);
    }
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  CacheEntry({required this.data, required this.timestamp});
}
