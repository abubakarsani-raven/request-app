import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('🔐 ========== LOGIN ATTEMPT ==========');
    print('🔐 Email: $email');
    print('🔐 API URL: ${AppConstants.apiBaseUrl}');
    print('🔐 Endpoint: ${AppConstants.apiBaseUrl}/auth/login');
    
    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      print('✅ Login response received');
      print('✅ Status Code: ${response.statusCode}');
      print('✅ Response Data: ${response.data}');
      
      // Accept both 200 (OK) and 201 (Created) as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token'];
        final user = UserModel.fromJson(data['user']);

        // Save token and user
        await StorageService.saveToken(token);
        await StorageService.saveUser(user.toJson());

        print('✅ Login successful for: ${user.email}');
        print('🔐 ========== LOGIN SUCCESS ==========');

        return {
          'success': true,
          'user': user,
          'token': token,
        };
      }
      
      print('❌ Login failed - Status: ${response.statusCode}');
      print('❌ Response: ${response.data}');
      print('🔐 ========== LOGIN FAILED ==========');
      
      // Extract error message from response
      String errorMessage = 'Login failed';
      if (response.data != null) {
        if (response.data is Map) {
          errorMessage = response.data['message'] ?? 
                        response.data['error'] ?? 
                        response.data['detail'] ?? 
                        'Invalid email or password';
        } else if (response.data is String) {
          errorMessage = response.data;
        }
      }
      
      // Add status code context for non-standard errors
      if (response.statusCode != 401 && response.statusCode != 403) {
        errorMessage = 'Login failed: $errorMessage';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e, stackTrace) {
      print('❌ ========== LOGIN EXCEPTION ==========');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace: $stackTrace');
      
      String errorMessage = 'An error occurred during login';
      
      // Handle DioException with response
      if (e is dio.DioException) {
        if (e.response != null) {
          final responseData = e.response?.data;
          if (responseData is Map) {
            errorMessage = responseData['message'] ?? 
                          responseData['error'] ?? 
                          responseData['detail'] ?? 
                          'Login failed';
          } else if (responseData is String) {
            errorMessage = responseData;
          } else if (e.response?.statusCode == 401) {
            errorMessage = 'Invalid email or password';
          } else if (e.response?.statusCode == 403) {
            errorMessage = 'Access denied. Please contact your administrator.';
          } else if (e.response?.statusCode == 404) {
            errorMessage = 'Server endpoint not found. Please contact support.';
          } else if (e.response?.statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          }
        } else if (e.type == dio.DioExceptionType.connectionTimeout ||
                   e.type == dio.DioExceptionType.receiveTimeout ||
                   e.type == dio.DioExceptionType.sendTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection and try again.';
        } else if (e.type == dio.DioExceptionType.connectionError) {
          errorMessage = 'Cannot connect to server. Please check your internet connection and ensure the server is running.';
        } else {
          errorMessage = e.message ?? 'Network error occurred';
        }
      } else {
        // Handle other exceptions
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('404')) {
          errorMessage = 'Server not found. Please check if the server is running.';
        } else if (errorStr.contains('connection refused') || errorStr.contains('socketexception')) {
          errorMessage = 'Cannot connect to server. Please check your internet connection.';
        } else if (errorStr.contains('timeout')) {
          errorMessage = 'Connection timeout. Please try again.';
        } else if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
          errorMessage = 'Invalid email or password.';
        }
      }
      
      print('❌ Final Error Message: $errorMessage');
      print('🔐 ========== LOGIN EXCEPTION END ==========');
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  Future<void> logout() async {
    await StorageService.removeToken();
    await StorageService.removeUser();
  }

  Future<UserModel?> getProfile() async {
    try {
      final response = await _apiService.get('/users/profile');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
    } catch (e) {
      print('Error getting profile: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _apiService.get('/users/dashboard');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error getting dashboard: $e');
    }
    return {};
  }

  bool isAuthenticated() {
    return StorageService.getToken() != null;
  }
}

