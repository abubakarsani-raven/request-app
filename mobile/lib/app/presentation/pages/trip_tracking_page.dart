import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/trip_controller.dart';
import '../controllers/trip_mode_controller.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/trip_progress_widget.dart';
import '../widgets/trip_statistics_section.dart';
import '../widgets/trip_floating_actions.dart';
import '../widgets/map_control_buttons.dart';
import '../../../core/animations/sheet_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class TripTrackingPage extends StatefulWidget {
  final String requestId;

  const TripTrackingPage({Key? key, required this.requestId}) : super(key: key);

  @override
  State<TripTrackingPage> createState() => _TripTrackingPageState();
}

class _TripTrackingPageState extends State<TripTrackingPage> {
  // Use Get.find() for controllers already registered in bindings
  // Use Get.put() only for page-specific controllers that need fresh instances
  late final TripController tripController;
  late final TripModeController modeController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Get or create controllers
    tripController = Get.find<TripController>();
    // TripModeController is page-specific, create new instance
    modeController = Get.put(TripModeController());
    
    // Load trip details and initialize mode
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await tripController.loadTripDetails(widget.requestId);
      final trip = tripController.currentTrip.value;
      modeController.updateModeBasedOnTrip(trip);
      
      if (trip != null && trip.tripStarted == true && !trip.tripCompleted) {
        tripController.startLocationTracking(widget.requestId);
        tripController.startGeofencing(widget.requestId);
        if (tripController.currentRoute.value == null) {
          await tripController.fetchRoute(widget.requestId);
        }
        if (trip.destinationReached && tripController.returnRoute.value == null) {
          await tripController.fetchReturnRoute(widget.requestId);
        }
      }
    });
    
    // Listen to trip changes and update mode accordingly (outside build phase)
    ever(tripController.currentTrip, (trip) {
      if (trip != null) {
        modeController.updateModeBasedOnTrip(trip);
      }
    });
  }

  @override
  void dispose() {
    // Don't manually dispose map controller - let Flutter handle it to prevent crashes
    // _mapController?.dispose(); // This can cause crashes with Google Maps
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Trip Tracking'),
        actions: [
          // Mode Toggle Button
          Obx(() => IconButton(
            icon: Icon(
              modeController.isNavigationMode
                  ? Icons.dashboard
                  : Icons.navigation,
            ),
            tooltip: modeController.isNavigationMode
                ? 'Switch to Monitoring Mode'
                : 'Switch to Navigation Mode',
            onPressed: () {
              SheetHaptics.selectionClick();
              modeController.toggleMode();
            },
          )),
        ],
      ),
      body: Obx(() {
        final trip = tripController.currentTrip.value;
        
        if (trip == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get current mode (mode is updated via ever() listener, not during build)
        final isNavigationMode = modeController.isNavigationMode;

        return Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Map View (flexible based on mode)
                Expanded(
                  flex: isNavigationMode ? 7 : 5,
                  child: _buildMapView(trip),
                ),
                // Bottom Panel (flexible based on mode)
                if (!isNavigationMode || trip.tripCompleted)
                  Expanded(
                    flex: isNavigationMode ? 3 : 5,
                    child: _buildBottomPanel(trip, isNavigationMode),
                  ),
              ],
            ),
            
            // Floating Action Buttons
            TripFloatingActions(
              trip: trip,
              requestId: widget.requestId,
              onStartTrip: () => _showStartTripDialog(),
              onReachDestination: () => _showReachDestinationDialog(),
              onReturnToOffice: () => _showReturnDialog(),
              onShowStatistics: () {
                // Statistics are shown in expandable section, this can trigger expansion
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMapView(dynamic trip) {
    return Obx(() {
      final currentPos = tripController.currentPosition.value;
      final routePoints = tripController.routePoints;
      
      // Get locations
      final officeLat = trip.officeLocation?['latitude']?.toDouble() ?? 
                       trip.startLocation?['latitude']?.toDouble();
      final officeLng = trip.officeLocation?['longitude']?.toDouble() ?? 
                       trip.startLocation?['longitude']?.toDouble();
      final destLat = trip.destinationLocation?['latitude']?.toDouble() ?? 
                     trip.requestedDestinationLocation?['latitude']?.toDouble();
      final destLng = trip.destinationLocation?['longitude']?.toDouble() ?? 
                     trip.requestedDestinationLocation?['longitude']?.toDouble();

      // Determine center and zoom
      LatLng? center;
      double zoom = 12.0;
      
      if (trip.destinationReached && !trip.tripCompleted) {
        if (currentPos != null) {
          center = LatLng(currentPos.latitude, currentPos.longitude);
          zoom = 15.0;
        } else if (destLat != null && destLng != null) {
          center = LatLng(destLat, destLng);
          zoom = 14.0;
        }
      } else if (currentPos != null && trip.tripStarted) {
        center = LatLng(currentPos.latitude, currentPos.longitude);
        zoom = 15.0;
      } else if (officeLat != null && officeLng != null) {
        center = LatLng(officeLat, officeLng);
      } else if (destLat != null && destLng != null) {
        center = LatLng(destLat, destLng);
      } else {
        center = const LatLng(9.0765, 7.3986); // Default
        zoom = 10.0;
      }

      // Build markers
      final Set<Marker> markers = {};
      
      if (officeLat != null && officeLng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('office'),
            position: LatLng(officeLat, officeLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Office'),
          ),
        );
      }
      
      if (destLat != null && destLng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: LatLng(destLat, destLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: trip.destination ?? 'Destination'),
          ),
        );
      }
      
      if (currentPos != null && trip.tripStarted) {
        markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: LatLng(currentPos.latitude, currentPos.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Current Location'),
          ),
        );
      }

      // Build polylines
      final Set<Polyline> polylines = {};
      
      if (!trip.destinationReached) {
        final outboundRoute = tripController.currentRoute.value;
        if (outboundRoute != null && trip.tripStarted) {
          final routePoints = outboundRoute.polylinePoints
              .map((p) => LatLng(p['latitude']!, p['longitude']!))
              .toList();
          if (routePoints.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('outbound-route'),
                points: routePoints,
                color: Color(outboundRoute.trafficColor),
                width: 6,
              ),
            );
          }
        }
      }
      
      if (trip.destinationReached && !trip.tripCompleted) {
        final returnRoute = tripController.returnRoute.value;
        if (returnRoute != null) {
          final routePoints = returnRoute.polylinePoints
              .map((p) => LatLng(p['latitude']!, p['longitude']!))
              .toList();
          if (routePoints.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('return-route'),
                points: routePoints,
                color: Color(returnRoute.trafficColor),
                width: 6,
              ),
            );
          }
        }
      }
      
      if (routePoints.isNotEmpty && trip.tripStarted) {
        final routeLatLngs = routePoints.map((pos) => LatLng(pos.latitude, pos.longitude)).toList();
        if (routeLatLngs.length > 1) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('tracked-route'),
              points: routeLatLngs,
              color: AppColors.primary.withOpacity(0.3),
              width: 3,
              patterns: [PatternItem.dash(10), PatternItem.gap(5)],
            ),
          );
        }
      }

      final mapCenter = center ?? const LatLng(9.0765, 7.3986);
      
      return Stack(
        children: [
          GoogleMap(
            key: ValueKey('trip_map_${widget.requestId}'), // Prevent unnecessary rebuilds
            initialCameraPosition: CameraPosition(
              target: mapCenter,
              zoom: zoom,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: trip.tripStarted && !trip.tripCompleted,
            myLocationButtonEnabled: false, // We have custom button
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              if (mounted) {
                _mapController = controller;
                tripController.setMapController(controller);
              }
            },
          ),
          // Navigation Panel
          if (trip.tripStarted && !trip.tripCompleted)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: NavigationPanel(
                  isReturnRoute: trip.destinationReached,
                ),
              ),
            ),
          // Map Control Buttons
          MapControlButtons(
            mapController: _mapController,
            onCenterLocation: () => tripController.centerOnCurrentLocation(),
            onShowFullRoute: () => tripController.showFullRoute(),
          ),
        ],
      );
    });
  }

  Widget _buildBottomPanel(dynamic trip, bool isNavigationMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Progress (with progress bar)
          TripProgressWidget(request: trip),
          const SizedBox(height: AppConstants.spacingL),
          
          // Expandable Statistics
          TripStatisticsSection(request: trip),
          const SizedBox(height: AppConstants.spacingL),
          
          // Waypoints (if multi-stop trip)
          if (trip.waypoints != null && trip.waypoints!.isNotEmpty) ...[
            _buildWaypointsSection(trip),
            const SizedBox(height: AppConstants.spacingL),
          ],
        ],
      ),
    );
  }

  Widget _buildWaypointsSection(dynamic trip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Waypoints',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            ...trip.waypoints!.asMap().entries.map((entry) {
              final index = entry.key;
              final waypoint = entry.value;
              return _buildWaypointRow(
                waypoint,
                index + 1,
                trip.tripStarted && !waypoint.reached && 
                  (index == 0 || trip.waypoints![index - 1].reached),
                () => _showReachWaypointDialog(index + 1, waypoint.name),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointRow(
    dynamic waypoint,
    int stopNumber,
    bool canReach,
    VoidCallback onReach,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Row(
        children: [
          Icon(
            waypoint.reached ? Icons.check_circle : Icons.radio_button_unchecked,
            color: waypoint.reached ? AppColors.success : AppColors.textDisabled,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stop $stopNumber: ${waypoint.name}',
                  style: TextStyle(
                    fontWeight: waypoint.reached ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (waypoint.distanceFromPrevious != null)
                  Text(
                    'Distance: ${waypoint.distanceFromPrevious!.toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (canReach && !waypoint.reached)
            TextButton(
              onPressed: onReach,
              child: const Text('Reach'),
            ),
        ],
      ),
    );
  }

  void _showStartTripDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Start Trip'),
        content: const Text('Are you ready to start the trip from the office location?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: tripController.isStartingTrip.value
                  ? null
                  : () async {
                      SheetHaptics.heavyImpact();
                      final success = await tripController.startTrip(widget.requestId);
                      if (success) {
                        Get.back();
                        Get.snackbar('Success', 'Trip started successfully');
                        await tripController.fetchRoute(widget.requestId);
                      } else {
                        Get.snackbar('Error', tripController.error.value);
                      }
                    },
              child: tripController.isStartingTrip.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Start Trip'),
            ),
          ),
        ],
      ),
    );
  }

  void _showReachDestinationDialog() {
    final trip = tripController.currentTrip.value;
    if (trip?.destinationReached == true) {
      Get.snackbar('Info', 'Destination has already been reached');
      return;
    }

    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Reach Destination'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Make sure you are within 5 meters of the destination before confirming.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any notes...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              notesController.dispose();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: tripController.isReachingDestination.value
                  ? null
                  : () async {
                      SheetHaptics.heavyImpact();
                      final notes = notesController.text.isEmpty ? null : notesController.text;
                      notesController.dispose();
                      final success = await tripController.reachDestination(
                        widget.requestId,
                        notes: notes,
                      );
                      if (success) {
                        Get.back();
                        Get.snackbar('Success', 'Destination marked as reached');
                      } else {
                        // Show formatted error message
                        final errorMsg = tripController.error.value;
                        Get.snackbar(
                          'Cannot Mark Destination',
                          errorMsg,
                          backgroundColor: Colors.orange.shade100,
                          colorText: Colors.orange.shade900,
                          duration: const Duration(seconds: 5),
                          icon: const Icon(Icons.warning, color: Colors.orange),
                        );
                      }
                    },
              child: tripController.isReachingDestination.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Confirm'),
            ),
          ),
        ],
      ),
    ).then((_) => notesController.dispose());
  }

  void _showReturnDialog() {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Return to Office'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Add any notes...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              notesController.dispose();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: tripController.isReturningToOffice.value
                  ? null
                  : () async {
                      SheetHaptics.heavyImpact();
                      final notes = notesController.text.isEmpty ? null : notesController.text;
                      notesController.dispose();
                      final success = await tripController.returnToOffice(
                        widget.requestId,
                        notes: notes,
                      );
                      if (success) {
                        Get.back();
                        if (tripController.error.value.isNotEmpty && 
                            (tripController.error.value.contains('away') || 
                             tripController.error.value.contains('meters'))) {
                          // Show formatted warning message
                          Get.snackbar(
                            'Warning',
                            tripController.error.value,
                            backgroundColor: Colors.orange.shade100,
                            colorText: Colors.orange.shade900,
                            duration: const Duration(seconds: 5),
                            icon: const Icon(Icons.warning, color: Colors.orange),
                          );
                        } else {
                          Get.snackbar('Success', 'Trip completed successfully');
                        }
                        Get.back(result: true);
                      } else {
                        // Show formatted error message
                        final errorMsg = tripController.error.value;
                        Get.snackbar(
                          'Cannot Mark Return',
                          errorMsg,
                          backgroundColor: Colors.orange.shade100,
                          colorText: Colors.orange.shade900,
                          duration: const Duration(seconds: 5),
                          icon: const Icon(Icons.warning, color: Colors.orange),
                        );
                      }
                    },
              child: tripController.isReturningToOffice.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }

  void _showReachWaypointDialog(int stopIndex, String waypointName) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Reach Stop $stopIndex: $waypointName'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Add any notes...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              notesController.dispose();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              SheetHaptics.mediumImpact();
              final notes = notesController.text.isEmpty ? null : notesController.text;
              notesController.dispose();
              final success = await tripController.reachWaypoint(
                widget.requestId,
                stopIndex,
                notes: notes,
              );
              if (success) {
                Get.back();
                Get.snackbar('Success', 'Waypoint marked as reached');
              } else {
                // Show formatted error message
                final errorMsg = tripController.error.value;
                Get.snackbar(
                  'Cannot Mark Waypoint',
                  errorMsg,
                  backgroundColor: Colors.orange.shade100,
                  colorText: Colors.orange.shade900,
                  duration: const Duration(seconds: 5),
                  icon: const Icon(Icons.warning, color: Colors.orange),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
