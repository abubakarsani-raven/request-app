import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../firebase_options.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling background message: ${message.messageId}');
  // Handle background notification
}

class FCMService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = Get.find<ApiService>();
  final LocalNotificationService _localNotificationService = Get.find<LocalNotificationService>();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Completer<void>? _initializationCompleter;
  bool _isTokenRegistered = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initialize();
  }

  Future<void> initialize() async {
    // If already initializing, wait for that to complete
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }
    
    _initializationCompleter = Completer<void>();
    
    try {
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM: User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ FCM: User granted provisional notification permission');
      } else {
        print('❌ FCM: User declined notification permission');
        _isInitialized = true;
        _initializationCompleter!.complete();
        return;
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('✅ FCM: Token obtained (${_fcmToken!.substring(0, 20)}...)');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM: Token refreshed');
        _fcmToken = newToken;
        // Note: We don't have userId here, so we'll register on next login
        // The token refresh listener will try to register if we have a stored userId
        _updateTokenOnBackend(newToken);
      });

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
      
      _isInitialized = true;
      _initializationCompleter!.complete();
    } catch (e) {
      print('❌ FCM: Error initializing: $e');
      _isInitialized = true;
      _initializationCompleter!.completeError(e);
    }
  }

  /// Register FCM token with retry logic
  /// Returns true if registration was successful, false otherwise
  /// IMPORTANT: Token remains registered on backend even after logout
  Future<bool> registerToken(String userId) async {
    print('🔔 FCM: Starting token registration for user $userId');
    
    // Wait for initialization to complete if not already done
    if (!_isInitialized && _initializationCompleter != null) {
      try {
        await _initializationCompleter!.future;
      } catch (e) {
        print('⚠️ FCM: Initialization failed, attempting to get token anyway');
      }
    }
    
    // If still not initialized, try to initialize now
    if (!_isInitialized) {
      await initialize();
    }

    // Get token if we don't have one
    if (_fcmToken == null) {
      try {
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken == null) {
          print('❌ FCM: Failed to get token');
          return false;
        }
        print('✅ FCM: Token obtained (${_fcmToken!.substring(0, 20)}...)');
      } catch (e) {
        print('❌ FCM: Failed to get token: $e');
        return false;
      }
    }

    // Register token on backend with retry logic
    // This token will remain registered even after logout
    if (_fcmToken != null) {
      final success = await _updateTokenOnBackendWithRetry(_fcmToken!);
      if (success) {
        _isTokenRegistered = true;
        print('✅ FCM: Token registered on backend (will persist after logout)');
      } else {
        print('❌ FCM: Token registration failed after retries');
      }
      return success;
    } else {
      print('⚠️ FCM: No token available to register');
      return false;
    }
  }

  /// Update token on backend with exponential backoff retry
  /// Token persists in user document even after logout
  Future<bool> _updateTokenOnBackendWithRetry(String token, {int maxRetries = 3}) async {
    int attempt = 0;
    int delayMs = 500; // Start with 500ms delay
    
    while (attempt < maxRetries) {
      try {
        await _apiService.post(
          '/notifications/register-token',
          data: {'fcmToken': token},
        );
        print('✅ FCM: Token registered on backend (attempt ${attempt + 1})');
        return true;
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          print('❌ FCM: Error updating token on backend after $maxRetries attempts: $e');
          return false;
        }
        
        // Exponential backoff: 500ms, 1000ms, 2000ms
        delayMs = delayMs * 2;
        print('⚠️ FCM: Token registration failed (attempt $attempt/$maxRetries), retrying in ${delayMs}ms...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    
    return false;
  }

  /// Non-blocking version for token refresh (when we don't have userId)
  Future<void> _updateTokenOnBackend(String token) async {
    try {
      // Only update if we have an auth token (user is logged in)
      // Otherwise, token will be registered on next login
      final authToken = await StorageService.getToken();
      if (authToken != null) {
        await _apiService.post(
          '/notifications/register-token',
          data: {'fcmToken': token},
        );
        print('✅ FCM: Token updated on backend');
      } else {
        print('ℹ️ FCM: Token refreshed but user not logged in - will register on next login');
      }
    } catch (e) {
      print('❌ FCM: Error updating token on backend: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification when app is in foreground
    _localNotificationService.showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
    );

    // Handle data payload if needed
    if (message.data.isNotEmpty) {
      // Data payload available for custom handling
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to relevant screen based on notification data
    final data = message.data;
    if (data.containsKey('requestId') && data.containsKey('requestType')) {
      final requestId = data['requestId'];
      final requestType = data['requestType'];

      if (requestType == 'VEHICLE' || requestType == 'ICT' || requestType == 'STORE') {
        Get.toNamed('/requests/$requestId');
      }
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('❌ FCM: Error unsubscribing from topic $topic: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      print('❌ FCM: Error subscribing to topic $topic: $e');
    }
  }
}
