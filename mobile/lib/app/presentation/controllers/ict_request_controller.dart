import 'package:get/get.dart';
import '../../data/services/ict_request_service.dart';
import '../../data/models/ict_request_model.dart';
import '../../data/models/request_model.dart';
import '../../../core/utils/id_utils.dart';
import '../../data/models/catalog_item_model.dart';
import 'auth_controller.dart';

class ICTRequestController extends GetxController {
  final ICTRequestService _ictService = Get.find<ICTRequestService>();

  final RxList<ICTRequestModel> ictRequests = <ICTRequestModel>[].obs;
  final RxList<ICTRequestModel> unfulfilledRequests = <ICTRequestModel>[].obs;
  final RxList<ICTRequestModel> historyRequests = <ICTRequestModel>[].obs;
  final Rx<ICTRequestModel?> selectedRequest = Rx<ICTRequestModel?>(null);
  final RxList<CatalogItemModel> catalogItems = <CatalogItemModel>[].obs;
  final RxList<String> categories = <String>[].obs;
  final RxString selectedCategory = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxString error = ''.obs;

  // Get count of pending approvals (requests that are pending and awaiting approval)
  int get pendingApprovalsCount {
    return ictRequests.where((request) {
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
    loadCatalogItems();
    loadICTRequests();
  }

  Future<void> loadCatalogItems({String? category}) async {
    isLoading.value = true;
    error.value = '';

    try {
      // Try backend filtering first
      List<CatalogItemModel> items;
      try {
        items = await _ictService.getCatalogItems(category: category);
      } catch (e) {
        // Fallback: load all items and filter client-side
        final allItems = await _ictService.getCatalogItems();
        if (category != null && category.isNotEmpty) {
          items = allItems.where((item) => item.category == category).toList();
        } else {
          items = allItems;
        }
      }

      catalogItems.value = items;

      // Extract unique categories (load all items for category list)
      if (categories.isEmpty) {
        final allItems = await _ictService.getCatalogItems();
        final uniqueCategories = allItems.map((item) => item.category).toSet().toList();
        categories.value = uniqueCategories;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadICTRequests({bool myRequests = false, bool pending = false}) async {
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _ictService.getICTRequests(
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
          ictRequests.value = requests.where((request) {
            // Only include requests where the user is the requester
            // Handle both string and ObjectId formats using utility
            return IdUtils.areIdsEqual(request.requesterId, currentUserId);
          }).toList();
        } else {
          ictRequests.value = requests;
        }
      } else {
        ictRequests.value = requests;
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
      final requests = await _ictService.getPendingApprovals();
      ictRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDepartmentRequests(String departmentId) async {
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _ictService.getDepartmentRequests(departmentId);
      ictRequests.value = requests;
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
      final requests = await _ictService.getICTRequests(
        workflowStage: workflowStage,
      );
      ictRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFulfillmentQueue() async {
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _ictService.getICTRequests(
        workflowStage: 'SO_REVIEW',
      );
      ictRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUnfulfilledRequests() async {
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _ictService.getUnfulfilledRequests();
      unfulfilledRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRequest(String id) async {
    isLoading.value = true;
    try {
      final request = await _ictService.getICTRequest(id);
      selectedRequest.value = request;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createICTRequest(List<Map<String, dynamic>> items, {String? notes}) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _ictService.createICTRequest(items, notes: notes);
      if (result['success'] == true) {
        await loadICTRequests();
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

  Future<bool> approveRequest(String id, {String? comment, bool reloadPending = false}) async {
    isLoading.value = true;
    try {
      final result = await _ictService.approveRequest(id, comment: comment);
      if (result['success'] == true) {
        await loadRequest(id);
        // Reload pending approvals if requested, otherwise reload all requests
        if (reloadPending) {
          await loadPendingApprovals();
        } else {
          await loadICTRequests();
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
      final result = await _ictService.rejectRequest(id, comment);
      if (result['success'] == true) {
        await loadRequest(id);
        await loadICTRequests();
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

  Future<bool> fulfillRequest(String id, Map<String, int> fulfillmentData) async {
    isLoading.value = true;
    try {
      final result = await _ictService.fulfillRequest(id, fulfillmentData);
      if (result['success'] == true) {
        await loadRequest(id);
        await loadICTRequests();
        await loadUnfulfilledRequests();
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to fulfill request';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> notifyRequester(String id, {String? message}) async {
    isLoading.value = true;
    try {
      final result = await _ictService.notifyRequester(id, message: message);
      if (result['success'] == true) {
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to notify requester';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> updateRequestItems(String id, Map<String, int> items) async {
    isLoading.value = true;
    try {
      // Convert Map<String, int> to List<Map<String, dynamic>>
      final itemsList = items.entries
          .map((entry) => {
                'itemId': entry.key,
                'quantity': entry.value,
              })
          .toList();
      
      final result = await _ictService.updateRequestItems(id, itemsList);
      if (result['success'] == true) {
        await loadRequest(id);
        await loadICTRequests();
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to update request items';
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
      final requests = await _ictService.getRequestHistory(
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

