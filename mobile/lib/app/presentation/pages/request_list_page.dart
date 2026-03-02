import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/unified_request_card.dart';
import 'request_detail_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_widget.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/bottom_sheets/request_filter_bottom_sheet.dart';
import '../widgets/bottom_sheets/create_ict_request_bottom_sheet.dart';
import '../widgets/bottom_sheets/create_store_request_bottom_sheet.dart';
import '../../data/models/request_model.dart';
import '../../data/models/ict_request_model.dart';
import '../../data/models/store_request_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/app_logger.dart';

class RequestListPage extends StatefulWidget {
  final bool myRequests;
  final bool pending;
  /// When true, show requests the current user has approved (approval history). Used for Approvals tab.
  final bool approvedByMe;
  /// When true, used as tab content in MainShellPage (no drawer, no back in bar).
  final bool inShell;
  /// When in shell: current tab index so this page can reload when it becomes visible.
  final int? currentTabIndex;
  /// When in shell: this tab's index (so we know when we're visible).
  final int? myTabIndex;

  const RequestListPage({
    Key? key,
    this.myRequests = false,
    this.pending = false,
    this.approvedByMe = false,
    this.inShell = false,
    this.currentTabIndex,
    this.myTabIndex,
  }) : super(key: key);

  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  late final RequestController vehicleController;
  late final ICTRequestController ictController;
  late final StoreRequestController storeController;
  final PermissionService permissionService = Get.find<PermissionService>();
  final AuthController authController = Get.find<AuthController>();
  // IMPORTANT: For "My Requests", filter should default to 'all' to show ALL statuses
  // Users should see all their requests (pending, approved, completed, fulfilled, etc.)
  String _selectedFilter = 'all'; // all, pending, approved, rejected, completed
  /// When inShell, toggles between All and My Requests in the tab.
  bool _showMyRequests = false;
  /// Filter by request type: null = all, or 'vehicle', 'ict', 'store'.
  String? _selectedType;
  /// When used as a tab: avoid loading until we're the visible tab.
  bool _wasVisible = false;

  bool get _effectiveMyRequests => widget.myRequests || (widget.inShell && _showMyRequests);

  /// True when this page is used as a tab and we should only load when visible.
  bool get _loadWhenVisible => widget.currentTabIndex != null && widget.myTabIndex != null;

