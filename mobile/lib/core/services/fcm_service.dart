import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';
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

  Future<void> registerToken(String userId) async {
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
      } catch (e) {
        print('❌ FCM: Failed to get token: $e');
        return;
      }
    }

    // Register token on backend
    if (_fcmToken != null) {
      await _updateTokenOnBackend(_fcmToken!);
    } else {
      print('⚠️ FCM: No token available to register');
    }
  }

  Future<void> _updateTokenOnBackend(String token) async {
    try {
      await _apiService.post(
        '/notifications/register-token',
        data: {'fcmToken': token},
      );
      print('✅ FCM: Token registered on backend');
    } catch (e) {
      print('❌ FCM: Error updating token on backend: $e');
      // Don't throw - allow retry later
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
