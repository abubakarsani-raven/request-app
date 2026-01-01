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

  // Operation-specific loading flags
  final RxBool isApproving = false.obs;
  final RxBool isRejecting = false.obs;
  final RxBool isCancelling = false.obs;
  final RxBool isFulfilling = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isReloading = false.obs;
  final RxBool isLoadingCatalog = false.obs;
  final RxBool isLoadingPending = false.obs;
  final RxBool isLoadingDepartment = false.obs;
  final RxBool isLoadingStage = false.obs;
  final RxBool isLoadingFulfillment = false.obs;
  final RxBool isLoadingUnfulfilled = false.obs;
  final RxBool isNotifying = false.obs;

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
    // Load catalog items on init (needed for create request page)
    loadCatalogItems();
    // Don't load requests on init - load only when needed (lazy loading)
  }

  Future<void> loadCatalogItems({String? category}) async {
    isLoadingCatalog.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      // Try backend filtering first
      List<CatalogItemModel> items;
      try {
        items = await _ictService.getCatalogItems(category: category);
        print('[ICT Controller] Loaded ${items.length} catalog items${category != null ? ' for category: $category' : ''}');
      } catch (e) {
        print('[ICT Controller] Error loading catalog items with category filter: $e');
        // Fallback: load all items and filter client-side
        try {
          final allItems = await _ictService.getCatalogItems();
          print('[ICT Controller] Loaded ${allItems.length} total catalog items');
          if (category != null && category.isNotEmpty) {
            items = allItems.where((item) => item.category == category).toList();
            print('[ICT Controller] Filtered to ${items.length} items for category: $category');
          } else {
            items = allItems;
          }
        } catch (fallbackError) {
          print('[ICT Controller] Error in fallback loading: $fallbackError');
          error.value = 'Failed to load catalog items: ${fallbackError.toString()}';
          catalogItems.value = [];
          return;
        }
      }

      if (items.isEmpty) {
        print('[ICT Controller] Warning: No catalog items found${category != null ? ' for category: $category' : ''}');
      }

      catalogItems.value = items;

      // Extract unique categories (load all items for category list)
      if (categories.isEmpty) {
        try {
          final allItems = await _ictService.getCatalogItems();
          final uniqueCategories = allItems.map((item) => item.category).where((cat) => cat.isNotEmpty).toSet().toList()..sort();
          categories.value = uniqueCategories;
          print('[ICT Controller] Found ${uniqueCategories.length} categories: $uniqueCategories');
        } catch (e) {
          print('[ICT Controller] Error loading categories: $e');
          // Don't fail if categories can't be loaded, just use empty list
        }
      }
    } catch (e) {
      print('[ICT Controller] Unexpected error in loadCatalogItems: $e');
      error.value = e.toString();
      catalogItems.value = [];
    } finally {
      isLoadingCatalog.value = false;
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
    isLoadingPending.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final requests = await _ictService.getPendingApprovals();
      ictRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingPending.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadDepartmentRequests(String departmentId) async {
    isLoadingDepartment.value = true;
    // Use specific flag instead of generic isLoading to avoid conflicts
    error.value = '';

    try {
      final requests = await _ictService.getDepartmentRequests(departmentId);
      ictRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingDepartment.value = false;
    }
  }

  Future<void> loadStageSpecificRequests(String workflowStage) async {
    isLoadingStage.value = true;
    // Use specific flag instead of generic isLoading to avoid conflicts
    error.value = '';

    try {
      final requests = await _ictService.getICTRequests(
        workflowStage: workflowStage,
      );
      ictRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingStage.value = false;
    }
  }

  Future<void> loadFulfillmentQueue() async {
    isLoadingFulfillment.value = true;
    // Use specific flag instead of generic isLoading to avoid conflicts
    error.value = '';

    try {
      final requests = await _ictService.getICTRequests(
        workflowStage: 'SO_REVIEW',
      );
      ictRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingFulfillment.value = false;
    }
  }

  Future<void> loadUnfulfilledRequests() async {
    isLoadingUnfulfilled.value = true;
    // Use specific flag instead of generic isLoading to avoid conflicts
    error.value = '';

    try {
      final requests = await _ictService.getUnfulfilledRequests();
      unfulfilledRequests.value = requests;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingUnfulfilled.value = false;
    }
  }

  Future<void> loadRequest(String id) async {
    isReloading.value = true;
    isLoading.value = true;
    try {
      final request = await _ictService.getICTRequest(id);
      selectedRequest.value = request;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isReloading.value = false;
      isLoading.value = false;
    }
  }

  Future<bool> createICTRequest(List<Map<String, dynamic>> items, {String? notes}) async {
    isCreating.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _ictService.createICTRequest(items, notes: notes);
      if (result['success'] == true) {
        await loadICTRequests();
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
      final result = await _ictService.approveRequest(id, comment: comment);
      if (result['success'] == true) {
        isReloading.value = true;
        await loadRequest(id);
        // Reload pending approvals if requested, otherwise reload all requests
        if (reloadPending) {
          await loadPendingApprovals();
        } else {
          await loadICTRequests();
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
      final result = await _ictService.rejectRequest(id, comment);
      if (result['success'] == true) {
        isReloading.value = true;
        await loadRequest(id);
        await loadICTRequests();
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

  Future<bool> cancelRequest(String id, String reason) async {
    isCancelling.value = true;
    isLoading.value = true;
    try {
      final result = await _ictService.cancelRequest(id, reason);
      if (result['success'] == true) {
        isReloading.value = true;
        await loadRequest(id);
        await loadICTRequests();
        isReloading.value = false;
        isCancelling.value = false;
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to cancel request';
        isCancelling.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isCancelling.value = false;
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> fulfillRequest(String id, Map<String, int> fulfillmentData) async {
    isFulfilling.value = true;
    isLoading.value = true;
    try {
      final result = await _ictService.fulfillRequest(id, fulfillmentData);
      if (result['success'] == true) {
        isReloading.value = true;
        await loadRequest(id);
        await loadICTRequests();
        await loadUnfulfilledRequests();
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

  Future<bool> notifyRequester(String id, {String? message}) async {
    isNotifying.value = true;
    isLoading.value = true;
    try {
      final result = await _ictService.notifyRequester(id, message: message);
      if (result['success'] == true) {
        isNotifying.value = false;
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to notify requester';
        isNotifying.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isNotifying.value = false;
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> updateRequestItems(String id, Map<String, int> items) async {
    isUpdating.value = true;
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
        isReloading.value = true;
        try {
          await loadRequest(id);
          await loadICTRequests();
        } finally {
          isReloading.value = false;
        }
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to update request items';
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      // Always clear loading flags
      isUpdating.value = false;
      isLoading.value = false;
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

