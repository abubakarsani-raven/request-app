import 'request_model.dart';

class RequestItem {
  final String itemId;
  final String? itemName; // Item name if populated
  final int quantity;
  final int requestedQuantity;
  final int? approvedQuantity; // Quantity approved by DDICT
  final int fulfilledQuantity;
  final bool isAvailable;
  final int? availableQuantity; // Available quantity in stock (from populated itemId)

  RequestItem({
    required this.itemId,
    this.itemName,
    required this.quantity,
    required this.requestedQuantity,
    this.approvedQuantity,
    required this.fulfilledQuantity,
    required this.isAvailable,
    this.availableQuantity,
  });

  factory RequestItem.fromJson(Map<String, dynamic> json) {
    // Safe number parsing helper
    int safeIntParse(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }
    
    // Handle itemId which can be either a string or an object with _id and name
    String itemId = '';
    String? itemName;
    int? availableQty;
    try {
      final itemIdValue = json['itemId'];
      if (itemIdValue is Map) {
        itemId = itemIdValue['_id']?.toString() ?? 
                 itemIdValue['id']?.toString() ?? 
                 '';
        itemName = itemIdValue['name']?.toString();
        // Extract available quantity from populated itemId
        if (itemIdValue['quantity'] != null) {
          availableQty = safeIntParse(itemIdValue['quantity'], 0);
        }
      } else if (itemIdValue != null) {
        itemId = itemIdValue.toString();
      }
    } catch (e) {
      print('Error parsing itemId: $e');
      itemId = json['itemId']?.toString() ?? '';
    }
    
    // Safe nullable int parsing helper
    int? safeIntParseNullable(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }
    
    return RequestItem(
      itemId: itemId,
      itemName: itemName,
      quantity: safeIntParse(json['quantity'], 0),
      requestedQuantity: safeIntParse(json['requestedQuantity'], safeIntParse(json['quantity'], 0)),
      approvedQuantity: safeIntParseNullable(json['approvedQuantity']),
      fulfilledQuantity: safeIntParse(json['fulfilledQuantity'], 0),
      isAvailable: json['isAvailable'] is bool ? json['isAvailable'] : (json['isAvailable'] == true || json['isAvailable'] == 'true'),
      availableQuantity: availableQty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'quantity': quantity,
      'requestedQuantity': requestedQuantity,
      'fulfilledQuantity': fulfilledQuantity,
      'isAvailable': isAvailable,
    };
  }
}

class QuantityChange {
  final String itemId;
  final String? itemName;
  final int previousQuantity;
  final int newQuantity;
  final String changedBy;
  final DateTime changedAt;
  final String? reason;

  QuantityChange({
    required this.itemId,
    this.itemName,
    required this.previousQuantity,
    required this.newQuantity,
    required this.changedBy,
    required this.changedAt,
    this.reason,
  });

  factory QuantityChange.fromJson(Map<String, dynamic> json) {
    // Safe number parsing helper
    int safeIntParse(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }
    
    // Handle itemId which can be either a string or an object with _id
    String itemId = '';
    try {
      final itemIdValue = json['itemId'];
      if (itemIdValue is Map) {
        itemId = itemIdValue['_id']?.toString() ?? 
                 itemIdValue['id']?.toString() ?? 
                 '';
      } else if (itemIdValue != null) {
        itemId = itemIdValue.toString();
      }
    } catch (e) {
      print('Error parsing itemId in QuantityChange: $e');
      itemId = json['itemId']?.toString() ?? '';
    }
    
    // Handle changedBy which can be either a string or an object with _id
    String changedBy = '';
    try {
      final changedByValue = json['changedBy'];
      if (changedByValue is Map) {
        changedBy = changedByValue['_id']?.toString() ?? 
                    changedByValue['id']?.toString() ?? 
                    '';
      } else if (changedByValue != null) {
        changedBy = changedByValue.toString();
      }
    } catch (e) {
      print('Error parsing changedBy in QuantityChange: $e');
      changedBy = json['changedBy']?.toString() ?? '';
    }
    
    // Safe date parsing
    DateTime changedAt;
    try {
      changedAt = DateTime.parse(json['changedAt'] ?? DateTime.now().toIso8601String());
    } catch (e) {
      print('Error parsing changedAt: $e');
      changedAt = DateTime.now();
    }
    
    return QuantityChange(
      itemId: itemId,
      itemName: json['itemName']?.toString(),
      previousQuantity: safeIntParse(json['previousQuantity'], 0),
      newQuantity: safeIntParse(json['newQuantity'], 0),
      changedBy: changedBy,
      changedAt: changedAt,
      reason: json['reason']?.toString(),
    );
  }
}

