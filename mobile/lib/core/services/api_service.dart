import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_toast.dart';
import '../utils/app_logger.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  late dio.Dio _dio;
  bool _isRefreshing = false;

  /// Sanitize data to remove sensitive information before logging
  Map<String, dynamic> _sanitizeData(dynamic data) {
    if (data == null) return {};
    if (data is! Map) return {'data': '[non-map data]'};
    
    final sanitized = Map<String, dynamic>.from(data);
    // Remove sensitive fields
    final sensitiveKeys = ['password', 'access_token', 'refresh_token', 'token', 'authorization'];
    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '[REDACTED]';
      }
    }
    return sanitized;
  }

  @override
  void onInit() {
    super.onInit();
    _dio = dio.Dio(dio.BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(dio.InterceptorsWrapper(
      onRequest: (options, handler) async {
        AppLogger.apiRequest(
          options.method,
          '${options.baseUrl}${options.path}',
          options.data != null ? _sanitizeData(options.data) : null,
        );
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.apiResponse(
          response.statusCode ?? 0,
          response.requestOptions.method,
          response.requestOptions.path,
          response.data != null ? _sanitizeData(response.data) : null,
        );
        return handler.next(response);
      },
      onError: (error, handler) async {
        AppLogger.apiError(
          error.requestOptions.method,
          '${error.requestOptions.baseUrl}${error.requestOptions.path}',
          error.message ?? 'Unknown error',
          error.response?.statusCode,
        );
        if (error.response != null) {
          final sanitized = _sanitizeData(error.response?.data);
          AppLogger.debug('Response Data: $sanitized', 'API');
        } else {
          AppLogger.warning('No Response - Connection error: ${error.message}', 'API');
        }
        
        // Skip refresh logic for refresh endpoint itself to prevent infinite loop
        if (error.requestOptions.path == '/auth/refresh') {
          // Refresh failed, logout user
          StorageService.removeToken();
          StorageService.removeUser();
          CustomToast.error('Your session has expired. Please login again.', title: 'Session Expired');
          Get.offAllNamed('/login');
          return handler.next(error);
        }
        
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          // Try to refresh token
          _isRefreshing = true;
          final refreshed = await _refreshToken();
          _isRefreshing = false;
          
          if (refreshed) {
            // Retry the request
            final opts = error.requestOptions;
            final token = StorageService.getToken();
            if (token != null) {
              opts.headers['Authorization'] = 'Bearer $token';
            }
            try {
              final response = await _dio.request(
                opts.path,
                options: dio.Options(
                  method: opts.method,
                  headers: opts.headers,
                ),
                data: opts.data,
                queryParameters: opts.queryParameters,
              );
              return handler.resolve(response);
            } catch (retryError) {
              // Retry also failed, logout
              StorageService.removeToken();
              StorageService.removeUser();
              CustomToast.error('Your session has expired. Please login again.', title: 'Session Expired');
              Get.offAllNamed('/login');
              if (retryError is dio.DioException) {
                return handler.next(retryError);
              } else {
                return handler.next(error);
              }
            }
          } else {
            // Token refresh failed, logout user
            StorageService.removeToken();
            StorageService.removeUser();
            CustomToast.error('Your session has expired. Please login again.', title: 'Session Expired');
            Get.offAllNamed('/login');
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      // Create a new Dio instance without interceptors to avoid infinite loop
      final refreshDio = dio.Dio(dio.BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
        },
      ));
      
      // Get the current token and add it to the request
      final token = await StorageService.getToken();
      if (token == null) {
        print('❌ [Refresh] No token found');
        return false;
      }
      
      print('🔄 [Refresh] Attempting to refresh token');
      final response = await refreshDio.post(
        '/auth/refresh',
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final newToken = response.data['access_token'];
        if (newToken != null) {
          await StorageService.saveToken(newToken);
          AppLogger.info('Token refreshed successfully', 'Auth');
          return true;
        }
      }
      AppLogger.error('Invalid response: ${response.statusCode}', null, null, 'Auth');
    } catch (e, stackTrace) {
      AppLogger.error('Token refresh error', e, stackTrace, 'Auth');
    }
    return false;
  }

  Future<dio.Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<dio.Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<dio.Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<dio.Response> delete(String path) {
    return _dio.delete(path);
  }
}

