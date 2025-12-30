import 'request_model.dart';
import 'ict_request_model.dart';

class StoreRequestModel {
  final String id;
  final String requesterId;
  final List<RequestItem> items;
  final RequestStatus status;
  final String? workflowStage;
  final bool priority;
  final String? qrCode;
  final List<Map<String, dynamic>> fulfillmentStatus;
  final bool directToSO;
  final List<Participant> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreRequestModel({
    required this.id,
    required this.requesterId,
    required this.items,
    required this.status,
    this.workflowStage,
    this.priority = false,
    this.qrCode,
    this.fulfillmentStatus = const [],
    this.directToSO = false,
    this.participants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreRequestModel.fromJson(Map<String, dynamic> json) {
    return StoreRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      requesterId: json['requesterId'] is Map
          ? (json['requesterId']?['_id']?.toString() ?? json['requesterId']?['id']?.toString() ?? '')
          : (json['requesterId']?.toString() ?? ''),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => RequestItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      status: _parseStatus(json['status']),
      workflowStage: json['workflowStage'],
      priority: json['priority'] ?? false,
      qrCode: json['qrCode'],
      fulfillmentStatus: (json['fulfillmentStatus'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [],
      directToSO: json['directToSO'] ?? false,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => Participant.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Check if this request is partially fulfilled
  /// Returns true if any item has fulfilledQuantity < requestedQuantity
  bool isPartiallyFulfilled() {
    if (status != RequestStatus.approved || workflowStage != 'FULFILLMENT') {
      return false;
    }
    
    return items.any((item) {
      return item.fulfilledQuantity > 0 && item.fulfilledQuantity < item.requestedQuantity;
    });
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return RequestStatus.pending;
      case 'approved':
        return RequestStatus.approved;
      case 'rejected':
        return RequestStatus.rejected;
      case 'corrected':
        return RequestStatus.corrected;
      case 'assigned':
        return RequestStatus.assigned;
      case 'fulfilled':
        return RequestStatus.fulfilled;
      case 'completed':
        return RequestStatus.completed;
      default:
        return RequestStatus.pending;
    }
  }
}

