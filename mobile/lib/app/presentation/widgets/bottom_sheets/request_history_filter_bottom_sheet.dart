import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/animations/sheet_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_icons.dart';

class RequestHistoryFilterBottomSheet extends StatefulWidget {
  final String? initialStatus;
  final String? initialAction;
  final String? initialWorkflowStage;
  final DateTimeRange? initialDateRange;
  final String requestType; // 'ict', 'vehicle', 'store'
  final Function(String?, String?, String?, DateTimeRange?)? onApply;
  final VoidCallback? onClear;

  const RequestHistoryFilterBottomSheet({
    Key? key,
    this.initialStatus,
    this.initialAction,
    this.initialWorkflowStage,
    this.initialDateRange,
    required this.requestType,
    this.onApply,
    this.onClear,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    String? initialStatus,
    String? initialAction,
    String? initialWorkflowStage,
    DateTimeRange? initialDateRange,
    required String requestType,
    Function(String?, String?, String?, DateTimeRange?)? onApply,
    VoidCallback? onClear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestHistoryFilterBottomSheet(
        initialStatus: initialStatus,
        initialAction: initialAction,
        initialWorkflowStage: initialWorkflowStage,
        initialDateRange: initialDateRange,
        requestType: requestType,
        onApply: onApply,
        onClear: onClear,
      ),
    );
  }

  @override
  State<RequestHistoryFilterBottomSheet> createState() => _RequestHistoryFilterBottomSheetState();
}

