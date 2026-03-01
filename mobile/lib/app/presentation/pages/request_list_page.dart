import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/unified_request_card.dart';
import 'request_detail_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_widget.dart';
import '../widgets/app_drawer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/bottom_sheets/request_filter_bottom_sheet.dart';
import '../widgets/bottom_sheets/create_ict_request_bottom_sheet.dart';
import '../widgets/bottom_sheets/create_store_request_bottom_sheet.dart';
import '../../data/models/request_model.dart';
import '../../data/models/ict_request_model.dart';
import '../../data/models/store_request_model.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/app_logger.dart';

class RequestListPage extends StatefulWidget {
  final bool myRequests;
  final bool pending;

  const RequestListPage({
    Key? key,
    this.myRequests = false,
    this.pending = false,
  }) : super(key: key);

  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  late final RequestController vehicleController;
  late final ICTRequestController ictController;
  late final StoreRequestController storeController;
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();
  final PermissionService permissionService = Get.find<PermissionService>();
  final AuthController authController = Get.find<AuthController>();
  // IMPORTANT: For "My Requests", filter should default to 'all' to show ALL statuses
  // Users should see all their requests (pending, approved, completed, fulfilled, etc.)
  String _selectedFilter = 'all'; // all, pending, approved, rejected, completed

  @override
  void initState() {
    super.initState();
    // Use Get.find() - controllers already registered in InitialBinding
    vehicleController = Get.find<RequestController>();
    ictController = Get.find<ICTRequestController>();
    storeController = Get.find<StoreRequestController>();
    
    // IMPORTANT: For "My Requests", ensure filter is set to 'all' to show all statuses
    // Users should see all their requests regardless of status (pending, approved, completed, etc.)
    if (widget.myRequests) {
      _selectedFilter = 'all';
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllRequests();
    });
  }

  Future<void> _loadAllRequests() async {
    final user = authController.user.value;
    if (user == null) return;

    // For "My Requests", always load ALL request types (ICT, Store, Transport)
    // regardless of user role - users should see all requests they created
    if (widget.myRequests) {
      try {
        await Future.wait([
          vehicleController.loadVehicleRequestsCacheFirst(
            myRequests: true,
            pending: false,
          ),
          ictController.loadICTRequestsCacheFirst(
            myRequests: true,
            pending: false,
          ),
          storeController.loadStoreRequestsCacheFirst(
            myRequests: true,
            pending: false,
          ),
        ]);
      } catch (e) {
        await vehicleController.loadVehicleRequestsCacheFirst(myRequests: true, pending: false);
        await ictController.loadICTRequestsCacheFirst(myRequests: true, pending: false);
        await storeController.loadStoreRequestsCacheFirst(myRequests: true, pending: false);
      }
      return;
    }

    // For "All Requests" and "Pending Approvals", use role-based filtering
    final visibleTypes = permissionService.getVisibleRequestTypes(user);
    final roles = user.roles;
    final isRoleBasedUser = roles.any((role) => 
        role.toUpperCase() == 'DDICT' ||
        role.toUpperCase() == 'TO' ||
        role.toUpperCase() == 'SO' ||
        role.toUpperCase() == 'DGS' ||
        role.toUpperCase() == 'DDGS' ||
        role.toUpperCase() == 'ADGS');
    
    // If showing "All Requests" for a role-based user, show pending approvals
    // (requests they're involved in) instead of all requests
    final shouldShowPending = !widget.pending && isRoleBasedUser;

    // OPTIMIZED: Load all visible request types in parallel (much faster than sequential)
    final loadTasks = <Future<void>>[];
    final pendingParam = widget.pending || shouldShowPending;
    
    if (visibleTypes.contains(RequestType.vehicle)) {
      loadTasks.add(vehicleController.loadVehicleRequestsCacheFirst(
        myRequests: false,
        pending: pendingParam,
      ));
    }
    if (visibleTypes.contains(RequestType.ict)) {
      loadTasks.add(ictController.loadICTRequestsCacheFirst(
        myRequests: false,
        pending: pendingParam,
      ));
    }
    if (visibleTypes.contains(RequestType.store)) {
      loadTasks.add(storeController.loadStoreRequestsCacheFirst(
        myRequests: false,
        pending: pendingParam,
      ));
    }
    
    // Execute all loads in parallel
    if (loadTasks.isNotEmpty) {
      await Future.wait(loadTasks);
    }
  }

  List<dynamic> _computeAllRequests() {
    final allRequests = <dynamic>[];
    final user = authController.user.value;
    
    if (user == null) return [];
    
    // Get visible request types based on user role
    final visibleTypes = permissionService.getVisibleRequestTypes(user);
    
    // IMPORTANT: When myRequests is true, only show requests where the user is the requester.
    // For "My Requests", show ALL request types (ICT, Store, Transport) regardless of role
    // The controllers already filter by requesterId when myRequests=true, so we can use them directly
    if (widget.myRequests) {
      // Controllers already filtered by requesterId, so add all requests from controllers
      allRequests.addAll(vehicleController.vehicleRequests);
      allRequests.addAll(ictController.ictRequests);
      allRequests.addAll(storeController.storeRequests);
    } else {
      // For "All Requests" or "Pending Approvals", show only request types user can see
      // DDICT should only see ICT requests, TO should only see vehicle requests, etc.
      if (visibleTypes.contains(RequestType.vehicle)) {
        allRequests.addAll(vehicleController.vehicleRequests);
      }
      if (visibleTypes.contains(RequestType.ict)) {
        allRequests.addAll(ictController.ictRequests);
      }
      if (visibleTypes.contains(RequestType.store)) {
        allRequests.addAll(storeController.storeRequests);
      }
    }
    
    // Sort by creation date (newest first)
    allRequests.sort((a, b) {
      DateTime aDate, bDate;
      if (a is VehicleRequestModel) {
        aDate = a.createdAt;
      } else if (a is ICTRequestModel) {
        aDate = a.createdAt;
      } else if (a is StoreRequestModel) {
        aDate = a.createdAt;
      } else {
        return 0;
      }
      
      if (b is VehicleRequestModel) {
        bDate = b.createdAt;
      } else if (b is ICTRequestModel) {
        bDate = b.createdAt;
      } else if (b is StoreRequestModel) {
        bDate = b.createdAt;
      } else {
        return 0;
      }
      
      return bDate.compareTo(aDate);
    });
    
    return allRequests;
  }

  List<dynamic> _computeFilteredRequests(List<dynamic> allRequests) {
    if (_selectedFilter == 'all') {
      return allRequests;
    }
    
    return allRequests.where((request) {
      RequestStatus status;
      if (request is VehicleRequestModel) {
        status = request.status;
      } else if (request is ICTRequestModel) {
        status = request.status;
      } else if (request is StoreRequestModel) {
        status = request.status;
      } else {
        return false;
      }
      
      switch (_selectedFilter) {
        case 'pending':
          return status == RequestStatus.pending;
        case 'approved':
          return status == RequestStatus.approved;
        case 'rejected':
          return status == RequestStatus.rejected;
        case 'completed':
          return status == RequestStatus.completed || status == RequestStatus.fulfilled;
        default:
          return true;
      }
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Modern App Bar
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: AppConstants.spacingL,
                right: AppConstants.spacingL,
                bottom: AppConstants.spacingM,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark 
                        ? AppColors.darkBorderDefined.withOpacity(0.5)
                        : AppColors.border.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          AppIcons.back,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () => Get.back(),
                      ),
                      Expanded(
                        child: Text(
                          widget.pending
                              ? 'Pending Approvals'
                              : widget.myRequests
                                  ? 'My Requests'
                                  : 'All Requests',
                          style: AppTextStyles.h3.copyWith(
                            fontSize: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          AppIcons.search,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          // TODO: Implement search
                          CustomToast.info('Search feature coming soon');
                        },
                      ),
                      if (!widget.pending)
                        IconButton(
                          icon: Stack(
                            children: [
                              Icon(
                                AppIcons.filter,
                                color: theme.colorScheme.onSurface,
                              ),
                              if (_selectedFilter != 'all')
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 8,
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () {
                            RequestFilterBottomSheet.show(
                              context: context,
                              initialStatus: _selectedFilter != 'all' ? _selectedFilter : null,
                              onApply: (status, type, dateRange) {
                                setState(() {
                                  _selectedFilter = status ?? 'all';
                                });
                              },
                              onClear: () {
                                setState(() {
                                  _selectedFilter = 'all';
                                });
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (Get.isRegistered<ConnectivityService>())
              Obx(() {
                final connectivity = Get.find<ConnectivityService>();
                if (connectivity.isOnline.value) return const SizedBox.shrink();
                return Material(
                  color: AppColors.warning.withOpacity(0.2),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off, size: 20, color: AppColors.warning),
                          SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: Text(
                              'You\'re offline. Showing saved data.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            // Request List
            Expanded(
              child: Obx(
                () {
                  // Cache observable values first to avoid multiple accesses
                  final isLoading = vehicleController.isLoading.value ||
                      ictController.isLoading.value ||
                      storeController.isLoading.value;
                  final isRefreshing = vehicleController.isRefreshing.value ||
                      ictController.isRefreshing.value ||
                      storeController.isRefreshing.value;
                  final isStale = vehicleController.isStale.value ||
                      ictController.isStale.value ||
                      storeController.isStale.value;
                  final vehicleError = vehicleController.error.value;
                  final ictError = ictController.error.value;
                  final storeError = storeController.error.value;
                  final error = vehicleError.isNotEmpty
                      ? vehicleError
                      : (ictError.isNotEmpty ? ictError : storeError);
                  List<dynamic> allRequests = [];
                  List<dynamic> filteredRequests = [];
                  try {
                    allRequests = _computeAllRequests();
                    filteredRequests = _computeFilteredRequests(allRequests);
                  } catch (e) {
                    AppLogger.error('Error computing requests', e, null, 'RequestList');
                    return AppErrorWidget(
                      title: 'Error Loading Requests',
                      message: 'An error occurred while loading requests',
                      type: ErrorType.unknown,
                      onRetry: _loadAllRequests,
                    );
                  }
                  if (isLoading && allRequests.isEmpty) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                        child: const SkeletonCard(),
                      ),
                    );
                  }
                  if (error.isNotEmpty && allRequests.isEmpty) {
                    return AppErrorWidget(
                      title: 'Error Loading Requests',
                      message: error,
                      type: ErrorType.network,
                      onRetry: _loadAllRequests,
                    );
                  }

                  if (filteredRequests.isEmpty) {
                    return EmptyState(
                      title: 'No Requests Found',
                      message: widget.pending
                          ? 'You have no pending approvals'
                          : widget.myRequests
                              ? 'You haven\'t created any requests yet'
                              : _selectedFilter != 'all'
                                  ? 'No ${_selectedFilter} requests found'
                                  : 'No requests available',
                      type: EmptyStateType.noData,
                      action: widget.myRequests
                          ? ElevatedButton.icon(
                              onPressed: () => Get.toNamed('/create-request',
                                  parameters: {'type': 'vehicle'}),
                              icon: Icon(AppIcons.add),
                              label: const Text('Create Request'),
                            )
                          : null,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isStale)
                        Material(
                          color: AppColors.warning.withOpacity(0.15),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingM,
                              vertical: AppConstants.spacingS,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: AppColors.warning),
                                SizedBox(width: AppConstants.spacingS),
                                Expanded(
                                  child: Text(
                                    'Couldn\'t update. Showing last saved data.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loadAllRequests,
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isRefreshing)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: AppConstants.spacingS),
                              Text(
                                'Updating…',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadAllRequests,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppConstants.spacingM),
                            itemCount: filteredRequests.length,
                            itemBuilder: (context, index) {
                              final request = filteredRequests[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                                child: _buildRequestCard(request),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static RequestType _typeOf(dynamic request) {
    if (request is VehicleRequestModel) return RequestType.vehicle;
    if (request is ICTRequestModel) return RequestType.ict;
    if (request is StoreRequestModel) return RequestType.store;
    return RequestType.vehicle;
  }

  Widget _buildRequestCard(dynamic request) {
    final type = _typeOf(request);
    final source = widget.myRequests
        ? RequestDetailSource.myRequests
        : widget.pending
            ? RequestDetailSource.pendingApprovals
            : RequestDetailSource.other;
    VoidCallback? onRepeat;
    if (widget.myRequests) {
      if (request is ICTRequestModel) {
        onRepeat = () => _repeatICTRequest(request);
      } else if (request is StoreRequestModel) {
        onRepeat = () => _repeatStoreRequest(request);
      }
    }
    return UnifiedRequestCard(
      type: type,
      request: request,
      source: source,
      onRepeat: onRepeat,
    );
  }

  void _repeatICTRequest(ICTRequestModel request) {
    // Extract items from the request
    final items = request.items.map((item) => {
      'itemId': item.itemId,
      'quantity': item.requestedQuantity, // Use original requested quantity
    }).toList();
    
    // Show create ICT request bottom sheet with pre-filled items
    CreateICTRequestBottomSheet.showWithItems(context, items);
  }

  void _repeatStoreRequest(StoreRequestModel request) {
    // Extract items from the request
    final items = request.items.map((item) => {
      'itemId': item.itemId,
      'quantity': item.requestedQuantity, // Use original requested quantity
    }).toList();
    
    // Show create Store request bottom sheet with pre-filled items
    CreateStoreRequestBottomSheet.showWithItems(context, items);
  }

  Future<void> _showCancelConfirmationDialog(
    BuildContext context,
    dynamic request,
    RequestType type,
  ) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
        title: Text(
          'Cancel Request',
          style: AppTextStyles.h4.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this request?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Request Type: ${type == RequestType.vehicle ? 'Vehicle' : type == RequestType.ict ? 'ICT' : 'Store'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Created: ${DateFormat('MMM dd, yyyy').format(request.createdAt)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                labelStyle: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                hintText: 'Enter cancellation reason...',
                hintStyle: TextStyle(
                  color: isDark 
                      ? AppColors.darkTextSecondary.withOpacity(0.5)
                      : AppColors.textSecondary.withOpacity(0.5),
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceLight : AppColors.surfaceElevation1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark 
                        ? AppColors.darkBorderDefined.withOpacity(0.3)
                        : AppColors.border.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark 
                        ? AppColors.darkBorderDefined.withOpacity(0.3)
                        : AppColors.border.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep Request',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _cancelRequest(request, type, reasonController.text.trim());
    }

    reasonController.dispose();
  }

  Future<void> _cancelRequest(dynamic request, RequestType type, String reason) async {
    try {
      bool success = false;

      if (type == RequestType.vehicle) {
        success = await vehicleController.cancelRequest(request.id, reason);
      } else if (type == RequestType.ict) {
        success = await ictController.cancelRequest(request.id, reason);
      } else if (type == RequestType.store) {
        success = await storeController.cancelRequest(request.id, reason);
      }

      if (success) {
        CustomToast.success('Request cancelled successfully');
        // Reload requests
        await _loadAllRequests();
      } else {
        final errorMessage = type == RequestType.vehicle
            ? vehicleController.error.value
            : type == RequestType.ict
                ? ictController.error.value
                : storeController.error.value;
        CustomToast.error(errorMessage.isNotEmpty ? errorMessage : 'Failed to cancel request');
      }
    } catch (e) {
      CustomToast.error('Error cancelling request: ${e.toString()}');
    }
  }
}
