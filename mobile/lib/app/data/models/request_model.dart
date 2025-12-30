enum RequestType { vehicle, ict, store }

class WorkflowApproval {
  final String approverId;
  final String role;
  final String status; // 'APPROVED' or 'REJECTED'
  final String? comment;
  final DateTime timestamp;

  WorkflowApproval({
    required this.approverId,
    required this.role,
    required this.status,
    this.comment,
    required this.timestamp,
  });

  factory WorkflowApproval.fromJson(Map<String, dynamic> json) {
    return WorkflowApproval(
      approverId: json['approverId']?['_id']?.toString() ?? 
                  json['approverId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      comment: json['comment']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class DriverInfo {
  final String id;
  final String name;
  final String phone;
  final String licenseNumber;

  DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNumber,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Driver',
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
    );
  }
}

class VehicleInfo {
  final String id;
  final String plateNumber;
  final String type;
  final String make;
  final String model;
  final int? year;

  VehicleInfo({
    required this.id,
    required this.plateNumber,
    required this.type,
    required this.make,
    required this.model,
    this.year,
  });

  String get displayName => '$make $model';

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Unknown',
      make: json['make']?.toString() ?? 'Unknown',
      model: json['model']?.toString() ?? 'Unknown',
      year: json['year']?.toInt(),
    );
  }
}

class Waypoint {
  final String name;
  final double latitude;
  final double longitude;
  final int order;
  final bool reached;
  final DateTime? reachedTime;
  final double? distanceFromPrevious;
  final double? fuelFromPrevious;

  Waypoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
    this.reached = false,
    this.reachedTime,
    this.distanceFromPrevious,
    this.fuelFromPrevious,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      order: json['order'] ?? 0,
      reached: json['reached'] ?? false,
      reachedTime: json['reachedTime'] != null
          ? DateTime.parse(json['reachedTime'])
          : null,
      distanceFromPrevious: json['distanceFromPrevious']?.toDouble(),
      fuelFromPrevious: json['fuelFromPrevious']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'order': order,
      'reached': reached,
      'reachedTime': reachedTime?.toIso8601String(),
      'distanceFromPrevious': distanceFromPrevious,
      'fuelFromPrevious': fuelFromPrevious,
    };
  }
}

enum RequestStatus {
  pending,
  approved,
  rejected,
  corrected,
  assigned,
  fulfilled,
  completed,
}

class Participant {
  final String userId;
  final String role;
  final String action; // 'created', 'approved', 'rejected', 'corrected', 'assigned', 'fulfilled'
  final DateTime timestamp;

