import 'package:get/get.dart';
import '../../data/services/assignment_service.dart';
import '../../data/models/request_model.dart';
import '../controllers/auth_controller.dart';
import '../../../core/services/websocket_service.dart';

class DriverController extends GetxController {
  final AssignmentService _assignmentService = Get.find<AssignmentService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<VehicleRequestModel> assignedTrips = <VehicleRequestModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAssignedTrips();
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    final wsService = Get.find<WebSocketService>();
    wsService.on('trip:completed', (data) {
      // Refresh when trip completes
      loadAssignedTrips();
    });
  }

  Future<void> loadAssignedTrips() async {
    isLoading.value = true;
    error.value = '';

    try {
      final userId = _authController.user.value?.id;
      if (userId == null) {
        isLoading.value = false;
        return;
      }

      final trips = await _assignmentService.getDriverTrips(userId);
      // Include all trips (including completed) - getters will filter them
      assignedTrips.value = trips
          .map((json) => VehicleRequestModel.fromJson(json))
          .toList();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  List<VehicleRequestModel> get activeTrips {
    return assignedTrips
        .where((trip) => 
            trip.tripStarted && 
            !trip.tripCompleted &&
            trip.status != RequestStatus.completed) // Additional safety check
        .toList();
  }

  List<VehicleRequestModel> get pendingTrips {
    return assignedTrips
        .where((trip) => 
            trip.status == RequestStatus.assigned && 
            !trip.tripStarted && 
            !trip.tripCompleted &&
            trip.status != RequestStatus.completed) // Exclude completed trips
        .toList();
  }

  List<VehicleRequestModel> get completedTrips {
    return assignedTrips
        .where((trip) => 
            trip.tripCompleted || 
            trip.status == RequestStatus.completed) // Include trips marked as completed
        .toList();
  }
}

