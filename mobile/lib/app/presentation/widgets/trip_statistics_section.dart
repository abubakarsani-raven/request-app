import 'package:flutter/material.dart';
import '../../data/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/animations/sheet_animations.dart';

class TripStatisticsSection extends StatefulWidget {
  final VehicleRequestModel request;

  const TripStatisticsSection({Key? key, required this.request}) : super(key: key);

  @override
  State<TripStatisticsSection> createState() => _TripStatisticsSectionState();
}

class _TripStatisticsSectionState extends State<TripStatisticsSection>
    with SingleTickerProviderStateMixin {
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
      SheetHaptics.lightImpact();
    });
  }

  String _getSummaryText() {
    final totalDistance = widget.request.totalDistanceKm;
    final totalFuel = widget.request.totalFuelLiters;
    
    if (totalDistance != null && totalFuel != null) {
      return '${totalDistance.toStringAsFixed(1)} km • ${totalFuel.toStringAsFixed(1)}L';
    } else if (totalDistance != null) {
      return '${totalDistance.toStringAsFixed(1)} km';
    } else if (totalFuel != null) {
      return '${totalFuel.toStringAsFixed(1)}L';
    }
    return 'No data available';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppConstants.radiusL),
              bottom: Radius.circular(_isExpanded ? 0 : AppConstants.radiusL),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Statistics',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (!_isExpanded) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getSummaryText(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _expandAnimation,
                    child: Icon(
                      Icons.expand_more,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance Section
                      if (widget.request.outboundDistanceKm != null ||
                          widget.request.returnDistanceKm != null ||
                          widget.request.totalDistanceKm != null) ...[
                        _buildSectionTitle('Distance'),
                        const SizedBox(height: AppConstants.spacingM),
                        if (widget.request.outboundDistanceKm != null)
                          _buildStatRow('Outbound Distance', '${widget.request.outboundDistanceKm!.toStringAsFixed(2)} km'),
                        if (widget.request.returnDistanceKm != null)
                          _buildStatRow('Return Distance', '${widget.request.returnDistanceKm!.toStringAsFixed(2)} km'),
                        if (widget.request.totalDistanceKm != null)
                          _buildStatRow('Total Distance', '${widget.request.totalDistanceKm!.toStringAsFixed(2)} km', isTotal: true),
                        const SizedBox(height: AppConstants.spacingL),
                      ],
                      
                      // Fuel Section
                      if (widget.request.outboundFuelLiters != null ||
                          widget.request.returnFuelLiters != null ||
                          widget.request.totalFuelLiters != null) ...[
                        _buildSectionTitle('Fuel Consumption'),
                        const SizedBox(height: AppConstants.spacingM),
                        if (widget.request.outboundFuelLiters != null)
                          _buildStatRow('Outbound Fuel', '${widget.request.outboundFuelLiters!.toStringAsFixed(2)} liters'),
                        if (widget.request.returnFuelLiters != null)
                          _buildStatRow('Return Fuel', '${widget.request.returnFuelLiters!.toStringAsFixed(2)} liters'),
                        if (widget.request.totalFuelLiters != null)
                          _buildStatRow('Total Fuel', '${widget.request.totalFuelLiters!.toStringAsFixed(2)} liters', isTotal: true),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
