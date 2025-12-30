import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:intl/intl.dart';
import '../controllers/request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/bottom_sheets/request_history_filter_bottom_sheet.dart';
import '../../data/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/id_utils.dart';
import 'request_detail_page.dart';

class TransportRequestHistoryPage extends StatefulWidget {
  const TransportRequestHistoryPage({Key? key}) : super(key: key);

  @override
  State<TransportRequestHistoryPage> createState() => _TransportRequestHistoryPageState();
}

class _TransportRequestHistoryPageState extends State<TransportRequestHistoryPage> {
  final RequestController _controller = Get.find<RequestController>();
  final AuthController _authController = Get.find<AuthController>();
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();
  
  String? _selectedStatus;
  String? _selectedAction;
  String? _selectedWorkflowStage;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    await _controller.loadRequestHistory(
      status: _selectedStatus,
      action: _selectedAction,
      workflowStage: _selectedWorkflowStage,
      dateFrom: _selectedDateRange?.start,
      dateTo: _selectedDateRange?.end,
    );
  }

  Participant? _getUserParticipant(VehicleRequestModel request) {
    final userId = _authController.user.value?.id;
    if (userId == null) return null;
    
    try {
      return request.participants.firstWhere(
        (p) => IdUtils.areIdsEqual(p.userId, userId),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final responsive = Responsive(context);

    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark ? null : AppColors.backgroundGradient,
            color: isDark ? AppColors.darkBackground : null,
          ),
          child: Column(
            children: [
              // App Bar
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  left: AppConstants.spacingL,
                  right: AppConstants.spacingL,
                  bottom: AppConstants.spacingM,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        AppIcons.back,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Text(
                        'Transport Request History',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24 * responsive.fontSizeMultiplier,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Stack(
                        children: [
                          Icon(
                            AppIcons.filter,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          if (_selectedStatus != null ||
                              _selectedAction != null ||
                              _selectedWorkflowStage != null ||
                              _selectedDateRange != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
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
                        RequestHistoryFilterBottomSheet.show(
                          context: context,
                          initialStatus: _selectedStatus,
                          initialAction: _selectedAction,
                          initialWorkflowStage: _selectedWorkflowStage,
                          initialDateRange: _selectedDateRange,
                          requestType: 'vehicle',
                          onApply: (status, action, workflowStage, dateRange) {
                            setState(() {
                              _selectedStatus = status;
                              _selectedAction = action;
                              _selectedWorkflowStage = workflowStage;
                              _selectedDateRange = dateRange;
                            });
                            _loadHistory();
                          },
                          onClear: () {
                            setState(() {
                              _selectedStatus = null;
                              _selectedAction = null;
                              _selectedWorkflowStage = null;
                              _selectedDateRange = null;
                            });
                            _loadHistory();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Request List
              Expanded(
                child: Obx(
                  () {
                    if (_controller.isLoadingHistory.value && _controller.historyRequests.isEmpty) {
                      return ListView.builder(
                        padding: EdgeInsets.all(AppConstants.spacingM * responsive.spacingMultiplier),
                        itemCount: 5,
                        itemBuilder: (context, index) => Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.spacingM * responsive.spacingMultiplier),
                          child: const SkeletonCard(),
                        ),
                      );
                    }

                    if (_controller.error.isNotEmpty && _controller.historyRequests.isEmpty) {
                      return AppErrorWidget(
                        title: 'Error Loading History',
                        message: _controller.error.value,
                        onRetry: _loadHistory,
                      );
                    }

                    if (_controller.historyRequests.isEmpty) {
                      return EmptyState(
                        title: 'No Request History',
                        message: 'You haven\'t participated in any transport requests yet.',
                        icon: AppIcons.vehicle,
                        type: EmptyStateType.noData,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppConstants.spacingM * responsive.spacingMultiplier),
                        itemCount: _controller.historyRequests.length,
                        itemBuilder: (context, index) {
                          final request = _controller.historyRequests[index];
                          final participant = _getUserParticipant(request);
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: AppConstants.spacingM * responsive.spacingMultiplier),
                            child: _buildRequestCard(context, request, participant),
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
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, VehicleRequestModel request, Participant? participant) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    String actionText = 'Participated';
    if (participant != null) {
      switch (participant.action) {
        case 'created':
          actionText = 'You created this request';
          break;
        case 'approved':
          actionText = 'You approved this request';
          break;
        case 'rejected':
          actionText = 'You rejected this request';
          break;
        case 'corrected':
          actionText = 'You corrected this request';
          break;
        case 'assigned':
          actionText = 'You assigned this request';
          break;
        case 'fulfilled':
          actionText = 'You fulfilled this request';
          break;
        default:
          actionText = 'You participated in this request';
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        side: BorderSide(
          color: isDark 
              ? AppColors.darkBorderDefined.withOpacity(0.5) 
              : AppColors.border.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      child: InkWell(
        onTap: () {
          Get.to(() => RequestDetailPage(requestId: request.id));
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingS),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Icon(
                      AppIcons.vehicle,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      size: AppIcons.sizeDefault,
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.destination,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppConstants.spacingXS),
                        StatusBadge(
                          status: request.status,
                          workflowStage: request.workflowStage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacingS),
              Text(
                request.purpose,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppConstants.spacingS),
              if (participant != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.check,
                        size: AppIcons.sizeSmall,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppConstants.spacingXS),
                      Expanded(
                        child: Text(
                          actionText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        dateFormat.format(participant.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppConstants.spacingS),
              ],
              Text(
                'Created: ${dateFormat.format(request.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
