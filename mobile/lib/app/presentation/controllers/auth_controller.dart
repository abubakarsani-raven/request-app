import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isAuthenticated = false.obs;

  // Operation-specific loading flags
  final RxBool isLoggingIn = false.obs;
  final RxBool isLoadingProfile = false.obs;
  final RxBool isLoggingOut = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuth();
  }

  void checkAuth() {
    final token = StorageService.getToken();
    final userData = StorageService.getUser();
    
    if (token != null && userData != null) {
      user.value = UserModel.fromJson(userData);
      isAuthenticated.value = true;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoggingIn.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _authService.login(email, password);
      
      if (result['success'] == true) {
        user.value = result['user'] as UserModel;
        isAuthenticated.value = true;
        isLoggingIn.value = false;
        isLoading.value = false;
        
        // Register FCM token after successful login
        try {
          final fcmService = Get.find<FCMService>();
          final userId = user.value?.id;
          if (userId != null) {
            // Ensure FCM is initialized before registering
            if (!fcmService.isInitialized) {
              await fcmService.initialize();
            }
            await fcmService.registerToken(userId);
          }
        } catch (e) {
          print('⚠️ Auth: Error registering FCM token: $e');
          // Don't fail login if FCM registration fails
        }
        
        CustomToast.success('Login successful!');
        return true;
      } else {
        final errorMsg = result['message'] ?? 'Login failed';
        error.value = errorMsg;
        isLoggingIn.value = false;
        isLoading.value = false;
        
        // Show toast with user-friendly error message
        String toastMessage = _getUserFriendlyErrorMessage(errorMsg);
        CustomToast.error(toastMessage, title: 'Login Failed');
        
        return false;
      }
    } catch (e) {
      print('❌ Auth: Login exception: ${e.runtimeType} - $e');
      
      final errorMsg = e.toString();
      error.value = errorMsg;
      isLoggingIn.value = false;
      isLoading.value = false;
      
      // Show toast with user-friendly error message
      String toastMessage = _getUserFriendlyErrorMessage(errorMsg);
      CustomToast.error(toastMessage, title: 'Login Failed');
      
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user.value = null;
    isAuthenticated.value = false;
    Get.offAllNamed('/login');
  }

  Future<void> loadProfile() async {
    isLoadingProfile.value = true;
    try {
      final profile = await _authService.getProfile();
      if (profile != null) {
        user.value = profile;
        await StorageService.saveUser(profile.toJson());
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      isLoadingProfile.value = false;
    }
  }

  /// Converts technical error messages to user-friendly messages
  String _getUserFriendlyErrorMessage(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();
    
    // Connection errors
    if (lowerError.contains('connection refused') || 
        lowerError.contains('socketexception') ||
        lowerError.contains('failed host lookup')) {
      return 'Cannot connect to server. Please check your internet connection and try again.';
    }
    
    // Timeout errors
    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return 'Connection timeout. The server is taking too long to respond. Please try again.';
    }
    
    // 404 errors
    if (lowerError.contains('404') || lowerError.contains('not found')) {
      return 'Server not found. Please check if the server is running.';
    }
    
    // 401/Unauthorized errors
    if (lowerError.contains('401') || 
        lowerError.contains('unauthorized') ||
        lowerError.contains('invalid credentials') ||
        lowerError.contains('invalid email or password')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    
    // 500/Server errors
    if (lowerError.contains('500') || lowerError.contains('internal server error')) {
      return 'Server error occurred. Please try again later.';
    }
    
    // Network errors
    if (lowerError.contains('network') || lowerError.contains('no internet')) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    // Generic error - clean up technical details
    String cleaned = errorMessage
        .replaceAll('Exception: ', '')
        .replaceAll('DioException: ', '')
        .replaceAll('DioError: ', '')
        .trim();
    
    // If it's still too technical, provide a generic message
    if (cleaned.length > 100 || cleaned.contains('at ') || cleaned.contains('stack trace')) {
      return 'An error occurred during login. Please try again.';
    }
    
    return cleaned;
  }
}

