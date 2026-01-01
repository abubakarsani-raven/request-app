import 'package:dio/dio.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';

class Office {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final bool isHeadOffice;

  Office({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.isHeadOffice,
  });

  factory Office.fromJson(Map<String, dynamic> json) {
    return Office(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] is num) 
          ? (json['latitude'] as num).toDouble() 
          : double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      description: json['description']?.toString(),
      isHeadOffice: json['isHeadOffice'] == true,
    );
  }
}

class OfficeService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.apiTimeout,
    receiveTimeout: AppConstants.apiTimeout,
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  Office? _cachedHeadOffice;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 30);

  OfficeService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Get all offices
  Future<List<Office>> getAllOffices() async {
    try {
      final response = await _dio.get('/offices');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => Office.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching offices: $e');
      return [];
    }
  }

  /// Get head office (cached for 30 minutes)
  Future<Office?> getHeadOffice({bool forceRefresh = false}) async {
    // Return cached value if still valid and not forcing refresh
    if (!forceRefresh && 
        _cachedHeadOffice != null && 
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedHeadOffice;
    }

    try {
      final offices = await getAllOffices();
      final headOffice = offices.firstWhere(
        (office) => office.isHeadOffice,
        orElse: () => offices.isNotEmpty ? offices.first : throw StateError('No offices found'),
      );
      
      // Cache the result
      _cachedHeadOffice = headOffice;
      _cacheTimestamp = DateTime.now();
      
      return headOffice;
    } catch (e) {
      print('Error fetching head office: $e');
      // Return cached value if available, even if expired
      if (_cachedHeadOffice != null) {
        return _cachedHeadOffice;
      }
      // Fallback to default Lagos coordinates if no cache
      return Office(
        id: 'default',
        name: 'Head Office',
        address: 'Lagos, Nigeria',
        latitude: 6.5244,
        longitude: 3.3792,
        isHeadOffice: true,
      );
    }
  }

  /// Get office by ID
  Future<Office?> getOfficeById(String id) async {
    try {
      final response = await _dio.get('/offices/$id');
      if (response.statusCode == 200) {
        return Office.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching office by ID: $e');
      return null;
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedHeadOffice = null;
    _cacheTimestamp = null;
  }
}
