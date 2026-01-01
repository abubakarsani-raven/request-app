import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/assignment_controller.dart';
import '../controllers/assignment_selection_controller.dart';
import '../controllers/request_controller.dart';
import '../controllers/notification_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/assignment_preview_card.dart';
import '../widgets/bottom_sheets/vehicle_selection_bottom_sheet.dart';
import '../widgets/bottom_sheets/driver_selection_bottom_sheet.dart';
import '../../data/services/settings_service.dart';
import '../../data/services/office_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_toast.dart';

class AssignmentPage extends StatefulWidget {
  final String requestId;

  const AssignmentPage({Key? key, required this.requestId}) : super(key: key);

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  // Use Get.find() for controllers already registered in bindings
  late final AssignmentController assignmentController;
  // Page-specific controller - create new instance
  late final AssignmentSelectionController selectionController;
  final requestController = Get.find<RequestController>();
  final settingsService = SettingsService();
  final officeService = OfficeService();
  final _drawerController = AdvancedDrawerController();
  
  double? _fuelMpg;
  double? _estimatedFuelLiters;
  Office? _headOffice;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    assignmentController = Get.find<AssignmentController>();
    selectionController = Get.put(AssignmentSelectionController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    // Dispose page-specific controller
    Get.delete<AssignmentSelectionController>();
    super.dispose();
  }

  Future<void> _loadData() async {
    await requestController.loadRequest(widget.requestId);
    await _loadFuelMpg();
    await _loadHeadOffice();
    
    // Get trip dates from request for date-based availability checking
    final request = requestController.selectedRequest.value;
    DateTime? tripDate;
    DateTime? returnDate;
    
    if (request != null) {
      tripDate = request.tripDate;
      returnDate = request.returnDate;
    }
    
    // Load vehicles and drivers with trip dates for date-based filtering
    await assignmentController.loadAvailableVehicles(
      tripDate: tripDate,
      returnDate: returnDate,
    );
    await assignmentController.loadAvailableDrivers(
      tripDate: tripDate,
      returnDate: returnDate,
    );
    _calculateEstimatedFuel();
  }

  Future<void> _loadFuelMpg() async {
    try {
      _fuelMpg = await settingsService.getFuelConsumptionMpg();
    } catch (e) {
      print('Error loading fuel MPG: $e');
      _fuelMpg = 14.0; // Default
    }
  }

  Future<void> _loadHeadOffice() async {
    try {
      _headOffice = await officeService.getHeadOffice();
    } catch (e) {
      print('Error loading head office: $e');
      // Fallback to default coordinates
      _headOffice = Office(
        id: 'default',
        name: 'Head Office',
        address: 'Lagos, Nigeria',
        latitude: 6.5244,
        longitude: 3.3792,
        isHeadOffice: true,
      );
    }
  }

