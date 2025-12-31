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

  // Operation-specific loading flags
  final RxBool isApproving = false.obs;
  final RxBool isRejecting = false.obs;
  final RxBool isAssigning = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isReloading = false.obs;
  final RxBool isLoadingPending = false.obs;
  final RxBool isLoadingDepartment = false.obs;
  final RxBool isLoadingStage = false.obs;
  final RxBool isDeleting = false.obs;

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
    isLoadingPending.value = true;
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
      isLoadingPending.value = false;
      isLoading.value = false;
      print('🏁 [RequestController] Finished loading pending approvals');
    }
  }

  Future<void> loadDepartmentRequests(String departmentId) async {
    isLoadingDepartment.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _requestService.getDepartmentRequests(departmentId);
      vehicleRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingDepartment.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadStageSpecificRequests(String workflowStage) async {
    isLoadingStage.value = true;
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
      isLoadingStage.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadRequest(String id) async {
    isReloading.value = true;
    isLoading.value = true;
    try {
      final request = await _requestService.getVehicleRequest(id);
      selectedRequest.value = request;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isReloading.value = false;
      isLoading.value = false;
    }
  }

  Future<bool> createVehicleRequest(Map<String, dynamic> data) async {
    isCreating.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _requestService.createVehicleRequest(data);
      if (result['success'] == true) {
        await loadVehicleRequests();
        isCreating.value = false;
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to create request';
        isCreating.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isCreating.value = false;
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> deleteAllRequests() async {
    isDeleting.value = true;
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
        isDeleting.value = false;
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to delete requests';
        isDeleting.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isDeleting.value = false;
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> approveRequest(String id, {String? comment, bool reloadPending = false}) async {
    isApproving.value = true;
    isLoading.value = true;
    try {
      final result = await _requestService.approveRequest(id, comment);
      if (result['success'] == true) {
        isReloading.value = true;
        await loadRequest(id);
        // Reload pending approvals if requested, otherwise reload all requests
        if (reloadPending) {
          await loadPendingApprovals();
        } else {
          await loadVehicleRequests();
        }
        isReloading.value = false;
        isApproving.value = false;
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to approve request';
        isApproving.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isApproving.value = false;
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> rejectRequest(String id, String comment) async {
    isRejecting.value = true;
    isLoading.value = true;
    try {
      final result = await _requestService.rejectRequest(id, comment);
      if (result['success'] == true) {
        isReloading.value = true;
        await loadRequest(id);
        await loadVehicleRequests();
        isReloading.value = false;
        isRejecting.value = false;
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to reject request';
        isRejecting.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isRejecting.value = false;
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
    isUpdating.value = true;
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
        isReloading.value = true;
        await loadRequest(id);
        await loadVehicleRequests();
        isReloading.value = false;
        isUpdating.value = false;
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to correct request';
        isUpdating.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isUpdating.value = false;
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

