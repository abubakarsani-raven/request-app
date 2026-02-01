import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:request_app/app/presentation/controllers/notification_controller.dart';
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
  Timer? _apnsRetryTimer;

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

      // Wait for APNS token on iOS before getting FCM token
      // Retry getting FCM token with exponential backoff
      int retryCount = 0;
      const maxRetries = 10; // Increased retries for iOS
      int delayMs = 500;
      
      while (retryCount < maxRetries && _fcmToken == null) {
        try {
          // On iOS, wait for APNS token to be available before getting FCM token
          if (GetPlatform.isIOS) {
            String? apnsToken;
            int apnsRetryCount = 0;
            const maxApnsRetries = 3;
            
            // Try to get APNS token with a few quick retries
            while (apnsRetryCount < maxApnsRetries && apnsToken == null) {
              try {
                apnsToken = await _firebaseMessaging.getAPNSToken();
                if (apnsToken != null) {
                  print('✅ FCM: APNS token available');
                  break;
                }
              } catch (e) {
                // APNS token might not be ready yet
              }
              
              if (apnsToken == null && apnsRetryCount < maxApnsRetries - 1) {
                await Future.delayed(Duration(milliseconds: 200));
                apnsRetryCount++;
              }
            }
            
            // If APNS token is still not available, wait a bit longer before trying FCM token
            if (apnsToken == null) {
              print('⚠️ FCM: APNS token not yet available, waiting ${delayMs}ms before retry...');
              await Future.delayed(Duration(milliseconds: delayMs));
              retryCount++;
              if (retryCount < maxRetries) {
                delayMs = (delayMs * 1.5).round(); // Slower exponential backoff
              }
              continue; // Skip FCM token request and retry APNS check
            }
          }
          
          // Get FCM token (APNS token should be available on iOS at this point)
          _fcmToken = await _firebaseMessaging.getToken();
          if (_fcmToken != null) {
            print('✅ FCM: Token obtained (${_fcmToken!.substring(0, 20)}...)');
            break;
          }
        } catch (e) {
          retryCount++;
          if (e.toString().contains('apns-token-not-set')) {
            print('⚠️ FCM: APNS token not set yet (attempt $retryCount/$maxRetries), retrying in ${delayMs}ms...');
            if (retryCount < maxRetries) {
              await Future.delayed(Duration(milliseconds: delayMs));
              delayMs = (delayMs * 1.5).round(); // Slower exponential backoff
            } else {
              print('❌ FCM: Failed to get token after $maxRetries attempts: $e');
              // Don't fail initialization, just log the error
              // Token will be retried later when APNS is ready
            }
          } else {
            print('❌ FCM: Error getting token: $e');
            // For other errors, don't retry
            break;
          }
        }
      }
      
      // If we still don't have a token, set up a listener to retry when APNS is ready
      if (_fcmToken == null && GetPlatform.isIOS) {
        print('⚠️ FCM: Token not available yet, will retry when APNS token is set');
        // Set up periodic check for APNS token availability
        _retryTokenWhenAPNSReady();
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM: Token refreshed');
        _fcmToken = newToken;
        // Cancel APNS retry timer if token is now available
        _apnsRetryTimer?.cancel();
        _apnsRetryTimer = null;
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
    print('📨 FCM: Received foreground message: ${message.messageId}');
    print('📨 FCM: Title: ${message.notification?.title}');
    print('📨 FCM: Body: ${message.notification?.body}');
    print('📨 FCM: Data: ${message.data}');
    
    // Show local notification when app is in foreground
    _localNotificationService.showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
    );

    // Add notification to in-app notification list
    try {
      // Get NotificationController if available
      if (Get.isRegistered<NotificationController>()) {
        final notificationController = Get.find<NotificationController>();
        
        // Parse notification data from FCM message
        final notificationId = message.data['notificationId']?.toString() ?? 
                               message.messageId ?? 
                               DateTime.now().millisecondsSinceEpoch.toString();
        
        final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Notification';
        final body = message.notification?.body ?? message.data['body']?.toString() ?? message.data['message']?.toString() ?? '';
        final requestId = message.data['requestId']?.toString();
        final requestTypeStr = message.data['requestType']?.toString();
        final typeStr = message.data['type']?.toString() ?? 'OTHER';
        
        // Create notification data map similar to WebSocket format
        final notificationData = {
          'notificationId': notificationId,
          'title': title,
          'message': body,
          'type': typeStr,
          'requestId': requestId,
          'requestType': requestTypeStr,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Use the same handler as WebSocket notifications
        notificationController.handleWebSocketNotification(notificationData);
        print('✅ FCM: Added notification to in-app list: $notificationId');
      } else {
        print('⚠️ FCM: NotificationController not registered yet');
      }
    } catch (e) {
      print('❌ FCM: Error adding notification to in-app list: $e');
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

  /// Retry getting FCM token when APNS token becomes available
  /// This is called when initialization fails to get token due to missing APNS token
  void _retryTokenWhenAPNSReady() {
    // Cancel any existing timer
    _apnsRetryTimer?.cancel();
    
    int attempt = 0;
    const maxAttempts = 20; // Check for up to 20 seconds (20 * 1 second intervals)
    
    _apnsRetryTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      attempt++;
      
      if (_fcmToken != null) {
        // Token is now available, cancel the timer
        timer.cancel();
        _apnsRetryTimer = null;
        print('✅ FCM: Token obtained via retry mechanism');
        return;
      }
      
      if (attempt >= maxAttempts) {
        // Stop retrying after max attempts
        timer.cancel();
        _apnsRetryTimer = null;
        print('⚠️ FCM: Stopped retrying token after $maxAttempts attempts');
        return;
      }
      
      try {
        // Check if APNS token is now available
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          print('✅ FCM: APNS token now available, attempting to get FCM token...');
          
          try {
            final token = await _firebaseMessaging.getToken();
            if (token != null) {
              _fcmToken = token;
              timer.cancel();
              _apnsRetryTimer = null;
              print('✅ FCM: Token obtained via retry (${token.substring(0, 20)}...)');
              
              // Try to register token if user is logged in
              _updateTokenOnBackend(token);
            }
          } catch (e) {
            // Still can't get token, continue retrying
            if (attempt % 5 == 0) {
              print('⚠️ FCM: Still waiting for FCM token (attempt $attempt/$maxAttempts)...');
            }
          }
        }
      } catch (e) {
        // APNS token still not available, continue waiting
        if (attempt % 5 == 0) {
          print('⚠️ FCM: Still waiting for APNS token (attempt $attempt/$maxAttempts)...');
        }
      }
    });
  }
  
  @override
  void onClose() {
    _apnsRetryTimer?.cancel();
    super.onClose();
  }
}