  void _calculateEstimatedFuel() {
    final request = requestController.selectedRequest.value;
    if (request == null || _fuelMpg == null) {
      _estimatedFuelLiters = null;
      return;
    }

    // Get destination coordinates if available
    final destLocation = request.requestedDestinationLocation;
    if (destLocation == null) {
      _estimatedFuelLiters = null;
      return;
    }

    // Get office coordinates from head office
    final officeLat = _headOffice?.latitude ?? 6.5244; // Fallback to default
    final officeLng = _headOffice?.longitude ?? 3.3792; // Fallback to default

    final destLat = destLocation['latitude'] as double?;
    final destLng = destLocation['longitude'] as double?;

    if (destLat == null || destLng == null) {
      _estimatedFuelLiters = null;
      return;
    }

    // Calculate distance (outbound + return)
    final outboundDistance = _calculateDistance(officeLat, officeLng, destLat, destLng);
    final returnDistance = _calculateDistance(destLat, destLng, officeLat, officeLng);
    final totalDistance = outboundDistance + returnDistance;

    // Calculate fuel: (Distance in km / 1.60934) / MPG * 3.78541 liters/gallon
    final distanceMiles = totalDistance / 1.60934;
    final gallonsNeeded = distanceMiles / _fuelMpg!;
    _estimatedFuelLiters = gallonsNeeded * 3.78541;
    setState(() {});
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = (dLat / 2) * (dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * (dLon / 2) * (dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  @override
  Widget build(BuildContext context) {
    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
          ),
          title: const Text('Assign Vehicle'),
        ),
        body: Obx(
          () => LoadingOverlay(
            isLoading: assignmentController.isAssigning.value ||
                       requestController.isReloading.value,
            message: assignmentController.isAssigning.value
                ? 'Assigning vehicle...'
                : 'Loading...',
            child: () {
              final request = requestController.selectedRequest.value;

              if (request == null) {
                return ListView(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  children: [
                    const SkeletonCard(height: 150),
                    const SizedBox(height: AppConstants.spacingXL),
                    const SkeletonText(width: double.infinity, height: 20, lines: 1),
                    const SizedBox(height: AppConstants.spacingM),
                    const SkeletonCard(height: 200),
                    const SizedBox(height: AppConstants.spacingM),
                    const SkeletonCard(height: 200),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRequestDetailsHeader(context, request),
                          const SizedBox(height: AppConstants.spacingXL),
                          _buildSelectionButtons(context),
                          const SizedBox(height: AppConstants.spacingXL),
                          _buildPreviewSection(context),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }(),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestDetailsHeader(BuildContext context, dynamic request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefined : AppColors.borderLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.destination ?? 'N/A',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${request.tripDate.toString().split(' ')[0]} • ${request.tripTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (request.purpose != null && request.purpose.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    request.purpose,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final selectedVehicle = selectionController.selectedVehicleId.value != null
          ? assignmentController.availableVehicles.firstWhereOrNull(
              (v) => (v['_id'] ?? v['id'])?.toString() == selectionController.selectedVehicleId.value,
            )
          : null;

      final selectedDriver = selectionController.selectedDriverId.value != null
          ? assignmentController.availableDrivers.firstWhereOrNull(
              (d) => (d['_id'] ?? d['id'])?.toString() == selectionController.selectedDriverId.value,
            )
          : null;

      return Column(
        children: [
          // Vehicle Selection Button
          InkWell(
            onTap: () {
              VehicleSelectionBottomSheet.show(context, estimatedFuelLiters: _estimatedFuelLiters);
            },
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                border: Border.all(
                  color: selectedVehicle != null
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorderDefined : AppColors.borderLight),
                  width: selectedVehicle != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Vehicle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedVehicle != null
                              ? '${selectedVehicle['plateNumber'] ?? 'N/A'} - ${selectedVehicle['make'] ?? ''} ${selectedVehicle['model'] ?? ''}'.trim()
                              : 'Tap to choose a vehicle',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedVehicle != null
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (selectedVehicle != null)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.textOnPrimary,
                        size: 18,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Driver Selection Button
          InkWell(
            onTap: () {
              DriverSelectionBottomSheet.show(context);
            },
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                border: Border.all(
                  color: selectedDriver != null
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorderDefined : AppColors.borderLight),
                  width: selectedDriver != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Driver',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedDriver != null
                              ? selectedDriver['name'] ?? 'N/A'
                              : 'Tap to choose a driver',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedDriver != null
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (selectedDriver != null)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.textOnPrimary,
                        size: 18,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPreviewSection(BuildContext context) {
    return Obx(() {
      final selectedVehicleId = selectionController.selectedVehicleId.value;
      final selectedVehicle = selectedVehicleId != null
          ? assignmentController.availableVehicles.firstWhereOrNull(
              (v) => (v['_id'] ?? v['id'])?.toString() == selectedVehicleId,
            )
          : null;

      final selectedDriverId = selectionController.selectedDriverId.value;
      final selectedDriver = selectedDriverId != null
          ? assignmentController.availableDrivers.firstWhereOrNull(
              (d) => (d['_id'] ?? d['id'])?.toString() == selectedDriverId,
            )
          : null;

      return AssignmentPreviewCard(
        selectedVehicle: selectedVehicle,
        selectedDriver: selectedDriver,
        estimatedFuelLiters: _estimatedFuelLiters,
        isAssigning: assignmentController.isAssigning.value,
        onAssign: (selectedVehicleId != null && selectedDriverId != null) ? () async {
          final success = await assignmentController.assignVehicle(
            widget.requestId,
            selectedVehicleId,
            driverId: selectedDriverId,
          );
          if (success) {
            await requestController.loadRequest(widget.requestId);
            try {
              final notificationController = Get.find<NotificationController>();
              await notificationController.loadNotifications(unreadOnly: false);
              await notificationController.loadUnreadCount();
            } catch (e) {
              print('Error refreshing notifications: $e');
            }
            CustomToast.success('Vehicle assigned successfully');
            await Future.delayed(const Duration(milliseconds: 500));
            Get.back(result: true);
          } else {
            CustomToast.error(
              assignmentController.error.value.isNotEmpty
                  ? assignmentController.error.value
                  : 'Failed to assign vehicle',
            );
          }
        } : null,
      );
    });
  }
}