  @override
  void initState() {
    super.initState();
    // Use Get.find() - controllers already registered in InitialBinding
    vehicleController = Get.find<RequestController>();
    ictController = Get.find<ICTRequestController>();
    storeController = Get.find<StoreRequestController>();
    
    // IMPORTANT: For "My Requests", ensure filter is set to 'all' to show all statuses
    if (widget.myRequests) {
      _selectedFilter = 'all';
    }
    
    // When not in tab mode, load once. When in tab mode, load when we become visible (in build).
    if (!_loadWhenVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAllRequests();
      });
    }
  }

  Future<void> _loadAllRequests() async {
    final user = authController.user.value;
    if (user == null) return;

    final showMy = _effectiveMyRequests;

    // For "My Requests", always load ALL request types (ICT, Store, Transport)
    // regardless of user role - users should see all requests they created
    if (showMy) {
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

    // Visibility is by role only (not email): DDICT sees ICT, TO sees vehicle, etc.
    final visibleTypes = permissionService.getVisibleRequestTypes(user);

    // Approvals tab: show requests the user has already approved (approval history).
    if (widget.approvedByMe) {
      final loadTasks = <Future<void>>[];
      if (visibleTypes.contains(RequestType.vehicle)) {
        loadTasks.add(vehicleController.loadVehicleRequestsCacheFirst(
          myRequests: false,
          pending: false,
          approvedByMe: true,
        ));
      }
      if (visibleTypes.contains(RequestType.ict)) {
        loadTasks.add(ictController.loadICTRequestsCacheFirst(
          myRequests: false,
          pending: false,
          approvedByMe: true,
        ));
      }
      if (visibleTypes.contains(RequestType.store)) {
        loadTasks.add(storeController.loadStoreRequestsCacheFirst(
          myRequests: false,
          pending: false,
          approvedByMe: true,
        ));
      }
      if (loadTasks.isNotEmpty) await Future.wait(loadTasks);
      return;
    }

    // Requests tab = all (or my) requests; pending-only view uses pendingParam.
    final pendingParam = widget.pending;

    // OPTIMIZED: Load all visible request types in parallel (much faster than sequential)
    final loadTasks = <Future<void>>[];
    
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
    if (_effectiveMyRequests) {
      // Controllers already filtered by requesterId, so add all requests from controllers
      allRequests.addAll(vehicleController.vehicleRequests);
      allRequests.addAll(ictController.ictRequests);
      allRequests.addAll(storeController.storeRequests);
    } else {
      // For "All Requests" or "Pending Requests", show only request types user can see
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
    List<dynamic> list = allRequests;

    // Filter by type first
    if (_selectedType != null) {
      list = list.where((request) {
        switch (_selectedType!) {
          case 'vehicle':
            return request is VehicleRequestModel;
          case 'ict':
            return request is ICTRequestModel;
          case 'store':
            return request is StoreRequestModel;
          default:
            return true;
        }
      }).toList();
    }

    if (_selectedFilter == 'all') {
      return list;
    }
    
    return list.where((request) {
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


  Widget _buildBody(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      children: [
        // When inShell: bar (title, filter only; no back - user switches tabs)
        // When in AppScaffold: actions are in app bar (filter only)
        if (widget.inShell) ...[
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
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        widget.pending
                            ? 'Approvals'
                            : _effectiveMyRequests
                                ? 'My Requests'
                                : 'All Requests',
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 24,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Stack(
                        children: [
                          Icon(AppIcons.filter, color: theme.colorScheme.onSurface),
                          if (_selectedFilter != 'all' || _selectedType != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () {
                        RequestFilterBottomSheet.show(
                          context: context,
                          initialStatus: _selectedFilter != 'all' ? _selectedFilter : null,
                          initialType: _selectedType,
                          onApply: (status, type, dateRange) {
                            setState(() {
                              _selectedFilter = status ?? 'all';
                              _selectedType = type;
                            });
                          },
                          onClear: () {
                            setState(() {
                              _selectedFilter = 'all';
                              _selectedType = null;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
                if (!widget.pending) ...[
                  const SizedBox(height: AppConstants.spacingS),
                  Row(
                    children: [
                      _ViewChip(
                        label: 'All',
                        selected: !_showMyRequests,
                        onTap: () {
                          setState(() {
                            _showMyRequests = false;
                            _loadAllRequests();
                          });
                        },
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      _ViewChip(
                        label: 'My Requests',
                        selected: _showMyRequests,
                        onTap: () {
                          setState(() {
                            _showMyRequests = true;
                            _loadAllRequests();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Wrap(
                    spacing: AppConstants.spacingS,
                    runSpacing: AppConstants.spacingXS,
                    children: [
                      _TypeChip(
                        label: 'All',
                        selected: _selectedType == null,
                        onTap: () => setState(() => _selectedType = null),
                      ),
                      _TypeChip(
                        label: 'Vehicle',
                        selected: _selectedType == 'vehicle',
                        onTap: () => setState(() => _selectedType = 'vehicle'),
                      ),
                      _TypeChip(
                        label: 'ICT',
                        selected: _selectedType == 'ict',
                        onTap: () => setState(() => _selectedType = 'ict'),
                      ),
                      _TypeChip(
                        label: 'Store',
                        selected: _selectedType == 'store',
                        onTap: () => setState(() => _selectedType = 'store'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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
                    final String message = widget.pending
                        ? 'You have no pending requests'
                        : _effectiveMyRequests
                            ? (_selectedType == 'vehicle'
                                ? 'You have no vehicle requests'
                                : _selectedType == 'ict'
                                    ? 'You have no ICT requests'
                                    : _selectedType == 'store'
                                        ? 'You have no store requests'
                                        : 'You haven\'t created any requests yet')
                            : (_selectedType == 'vehicle'
                                ? 'No vehicle requests'
                                : _selectedType == 'ict'
                                    ? 'No ICT requests'
                                    : _selectedType == 'store'
                                        ? 'No store requests'
                                        : _selectedFilter != 'all'
                                            ? 'No ${_selectedFilter} requests found'
                                            : 'No requests available');
                    return EmptyState(
                      title: 'No Requests Found',
                      message: message,
                      type: EmptyStateType.noData,
                      action: _effectiveMyRequests
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
    );
  }

  List<Widget> _buildAppBarActions(ThemeData theme) {
    return [
      IconButton(
        icon: Stack(
          children: [
            Icon(AppIcons.filter, color: theme.colorScheme.onSurface),
            if (_selectedFilter != 'all' || _selectedType != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
          ],
        ),
        onPressed: () {
          RequestFilterBottomSheet.show(
            context: context,
            initialStatus: _selectedFilter != 'all' ? _selectedFilter : null,
            initialType: _selectedType,
            onApply: (status, type, dateRange) {
              setState(() {
                _selectedFilter = status ?? 'all';
                _selectedType = type;
              });
            },
            onClear: () {
              setState(() {
                _selectedFilter = 'all';
                _selectedType = null;
              });
            },
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // When used as a tab: reload data when this tab becomes visible (so Requests vs Approvals show different data).
    if (_loadWhenVisible) {
      final isVisible = widget.currentTabIndex == widget.myTabIndex;
      if (isVisible && !_wasVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllRequests());
      }
      _wasVisible = isVisible;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final body = _buildBody(context, theme, isDark);
    if (widget.inShell) {
      return body;
    }
    final title = widget.pending
        ? 'Approvals'
        : widget.myRequests
            ? 'My Requests'
            : 'All Requests';
    return AppScaffold(
      title: title,
      showBackButton: true,
      actions: _buildAppBarActions(theme),
      body: body,
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
    final source = _effectiveMyRequests
        ? RequestDetailSource.myRequests
        : widget.pending
            ? RequestDetailSource.pendingApprovals
            : RequestDetailSource.other;
    VoidCallback? onRepeat;
    if (_effectiveMyRequests) {
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
}

class _ViewChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }
}
