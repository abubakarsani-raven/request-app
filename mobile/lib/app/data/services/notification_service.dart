import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  Future<List<NotificationModel>> getNotifications({bool unreadOnly = false}) async {
    try {
      final response = await _apiService.get(
        '/notifications',
        queryParameters: unreadOnly ? {'unreadOnly': 'true'} : null,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data == null) {
          print('⚠️ [NotificationService] Response data is null');
          return [];
        }
        
        if (data is! List) {
          print('⚠️ [NotificationService] Response data is not a List: ${data.runtimeType}');
          return [];
        }
        
        final List<NotificationModel> notifications = [];
        for (int i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            if (item is Map<String, dynamic>) {
              final notification = NotificationModel.fromJson(item);
              notifications.add(notification);
            } else {
              print('⚠️ [NotificationService] Item at index $i is not a Map: ${item.runtimeType}');
            }
          } catch (e, stackTrace) {
            print('❌ [NotificationService] Error parsing notification at index $i: $e');
            print('❌ [NotificationService] Stack trace: $stackTrace');
            print('❌ [NotificationService] Item data: ${data[i]}');
          }
        }
        
        print('✅ [NotificationService] Successfully parsed ${notifications.length} notifications');
        return notifications;
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ [NotificationService] Error loading notifications: $e');
      print('❌ [NotificationService] Stack trace: $stackTrace');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread-count');
      print('📊 [NotificationService] getUnreadCount - statusCode: ${response.statusCode}');
      print('📊 [NotificationService] getUnreadCount - response.data: ${response.data}');
      print('📊 [NotificationService] getUnreadCount - response.data type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Handle direct number response (most common case)
        if (data is int) {
          print('✅ [NotificationService] Parsed as int: $data');
          return data;
        }
        
        // Handle num type (can be int or double)
        if (data is num) {
          final count = data.toInt();
          print('✅ [NotificationService] Parsed as num: $count (from $data)');
          return count;
        }
        
        // Handle double
        if (data is double) {
          final count = data.toInt();
          print('✅ [NotificationService] Parsed as double: $count (from $data)');
          return count;
        }
        
        // Handle string representation
        if (data is String) {
          final count = int.tryParse(data.trim()) ?? 0;
          print('✅ [NotificationService] Parsed as String: $count (from "$data")');
          return count;
        }
        
        // Handle Map with unreadCount key
        if (data is Map) {
          final count = data['unreadCount'];
          if (count != null) {
            if (count is int) {
              print('✅ [NotificationService] Parsed from Map (int): $count');
              return count;
            }
            if (count is num) {
              final intCount = count.toInt();
              print('✅ [NotificationService] Parsed from Map (num): $intCount (from $count)');
              return intCount;
            }
            if (count is String) {
              final intCount = int.tryParse(count.trim()) ?? 0;
              print('✅ [NotificationService] Parsed from Map (String): $intCount (from "$count")');
              return intCount;
            }
          }
        }
        
        print('⚠️ [NotificationService] Unexpected unread count format: $data (type: ${data.runtimeType})');
        return 0;
      }
      
      print('❌ [NotificationService] Bad status code: ${response.statusCode}');
      return 0;
    } catch (e, stackTrace) {
      print('❌ [NotificationService] Error loading unread count: $e');
      print('❌ [NotificationService] Stack trace: $stackTrace');
      return 0;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.put('/notifications/$notificationId/read', data: {});
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.put('/notifications/read-all', data: {});
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
}

