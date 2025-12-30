import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/request_card.dart';
import 'request_detail_page.dart';
import 'ict_request_detail_page.dart';
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
import '../widgets/status_badge.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/services/permission_service.dart';

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
    // Ensure controllers are initialized
    vehicleController = Get.put(RequestController());
    ictController = Get.put(ICTRequestController());
    storeController = Get.put(StoreRequestController());
    
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
      print('[RequestListPage] Loading My Requests for user: ${user.id}');
      await vehicleController.loadVehicleRequests(
        myRequests: true,
        pending: false,
      );
      print('[RequestListPage] Vehicle requests loaded: ${vehicleController.vehicleRequests.length}');
      
      await ictController.loadICTRequests(
        myRequests: true,
        pending: false,
      );
      print('[RequestListPage] ICT requests loaded: ${ictController.ictRequests.length}');
      
      await storeController.loadStoreRequests(
        myRequests: true,
        pending: false,
      );
      print('[RequestListPage] Store requests loaded: ${storeController.storeRequests.length}');
      
      // Debug: Print all requester IDs from loaded requests
      print('[RequestListPage] User ID: ${user.id}');
      if (ictController.ictRequests.isNotEmpty) {
        print('[RequestListPage] ICT Request requester IDs: ${ictController.ictRequests.map((r) => r.requesterId).toList()}');
      }
      if (storeController.storeRequests.isNotEmpty) {
        print('[RequestListPage] Store Request requester IDs: ${storeController.storeRequests.map((r) => r.requesterId).toList()}');
      }
      if (vehicleController.vehicleRequests.isNotEmpty) {
        print('[RequestListPage] Vehicle Request requester IDs: ${vehicleController.vehicleRequests.map((r) => r.requesterId).toList()}');
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

    // Only load request types the user can see
    if (visibleTypes.contains(RequestType.vehicle)) {
      await vehicleController.loadVehicleRequests(
        myRequests: false,
        pending: widget.pending || shouldShowPending,
      );
    }
    if (visibleTypes.contains(RequestType.ict)) {
      await ictController.loadICTRequests(
        myRequests: false,
        pending: widget.pending || shouldShowPending,
      );
    }
    if (visibleTypes.contains(RequestType.store)) {
      await storeController.loadStoreRequests(
        myRequests: false,
        pending: widget.pending || shouldShowPending,
      );
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
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
            // Request List
            Expanded(
              child: Obx(
                () {
                  // Cache observable values first to avoid multiple accesses
                  final isLoading = vehicleController.isLoading.value ||
                      ictController.isLoading.value ||
                      storeController.isLoading.value;
                  
                  final vehicleError = vehicleController.error.value;
                  final ictError = ictController.error.value;
                  final storeError = storeController.error.value;
                  final error = vehicleError.isNotEmpty 
                      ? vehicleError 
                      : (ictError.isNotEmpty ? ictError : storeError);
                  
                  // Safely compute requests - these methods only read from observables
                  List<dynamic> allRequests = [];
                  List<dynamic> filteredRequests = [];
                  
                  try {
                    allRequests = _computeAllRequests();
                    filteredRequests = _computeFilteredRequests(allRequests);
                  } catch (e) {
                    print('Error computing requests: $e');
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

                  if (error.isNotEmpty) {
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

                  return RefreshIndicator(
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    if (request is VehicleRequestModel) {
      return RequestCard(
        request: request,
        source: widget.myRequests
            ? RequestDetailSource.myRequests
            : widget.pending
                ? RequestDetailSource.pendingApprovals
                : RequestDetailSource.other,
      );
    } else if (request is ICTRequestModel) {
      return _buildICTRequestCard(request);
    } else if (request is StoreRequestModel) {
      return _buildStoreRequestCard(request);
    }
    return const SizedBox.shrink();
  }

  Widget _buildICTRequestCard(ICTRequestModel request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark 
              ? AppColors.darkBorderDefined.withOpacity(0.5)
              : AppColors.border.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => ICTRequestDetailPage(requestId: request.id));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppIcons.ict,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      size: AppIcons.sizeSmall,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ICT Request',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusBadge(
                          status: request.status,
                          workflowStage: request.workflowStage,
                          isPartiallyFulfilled: request.isPartiallyFulfilled(),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${request.items.length} ${request.items.length == 1 ? 'item' : 'items'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Created: ${DateFormat('MMM dd, yyyy').format(request.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.textSecondary,
                ),
              ),
              // Repeat Request button (only show in My Requests)
              if (widget.myRequests) ...[
                const SizedBox(height: AppConstants.spacingM),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _repeatICTRequest(request),
                    icon: Icon(
                      Icons.repeat,
                      size: 18,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                    label: Text(
                      'Repeat Request',
                      style: TextStyle(
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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

  Widget _buildStoreRequestCard(StoreRequestModel request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark 
              ? AppColors.darkBorderDefined.withOpacity(0.5)
              : AppColors.border.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed('/store/requests/${request.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.secondaryLight : AppColors.secondary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppIcons.store,
                      color: isDark ? AppColors.secondaryLight : AppColors.secondary,
                      size: AppIcons.sizeSmall,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Store Request',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusBadge(
                          status: request.status,
                          workflowStage: request.workflowStage,
                          isPartiallyFulfilled: request.isPartiallyFulfilled(),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${request.items.length} ${request.items.length == 1 ? 'item' : 'items'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Created: ${DateFormat('MMM dd, yyyy').format(request.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.textSecondary,
                ),
              ),
              // Repeat Request button (only show in My Requests)
              if (widget.myRequests) ...[
                const SizedBox(height: AppConstants.spacingM),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _repeatStoreRequest(request),
                    icon: Icon(
                      Icons.repeat,
                      size: 18,
                      color: isDark ? AppColors.secondaryLight : AppColors.secondary,
                    ),
                    label: Text(
                      'Repeat Request',
                      style: TextStyle(
                        color: isDark ? AppColors.secondaryLight : AppColors.secondary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? AppColors.secondaryLight : AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
}
