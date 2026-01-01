import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final GetStorage _storage = GetStorage();
  // Secure storage for sensitive data (tokens)
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Token Management - Using secure storage
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
  
  static Future<void> removeToken() async {
    await _secureStorage.delete(key: 'auth_token');
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
  
  // FCM Token - Using secure storage
  static Future<void> saveFcmToken(String token) async {
    await _secureStorage.write(key: 'fcm_token', value: token);
  }
  
  static Future<String?> getFcmToken() async {
    return await _secureStorage.read(key: 'fcm_token');
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

