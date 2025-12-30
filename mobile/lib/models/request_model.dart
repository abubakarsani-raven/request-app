enum RequestType { VEHICLE, ICT, STORE }
enum RequestStatus { PENDING, APPROVED, REJECTED, CORRECTED, ASSIGNED, FULFILLED, COMPLETED }

class RequestModel {
  final String id;
  final String requesterId;
  final RequestType type;
  final RequestStatus status;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  RequestModel({
    required this.id,
    required this.requesterId,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.data,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json, RequestType type) {
    return RequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      requesterId: json['requesterId']?['_id'] ?? json['requesterId'] ?? '',
      type: type,
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      data: json,
    );
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status) {
      case 'PENDING':
        return RequestStatus.PENDING;
      case 'APPROVED':
        return RequestStatus.APPROVED;
      case 'REJECTED':
        return RequestStatus.REJECTED;
      case 'CORRECTED':
        return RequestStatus.CORRECTED;
      case 'ASSIGNED':
        return RequestStatus.ASSIGNED;
      case 'FULFILLED':
        return RequestStatus.FULFILLED;
      case 'COMPLETED':
        return RequestStatus.COMPLETED;
      default:
        return RequestStatus.PENDING;
    }
  }
}

