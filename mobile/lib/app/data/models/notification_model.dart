import 'request_model.dart';

enum NotificationType {
  requestSubmitted,
  approvalRequired,
  requestApproved,
  requestRejected,
  requestAssigned,
  requestFulfilled,
  requestCorrection,
  tripStarted,
  tripCompleted,
  vehicleAssigned,
  driverAssigned,
  other,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final NotificationType? type;
  final String? requestId;
  final RequestType? requestType;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.requestId,
    this.requestType,
  });

  factory NotificationModel.fromJson(dynamic json) {
    // Ensure json is a Map
    if (json is! Map) {
      throw FormatException('NotificationModel.fromJson: Expected Map, got ${json.runtimeType}');
    }
    
    final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(json);
    
    NotificationType? parseType(dynamic typeValue) {
      if (typeValue == null) return null;
      final typeStr = typeValue.toString().toUpperCase();
      switch (typeStr) {
        case 'REQUEST_SUBMITTED':
          return NotificationType.requestSubmitted;
        case 'APPROVAL_REQUIRED':
          return NotificationType.approvalRequired;
        case 'REQUEST_APPROVED':
          return NotificationType.requestApproved;
        case 'REQUEST_REJECTED':
          return NotificationType.requestRejected;
        case 'REQUEST_ASSIGNED':
          return NotificationType.requestAssigned;
        case 'REQUEST_FULFILLED':
          return NotificationType.requestFulfilled;
        case 'REQUEST_CORRECTION':
        case 'REQUEST_CORRECTED':
          return NotificationType.requestCorrection;
        case 'TRIP_STARTED':
          return NotificationType.tripStarted;
        case 'TRIP_COMPLETED':
          return NotificationType.tripCompleted;
        case 'VEHICLE_ASSIGNED':
          return NotificationType.vehicleAssigned;
        case 'DRIVER_ASSIGNED':
          return NotificationType.driverAssigned;
        default:
          return NotificationType.other;
      }
    }

    RequestType? parseRequestType(dynamic typeValue) {
      if (typeValue == null) return null;
      final typeStr = typeValue.toString().toUpperCase();
      switch (typeStr) {
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

    // Parse requestId - handle both string and ObjectId formats
    String? parsedRequestId;
    final requestIdValue = jsonMap['requestId'];
    if (requestIdValue != null) {
      if (requestIdValue is String) {
        parsedRequestId = requestIdValue;
      } else if (requestIdValue is Map) {
        parsedRequestId = requestIdValue['_id']?.toString() ?? requestIdValue['id']?.toString();
      } else {
        parsedRequestId = requestIdValue.toString();
      }
    }

    // Parse createdAt - handle both string and DateTime formats
    DateTime parsedCreatedAt;
    try {
      final createdAtValue = jsonMap['createdAt'];
      if (createdAtValue is String) {
        parsedCreatedAt = DateTime.parse(createdAtValue);
      } else if (createdAtValue is DateTime) {
        parsedCreatedAt = createdAtValue;
      } else {
        parsedCreatedAt = DateTime.now();
      }
    } catch (e) {
      print('⚠️ [NotificationModel] Error parsing createdAt: $e');
      parsedCreatedAt = DateTime.now();
    }

    // Parse id
    String parsedId = '';
    final idValue = jsonMap['_id'] ?? jsonMap['id'];
    if (idValue != null) {
      parsedId = idValue.toString();
    }

    // Parse isRead
    bool parsedIsRead = false;
    final isReadValue = jsonMap['isRead'];
    if (isReadValue is bool) {
      parsedIsRead = isReadValue;
    } else if (isReadValue != null) {
      parsedIsRead = isReadValue.toString().toLowerCase() == 'true';
    }

    return NotificationModel(
      id: parsedId,
      title: jsonMap['title']?.toString() ?? '',
      message: jsonMap['message']?.toString() ?? '',
      isRead: parsedIsRead,
      createdAt: parsedCreatedAt,
      type: parseType(jsonMap['type']),
      requestId: parsedRequestId,
      requestType: parseRequestType(jsonMap['requestType']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

