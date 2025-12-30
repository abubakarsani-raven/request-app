import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/animations/sheet_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/controllers/theme_controller.dart';
import '../controllers/trip_mode_controller.dart';
import '../../data/models/request_model.dart';

class TripFloatingActions extends StatefulWidget {
  final VehicleRequestModel trip;
  final String requestId;
  final VoidCallback? onStartTrip;
  final VoidCallback? onReachDestination;
  final VoidCallback? onReturnToOffice;
  final VoidCallback? onShowStatistics;

  const TripFloatingActions({
    Key? key,
    required this.trip,
    required this.requestId,
    this.onStartTrip,
    this.onReachDestination,
    this.onReturnToOffice,
    this.onShowStatistics,
  }) : super(key: key);

  @override
  State<TripFloatingActions> createState() => _TripFloatingActionsState();
}

class _TripFloatingActionsState extends State<TripFloatingActions>
    with TickerProviderStateMixin {
  final TripModeController _modeController = Get.find<TripModeController>();
  bool _isExpanded = false;
  late AnimationController _expandAnimationController;
  late Animation<double> _expandAnimation;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _expandAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandAnimationController,
      curve: Curves.easeInOut,
    );
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandAnimationController.forward();
        SheetHaptics.lightImpact();
      } else {
        _expandAnimationController.reverse();
        SheetHaptics.lightImpact();
      }
    });
  }

  Widget _buildPrimaryFAB() {
    String label;
    IconData icon;
    VoidCallback? onPressed;
    Color backgroundColor;
    bool isPulsing = false;

    if (!widget.trip.tripStarted) {
      label = 'Start Trip';
      icon = Icons.play_arrow;
      onPressed = widget.onStartTrip;
      backgroundColor = AppColors.primary;
    } else if (!widget.trip.destinationReached) {
      label = 'Mark Destination\nReached';
      icon = Icons.location_on;
      onPressed = widget.onReachDestination;
      backgroundColor = AppColors.accent;
      isPulsing = true;
    } else if (!widget.trip.tripCompleted) {
      label = 'Mark Return\nto Office';
      icon = Icons.home;
      onPressed = widget.onReturnToOffice;
      backgroundColor = AppColors.success;
      isPulsing = true;
    } else {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final isNavigationMode = _modeController.isNavigationMode;
      
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isPulsing ? 1.0 + (_pulseAnimation.value * 0.1) : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed != null
                      ? () {
                          SheetHaptics.heavyImpact();
                          onPressed!();
                        }
                      : null,
                  borderRadius: BorderRadius.circular(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      if (isNavigationMode) ...[
                        const SizedBox(height: 2),
                        Text(
                          label.split('\n').first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }


  Widget _buildSecondaryFAB({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = backgroundColor ?? 
        (isDark ? AppColors.darkSurface : AppColors.surface);

    return ScaleTransition(
      scale: _expandAnimation,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(
              color: isDark ? AppColors.darkBorderDefined : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                SheetHaptics.mediumImpact();
                onTap();
              },
              borderRadius: BorderRadius.circular(28),
              child: Icon(
                icon,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Obx(() {
      final isNavigationMode = _modeController.isNavigationMode;
      
      // In navigation mode, only show primary FAB if trip is active
      if (isNavigationMode && !widget.trip.tripStarted) {
        return const SizedBox.shrink();
      }

      return Positioned(
        bottom: AppConstants.spacingXL,
        right: AppConstants.spacingL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Secondary FABs (expandable)
            if (_isExpanded || !isNavigationMode) ...[
              _buildSecondaryFAB(
                icon: Icons.bar_chart,
                tooltip: 'Statistics',
                onTap: widget.onShowStatistics ?? () {},
              ),
              _buildSecondaryFAB(
                icon: theme.brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                tooltip: 'Toggle Theme',
                onTap: () {
                  final themeController = Get.find<ThemeController>();
                  themeController.toggleTheme();
                },
              ),
            ],
            
            // Expand/Collapse button
            if (isNavigationMode)
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorderDefined : AppColors.borderLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleExpanded,
                    borderRadius: BorderRadius.circular(28),
                    child: RotationTransition(
                      turns: _expandAnimation,
                      child: Icon(
                        Icons.add,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Primary FAB
            _buildPrimaryFAB(),
          ],
        ),
      );
    });
  }
}
