import 'package:get/get.dart';
import '../../data/services/request_service.dart';
import '../../data/models/request_model.dart';
import 'auth_controller.dart';
import '../../../core/utils/id_utils.dart';

class RequestController extends GetxController {
  final RequestService _requestService = Get.find<RequestService>();

  final RxList<VehicleRequestModel> vehicleRequests = <VehicleRequestModel>[].obs;
  final RxList<VehicleRequestModel> historyRequests = <VehicleRequestModel>[].obs;
  final Rx<VehicleRequestModel?> selectedRequest = Rx<VehicleRequestModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxString error = ''.obs;

  // Get count of pending approvals (requests that are pending and awaiting approval)
  int get pendingApprovalsCount {
    return vehicleRequests.where((request) {
      return request.status == RequestStatus.pending ||
          (request.status != RequestStatus.approved &&
              request.status != RequestStatus.rejected &&
              request.status != RequestStatus.assigned &&
              request.status != RequestStatus.completed);
    }).length;
  }

  @override
  void onInit() {
    super.onInit();
    loadVehicleRequests();
  }

  Future<void> loadVehicleRequests({bool myRequests = false, bool pending = false}) async {
    isLoading.value = true;
    error.value = '';

    try {
      // Clear existing requests first to avoid showing stale data
      vehicleRequests.clear();
      
      final requests = await _requestService.getVehicleRequests(
        myRequests: myRequests,
        pending: pending,
      );
      
      // IMPORTANT: When myRequests is true, we should only see requests where
      // the user is the requester. The backend filters by requesterId only.
      // If any requests slip through where user is only the driver, filter them out client-side as a safeguard.
      if (myRequests) {
        final authController = Get.find<AuthController>();
        final currentUserId = authController.user.value?.id;
        if (currentUserId != null) {
          vehicleRequests.value = requests.where((request) {
            // Only include requests where the user is the requester
            // Handle both string and ObjectId formats using utility
            return IdUtils.areIdsEqual(request.requesterId, currentUserId);
          }).toList();
        } else {
          vehicleRequests.value = requests;
        }
      } else {
        vehicleRequests.value = requests;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPendingApprovals() async {
    isLoading.value = true;
    error.value = '';

    try {
      print('🔄 [RequestController] Loading pending approvals...');
      final requests = await _requestService.getPendingApprovals();
      print('✅ [RequestController] Received ${requests.length} pending approvals');
      vehicleRequests.value = requests;
      print('✅ [RequestController] Updated vehicleRequests with ${vehicleRequests.length} items');
    } catch (e, stackTrace) {
      print('❌ [RequestController] Error loading pending approvals: $e');
      print('❌ [RequestController] Stack trace: $stackTrace');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      print('🏁 [RequestController] Finished loading pending approvals');
    }
  }

  Future<void> loadDepartmentRequests(String departmentId) async {
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _requestService.getDepartmentRequests(departmentId);
      vehicleRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStageSpecificRequests(String workflowStage) async {
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _requestService.getVehicleRequests(
        workflowStage: workflowStage,
      );
      vehicleRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRequest(String id) async {
    isLoading.value = true;
    try {
      final request = await _requestService.getVehicleRequest(id);
      selectedRequest.value = request;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createVehicleRequest(Map<String, dynamic> data) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _requestService.createVehicleRequest(data);
      if (result['success'] == true) {
        await loadVehicleRequests();
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to create request';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> deleteAllRequests() async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _requestService.deleteAllRequests();
      if (result['success'] == true) {
        // Clear local state immediately
        vehicleRequests.clear();
        selectedRequest.value = null;
        
        // Reload to ensure sync
        await loadVehicleRequests();
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to delete requests';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> approveRequest(String id, {String? comment, bool reloadPending = false}) async {
    isLoading.value = true;
    try {
      final result = await _requestService.approveRequest(id, comment);
      if (result['success'] == true) {
        await loadRequest(id);
        // Reload pending approvals if requested, otherwise reload all requests
        if (reloadPending) {
          await loadPendingApprovals();
        } else {
          await loadVehicleRequests();
        }
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to approve request';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> rejectRequest(String id, String comment) async {
    isLoading.value = true;
    try {
      final result = await _requestService.rejectRequest(id, comment);
      if (result['success'] == true) {
        await loadRequest(id);
        await loadVehicleRequests();
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to reject request';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> correctRequest(
    String id,
    String comment, {
    String? tripDate,
    String? tripTime,
    String? destination,
    String? purpose,
  }) async {
    isLoading.value = true;
    try {
      final result = await _requestService.correctRequest(
        id,
        comment,
        tripDate: tripDate,
        tripTime: tripTime,
        destination: destination,
        purpose: purpose,
      );
      if (result['success'] == true) {
        await loadRequest(id);
        await loadVehicleRequests();
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to correct request';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<void> loadRequestHistory({
    String? status,
    String? action,
    String? workflowStage,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    isLoadingHistory.value = true;
    error.value = '';

    try {
      final requests = await _requestService.getRequestHistory(
        status: status,
        action: action,
        workflowStage: workflowStage,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      historyRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingHistory.value = false;
    }
  }
}

