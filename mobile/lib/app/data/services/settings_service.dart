import 'package:dio/dio.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';

class SettingsService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.apiTimeout,
    receiveTimeout: AppConstants.apiTimeout,
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  SettingsService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Get a setting value by key
  Future<dynamic> getSetting(String key) async {
    try {
      final response = await _dio.get('/settings/$key');
      return response.data['value'];
    } catch (e) {
      print('Error fetching setting $key: $e');
      return null;
    }
  }

  /// Get fuel consumption MPG setting (default: 14)
  Future<double> getFuelConsumptionMpg() async {
    try {
      final mpg = await getSetting('fuel_consumption_mpg');
      if (mpg != null) {
        return (mpg is num) ? mpg.toDouble() : 14.0;
      }
      return 14.0; // Default value
    } catch (e) {
      print('Error fetching fuel consumption MPG: $e');
      return 14.0; // Default value
    }
  }
}
