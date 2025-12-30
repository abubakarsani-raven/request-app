import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/request_controller.dart';
import '../controllers/trip_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/permission_button.dart';
import '../widgets/app_drawer.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/workflow_timeline.dart';
import '../../data/models/request_model.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/id_utils.dart';
import 'trip_tracking_page.dart';
import 'assignment_page.dart';

enum RequestDetailSource {
  myRequests,
  pendingApprovals,
  assignVehicle,
  other,
}

class RequestDetailPage extends StatelessWidget {
  final String requestId;
  final RequestDetailSource? source;
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();

  RequestDetailPage({
    Key? key,
    required this.requestId,
    this.source,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final requestController = Get.put(RequestController());
    final authController = Get.find<AuthController>();

    // Load request details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestController.loadRequest(requestId);
    });

    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
          ),
          title: const Text('Request Details'),
        ),
      body: Obx(
        () {
          final request = requestController.selectedRequest.value;
          
          if (requestController.isLoading.value && request == null) {
            return ListView(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              children: [
                const SkeletonCard(height: 200),
                const SizedBox(height: AppConstants.spacingL),
                const SkeletonText(width: double.infinity, height: 20, lines: 3),
                const SizedBox(height: AppConstants.spacingL),
                const SkeletonCard(height: 150),
              ],
            );
          }

          if (request == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Request not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => requestController.loadRequest(requestId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and Priority
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(
                      status: request.status,
                      workflowStage: request.workflowStage,
                    ),
                    if (request.priority)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.priority_high, size: 16, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Priority',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingXXL),
                
                // Trip Details
                _buildDetailSection(
                  context,
                  'Trip Details',
                  [
                    _buildDetailRow('Destination', request.destination),
                    _buildDetailRow('Purpose', request.purpose),
                    _buildDetailRow(
                      'Trip Date',
                      DateFormat('MMM dd, yyyy').format(request.tripDate),
                    ),
                    _buildDetailRow('Trip Time', request.tripTime),
                    _buildDetailRow(
                      'Return Date',
                      DateFormat('MMM dd, yyyy').format(request.returnDate),
                    ),
                    _buildDetailRow('Return Time', request.returnTime),
                  ],
                ),
                
                // Workflow Timeline (for My Requests)
                const SizedBox(height: AppConstants.spacingXXL),
                WorkflowTimeline(request: request),
                
                // Driver & Vehicle Info (if assigned)
                if (request.driver != null || request.vehicle != null) ...[
                  const SizedBox(height: AppConstants.spacingXXL),
                  _buildDetailSection(
                    context,
                    'Assignment Details',
                    [
                      if (request.driver != null) ...[
                        _buildDetailRow('Driver Name', request.driver!.name),
                        _buildDetailRow('Driver Phone', request.driver!.phone),
                        _buildDetailRow(
                          'License Number',
                          request.driver!.licenseNumber,
                        ),
                      ],
                      if (request.vehicle != null) ...[
                        if (request.driver != null)
                          const SizedBox(height: AppConstants.spacingM),
                        _buildDetailRow(
                          'Vehicle',
                          request.vehicle!.displayName,
                        ),
                        _buildDetailRow(
                          'Plate Number',
                          request.vehicle!.plateNumber,
                        ),
                        _buildDetailRow('Vehicle Type', request.vehicle!.type),
                        _buildDetailRow('Make', request.vehicle!.make),
                        _buildDetailRow('Model', request.vehicle!.model),
                        if (request.vehicle!.year != null)
                          _buildDetailRow(
                            'Year',
                            request.vehicle!.year!.toString(),
                          ),
                      ],
                    ],
                  ),
                ],
                
                // Waypoints (if multi-stop trip)
                if (request.waypoints != null && request.waypoints!.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingXXL),
                  _buildDetailSection(
                    context,
                    'Trip Waypoints',
                    [
                      ...request.waypoints!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final waypoint = entry.value;
                        return _buildWaypointDetailRow(
                          context,
                          'Stop ${index + 1}',
                          waypoint.name,
                          waypoint.reached,
                          waypoint.distanceFromPrevious,
                          waypoint.fuelFromPrevious,
                        );
                      }),
                    ],
                  ),
                ],
                
                // Pre-trip Estimation (for DGS, TO, DDGS, ADGS before trip starts)
                if (!request.tripStarted) ...[
                  Obx(() {
                    final user = authController.user.value;
                    if (user != null) {
                      final permissionService = Get.find<PermissionService>();
                      if (permissionService.canViewFuelDistanceEstimate(user)) {
                        return _buildEstimationCard(context, request);
                      }
                    }
                    return const SizedBox.shrink();
                  }),
                ],
                
                // Trip Tracking Info
                if (request.tripStarted) ...[
                  const SizedBox(height: AppConstants.spacingXXL),
                  _buildDetailSection(
                    context,
                    'Trip Tracking',
                    [
                      if (request.actualDepartureTime != null)
                        _buildDetailRow(
                          'Departure Time',
                          DateFormat('MMM dd, yyyy hh:mm a')
                              .format(request.actualDepartureTime!),
                        ),
                      if (request.destinationReached && request.destinationReachedTime != null)
                        _buildDetailRow(
                          'Destination Reached',
                          DateFormat('MMM dd, yyyy hh:mm a')
                              .format(request.destinationReachedTime!),
                        ),
                      if (request.tripCompleted && request.actualReturnTime != null)
                        _buildDetailRow(
                          'Return Time',
                          DateFormat('MMM dd, yyyy hh:mm a')
                              .format(request.actualReturnTime!),
                        ),
                      if (request.totalDistanceKm != null)
                        _buildDetailRow(
                          'Total Distance',
                          '${request.totalDistanceKm!.toStringAsFixed(2)} km',
                        ),
                      if (request.totalFuelLiters != null)
                        _buildDetailRow(
                          'Total Fuel',
                          '${request.totalFuelLiters!.toStringAsFixed(2)} liters',
                        ),
                    ],
                  ),
                ],
                
                const SizedBox(height: AppConstants.spacingXXL),
                
                // Action Buttons
                _buildActionButtons(context, request, authController, source ?? RequestDetailSource.other),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
                height: 1.3,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? AppColors.darkBorderDefined.withOpacity(0.5)
                  : AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildWaypointDetailRow(
    BuildContext context,
    String label,
    String waypointName,
    bool reached,
    double? distance,
    double? fuel,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      reached ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: reached ? AppColors.success : (isDark ? AppColors.darkTextDisabled : AppColors.textDisabled),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        waypointName,
                        style: TextStyle(
                          fontWeight: reached ? FontWeight.w600 : FontWeight.normal,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (distance != null || fuel != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 138),
              child: Wrap(
                spacing: 16,
                children: [
                  if (distance != null)
                    Text(
                      'Distance: ${distance.toStringAsFixed(2)} km',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                    ),
                  if (fuel != null)
                    Text(
                      'Fuel: ${fuel.toStringAsFixed(2)} liters',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimationCard(BuildContext context, VehicleRequestModel request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate estimated distance and fuel
    double? estimatedDistance;
    double? estimatedFuel;

    // Get all location coordinates
    final officeLat = request.officeLocation?['latitude'] as num?;
    final officeLng = request.officeLocation?['longitude'] as num?;
    final startLat = request.startLocation?['latitude'] as num?;
    final startLng = request.startLocation?['longitude'] as num?;
    final destLat = request.requestedDestinationLocation?['latitude'] as num?;
    final destLng = request.requestedDestinationLocation?['longitude'] as num?;
    final dropOffLat = request.returnLocation?['latitude'] as num?;
    final dropOffLng = request.returnLocation?['longitude'] as num?;

    // Need at least office and destination to calculate
    if (officeLat != null && officeLng != null && destLat != null && destLng != null) {
      double totalDistance = 0.0;
      double lastLat;
      double lastLng;

      // Leg 1: Office → Start Point (if start is different from office)
      if (startLat != null && startLng != null) {
        final officeToStart = _calculateDistance(
          officeLat.toDouble(),
          officeLng.toDouble(),
          startLat.toDouble(),
          startLng.toDouble(),
        );
        // Only add if start is significantly different from office (> 100m)
        if (officeToStart > 0.1) {
          totalDistance += officeToStart;
          lastLat = startLat.toDouble();
          lastLng = startLng.toDouble();
        } else {
          // Start is same as office
          lastLat = officeLat.toDouble();
          lastLng = officeLng.toDouble();
        }
      } else {
        // No start location, use office as start
        lastLat = officeLat.toDouble();
        lastLng = officeLng.toDouble();
      }

      // Leg 2: Start → Waypoints → Destination (outbound)
      if (request.waypoints != null && request.waypoints!.isNotEmpty) {
        // Start → First waypoint
        totalDistance += _calculateDistance(
          lastLat,
          lastLng,
          request.waypoints![0].latitude,
          request.waypoints![0].longitude,
        );
        lastLat = request.waypoints![0].latitude;
        lastLng = request.waypoints![0].longitude;

        // Waypoint to waypoint
        for (int i = 1; i < request.waypoints!.length; i++) {
          totalDistance += _calculateDistance(
            lastLat,
            lastLng,
            request.waypoints![i].latitude,
            request.waypoints![i].longitude,
          );
          lastLat = request.waypoints![i].latitude;
          lastLng = request.waypoints![i].longitude;
        }

        // Last waypoint → Destination
        totalDistance += _calculateDistance(
          lastLat,
          lastLng,
          destLat.toDouble(),
          destLng.toDouble(),
        );
      } else {
        // No waypoints: Start → Destination
        totalDistance += _calculateDistance(
          lastLat,
          lastLng,
          destLat.toDouble(),
          destLng.toDouble(),
        );
      }

      lastLat = destLat.toDouble();
      lastLng = destLng.toDouble();

      // Leg 3: Destination → Drop-off (if set)
      if (dropOffLat != null && dropOffLng != null) {
        totalDistance += _calculateDistance(
          lastLat,
          lastLng,
          dropOffLat.toDouble(),
          dropOffLng.toDouble(),
        );
        lastLat = dropOffLat.toDouble();
        lastLng = dropOffLng.toDouble();
      }

      // Leg 4: Drop-off (or Destination) → Office (return)
      totalDistance += _calculateDistance(
        lastLat,
        lastLng,
        officeLat.toDouble(),
        officeLng.toDouble(),
      );

      estimatedDistance = totalDistance;

      // Calculate fuel consumption
      // Using realistic fuel economy: 10 km/liter (24 MPG) for mixed city/highway driving
      // This is typical for a Toyota Camry or similar sedan
      const double kmPerLiter = 10.0; // 10 km per liter
      estimatedFuel = estimatedDistance / kmPerLiter;
    }

    if (estimatedDistance == null || estimatedFuel == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: AppConstants.spacingXXL),
        Container(
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.info.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      'Pre-Trip Estimation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildDetailRow(
                  'Estimated Total Distance',
                  '${estimatedDistance.toStringAsFixed(2)} km',
                ),
                _buildDetailRow(
                  'Estimated Total Fuel',
                  '${estimatedFuel.toStringAsFixed(2)} liters',
                ),
                if (request.waypoints != null && request.waypoints!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Includes ${request.waypoints!.length} waypoint(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Haversine formula to calculate distance between two coordinates
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

  Widget _buildDetailRow(String label, String value) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    dynamic request,
    AuthController authController,
    RequestDetailSource source,
  ) {
    final user = authController.user.value;
    final permissionService = Get.find<PermissionService>();
    if (user == null) return const SizedBox();

    // Check if current user is the requester
    // Convert both to strings for comparison (requesterId might be object or string)
    final isRequester = IdUtils.areIdsEqual(request.requesterId, user.id);
    
    // Check if user is DGS
    final isDGS = user.roles.any((role) => role.toUpperCase() == 'DGS');
    
    // Check if user is an approver role (DGS, DDGS, ADGS, or TO)
    final isDDGS = user.roles.any((role) => role.toUpperCase() == 'DDGS');
    final isADGS = user.roles.any((role) => role.toUpperCase() == 'ADGS');
    final isTO = user.roles.any((role) => role.toUpperCase() == 'TO');
    final isApprover = isDGS || isDDGS || isADGS || isTO;
    
    // Get actual workflow stage from request
    final workflowStage = request.workflowStage ?? 'SUBMITTED';

    // DGS and other approvers can approve/assign even if they're the requester (self-approval allowed)
    // Other users cannot approve their own requests
    final canApprove = (isApprover || !isRequester) &&
        permissionService.canApprove(
          user,
          RequestType.vehicle,
          workflowStage,
        ) && (request.status == RequestStatus.pending ||
            request.status == RequestStatus.corrected);
    
    // DGS can assign vehicles even when pending (can skip approval workflow)
    // TO can only assign when approved
    // DGS and TO can assign even if they're the requester
    final canAssign = (isDGS || isTO || !isRequester) &&
        permissionService.canAssignVehicle(user) &&
        request.vehicleId == null &&
        (isDGS 
          ? (request.status == RequestStatus.pending || 
             request.status == RequestStatus.corrected || 
             request.status == RequestStatus.approved)
          : (request.status == RequestStatus.approved));
    
    final canStartTrip = permissionService.canStartTrip(user, request) &&
        request.status == RequestStatus.assigned && 
        !request.tripStarted;
    final canTrackTrip = request.tripStarted && !request.tripCompleted;

    // Determine button visibility based on source
    // Approvers (DGS, DDGS, ADGS, TO) can see approval/assign buttons from any source if they have permission
    // Other users need to come from the appropriate source
    final showApproveButtons = (source == RequestDetailSource.pendingApprovals || isApprover) && canApprove;
    final showAssignButton = (source == RequestDetailSource.assignVehicle || isDGS || isTO) && canAssign;
    final showTripButtons = source == RequestDetailSource.myRequests && (canStartTrip || canTrackTrip);
    
    // For "other" source, use permission-based logic (backward compatibility)
    final usePermissionBased = source == RequestDetailSource.other;
    final showApproveButtonsPermission = usePermissionBased && canApprove;
    final showAssignButtonPermission = usePermissionBased && canAssign;
    final showTripButtonsPermission = usePermissionBased && (canStartTrip || canTrackTrip);

    return Column(
      children: [
        // Approve/Reject (Approvers) - Show based on source
        if (showApproveButtons || showApproveButtonsPermission) ...[
          if (isDGS && workflowStage == 'DGS_REVIEW') ...[
            // DGS special approval dialog - show both approve and assign options
            PermissionButton(
              text: 'Approve or Assign',
              icon: Icons.check_circle,
              type: ButtonType.primary,
              permissionCheck: (u) => permissionService.canApprove(
                u,
                RequestType.vehicle,
                workflowStage,
              ),
              onPressed: () => _showDGSApprovalChoiceDialog(context, request),
            ),
            const SizedBox(height: AppConstants.spacingM),
            CustomButton(
              text: 'Reject',
              icon: Icons.close,
              type: ButtonType.outlined,
              backgroundColor: AppColors.error,
              textColor: AppColors.error,
              onPressed: () => _showRejectDialog(context, request.id),
            ),
          ] else ...[
            // Regular approval for other roles
            Row(
              children: [
                Expanded(
                  child: PermissionButton(
                    text: 'Approve',
                    icon: Icons.check,
                    type: ButtonType.primary,
                    permissionCheck: (u) => permissionService.canApprove(
                      u,
                      RequestType.vehicle,
                      workflowStage,
                    ),
                    onPressed: () => _showApproveDialog(context, request.id),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    icon: Icons.close,
                    type: ButtonType.outlined,
                    backgroundColor: AppColors.error,
                    textColor: AppColors.error,
                    onPressed: () => _showRejectDialog(context, request.id),
                  ),
                ),
              ],
            ),
          ],
        ],
        
        // Assign Vehicle (TO/DGS) - Show based on source
        if ((showAssignButton || (showAssignButtonPermission && !(isDGS && canApprove && workflowStage == 'DGS_REVIEW')))) ...[
          if (showApproveButtons || showApproveButtonsPermission) const SizedBox(height: AppConstants.spacingM),
          PermissionButton(
            text: isDGS && (request.status == RequestStatus.pending || request.status == RequestStatus.corrected)
                ? 'Assign Vehicle (Skip Approval)'
                : 'Assign Vehicle',
            icon: Icons.assignment,
            permissionCheck: (u) => permissionService.canAssignVehicle(u),
            onPressed: () async {
              final result = await Get.to(() => AssignmentPage(requestId: request.id));
              // Refresh request after returning from assignment page
              if (result == true) {
                final requestController = Get.find<RequestController>();
                await requestController.loadRequest(requestId);
              }
            },
          ),
        ],
        
        // Start Trip (Driver) - Only show for My Requests or Other
        if (showTripButtons || showTripButtonsPermission) ...[
          if (canStartTrip) ...[
            if (showAssignButton || showAssignButtonPermission || showApproveButtons || showApproveButtonsPermission) 
              const SizedBox(height: AppConstants.spacingM),
            PermissionButton(
              text: 'Start Trip',
              icon: Icons.play_arrow,
              permissionCheck: (u) => permissionService.canStartTrip(u, request),
              onPressed: () async {
                final tripController = Get.put(TripController());
                final success = await tripController.startTrip(request.id);
                if (success) {
                  // Navigate to trip tracking page with map view
                  Get.to(() => TripTrackingPage(requestId: request.id));
                }
              },
            ),
          ],
          
          // View Trip Tracking
          if (canTrackTrip) ...[
            const SizedBox(height: AppConstants.spacingM),
            CustomButton(
              text: 'View Trip Tracking',
              icon: Icons.map,
              type: ButtonType.secondary,
              onPressed: () => Get.to(() => TripTrackingPage(requestId: request.id)),
            ),
          ],
        ],
      ],
    );
  }

  void _showDGSApprovalChoiceDialog(BuildContext context, VehicleRequestModel request) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'DGS Approval',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Text(
                    'Choose how to proceed with this request:\n\n'
                    '• Approve to Next Stage: Continue normal workflow (DGS → DDGS → ADGS → TO)\n'
                    '• Assign Vehicle Now: Skip workflow and assign vehicle directly (notifies TO)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  // Action buttons - full width, stacked vertically
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _showApproveDialog(context, request.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Approve to Next Stage'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      // Navigate to assignment page (this will skip workflow)
                      Get.to(() => AssignmentPage(requestId: request.id));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Assign Vehicle Now'),
                  ),
                  const SizedBox(height: 12),
                  // Cancel button
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, String requestId) {
    final commentController = TextEditingController();
    bool isDisposed = false;
    final requestController = Get.find<RequestController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Approve Request'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            labelText: 'Comment (Optional)',
            hintText: 'Add a comment...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await requestController.approveRequest(
                requestId,
                comment: commentController.text.isEmpty ? null : commentController.text,
              );
              if (success) {
                Get.back();
                Get.snackbar('Success', 'Request approved successfully');
              } else {
                Get.snackbar('Error', requestController.error.value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    ).then((_) {
      // Ensure controller is disposed only once when dialog is dismissed
      if (!isDisposed) {
        isDisposed = true;
        commentController.dispose();
      }
    });
  }

  void _showRejectDialog(BuildContext context, String requestId) {
    final commentController = TextEditingController();
    bool isDisposed = false;
    if (!Get.isRegistered<RequestController>()) {
      Get.put(RequestController());
    }
    final requestController = Get.find<RequestController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            labelText: 'Reason *',
            hintText: 'Please provide a reason for rejection...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.isEmpty) {
                Get.snackbar('Error', 'Please provide a reason');
                return;
              }
              final comment = commentController.text;
              final success = await requestController.rejectRequest(
                requestId,
                comment,
              );
              if (success) {
                Get.back();
                Get.snackbar('Success', 'Request rejected');
              } else {
                Get.snackbar('Error', requestController.error.value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    ).then((_) {
      // Ensure controller is disposed only once when dialog is dismissed
      if (!isDisposed) {
        isDisposed = true;
        commentController.dispose();
      }
    });
  }

}