  Participant({
    required this.userId,
    required this.role,
    required this.action,
    required this.timestamp,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          return DateTime.now();
        }
      }
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      if (timestamp is Map && timestamp.containsKey('\$date')) {
        final dateValue = timestamp['\$date'];
        if (dateValue is int) {
          return DateTime.fromMillisecondsSinceEpoch(dateValue);
        }
        if (dateValue is String) {
          try {
            return DateTime.parse(dateValue);
          } catch (e) {
            return DateTime.now();
          }
        }
      }
      return DateTime.now();
    }

    return Participant(
      userId: json['userId'] is Map
          ? (json['userId']?['_id']?.toString() ?? json['userId']?['id']?.toString() ?? '')
          : (json['userId']?.toString() ?? ''),
      role: json['role']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      timestamp: parseTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class VehicleRequestModel {
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
  final DateTime tripDate;
  final String tripTime;
  final DateTime returnDate;
  final String returnTime;
  final String destination;
  final String purpose;
  final String? vehicleId;
  final String? driverId;
  final DriverInfo? driver;
  final VehicleInfo? vehicle;
  final RequestStatus status;
  final String? workflowStage;
  final List<WorkflowApproval> approvals;
  final bool priority;
  final bool tripStarted;
  final bool destinationReached;
  final bool tripCompleted;
  final Map<String, dynamic>? startLocation;
  final Map<String, dynamic>? destinationLocation;
  final Map<String, dynamic>? returnLocation;
  final Map<String, dynamic>? requestedDestinationLocation;
  final Map<String, dynamic>? officeLocation;
  final DateTime? actualDepartureTime;
  final DateTime? destinationReachedTime;
  final DateTime? actualReturnTime;
  final double? outboundDistanceKm;
  final double? returnDistanceKm;
  final double? totalDistanceKm;
  final double? outboundFuelLiters;
  final double? returnFuelLiters;
  final double? totalFuelLiters;
  final List<Waypoint>? waypoints;
  final int currentStopIndex;
  final double? totalTripDistanceKm;
  final double? totalTripFuelLiters;
  final List<Participant> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleRequestModel({
    required this.id,
    required this.requesterId,
    required this.tripDate,
    required this.tripTime,
    required this.returnDate,
    required this.returnTime,
    required this.destination,
    required this.purpose,
    this.vehicleId,
    this.driverId,
    this.driver,
    this.vehicle,
    required this.status,
    this.workflowStage,
    this.approvals = const [],
    this.priority = false,
    this.tripStarted = false,
    this.destinationReached = false,
    this.tripCompleted = false,
    this.startLocation,
    this.destinationLocation,
    this.returnLocation,
    this.requestedDestinationLocation,
    this.officeLocation,
    this.actualDepartureTime,
    this.destinationReachedTime,
    this.actualReturnTime,
    this.outboundDistanceKm,
    this.returnDistanceKm,
    this.totalDistanceKm,
    this.outboundFuelLiters,
    this.returnFuelLiters,
    this.totalFuelLiters,
    this.waypoints,
    this.currentStopIndex = 0,
    this.totalTripDistanceKm,
    this.totalTripFuelLiters,
    this.participants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleRequestModel.fromJson(Map<String, dynamic> json) {
    return VehicleRequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      requesterId: json['requesterId']?['_id'] ?? 
                   json['requesterId'] ?? '',
      tripDate: _parseDateTime(json['tripDate']),
      tripTime: json['tripTime'] ?? '',
      returnDate: _parseDateTime(json['returnDate'] ?? json['tripDate']),
      returnTime: json['returnTime'] ?? json['tripTime'] ?? '',
      destination: json['destination'] ?? '',
      purpose: json['purpose'] ?? '',
      vehicleId: json['vehicleId']?['_id'] ?? json['vehicleId'],
      driverId: json['driverId']?['_id'] ?? json['driverId'],
      driver: json['driverId'] != null && json['driverId'] is Map
          ? DriverInfo.fromJson(json['driverId'] as Map<String, dynamic>)
          : null,
      vehicle: json['vehicleId'] != null && json['vehicleId'] is Map
          ? VehicleInfo.fromJson(json['vehicleId'] as Map<String, dynamic>)
          : null,
      status: _parseStatus(json['status']),
      workflowStage: json['workflowStage'],
      approvals: json['approvals'] != null
          ? (json['approvals'] as List)
              .map((a) => WorkflowApproval.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
      priority: json['priority'] ?? false,
      tripStarted: json['tripStarted'] ?? false,
      destinationReached: json['destinationReached'] ?? false,
      tripCompleted: json['tripCompleted'] ?? false,
      startLocation: json['startLocation'],
      destinationLocation: json['destinationLocation'],
      returnLocation: json['returnLocation'],
      requestedDestinationLocation: json['requestedDestinationLocation'],
      officeLocation: json['officeLocation'],
      actualDepartureTime: json['actualDepartureTime'] != null
          ? _parseDateTime(json['actualDepartureTime'])
          : null,
      destinationReachedTime: json['destinationReachedTime'] != null
          ? _parseDateTime(json['destinationReachedTime'])
          : null,
      actualReturnTime: json['actualReturnTime'] != null
          ? _parseDateTime(json['actualReturnTime'])
          : null,
      outboundDistanceKm: json['outboundDistanceKm']?.toDouble(),
      returnDistanceKm: json['returnDistanceKm']?.toDouble(),
      totalDistanceKm: json['totalDistanceKm']?.toDouble(),
      outboundFuelLiters: json['outboundFuelLiters']?.toDouble(),
      returnFuelLiters: json['returnFuelLiters']?.toDouble(),
      totalFuelLiters: json['totalFuelLiters']?.toDouble(),
      waypoints: json['waypoints'] != null
          ? (json['waypoints'] as List)
              .map((wp) => Waypoint.fromJson(wp))
              .toList()
          : null,
      currentStopIndex: json['currentStopIndex'] ?? 0,
      totalTripDistanceKm: json['totalTripDistanceKm']?.toDouble(),
      totalTripFuelLiters: json['totalTripFuelLiters']?.toDouble(),
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => Participant.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt'] ?? 
                                DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? 
                                DateTime.now().toIso8601String()),
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

