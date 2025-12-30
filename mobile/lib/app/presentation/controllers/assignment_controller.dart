import 'package:get/get.dart';
import '../../data/services/assignment_service.dart';

class AssignmentController extends GetxController {
  final AssignmentService _assignmentService = Get.find<AssignmentService>();

  final RxList<dynamic> availableVehicles = <dynamic>[].obs;
  final RxList<dynamic> availableDrivers = <dynamic>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingVehicles = false.obs;
  final RxBool isLoadingDrivers = false.obs;
  final RxBool isAssigning = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAvailableVehicles();
    loadAvailableDrivers();
  }

  Future<void> loadAvailableVehicles({
    DateTime? tripDate,
    DateTime? returnDate,
  }) async {
    isLoadingVehicles.value = true;
    try {
      final vehicles = await _assignmentService.getAvailableVehicles(
        tripDate: tripDate,
        returnDate: returnDate,
      );
      availableVehicles.value = vehicles;
    } catch (e) {
      print('Error loading vehicles: $e');
    } finally {
      isLoadingVehicles.value = false;
    }
  }

  Future<void> loadAvailableDrivers({
    DateTime? tripDate,
    DateTime? returnDate,
  }) async {
    isLoadingDrivers.value = true;
    error.value = '';
    try {
      print('[AssignmentController] ===== LOADING DRIVERS =====');
      print('[AssignmentController] Calling assignment service...');
      if (tripDate != null && returnDate != null) {
        print('[AssignmentController] Checking availability for trip dates: $tripDate to $returnDate');
      }
      final drivers = await _assignmentService.getAvailableDrivers(
        tripDate: tripDate,
        returnDate: returnDate,
      );
      print('[AssignmentController] Received ${drivers.length} drivers from service');
      
      if (drivers.isNotEmpty) {
        print('[AssignmentController] Driver list details:');
        for (var i = 0; i < drivers.length; i++) {
          final driver = drivers[i];
          print('[AssignmentController]   Driver ${i + 1}: ${driver['name'] ?? 'Unknown'} (${driver['_id'] ?? 'N/A'})');
        }
      }
      
      availableDrivers.value = drivers;
      
      if (drivers.isEmpty) {
        print('[AssignmentController] ⚠️ WARNING: No drivers returned from service');
        error.value = 'No available drivers found';
      } else {
        final driverNames = drivers.map((d) => d['name'] ?? 'Unknown').join(', ');
        print('[AssignmentController] ✅ Successfully loaded ${drivers.length} driver(s): $driverNames');
        error.value = '';
      }
      print('[AssignmentController] ===== END LOADING DRIVERS =====');
    } catch (e, stackTrace) {
      print('[AssignmentController] ❌ ERROR loading drivers: $e');
      print('[AssignmentController] Stack trace: $stackTrace');
      error.value = 'Failed to load drivers: ${e.toString()}';
      availableDrivers.value = [];
      print('[AssignmentController] ===== END LOADING DRIVERS =====');
    } finally {
      isLoadingDrivers.value = false;
    }
  }

  Future<bool> assignVehicle(
    String requestId,
    String vehicleId, {
    String? driverId,
  }) async {
    isAssigning.value = true;
    error.value = '';

    try {
      final result = await _assignmentService.assignVehicle(
        requestId,
        vehicleId,
        driverId: driverId,
      );

      if (result['success'] == true) {
        isAssigning.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to assign vehicle';
        isAssigning.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isAssigning.value = false;
      return false;
    }
  }
}

