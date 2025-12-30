import 'package:get_storage/get_storage.dart';

class StorageService {
  static final GetStorage _storage = GetStorage();
  
  // Token Management
  static Future<void> saveToken(String token) async {
    await _storage.write('auth_token', token);
  }
  
  static String? getToken() {
    return _storage.read('auth_token');
  }
  
  static Future<void> removeToken() async {
    await _storage.remove('auth_token');
  }
  
  // User Data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write('user_data', user);
  }
  
  static Map<String, dynamic>? getUser() {
    return _storage.read('user_data');
  }
  
  static Future<void> removeUser() async {
    await _storage.remove('user_data');
  }
  
  // FCM Token
  static Future<void> saveFcmToken(String token) async {
    await _storage.write('fcm_token', token);
  }
  
  static String? getFcmToken() {
    return _storage.read('fcm_token');
  }
  
  // Generic Methods
  static Future<void> write(String key, dynamic value) async {
    await _storage.write(key, value);
  }
  
  static T? read<T>(String key) {
    return _storage.read<T>(key);
  }
  
  static Future<void> remove(String key) async {
    await _storage.remove(key);
  }
  
  static Future<void> clear() async {
    await _storage.erase();
  }
  
  // Demo Mode
  static Future<void> setDemoMode(bool enabled) async {
    await _storage.write('demo_mode_enabled', enabled);
  }
  
  static bool isDemoModeEnabled() {
    return _storage.read('demo_mode_enabled') ?? false;
  }
}

