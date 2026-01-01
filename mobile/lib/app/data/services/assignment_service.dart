import 'package:get/get.dart';
import '../../../core/services/api_service.dart';

class AssignmentService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  Future<List<dynamic>> getAvailableVehicles({
    DateTime? tripDate,
    DateTime? returnDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{'available': 'true'};
      if (tripDate != null) {
        queryParams['tripDate'] = tripDate.toIso8601String();
      }
      if (returnDate != null) {
        queryParams['returnDate'] = returnDate.toIso8601String();
      }
      
      final response = await _apiService.get(
        '/vehicles/vehicles',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data;
        }
        return [];
      }
      print('Failed to fetch vehicles: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching available vehicles: $e');
      return [];
    }
  }

  Future<List<dynamic>> getAvailableDrivers({
    DateTime? tripDate,
    DateTime? returnDate,
  }) async {
    try {
      print('[AssignmentService] ===== FETCHING DRIVERS =====');
      final queryParams = <String, dynamic>{'available': 'true'};
      if (tripDate != null) {
        queryParams['tripDate'] = tripDate.toIso8601String();
      }
      if (returnDate != null) {
        queryParams['returnDate'] = returnDate.toIso8601String();
      }
      print('[AssignmentService] Endpoint: /vehicles/drivers?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}');
      final response = await _apiService.get(
        '/vehicles/drivers',
        queryParameters: queryParams,
      );
      print('[AssignmentService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('[AssignmentService] Response data type: ${data.runtimeType}');
        print('[AssignmentService] Response data (raw): $data');
        
        if (data is List) {
          print('[AssignmentService] ✅ Found ${data.length} available drivers');
          if (data.isNotEmpty) {
            print('[AssignmentService] Driver details:');
            for (var i = 0; i < data.length; i++) {
              final driver = data[i];
              print('[AssignmentService]   Driver ${i + 1}:');
              print('[AssignmentService]     - Name: ${driver['name'] ?? 'N/A'}');
              print('[AssignmentService]     - ID: ${driver['_id'] ?? 'N/A'}');
              print('[AssignmentService]     - Email: ${driver['email'] ?? 'N/A'}');
              print('[AssignmentService]     - Phone: ${driver['phone'] ?? 'N/A'}');
              print('[AssignmentService]     - Employee ID: ${driver['employeeId'] ?? 'N/A'}');
              print('[AssignmentService]     - License Number: ${driver['licenseNumber'] ?? 'N/A'}');
              print('[AssignmentService]     - Is Available: ${driver['isAvailable'] ?? 'N/A'}');
            }
          } else {
            print('[AssignmentService] ⚠️ WARNING: Empty driver list returned!');
          }
          print('[AssignmentService] ===== END FETCHING DRIVERS =====');
          return data;
        } else if (data is Map) {
          print('[AssignmentService] Response is Map, not List. Keys: ${data.keys}');
          // Sometimes APIs return { data: [...] } format
          if (data.containsKey('data') && data['data'] is List) {
            print('[AssignmentService] Found drivers in data field: ${(data['data'] as List).length}');
            print('[AssignmentService] ===== END FETCHING DRIVERS =====');
            return data['data'] as List;
          }
        }
        print('[AssignmentService] ❌ Response is not a List, returning empty list');
        print('[AssignmentService] ===== END FETCHING DRIVERS =====');
        return [];
      }
      print('[AssignmentService] ❌ Failed to fetch drivers: Status ${response.statusCode}');
      if (response.data != null) {
        print('[AssignmentService] Error response: ${response.data}');
      }
      print('[AssignmentService] ===== END FETCHING DRIVERS =====');
      return [];
    } catch (e, stackTrace) {
      print('[AssignmentService] ❌ EXCEPTION: $e');
      print('[AssignmentService] Stack trace: $stackTrace');
      print('[AssignmentService] ===== END FETCHING DRIVERS =====');
      return [];
    }
  }

  Future<Map<String, dynamic>> assignVehicle(
    String requestId,
    String vehicleId, {
    String? driverId,
  }) async {
    try {
      final data = {'vehicleId': vehicleId};
      if (driverId != null) data['driverId'] = driverId;

      final response = await _apiService.put(
        '/vehicles/requests/$requestId/assign',
        data: data,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to assign vehicle'};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<List<dynamic>> getDriverTrips(String driverId) async {
    try {
      print('[AssignmentService] ===== FETCHING DRIVER TRIPS =====');
      print('[AssignmentService] Driver ID: $driverId');
      final response = await _apiService.get('/vehicles/requests?driverId=$driverId');
      print('[AssignmentService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('[AssignmentService] Response data type: ${data.runtimeType}');
        print('[AssignmentService] Response data (raw): $data');
        
        if (data is List) {
          print('[AssignmentService] ✅ Found ${data.length} driver trips');
          print('[AssignmentService] ===== END FETCHING DRIVER TRIPS =====');
          return data;
        } else if (data is Map) {
          print('[AssignmentService] Response is Map, not List. Keys: ${data.keys}');
          // Sometimes APIs return { data: [...] } format
          if (data.containsKey('data') && data['data'] is List) {
            print('[AssignmentService] Found trips in data field: ${(data['data'] as List).length}');
            print('[AssignmentService] ===== END FETCHING DRIVER TRIPS =====');
            return data['data'] as List;
          }
        }
        print('[AssignmentService] ❌ Response is not a List, returning empty list');
        print('[AssignmentService] ===== END FETCHING DRIVER TRIPS =====');
        return [];
      }
      print('[AssignmentService] ❌ Failed to fetch driver trips: Status ${response.statusCode}');
      if (response.data != null) {
        print('[AssignmentService] Error response: ${response.data}');
      }
      print('[AssignmentService] ===== END FETCHING DRIVER TRIPS =====');
      return [];
    } catch (e, stackTrace) {
      print('[AssignmentService] ❌ EXCEPTION: $e');
      print('[AssignmentService] Stack trace: $stackTrace');
      print('[AssignmentService] ===== END FETCHING DRIVER TRIPS =====');
      return [];
    }
  }
}

