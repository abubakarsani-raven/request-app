import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final ApiService apiService;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  NotificationProvider({required this.apiService});

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.get(
        '/notifications',
        queryParameters: unreadOnly ? {'unreadOnly': 'true'} : null,
      );
      _notifications = (response.data as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await apiService.get('/notifications/unread-count');
      _unreadCount = response.data['unreadCount'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await apiService.put('/notifications/$notificationId/read', data: {});
      await loadNotifications();
      await loadUnreadCount();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}

