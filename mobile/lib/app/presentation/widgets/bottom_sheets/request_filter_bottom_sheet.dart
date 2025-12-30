import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/animations/sheet_animations.dart';

class RequestFilterBottomSheet extends StatefulWidget {
  final String? initialStatus;
  final String? initialType;
  final DateTimeRange? initialDateRange;
  final Function(String?, String?, DateTimeRange?)? onApply;
  final VoidCallback? onClear;

  const RequestFilterBottomSheet({
    Key? key,
    this.initialStatus,
    this.initialType,
    this.initialDateRange,
    this.onApply,
    this.onClear,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    String? initialStatus,
    String? initialType,
    DateTimeRange? initialDateRange,
    Function(String?, String?, DateTimeRange?)? onApply,
    VoidCallback? onClear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestFilterBottomSheet(
        initialStatus: initialStatus,
        initialType: initialType,
        initialDateRange: initialDateRange,
        onApply: onApply,
        onClear: onClear,
      ),
    );
  }

  @override
  State<RequestFilterBottomSheet> createState() => _RequestFilterBottomSheetState();
}

class _RequestFilterBottomSheetState extends State<RequestFilterBottomSheet> {
  String? _selectedStatus;
  String? _selectedType;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _selectedType = widget.initialType;
    _selectedDateRange = widget.initialDateRange;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedStatus != null && _selectedStatus != 'all') count++;
    if (_selectedType != null) count++;
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
      _selectedType = null;
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
      widget.onApply!(_selectedStatus, _selectedType, _selectedDateRange);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FilterBottomSheet(
      title: 'Filter Requests',
      applyText: 'Apply Filters',
      clearText: 'Clear All',
      activeFilterCount: _activeFilterCount,
      onApply: _applyFilters,
      onClear: _activeFilterCount > 0 ? _clearFilters : null,
      initialChildSize: BottomSheetSizes.medium,
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
              _buildFilterChip('all', 'All', _selectedStatus == null || _selectedStatus == 'all'),
              _buildFilterChip('pending', 'Pending', _selectedStatus == 'pending'),
              _buildFilterChip('approved', 'Approved', _selectedStatus == 'approved'),
              _buildFilterChip('rejected', 'Rejected', _selectedStatus == 'rejected'),
              _buildFilterChip('completed', 'Completed', _selectedStatus == 'completed'),
            ],
          ),
          const SizedBox(height: 24),
          // Type Filter
          Text(
            'Request Type',
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
              _buildFilterChip('vehicle', 'Vehicle', _selectedType == 'vehicle'),
              _buildFilterChip('ict', 'ICT', _selectedType == 'ict'),
              _buildFilterChip('store', 'Store', _selectedType == 'store'),
            ],
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceLight : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark 
                      ? AppColors.darkBorderDefined.withOpacity(0.5)
                      : AppColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today, 
                    color: isDark ? AppColors.primaryLight : AppColors.primary, 
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDateRange != null
                          ? '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}'
                          : 'Select date range',
                      style: TextStyle(
                        fontSize: 15,
                        color: _selectedDateRange != null
                            ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  if (_selectedDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                        SheetHaptics.lightImpact();
                      },
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isSelected) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (value == 'all') {
            _selectedStatus = null;
          } else if (label == 'Vehicle' || label == 'ICT' || label == 'Store') {
            _selectedType = selected ? value : null;
          } else {
            _selectedStatus = selected ? value : null;
          }
        });
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
              : (isDark 
                  ? AppColors.darkBorderDefined.withOpacity(0.5)
                  : AppColors.border.withOpacity(0.5)),
          width: 1,
        ),
      ),
    );
  }
}

