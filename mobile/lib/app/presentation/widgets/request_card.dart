import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/request_model.dart';
import 'status_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/animations/sheet_animations.dart';
import '../pages/request_detail_page.dart';
import '../controllers/request_controller.dart';

class RequestCard extends StatefulWidget {
  final VehicleRequestModel request;
  final VoidCallback? onTap;
  final RequestDetailSource? source;
  final VoidCallback? onCancel;

  const RequestCard({
    Key? key,
    required this.request,
    this.onTap,
    this.source,
    this.onCancel,
  }) : super(key: key);

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    SheetHaptics.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark 
                ? AppColors.darkBorderDefined.withOpacity(0.5)
                : AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap ?? () {
              Get.to(() => RequestDetailPage(
                requestId: widget.request.id,
                source: widget.source,
              ))?.then((_) {
                // Reload pending approvals if we came from pending approvals page
                if (widget.source == RequestDetailSource.pendingApprovals) {
                  try {
                    final requestController = Get.find<RequestController>();
                    requestController.loadPendingApprovals();
                  } catch (e) {
                    // Controller might not be available, ignore
                  }
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collapsed/Header Row - Always visible
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Destination Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Destination and Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.request.destination,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    height: 1.3,
                                    color: isDark 
                                        ? AppColors.darkTextPrimary 
                                        : AppColors.textPrimary,
                                  ),
                              maxLines: _isExpanded ? null : 1,
                              overflow: _isExpanded ? null : TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            StatusBadge(
                              status: widget.request.status,
                              workflowStage: widget.request.workflowStage,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Repeat Request button (only show in My Requests, visible in collapsed view)
                      if (widget.source == RequestDetailSource.myRequests) ...[
                        IconButton(
                          icon: Icon(
                            Icons.repeat,
                            size: 20,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                          onPressed: () => _repeatVehicleRequest(),
                          tooltip: 'Repeat Request',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      // Expand/Collapse Icon
                      IconButton(
                        icon: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        onPressed: _toggleExpanded,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                  // Expanded content - Animated
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildExpandedContent(context, dateFormat),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, DateFormat dateFormat) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trip Date - Compact
        Row(
          children: [
            Icon(
              Icons.calendar_today, 
              size: 16, 
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              '${dateFormat.format(widget.request.tripDate)} • ${widget.request.tripTime}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Driver & Vehicle Info (if assigned)
        if (widget.request.driver != null || widget.request.vehicle != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.success.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                if (widget.request.driver != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Driver: ${widget.request.driver!.name}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.request.vehicle != null)
                  Row(
                    children: [
                      Icon(Icons.directions_car, size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.request.vehicle!.displayName} (${widget.request.vehicle!.plateNumber})',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Return Date and Time
        Row(
          children: [
            Icon(
              Icons.arrow_back, 
              size: 16, 
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Return: ${dateFormat.format(widget.request.returnDate)} • ${widget.request.returnTime}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Purpose
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.description_outlined, 
              size: 16, 
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.request.purpose,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // Priority Badge
        if (widget.request.priority) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.priority_high, size: 12, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  'Priority Request',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Action buttons (only show in My Requests)
        if (widget.source == RequestDetailSource.myRequests) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              // Cancel button (if callback provided)
              if (widget.onCancel != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: Icon(
                      Icons.cancel_outlined,
                      size: 18,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              if (widget.onCancel != null)
                const SizedBox(width: AppConstants.spacingS),
              // Repeat Request button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _repeatVehicleRequest(),
                  icon: Icon(
                    Icons.repeat, 
                    size: 18,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  label: Text(
                    'Repeat',
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
          ),
        ],
      ],
    );
  }

  void _repeatVehicleRequest() {
    // Navigate to create request page with vehicle type and pre-filled data
    final params = <String, String>{
      'type': 'vehicle',
      'destination': widget.request.destination,
      'purpose': widget.request.purpose,
      'tripDate': widget.request.tripDate.toIso8601String(),
      'tripTime': widget.request.tripTime,
      'returnDate': widget.request.returnDate.toIso8601String(),
      'returnTime': widget.request.returnTime,
      'priority': widget.request.priority.toString(),
    };
    
    // Add location data if available
    if (widget.request.destinationLocation != null) {
      final destLoc = widget.request.destinationLocation!;
      if (destLoc['latitude'] != null) {
        params['destinationLatitude'] = destLoc['latitude'].toString();
      }
      if (destLoc['longitude'] != null) {
        params['destinationLongitude'] = destLoc['longitude'].toString();
      }
    }
    
    if (widget.request.startLocation != null) {
      final startLoc = widget.request.startLocation!;
      if (startLoc['latitude'] != null) {
        params['startLatitude'] = startLoc['latitude'].toString();
      }
      if (startLoc['longitude'] != null) {
        params['startLongitude'] = startLoc['longitude'].toString();
      }
    }
    
    if (widget.request.returnLocation != null) {
      final returnLoc = widget.request.returnLocation!;
      if (returnLoc['latitude'] != null) {
        params['returnLatitude'] = returnLoc['latitude'].toString();
      }
      if (returnLoc['longitude'] != null) {
        params['returnLongitude'] = returnLoc['longitude'].toString();
      }
    }
    
    Get.toNamed('/create-request', parameters: params);
  }
}
