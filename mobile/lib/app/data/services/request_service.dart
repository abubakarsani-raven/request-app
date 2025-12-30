import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/services/api_service.dart';
import '../../../core/utils/error_message_formatter.dart';
import '../models/request_model.dart';

class RequestService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // Vehicle Requests
  Future<List<VehicleRequestModel>> getVehicleRequests({
    bool myRequests = false,
    bool pending = false,
    String? departmentId,
    String? workflowStage,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (myRequests) queryParams['myRequests'] = 'true';
      if (pending) queryParams['pending'] = 'true';
      if (departmentId != null) queryParams['departmentId'] = departmentId;
      if (workflowStage != null) queryParams['workflowStage'] = workflowStage;

      final response = await _apiService.get(
        '/vehicles/requests',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => VehicleRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vehicle requests: $e');
      return [];
    }
  }

  // Get pending approvals for current user's role
  Future<List<VehicleRequestModel>> getPendingApprovals() async {
    try {
      // Use query parameter instead of path parameter to avoid route conflicts
      final response = await _apiService.get(
        '/vehicles/requests',
        queryParameters: {'pending': 'true'},
      );
      print('📥 [Pending Approvals] Response status: ${response.statusCode}');
      print('📥 [Pending Approvals] Response data type: ${response.data.runtimeType}');
      print('📥 [Pending Approvals] Response data length: ${response.data is List ? (response.data as List).length : 'N/A'}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          print('📥 [Pending Approvals] Parsing ${data.length} requests');
          final requests = data
              .map((json) {
                try {
                  return VehicleRequestModel.fromJson(json);
                } catch (e) {
                  print('❌ [Pending Approvals] Error parsing request: $e');
                  print('❌ [Pending Approvals] JSON: $json');
                  rethrow;
                }
              })
              .toList();
          print('✅ [Pending Approvals] Successfully parsed ${requests.length} requests');
          return requests;
        } else {
          print('❌ [Pending Approvals] Response data is not a List: $data');
          return [];
        }
      }
      print('❌ [Pending Approvals] Non-200 status code: ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('❌ [Pending Approvals] Error fetching pending approvals: $e');
      print('❌ [Pending Approvals] Stack trace: $stackTrace');
      return [];
    }
  }

  // Get department requests (for supervisors)
  Future<List<VehicleRequestModel>> getDepartmentRequests(String departmentId) async {
    try {
      final response = await _apiService.get(
        '/vehicles/requests',
        queryParameters: {'departmentId': departmentId},
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => VehicleRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching department requests: $e');
      return [];
    }
  }

  Future<VehicleRequestModel?> getVehicleRequest(String id) async {
    try {
      final response = await _apiService.get('/vehicles/requests/$id');
      if (response.statusCode == 200) {
        return VehicleRequestModel.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching vehicle request: $e');
    }
    return null;
  }

  Future<List<VehicleRequestModel>> getRequestHistory({
    String? status,
    String? action,
    String? workflowStage,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (action != null) queryParams['action'] = action;
      if (workflowStage != null) queryParams['workflowStage'] = workflowStage;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom.toIso8601String();
      if (dateTo != null) queryParams['dateTo'] = dateTo.toIso8601String();

      final response = await _apiService.get(
        '/vehicles/requests/history',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => VehicleRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vehicle request history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createVehicleRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post('/vehicles/requests', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to create request'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> approveRequest(
    String id,
    String? comment,
  ) async {
    try {
      final response = await _apiService.put(
        '/vehicles/requests/$id/approve',
        data: comment != null ? {'comment': comment} : {},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to approve request'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> rejectRequest(String id, String comment) async {
    try {
      final response = await _apiService.put(
        '/vehicles/requests/$id/reject',
        data: {'comment': comment},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to reject request'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> correctRequest(
    String id,
    String comment, {
    String? tripDate,
    String? tripTime,
    String? destination,
    String? purpose,
  }) async {
    try {
      final data = <String, dynamic>{'comment': comment};
      if (tripDate != null) data['tripDate'] = tripDate;
      if (tripTime != null) data['tripTime'] = tripTime;
      if (destination != null) data['destination'] = destination;
      if (purpose != null) data['purpose'] = purpose;

      final response = await _apiService.put(
        '/vehicles/requests/$id/correct',
        data: data,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to correct request'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Trip Tracking
  Future<Map<String, dynamic>> startTrip(
    String requestId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _apiService.post(
        '/vehicles/requests/$requestId/trip/start',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to start trip'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> reachDestination(
    String requestId,
    double latitude,
    double longitude,
    String? notes, {
    int? stopIndex,
  }) async {
    try {
      final data = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (notes != null) data['notes'] = notes;
      if (stopIndex != null) data['stopIndex'] = stopIndex;

      final response = await _apiService.post(
        '/vehicles/requests/$requestId/trip/destination',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to mark destination reached'};
    } catch (e) {
      String errorMessage = 'Failed to mark destination reached';
      
      // Try to extract error message from DioException
      if (e is dio.DioException) {
        if (e.response != null) {
          final responseData = e.response?.data;
          final extractedMessage = ErrorMessageFormatter.extractErrorMessage(responseData);
          errorMessage = ErrorMessageFormatter.formatApiError(extractedMessage);
        } else {
          errorMessage = e.message ?? 'Network error occurred';
        }
      } else {
        errorMessage = ErrorMessageFormatter.formatApiError(e.toString());
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  Future<Map<String, dynamic>> reachWaypoint(
    String requestId,
    int stopIndex,
    double latitude,
    double longitude,
    String? notes,
  ) async {
    try {
      // Use reachDestination endpoint with stopIndex for waypoints
      return await reachDestination(
        requestId,
        latitude,
        longitude,
        notes,
        stopIndex: stopIndex,
      );
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> returnToOffice(
    String requestId,
    double latitude,
    double longitude,
    String? notes,
  ) async {
    try {
      final data = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (notes != null) data['notes'] = notes;

      final response = await _apiService.post(
        '/vehicles/requests/$requestId/trip/return',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to mark return to office'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> updateTripLocation(
    String requestId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _apiService.post(
        '/vehicles/requests/$requestId/trip/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  Future<VehicleRequestModel?> getTripDetails(String requestId) async {
    try {
      final response = await _apiService.get('/vehicles/requests/$requestId/trip');
      if (response.statusCode == 200) {
        return VehicleRequestModel.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching trip details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> deleteAllRequests() async {
    try {
      final response = await _apiService.delete('/vehicles/requests');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to delete requests'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }
}

