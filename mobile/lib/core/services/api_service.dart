import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_toast.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  late dio.Dio _dio;
  bool _isRefreshing = false;

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
        print('📤 [API Request] ${options.method} ${options.baseUrl}${options.path}');
        if (options.data != null) {
          print('📦 [Request Data] ${options.data}');
        }
        final token = StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ [API Response] ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}');
        if (response.data != null) {
          print('📥 [Response Data] ${response.data}');
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        print('❌ [API Error] ${error.requestOptions.method} ${error.requestOptions.baseUrl}${error.requestOptions.path}');
        print('❌ [Error Type] ${error.type}');
        print('❌ [Error Message] ${error.message}');
        if (error.response != null) {
          print('❌ [Status Code] ${error.response?.statusCode}');
          print('❌ [Response Data] ${error.response?.data}');
        } else {
          print('❌ [No Response] Connection error - ${error.message}');
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
      final token = StorageService.getToken();
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
          print('✅ [Refresh] Token refreshed successfully');
          return true;
        }
      }
      print('❌ [Refresh] Invalid response: ${response.statusCode}');
    } catch (e) {
      print('❌ [Refresh] Error: $e');
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