class ICTRequestModel {
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now();
    }
    try {
      if (dateTime is String) {
        return DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        return dateTime;
      } else {
        return DateTime.now();
      }
    } catch (e) {
      print('Error parsing DateTime: $e, value: $dateTime');
      return DateTime.now();
    }
  }

  final String id;
  final String requesterId;
  final List<RequestItem> items;
  final RequestStatus status;
  final String? workflowStage;
  final List<WorkflowApproval> approvals;
  final String? comment;
  final bool priority;
  final String? qrCode;
  final List<Map<String, dynamic>> fulfillmentStatus;
  final List<QuantityChange> quantityChanges;
  final List<Participant> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  ICTRequestModel({
    required this.id,
    required this.requesterId,
    required this.items,
    required this.status,
    this.workflowStage,
    this.approvals = const [],
    this.comment,
    this.priority = false,
    this.qrCode,
    this.fulfillmentStatus = const [],
    this.quantityChanges = const [],
    this.participants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this request is partially fulfilled
  /// Returns true if any item has fulfilledQuantity < (approvedQuantity ?? requestedQuantity)
  bool isPartiallyFulfilled() {
    if (status != RequestStatus.approved || workflowStage != 'FULFILLMENT') {
      return false;
    }
    
    return items.any((item) {
      final targetQuantity = item.approvedQuantity ?? item.requestedQuantity;
      return item.fulfilledQuantity > 0 && item.fulfilledQuantity < targetQuantity;
    });
  }

  factory ICTRequestModel.fromJson(Map<String, dynamic> json) {
    // Safely parse items list
    List<RequestItem> items = [];
    try {
      if (json['items'] != null && json['items'] is List) {
        items = (json['items'] as List).map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return RequestItem.fromJson(item);
            }
            return null;
          } catch (e) {
            print('Error parsing request item: $e, item: $item');
            return null;
          }
        }).whereType<RequestItem>().toList();
      }
    } catch (e) {
      print('Error parsing items array: $e');
      items = [];
    }
    
    // Safely parse quantityChanges list
    List<QuantityChange> quantityChanges = [];
    try {
      if (json['quantityChanges'] != null && json['quantityChanges'] is List) {
        quantityChanges = (json['quantityChanges'] as List).map((change) {
          try {
            if (change is Map<String, dynamic>) {
              return QuantityChange.fromJson(change);
            }
            return null;
          } catch (e) {
            print('Error parsing quantity change: $e, change: $change');
            return null;
          }
        }).whereType<QuantityChange>().toList();
      }
    } catch (e) {
      print('Error parsing quantityChanges array: $e');
      quantityChanges = [];
    }
    
    return ICTRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      requesterId: json['requesterId'] is Map 
          ? (json['requesterId']?['_id']?.toString() ?? json['requesterId']?['id']?.toString() ?? '')
          : (json['requesterId']?.toString() ?? ''),
      items: items,
      status: _parseStatus(json['status']),
      workflowStage: json['workflowStage'],
      approvals: json['approvals'] != null
          ? (json['approvals'] as List)
              .map((a) => WorkflowApproval.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
      comment: json['comment'] ?? json['notes'],
      priority: json['priority'] ?? false,
      qrCode: json['qrCode'],
      fulfillmentStatus: (json['fulfillmentStatus'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [],
      quantityChanges: quantityChanges,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => Participant.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
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