class _RequestHistoryFilterBottomSheetState extends State<RequestHistoryFilterBottomSheet> {
  String? _selectedStatus;
  String? _selectedAction;
  String? _selectedWorkflowStage;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _selectedAction = widget.initialAction;
    _selectedWorkflowStage = widget.initialWorkflowStage;
    _selectedDateRange = widget.initialDateRange;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedStatus != null && _selectedStatus != 'all') count++;
    if (_selectedAction != null && _selectedAction != 'all') count++;
    if (_selectedWorkflowStage != null && _selectedWorkflowStage != 'all') count++;
    if (_selectedDateRange != null) count++;
    return count;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      SheetHaptics.lightImpact();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedAction = null;
      _selectedWorkflowStage = null;
      _selectedDateRange = null;
    });
    SheetHaptics.lightImpact();
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  void _applyFilters() {
    SheetHaptics.mediumImpact();
    if (widget.onApply != null) {
      widget.onApply!(_selectedStatus, _selectedAction, _selectedWorkflowStage, _selectedDateRange);
    }
    Navigator.of(context).pop();
  }

  List<String> _getWorkflowStages() {
    switch (widget.requestType) {
      case 'ict':
        return ['all', 'SUBMITTED', 'SUPERVISOR_REVIEW', 'DDICT_REVIEW', 'DGS_REVIEW', 'SO_REVIEW', 'FULFILLMENT'];
      case 'vehicle':
        return ['all', 'SUBMITTED', 'SUPERVISOR_REVIEW', 'DGS_REVIEW', 'DDGS_REVIEW', 'ADGS_REVIEW', 'TO_REVIEW', 'FULFILLMENT'];
      case 'store':
        return ['all', 'SUBMITTED', 'SUPERVISOR_REVIEW', 'DGS_REVIEW', 'DDGS_REVIEW', 'ADGS_REVIEW', 'SO_REVIEW', 'FULFILLMENT'];
      default:
        return ['all'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FilterBottomSheet(
      title: 'Filter Request History',
      applyText: 'Apply Filters',
      clearText: 'Clear All',
      activeFilterCount: _activeFilterCount,
      onApply: _applyFilters,
      onClear: _activeFilterCount > 0 ? _clearFilters : null,
      initialChildSize: BottomSheetSizes.large,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Filter
            Text(
              'Status',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFilterChip('all', 'All', _selectedStatus == null || _selectedStatus == 'all', (selected) {
                  setState(() {
                    _selectedStatus = selected ? null : _selectedStatus;
                  });
                }),
                _buildFilterChip('pending', 'Pending', _selectedStatus == 'pending', (selected) {
                  setState(() {
                    _selectedStatus = selected ? 'pending' : null;
                  });
                }),
                _buildFilterChip('approved', 'Approved', _selectedStatus == 'approved', (selected) {
                  setState(() {
                    _selectedStatus = selected ? 'approved' : null;
                  });
                }),
                _buildFilterChip('rejected', 'Rejected', _selectedStatus == 'rejected', (selected) {
                  setState(() {
                    _selectedStatus = selected ? 'rejected' : null;
                  });
                }),
                _buildFilterChip('fulfilled', 'Fulfilled', _selectedStatus == 'fulfilled', (selected) {
                  setState(() {
                    _selectedStatus = selected ? 'fulfilled' : null;
                  });
                }),
                _buildFilterChip('completed', 'Completed', _selectedStatus == 'completed', (selected) {
                  setState(() {
                    _selectedStatus = selected ? 'completed' : null;
                  });
                }),
              ],
            ),
            const SizedBox(height: 24),
            // Action Filter
            Text(
              'Your Action',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFilterChip('all', 'All', _selectedAction == null || _selectedAction == 'all', (selected) {
                  setState(() {
                    _selectedAction = selected ? null : _selectedAction;
                  });
                }),
                _buildFilterChip('created', 'Created', _selectedAction == 'created', (selected) {
                  setState(() {
                    _selectedAction = selected ? 'created' : null;
                  });
                }),
                _buildFilterChip('approved', 'Approved', _selectedAction == 'approved', (selected) {
                  setState(() {
                    _selectedAction = selected ? 'approved' : null;
                  });
                }),
                _buildFilterChip('rejected', 'Rejected', _selectedAction == 'rejected', (selected) {
                  setState(() {
                    _selectedAction = selected ? 'rejected' : null;
                  });
                }),
                if (widget.requestType == 'vehicle')
                  _buildFilterChip('assigned', 'Assigned', _selectedAction == 'assigned', (selected) {
                    setState(() {
                      _selectedAction = selected ? 'assigned' : null;
                    });
                  }),
                _buildFilterChip('corrected', 'Corrected', _selectedAction == 'corrected', (selected) {
                  setState(() {
                    _selectedAction = selected ? 'corrected' : null;
                  });
                }),
                _buildFilterChip('fulfilled', 'Fulfilled', _selectedAction == 'fulfilled', (selected) {
                  setState(() {
                    _selectedAction = selected ? 'fulfilled' : null;
                  });
                }),
              ],
            ),
            const SizedBox(height: 24),
            // Workflow Stage Filter
            Text(
              'Workflow Stage',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _getWorkflowStages().map((stage) {
                final displayName = stage == 'all' 
                    ? 'All' 
                    : stage.replaceAll('_', ' ').split(' ').map((w) => 
                        w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
                return _buildFilterChip(stage, displayName, _selectedWorkflowStage == stage || (_selectedWorkflowStage == null && stage == 'all'), (selected) {
                  setState(() {
                    _selectedWorkflowStage = selected ? (stage == 'all' ? null : stage) : null;
                  });
                });
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Date Range Filter
            Text(
              'Date Range',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark 
                        ? AppColors.darkBorderDefined.withOpacity(0.5)
                        : AppColors.border.withOpacity(0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.calendar,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      size: AppIcons.sizeDefault,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        _selectedDateRange != null
                            ? '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}'
                            : 'Select date range',
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: _selectedDateRange != null
                                  ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                  : (isDark ? AppColors.darkTextDisabled : AppColors.textDisabled),
                            ),
                      ),
                    ),
                    if (_selectedDateRange != null)
                      IconButton(
                        icon: Icon(
                          AppIcons.close,
                          size: AppIcons.sizeSmall,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                          SheetHaptics.lightImpact();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    bool isSelected,
    Function(bool) onSelected,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(selected);
        SheetHaptics.selectionClick();
      },
      selectedColor: isDark ? AppColors.primaryLight : AppColors.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
      backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.surfaceElevation1,
      labelStyle: TextStyle(
        color: isSelected 
            ? theme.colorScheme.onPrimary
            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? (isDark ? AppColors.primaryLight : AppColors.primary)
              : (isDark ? AppColors.darkBorderDefined.withOpacity(0.5) : AppColors.border.withOpacity(0.5)),
          width: isSelected ? 2 : 1.5,
        ),
      ),
    );
  }
}
