import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/services/api_service.dart';
import '../models/ict_request_model.dart';
import '../models/catalog_item_model.dart';

class ICTRequestService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // Catalog Items
  Future<List<CatalogItemModel>> getCatalogItems({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;

      final response = await _apiService.get(
        '/ict/items',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => CatalogItemModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching catalog items: $e');
      return [];
    }
  }

  Future<CatalogItemModel?> getCatalogItem(String id) async {
    try {
      final response = await _apiService.get('/ict/items/$id');
      if (response.statusCode == 200) {
        return CatalogItemModel.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching catalog item: $e');
    }
    return null;
  }

  // ICT Requests
  Future<List<ICTRequestModel>> getICTRequests({
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
        '/ict/requests',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => ICTRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching ICT requests: $e');
      return [];
    }
  }

  // Get pending approvals for current user's role
  Future<List<ICTRequestModel>> getPendingApprovals() async {
    try {
      // Use query parameter instead of path parameter to avoid route conflicts
      final response = await _apiService.get(
        '/ict/requests',
        queryParameters: {'pending': 'true'},
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => ICTRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching pending approvals: $e');
      return [];
    }
  }

  // Get department requests (for supervisors)
  Future<List<ICTRequestModel>> getDepartmentRequests(String departmentId) async {
    try {
      final response = await _apiService.get(
        '/ict/requests',
        queryParameters: {'departmentId': departmentId},
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => ICTRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching department requests: $e');
      return [];
    }
  }

  Future<List<ICTRequestModel>> getUnfulfilledRequests() async {
    try {
      final response = await _apiService.get('/ict/requests/unfulfilled');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => ICTRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching unfulfilled requests: $e');
      return [];
    }
  }

  Future<ICTRequestModel?> getICTRequest(String id) async {
    try {
      final response = await _apiService.get('/ict/requests/$id');
      if (response.statusCode == 200) {
        return ICTRequestModel.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching ICT request: $e');
    }
    return null;
  }

  Future<List<ICTRequestModel>> getRequestHistory({
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
        '/ict/requests/history',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => ICTRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching ICT request history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createICTRequest(
    List<Map<String, dynamic>> items, {
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{'items': items};
      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }
      final response = await _apiService.post(
        '/ict/requests',
        data: data,
      );
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
    String id, {
    String? comment,
  }) async {
    try {
      final response = await _apiService.put(
        '/ict/requests/$id/approve',
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

  Future<Map<String, dynamic>> cancelRequest(String id, String reason) async {
    try {
      final response = await _apiService.put(
        '/requests/ict/$id/cancel',
        data: {'reason': reason},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to cancel request'};
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
        '/ict/requests/$id/reject',
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

  Future<Map<String, dynamic>> fulfillRequest(
    String id,
    Map<String, int> fulfillmentData,
  ) async {
    try {
      // Convert fulfillmentData to items array format expected by backend
      final items = fulfillmentData.entries
          .where((entry) => entry.value > 0)
          .map((entry) => <String, dynamic>{
                'itemId': entry.key,
                'quantityFulfilled': entry.value,
              })
          .toList();

      final response = await _apiService.put(
        '/ict/requests/$id/fulfill',
        data: {'items': items},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fulfill request'};
    } on dio.DioException catch (e) {
      // Extract error message from response data
      String errorMessage = 'Failed to fulfill request';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message']?.toString() ?? 
                        responseData['error']?.toString() ?? 
                        errorMessage;
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> notifyRequester(
    String id, {
    String? message,
  }) async {
    try {
      final response = await _apiService.post(
        '/ict/requests/$id/notify-requester',
        data: message != null ? {'message': message} : {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to notify requester'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> updateRequestItems(
    String id,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _apiService.put(
        '/ict/requests/$id/items',
        data: {'items': items},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to update request items'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }
}

