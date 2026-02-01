import 'package:get/get.dart';
import '../../data/services/assignment_service.dart';
import '../../data/models/request_model.dart';
import '../../data/models/ict_request_model.dart';
import '../controllers/auth_controller.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/utils/error_message_formatter.dart';

class DriverController extends GetxController {
  final AssignmentService _assignmentService = Get.find<AssignmentService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<VehicleRequestModel> assignedTrips = <VehicleRequestModel>[].obs;
  final RxList<ICTRequestModel> ictRequestsForPickup = <ICTRequestModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingICT = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAssignedTrips();
    // ICT requests removed - requesters pick up their own requests
    // Drivers no longer see ICT requests for pickup
    // loadICTRequestsForPickup();
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
      print('[Driver Controller] Received ${trips.length} trips from service');
      
      // Include all trips (including completed) - getters will filter them
      // Handle parsing errors for individual items gracefully
      final parsedTrips = <VehicleRequestModel>[];
      for (var i = 0; i < trips.length; i++) {
        try {
          final tripJson = trips[i];
          if (tripJson is Map<String, dynamic>) {
            parsedTrips.add(VehicleRequestModel.fromJson(tripJson));
          } else {
            print('[Driver Controller] ⚠️ Trip at index $i is not a Map: ${tripJson.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('[Driver Controller] ❌ Error parsing trip at index $i: $e');
          print('[Driver Controller] Stack trace: $stackTrace');
          // Continue parsing other trips even if one fails
        }
      }
      
      print('[Driver Controller] Successfully parsed ${parsedTrips.length} out of ${trips.length} trips');
      assignedTrips.value = parsedTrips;
    } catch (e, stackTrace) {
      print('[Driver Controller] ❌ Error loading assigned trips: $e');
      print('[Driver Controller] Stack trace: $stackTrace');
      error.value = ErrorMessageFormatter.getUserFacingMessage(e);
      assignedTrips.value = [];
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

  /// Load ICT requests that are approved and ready for pickup
  /// DEPRECATED: ICT requests are no longer shown to drivers
  /// Requesters pick up their own ICT requests
  /// This method is kept for backward compatibility but is no longer called
  Future<void> loadICTRequestsForPickup() async {
    isLoadingICT.value = true;
    try {
      // Always return empty list - drivers no longer see ICT requests
      ictRequestsForPickup.value = [];
      print('[Driver Controller] ICT requests no longer loaded for drivers - requesters pick up their own requests');
    } catch (e) {
      print('[Driver Controller] Error loading ICT requests: $e');
      ictRequestsForPickup.value = [];
    } finally {
      isLoadingICT.value = false;
    }
  }

  /// Get ICT requests related to a specific trip
  /// DEPRECATED: ICT requests are no longer shown to drivers
  /// This method is kept for backward compatibility but always returns empty list
  List<ICTRequestModel> getICTRequestsForTrip(VehicleRequestModel trip) {
    // Always return empty - drivers no longer see ICT requests
    return [];
  }
}
