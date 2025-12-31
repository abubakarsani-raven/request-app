import 'package:get/get.dart';
import '../../data/services/store_request_service.dart';
import '../../data/models/store_request_model.dart';
import '../../data/models/request_model.dart';
import '../../data/models/inventory_item_model.dart';
import 'auth_controller.dart';
import '../../../core/utils/id_utils.dart';

class StoreRequestController extends GetxController {
  final StoreRequestService _storeService = Get.find<StoreRequestService>();

  final RxList<StoreRequestModel> storeRequests = <StoreRequestModel>[].obs;
  final RxList<StoreRequestModel> historyRequests = <StoreRequestModel>[].obs;
  final Rx<StoreRequestModel?> selectedRequest = Rx<StoreRequestModel?>(null);
  final RxList<InventoryItemModel> inventoryItems = <InventoryItemModel>[].obs;
  final RxList<String> categories = <String>[].obs;
  final RxString selectedCategory = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxString error = ''.obs;

  // Operation-specific loading flags
  final RxBool isApproving = false.obs;
  final RxBool isRejecting = false.obs;
  final RxBool isFulfilling = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isReloading = false.obs;
  final RxBool isLoadingInventory = false.obs;
  final RxBool isLoadingPending = false.obs;
  final RxBool isLoadingDepartment = false.obs;
  final RxBool isLoadingStage = false.obs;
  final RxBool isLoadingFulfillment = false.obs;

  // Get count of pending approvals (requests that are pending and awaiting approval)
  int get pendingApprovalsCount {
    return storeRequests.where((request) {
      return request.status == RequestStatus.pending ||
          (request.status != RequestStatus.approved &&
              request.status != RequestStatus.rejected &&
              request.status != RequestStatus.fulfilled &&
              request.status != RequestStatus.completed);
    }).length;
  }

  @override
  void onInit() {
    super.onInit();
    loadInventoryItems();
    loadStoreRequests();
  }

  Future<void> loadInventoryItems({String? category}) async {
    isLoadingInventory.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final items = await _storeService.getInventoryItems(category: category);
      inventoryItems.value = items;

      // Extract unique categories
      final uniqueCategories = items.map((item) => item.category).toSet().toList();
      categories.value = uniqueCategories;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingInventory.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadStoreRequests({bool myRequests = false, bool pending = false}) async {
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _storeService.getStoreRequests(
        myRequests: myRequests,
        pending: pending,
      );
      
      // IMPORTANT: When myRequests is true, we should only see requests where
      // the user is the requester. The backend filters by requesterId only.
      // Add defensive filtering client-side as a safeguard.
      if (myRequests) {
        final authController = Get.find<AuthController>();
        final currentUserId = authController.user.value?.id;
        if (currentUserId != null) {
          storeRequests.value = requests.where((request) {
            // Only include requests where the user is the requester
            // Handle both string and ObjectId formats using utility
            return IdUtils.areIdsEqual(request.requesterId, currentUserId);
          }).toList();
        } else {
          storeRequests.value = requests;
        }
      } else {
        storeRequests.value = requests;
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
      final requests = await _storeService.getPendingApprovals();
      storeRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingPending.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadDepartmentRequests(String departmentId) async {
    isLoadingDepartment.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _storeService.getDepartmentRequests(departmentId);
      storeRequests.value = requests;
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
      final requests = await _storeService.getStoreRequests(
        workflowStage: workflowStage,
      );
      storeRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingStage.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadFulfillmentQueue() async {
    isLoadingFulfillment.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _storeService.getStoreRequests(
        workflowStage: 'SO_REVIEW',
      );
      storeRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingFulfillment.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadRequest(String id) async {
    isReloading.value = true;
    isLoading.value = true;
    try {
      final request = await _storeService.getStoreRequest(id);
      selectedRequest.value = request;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isReloading.value = false;
      isLoading.value = false;
    }
  }

  Future<bool> createStoreRequest(List<Map<String, dynamic>> items) async {
    isCreating.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _storeService.createStoreRequest(items);
      if (result['success'] == true) {
        await loadStoreRequests();
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

  Future<bool> approveRequest(String id, {String? comment, bool reloadPending = false}) async {
    isApproving.value = true;
    isLoading.value = true;
    try {
      final result = await _storeService.approveRequest(id, comment: comment);
      if (result['success'] == true) {
        isReloading.value = true;
        await loadRequest(id);
        // Reload pending approvals if requested, otherwise reload all requests
        if (reloadPending) {
          await loadPendingApprovals();
        } else {
          await loadStoreRequests();
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
      final result = await _storeService.rejectRequest(id, comment);
      if (result['success'] == true) {
        isReloading.value = true;
        await loadRequest(id);
        await loadStoreRequests();
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

  Future<bool> fulfillRequest(String id, Map<String, int> fulfillmentData) async {
    isFulfilling.value = true;
    isLoading.value = true;
    try {
      final result = await _storeService.fulfillRequest(id, fulfillmentData);
      if (result['success'] == true) {
        isReloading.value = true;
        await loadRequest(id);
        await loadStoreRequests();
        isReloading.value = false;
        isFulfilling.value = false;
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to fulfill request';
        isFulfilling.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isFulfilling.value = false;
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
      final requests = await _storeService.getRequestHistory(
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

