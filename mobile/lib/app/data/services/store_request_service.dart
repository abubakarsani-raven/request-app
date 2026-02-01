import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../models/store_request_model.dart';
import '../models/inventory_item_model.dart';

class StoreRequestService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // Inventory Items
  Future<List<InventoryItemModel>> getInventoryItems({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;

      final response = await _apiService.get(
        '/store/items',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        if (response.data is! List) return [];
        return (response.data as List)
            .map((json) => InventoryItemModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching inventory items: $e');
      return [];
    }
  }

  Future<InventoryItemModel?> getInventoryItem(String id) async {
    try {
      final response = await _apiService.get('/store/items/$id');
      if (response.statusCode == 200) {
        return InventoryItemModel.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching inventory item: $e');
    }
    return null;
  }

  // Store Requests
  Future<List<StoreRequestModel>> getStoreRequests({
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
        '/store/requests',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        if (response.data is! List) return [];
        return (response.data as List)
            .map((json) => StoreRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching store requests: $e');
      return [];
    }
  }

  // Get pending approvals for current user's role
  Future<List<StoreRequestModel>> getPendingApprovals() async {
    try {
      // Use query parameter instead of path parameter to avoid route conflicts
      final response = await _apiService.get(
        '/store/requests',
        queryParameters: {'pending': 'true'},
      );
      if (response.statusCode == 200) {
        if (response.data is! List) return [];
        return (response.data as List)
            .map((json) => StoreRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching pending approvals: $e');
      return [];
    }
  }

  // Get department requests (for supervisors)
  Future<List<StoreRequestModel>> getDepartmentRequests(String departmentId) async {
    try {
      final response = await _apiService.get(
        '/store/requests',
        queryParameters: {'departmentId': departmentId},
      );
      if (response.statusCode == 200) {
        if (response.data is! List) return [];
        return (response.data as List)
            .map((json) => StoreRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching department requests: $e');
      return [];
    }
  }

  Future<StoreRequestModel?> getStoreRequest(String id) async {
    try {
      final response = await _apiService.get('/store/requests/$id');
      if (response.statusCode == 200) {
        return StoreRequestModel.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching store request: $e');
    }
    return null;
  }

  Future<List<StoreRequestModel>> getRequestHistory({
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
        '/store/requests/history',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        if (response.data is! List) return [];
        return (response.data as List)
            .map((json) => StoreRequestModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching store request history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createStoreRequest(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _apiService.post(
        '/store/requests',
        data: {'items': items},
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
        '/store/requests/$id/approve',
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
        '/requests/store/$id/cancel',
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
        '/store/requests/$id/reject',
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
      final response = await _apiService.post(
        '/store/requests/$id/fulfill',
        data: {'fulfillmentData': fulfillmentData},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fulfill request'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }
}

