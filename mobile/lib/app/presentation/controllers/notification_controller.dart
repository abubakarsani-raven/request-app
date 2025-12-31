import 'package:get/get.dart';
import 'dart:async';
import '../../data/services/notification_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/request_model.dart';
import '../../../core/services/notification_service.dart' as local_notification_service;
import '../../../core/animations/sheet_animations.dart';

class NotificationController extends GetxController {
  final NotificationService _notificationService = Get.find<NotificationService>();
  final local_notification_service.LocalNotificationService _localNotificationService = 
      Get.find<local_notification_service.LocalNotificationService>();
  Timer? _notificationIdTimer;
  int _notificationIdCounter = 0;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Operation-specific loading flags
  final RxBool isLoadingNotifications = false.obs;
  final RxBool isLoadingUnreadCount = false.obs;
  final RxBool isMarkingAsRead = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize local notification service
    _localNotificationService.initialize();
    // Load all notifications by default, not just unread
    loadNotifications(unreadOnly: false);
    loadUnreadCount();
    // Register this controller with WebSocket service for event handling
    _registerWithWebSocket();
  }

  void _registerWithWebSocket() {
    // The WebSocket service will automatically call our methods when events arrive
    // via Get.find when the controller is initialized
    // No explicit registration needed
  }

  @override
  void onClose() {
    _notificationIdTimer?.cancel();
    super.onClose();
  }

  /// Handle WebSocket notification event
  void handleWebSocketNotification(dynamic data) {
    try {
      SheetHaptics.lightImpact();
      
      // Parse notification data
      final notificationId = data['notificationId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final typeStr = data['type']?.toString() ?? '';
      final title = data['title']?.toString() ?? 'Notification';
      final message = data['message']?.toString() ?? '';
      final requestId = data['requestId']?.toString();
      final requestTypeStr = data['requestType']?.toString();
      
      DateTime createdAt;
      try {
        if (data['timestamp'] != null) {
          createdAt = DateTime.parse(data['timestamp'].toString());
        } else {
          createdAt = DateTime.now();
        }
      } catch (e) {
        createdAt = DateTime.now();
      }

      // Map notification type
      NotificationType? notificationType;
      try {
        notificationType = _mapNotificationType(typeStr);
      } catch (e) {
        notificationType = NotificationType.other;
      }

      // Map request type
      RequestType? requestType = _parseRequestType(requestTypeStr);

      // Create notification model
      final notification = NotificationModel(
        id: notificationId,
        title: title,
        message: message,
        isRead: false,
        createdAt: createdAt,
        type: notificationType,
        requestId: requestId,
        requestType: requestType,
      );

      // Add to beginning of list
      notifications.insert(0, notification);
      
      // Update unread count locally
      unreadCount.value = unreadCount.value + 1;

      // Sync unread count with server to ensure accuracy
      loadUnreadCount();

      // Show native notification
      _showNativeNotification(notification);
    } catch (e) {
      print('Error handling WebSocket notification: $e');
    }
  }

  /// Handle WebSocket workflow progress event
  void handleWorkflowProgress(dynamic data) {
    try {
      SheetHaptics.mediumImpact();
      
      final requestId = data['requestId']?.toString();
      final action = data['action']?.toString() ?? '';
      final message = data['message']?.toString() ?? 'Workflow progress updated';

      // Parse request type
      final requestTypeStr = data['requestType']?.toString();
      final requestType = _parseRequestType(requestTypeStr);

      // Create notification from workflow progress
      final notification = NotificationModel(
        id: 'progress_${requestId}_${DateTime.now().millisecondsSinceEpoch}',
        type: _mapNotificationTypeFromAction(action),
        title: _getTitleFromAction(action, requestTypeStr ?? ''),
        message: message,
        requestId: requestId,
        requestType: requestType,
        isRead: false,
        createdAt: DateTime.now(),
      );

      // Add to beginning of list
      notifications.insert(0, notification);
      
      // Update unread count locally
      unreadCount.value = unreadCount.value + 1;

      // Sync unread count with server to ensure accuracy
      loadUnreadCount();

      // Show native notification
      _showNativeNotification(notification);

      // Refresh notifications to get latest from server
      loadNotifications(unreadOnly: false);
    } catch (e) {
      print('Error handling workflow progress: $e');
    }
  }

  void _showNativeNotification(NotificationModel notification) {
    _notificationIdCounter++;
    _localNotificationService.showNotification(
      id: _notificationIdCounter,
      title: notification.title,
      body: notification.message,
    );
  }

  NotificationType _mapNotificationType(String type) {
    switch (type.toUpperCase()) {
      case 'REQUEST_SUBMITTED':
        return NotificationType.requestSubmitted;
      case 'APPROVAL_REQUIRED':
        return NotificationType.approvalRequired;
      case 'REQUEST_APPROVED':
        return NotificationType.requestApproved;
      case 'REQUEST_REJECTED':
        return NotificationType.requestRejected;
      case 'REQUEST_CORRECTED':
      case 'REQUEST_CORRECTION':
        return NotificationType.requestCorrection;
      case 'REQUEST_ASSIGNED':
        return NotificationType.requestAssigned;
      case 'REQUEST_FULFILLED':
        return NotificationType.requestFulfilled;
      default:
        return NotificationType.other;
    }
  }

  NotificationType _mapNotificationTypeFromAction(String action) {
    switch (action.toLowerCase()) {
      case 'approved':
        return NotificationType.requestApproved;
      case 'rejected':
        return NotificationType.requestRejected;
      case 'corrected':
        return NotificationType.requestCorrection;
      case 'assigned':
        return NotificationType.requestAssigned;
      case 'submitted':
        return NotificationType.requestSubmitted;
      default:
        return NotificationType.other;
    }
  }

  String _getTitleFromAction(String action, String requestType) {
    final type = requestType.isNotEmpty ? requestType : 'Request';
    switch (action.toLowerCase()) {
      case 'approved':
        return '$type Request Approved';
      case 'rejected':
        return '$type Request Rejected';
      case 'corrected':
        return 'Correction Required: $type Request';
      case 'assigned':
        return '$type Request Assigned';
      case 'submitted':
        return '$type Request Submitted';
      default:
        return '$type Request Updated';
    }
  }

  RequestType? _parseRequestType(String? requestTypeStr) {
    if (requestTypeStr == null) return null;
    switch (requestTypeStr.toUpperCase()) {
      case 'VEHICLE':
        return RequestType.vehicle;
      case 'ICT':
        return RequestType.ict;
      case 'STORE':
        return RequestType.store;
      default:
        return null;
    }
  }

  Future<void> loadNotifications({bool unreadOnly = false}) async {
    isLoadingNotifications.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _notificationService.getNotifications(unreadOnly: unreadOnly);
      notifications.value = result;
      // Reload unread count after loading notifications to keep it in sync
      await loadUnreadCount();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingNotifications.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadUnreadCount() async {
    isLoadingUnreadCount.value = true;
    try {
      final count = await _notificationService.getUnreadCount();
      print('📊 [NotificationController] Setting unreadCount to: $count');
      unreadCount.value = count;
      print('📊 [NotificationController] unreadCount.value is now: ${unreadCount.value}');
    } catch (e) {
      print('Error loading unread count: $e');
    } finally {
      isLoadingUnreadCount.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    isMarkingAsRead.value = true;
    try {
      final success = await _notificationService.markAsRead(notificationId);
      if (success) {
        // Reload all notifications (not just unread) to show updated read status
        await loadNotifications(unreadOnly: false);
        await loadUnreadCount();
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isMarkingAsRead.value = false;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      if (success) {
        // Reload all notifications (not just unread) to show updated read status
        await loadNotifications(unreadOnly: false);
        await loadUnreadCount();
      }
    } catch (e) {
      error.value = e.toString();
    }
  }
}

