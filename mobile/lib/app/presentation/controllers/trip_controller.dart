import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/request_service.dart';
import '../../data/models/request_model.dart';
import '../../data/models/route_model.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/directions_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/error_message_formatter.dart';
import '../../../core/constants/app_constants.dart';

class TripController extends GetxController {
  final RequestService _requestService = Get.find<RequestService>();
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final DirectionsService _directionsService = DirectionsService();

  final Rx<VehicleRequestModel?> currentTrip = Rx<VehicleRequestModel?>(null);
  final RxBool isTracking = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxList<Position> routePoints = <Position>[].obs;
  Timer? _locationTimer;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Operation-specific loading flags
  final RxBool isLoadingTrip = false.obs;
  final RxBool isFetchingRoute = false.obs;
  final RxBool isFetchingReturnRoute = false.obs;
  final RxBool isStartingTrip = false.obs;
  final RxBool isCompletingTrip = false.obs;
  final RxBool isUpdatingLocation = false.obs;
  final RxBool isReachingDestination = false.obs;
  final RxBool isReturningToOffice = false.obs;
  final RxBool isReachingWaypoint = false.obs;
  
  // Route management
  final Rx<RouteModel?> currentRoute = Rx<RouteModel?>(null);
  final Rx<RouteModel?> returnRoute = Rx<RouteModel?>(null);
  final RxList<RouteStep> navigationSteps = <RouteStep>[].obs;
  final RxInt currentStepIndex = 0.obs;
  Timer? _routeRefreshTimer;
  
  // Map controller for programmatic control
  GoogleMapController? mapController;
  
  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }
  
  /// Center map on current location
  Future<void> centerOnCurrentLocation() async {
    try {
      if (mapController == null || currentPosition.value == null) return;
      
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            currentPosition.value!.latitude,
            currentPosition.value!.longitude,
          ),
          15.0,
        ),
      );
    } catch (e) {
      print('Error centering on location: $e');
      // Silently fail - map might be disposed
    }
  }
  
  /// Show full route (office -> destination -> office)
  Future<void> showFullRoute() async {
    try {
      if (mapController == null) return;
      
      final trip = currentTrip.value;
      if (trip == null) return;
      final officeLat = trip.officeLocation?['latitude']?.toDouble() ?? 
                       trip.startLocation?['latitude']?.toDouble();
      final officeLng = trip.officeLocation?['longitude']?.toDouble() ?? 
                       trip.startLocation?['longitude']?.toDouble();
      final destLat = trip.destinationLocation?['latitude']?.toDouble() ?? 
                     trip.requestedDestinationLocation?['latitude']?.toDouble();
      final destLng = trip.destinationLocation?['longitude']?.toDouble() ?? 
                     trip.requestedDestinationLocation?['longitude']?.toDouble();
      
      if (officeLat == null || officeLng == null || destLat == null || destLng == null) {
        return;
      }
      
      // Create bounds to include both office and destination
      final bounds = LatLngBounds(
        southwest: LatLng(
          officeLat < destLat ? officeLat : destLat,
          officeLng < destLng ? officeLng : destLng,
        ),
        northeast: LatLng(
          officeLat > destLat ? officeLat : destLat,
          officeLng > destLng ? officeLng : destLng,
        ),
      );
      
      await mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {
      print('Error showing full route: $e');
      // Silently fail - map might be disposed
    }
  }

  @override
  void onInit() {
    super.onInit();
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    _wsService.on('trip:started', (data) {
      if (data['requestId'] == currentTrip.value?.id) {
        loadTripDetails(data['requestId']);
      }
    });

    _wsService.on('trip:destination:reached', (data) {
      if (data['requestId'] == currentTrip.value?.id) {
        loadTripDetails(data['requestId']);
      }
    });

    _wsService.on('trip:waypoint:reached', (data) {
      if (data['requestId'] == currentTrip.value?.id) {
        loadTripDetails(data['requestId']);
      }
    });

    _wsService.on('trip:completed', (data) {
      if (data['requestId'] == currentTrip.value?.id) {
        loadTripDetails(data['requestId']);
        stopTracking();
      }
    });

    _wsService.on('trip:location:updated', (data) {
      // Handle real-time location updates from other users
    });
  }

  Future<void> loadTripDetails(String requestId) async {
    isLoadingTrip.value = true;
    isLoading.value = true;
    try {
      final trip = await _requestService.getTripDetails(requestId);
      final wasDestinationReached = currentTrip.value?.destinationReached ?? false;
      currentTrip.value = trip;
      
      // Fetch routes based on trip state
      if (trip != null) {
        if (trip.tripStarted && !trip.destinationReached) {
          // Fetch outbound route if not already loaded
          if (currentRoute.value == null) {
            await fetchRoute(requestId);
          }
        } else if (trip.destinationReached && !trip.tripCompleted) {
          // Fetch return route when destination is reached
          if (returnRoute.value == null || !wasDestinationReached) {
            await fetchReturnRoute(requestId);
            // Update navigation steps to return route
            if (returnRoute.value != null) {
              navigationSteps.value = returnRoute.value!.steps;
              currentStepIndex.value = 0;
            }
          }
        }
      }
    } catch (e) {
      error.value = e.toString();
      print('❌ [FRONTEND - LOAD TRIP] Error: $e');
    } finally {
      isLoadingTrip.value = false;
      isLoading.value = false;
    }
  }

  Future<bool> startTrip(String requestId) async {
    isStartingTrip.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        error.value = 'Unable to get current location';
        isLoading.value = false;
        return false;
      }

      print('   Destination Location (from trip): lat=${currentTrip.value?.requestedDestinationLocation?['latitude'] ?? "N/A"}, lng=${currentTrip.value?.requestedDestinationLocation?['longitude'] ?? "N/A"}');

      final result = await _requestService.startTrip(
        requestId,
        position.latitude,
        position.longitude,
      );

      if (result['success'] == true) {
        await loadTripDetails(requestId);
        startLocationTracking(requestId);
        _startGeofencing(requestId);
        // Fetch route when trip starts
        await fetchRoute(requestId);
        isStartingTrip.value = false;
        isLoading.value = false;
        return true;
      } else {
        error.value = result['message'] ?? 'Failed to start trip';
        isStartingTrip.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isStartingTrip.value = false;
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> reachDestination(String requestId, {String? notes}) async {
    isReachingDestination.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final isDemoMode = StorageService.isDemoModeEnabled();
      
      Position? position;
      if (!isDemoMode) {
        position = await _getCurrentPosition();
        if (position == null) {
          error.value = 'Unable to get current location';
          isLoading.value = false;
          return false;
        }
      } else {
        // In demo mode, use destination coordinates
        final destLat = currentTrip.value?.requestedDestinationLocation?['latitude'];
        final destLng = currentTrip.value?.requestedDestinationLocation?['longitude'];
        if (destLat != null && destLng != null) {
          position = Position(
            latitude: destLat.toDouble(),
            longitude: destLng.toDouble(),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        } else {
          error.value = 'Destination location not available';
          isLoading.value = false;
          return false;
        }
      }

      // 🔍 DEBUG: Log coordinates being sent when reaching destination
      print('🎯 [FRONTEND - REACH DESTINATION] Sending coordinates:');
      print('   Request ID: $requestId');
      print('   Demo Mode: $isDemoMode');
      print('   Current Location: lat=${position.latitude}, lng=${position.longitude}');
      print('   Target Destination (from trip): lat=${currentTrip.value?.requestedDestinationLocation?['latitude'] ?? "N/A"}, lng=${currentTrip.value?.requestedDestinationLocation?['longitude'] ?? "N/A"}');
      print('   Office Location (from trip): lat=${currentTrip.value?.officeLocation?['latitude'] ?? "N/A"}, lng=${currentTrip.value?.officeLocation?['longitude'] ?? "N/A"}');

      final result = await _requestService.reachDestination(
        requestId,
        position.latitude,
        position.longitude,
        notes,
      );

      if (result['success'] == true) {
        await loadTripDetails(requestId);
        isReachingDestination.value = false;
        isLoading.value = false;
        return true;
      } else {
        final errorMsg = result['message'] ?? 'Failed to mark destination reached';
        // Format error message to be more informative
        error.value = ErrorMessageFormatter.formatApiError(errorMsg);
        isReachingDestination.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = e.toString();
      isReachingDestination.value = false;
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> reachWaypoint(String requestId, int stopIndex, {String? notes}) async {
    isReachingWaypoint.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        error.value = 'Unable to get current location';
        isReachingWaypoint.value = false;
        isLoading.value = false;
        return false;
      }

      final result = await _requestService.reachWaypoint(
        requestId,
        stopIndex,
        position.latitude,
        position.longitude,
        notes,
      );

      if (result['success'] == true) {
        await loadTripDetails(requestId);
        isReachingWaypoint.value = false;
        isLoading.value = false;
        return true;
      } else {
        final errorMsg = result['message'] ?? 'Failed to mark waypoint reached';
        error.value = ErrorMessageFormatter.formatApiError(errorMsg);
        isReachingWaypoint.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = ErrorMessageFormatter.formatApiError(e.toString());
      isReachingWaypoint.value = false;
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> returnToOffice(String requestId, {String? notes}) async {
    isReturningToOffice.value = true;
    isLoading.value = true;
    error.value = '';

    try {
      final isDemoMode = StorageService.isDemoModeEnabled();
      
      Position? position;
      if (!isDemoMode) {
        position = await _getCurrentPosition();
        if (position == null) {
          error.value = 'Unable to get current location';
          isLoading.value = false;
          return false;
        }
      } else {
        // In demo mode, use office coordinates
        final officeLat = currentTrip.value?.officeLocation?['latitude'];
        final officeLng = currentTrip.value?.officeLocation?['longitude'];
        if (officeLat != null && officeLng != null) {
          position = Position(
            latitude: officeLat.toDouble(),
            longitude: officeLng.toDouble(),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        } else {
          error.value = 'Office location not available';
          isLoading.value = false;
          return false;
        }
      }

      // 🔍 DEBUG: Log coordinates being sent when returning to office
      print('🏢 [FRONTEND - RETURN TO OFFICE] Sending coordinates:');
      print('   Request ID: $requestId');
      print('   Demo Mode: $isDemoMode');
      print('   Current Location: lat=${position.latitude}, lng=${position.longitude}');
      print('   Office Location (from trip): lat=${currentTrip.value?.officeLocation?['latitude'] ?? "N/A"}, lng=${currentTrip.value?.officeLocation?['longitude'] ?? "N/A"}');
      print('   Start Location (from trip): lat=${currentTrip.value?.startLocation?['latitude'] ?? "N/A"}, lng=${currentTrip.value?.startLocation?['longitude'] ?? "N/A"}');
      print('   Destination Location (from trip): lat=${currentTrip.value?.destinationLocation?['latitude'] ?? "N/A"}, lng=${currentTrip.value?.destinationLocation?['longitude'] ?? "N/A"}');

      final result = await _requestService.returnToOffice(
        requestId,
        position.latitude,
        position.longitude,
        notes,
      );

      if (result['success'] == true) {
        // Check for warning message from backend
        final warning = result['data']?['warning'] ?? result['warning'];
        if (warning != null && warning.toString().isNotEmpty) {
          // Show warning but still allow success
          error.value = ErrorMessageFormatter.formatApiError(warning.toString());
          // Don't return false - allow the operation to succeed
        }
        await loadTripDetails(requestId);
        stopTracking();
        isReturningToOffice.value = false;
        isLoading.value = false;
        return true;
      } else {
        final errorMsg = result['message'] ?? 'Failed to mark return to office';
        error.value = ErrorMessageFormatter.formatApiError(errorMsg);
        isReturningToOffice.value = false;
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      error.value = ErrorMessageFormatter.formatApiError(e.toString());
      isReturningToOffice.value = false;
      isLoading.value = false;
      return false;
    }
  }

  void startLocationTracking(String requestId) {
    if (isTracking.value) return;

    isTracking.value = true;
    _wsService.joinRequestRoom(requestId);

    Position? lastRouteUpdatePosition;
    const double routeUpdateThreshold = 0.5; // Update route if moved 500m

    _locationTimer = Timer.periodic(
      Duration(seconds: AppConstants.locationUpdateInterval),
      (timer) async {
        final position = await _getCurrentPosition();
        if (position != null) {
          currentPosition.value = position;
          routePoints.add(position);

          // Send location update to server
          await _requestService.updateTripLocation(
            requestId,
            position.latitude,
            position.longitude,
          );

          // Emit WebSocket event
          _wsService.emit('trip:location:update', {
            'requestId': requestId,
            'location': {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          });

          // Check if route should be updated (user moved significantly)
          final previousPosition = lastRouteUpdatePosition;
          if (previousPosition != null) {
            final distance = Geolocator.distanceBetween(
              previousPosition.latitude,
              previousPosition.longitude,
              position.latitude,
              position.longitude,
            );
            
            if (distance > routeUpdateThreshold * 1000) {
              // User moved more than threshold, update route
              await updateRouteFromCurrentPosition(requestId);
              lastRouteUpdatePosition = position;
            }
          } else {
            lastRouteUpdatePosition = position;
          }
        }
      },
    );
  }

  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    isTracking.value = false;
    final trip = currentTrip.value;
    if (trip != null) {
      _wsService.leaveRequestRoom(trip.id);
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  StreamSubscription<Position>? _geofencingSubscription;
  static const double _proximityThreshold = 5.0; // 5 meters accuracy
  bool _isShowingDestinationDialog = false; // Prevent duplicate popups
  bool _isShowingReturnDialog = false; // Prevent duplicate popups

  // Public method to start geofencing (called from trip tracking page)
  void startGeofencing(String requestId) {
    _startGeofencing(requestId);
  }

  void _startGeofencing(String requestId) {
    if (_geofencingSubscription != null) return;

    _geofencingSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // Highest accuracy for 5m detection
        distanceFilter: 3, // Update every 3 meters for better accuracy
      ),
    ).listen((Position position) async {
      final trip = currentTrip.value;
      if (trip == null) return;
      
      // Check destination proximity (only if not already showing dialog and not reached)
      if (trip.tripStarted && !trip.destinationReached && !_isShowingDestinationDialog) {
        final destLat = trip.destinationLocation?['latitude']?.toDouble() ?? 
                       trip.requestedDestinationLocation?['latitude']?.toDouble();
        final destLng = trip.destinationLocation?['longitude']?.toDouble() ?? 
                       trip.requestedDestinationLocation?['longitude']?.toDouble();
        
        if (destLat != null && destLng != null) {
          final distance = _checkDestinationProximity(position, destLat, destLng);
          if (distance <= _proximityThreshold) {
            _isShowingDestinationDialog = true;
            await _autoMarkDestination(requestId);
            // Reset flag after a delay to allow re-checking if user cancels
            Future.delayed(const Duration(seconds: 5), () {
              _isShowingDestinationDialog = false;
            });
          }
        }
      }
      
      // Check office proximity (only after destination reached, and not showing dialog)
      if (trip.destinationReached && !trip.tripCompleted && !_isShowingReturnDialog) {
        final officeLat = trip.officeLocation?['latitude']?.toDouble() ?? 
                         trip.startLocation?['latitude']?.toDouble();
        final officeLng = trip.officeLocation?['longitude']?.toDouble() ?? 
                         trip.startLocation?['longitude']?.toDouble();
        
        if (officeLat != null && officeLng != null) {
          final distance = _checkOfficeProximity(position, officeLat, officeLng);
          if (distance <= _proximityThreshold) {
            _isShowingReturnDialog = true;
            await _autoMarkReturned(requestId);
            // Reset flag after a delay to allow re-checking if user cancels
            Future.delayed(const Duration(seconds: 5), () {
              _isShowingReturnDialog = false;
            });
          }
        }
      }
    });
  }

  double _checkDestinationProximity(Position current, double destLat, double destLng) {
    return Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      destLat,
      destLng,
    );
  }

  double _checkOfficeProximity(Position current, double officeLat, double officeLng) {
    return Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      officeLat,
      officeLng,
    );
  }

  Future<void> _autoMarkDestination(String requestId) async {
    // Reload trip to check if already reached (prevent duplicate)
    await loadTripDetails(requestId);
    if (currentTrip.value?.destinationReached == true) {
      _isShowingDestinationDialog = false;
      return;
    }

    // Show confirmation dialog before auto-marking
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Destination Detected'),
        content: const Text(
          'You are within 5 meters of the destination. Would you like to mark it as reached?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isShowingDestinationDialog = false;
              Get.back(result: false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Mark Reached'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await reachDestination(requestId);
      if (success) {
        _isShowingDestinationDialog = false;
      }
    } else {
      _isShowingDestinationDialog = false;
    }
  }

  Future<void> _autoMarkReturned(String requestId) async {
    // Reload trip to check if already completed (prevent duplicate)
    await loadTripDetails(requestId);
    if (currentTrip.value?.tripCompleted == true) {
      _isShowingReturnDialog = false;
      return;
    }

    // Show confirmation dialog before auto-marking
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Office Detected'),
        content: const Text(
          'You are within 5 meters of the office. Would you like to mark the trip as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isShowingReturnDialog = false;
              Get.back(result: false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await returnToOffice(requestId);
      if (success) {
        _isShowingReturnDialog = false;
      }
    } else {
      _isShowingReturnDialog = false;
    }
  }

  /// Fetch route from origin to destination
  Future<void> fetchRoute(String requestId) async {
    final trip = currentTrip.value;
    if (trip == null) return;

    isFetchingRoute.value = true;
    try {
      final originLat = trip.officeLocation?['latitude']?.toDouble() ?? 
                       trip.startLocation?['latitude']?.toDouble();
      final originLng = trip.officeLocation?['longitude']?.toDouble() ?? 
                       trip.startLocation?['longitude']?.toDouble();
      final destLat = trip.requestedDestinationLocation?['latitude']?.toDouble();
      final destLng = trip.requestedDestinationLocation?['longitude']?.toDouble();

      if (originLat == null || originLng == null || destLat == null || destLng == null) {
        print('⚠️ [TripController] Missing coordinates for route');
        error.value = 'Missing location coordinates for route calculation';
        return;
      }

      // Handle waypoints if present
      List<Map<String, double>>? waypoints;
      if (trip.waypoints != null && trip.waypoints!.isNotEmpty) {
        waypoints = trip.waypoints!.map((wp) => {
          'latitude': wp.latitude.toDouble(),
          'longitude': wp.longitude.toDouble(),
        }).toList();
      }

      final route = await _directionsService.getRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        waypoints: waypoints,
        departureTime: 'now',
      );

      if (route != null) {
        currentRoute.value = route;
        navigationSteps.value = route.steps;
        currentStepIndex.value = 0;
        print('✅ [TripController] Route fetched: ${route.formattedDistance}, ${route.formattedDuration}');
        
        // Start route refresh timer
        _startRouteRefresh(requestId);
        error.value = ''; // Clear any previous errors
      } else {
        print('⚠️ [TripController] Failed to fetch route');
        error.value = 'Failed to calculate route. Using simple path.';
        // Don't throw error - allow trip to continue with fallback
      }
    } catch (e) {
      print('❌ [TripController] Error fetching route: $e');
      error.value = 'Error calculating route: ${e.toString()}';
      // Don't throw - allow trip to continue with fallback polyline
    } finally {
      isFetchingRoute.value = false;
    }
  }

  /// Fetch return route from destination to office
  Future<void> fetchReturnRoute(String requestId) async {
    final trip = currentTrip.value;
    if (trip == null) return;

    isFetchingReturnRoute.value = true;
    try {
      final destLat = trip.destinationLocation?['latitude']?.toDouble() ?? 
                     trip.requestedDestinationLocation?['latitude']?.toDouble();
      final destLng = trip.destinationLocation?['longitude']?.toDouble() ?? 
                     trip.requestedDestinationLocation?['longitude']?.toDouble();
      final officeLat = trip.officeLocation?['latitude']?.toDouble();
      final officeLng = trip.officeLocation?['longitude']?.toDouble();

      if (destLat == null || destLng == null || officeLat == null || officeLng == null) {
        print('⚠️ [TripController] Missing coordinates for return route');
        return;
      }

      final route = await _directionsService.getRoute(
        originLat: destLat,
        originLng: destLng,
        destLat: officeLat,
        destLng: officeLng,
        departureTime: 'now',
      );

      if (route != null) {
        returnRoute.value = route;
        print('✅ [TripController] Return route fetched: ${route.formattedDistance}, ${route.formattedDuration}');
      } else {
        print('⚠️ [TripController] Failed to fetch return route');
      }
    } catch (e) {
      print('❌ [TripController] Error fetching return route: $e');
    } finally {
      isFetchingReturnRoute.value = false;
    }
  }

  /// Update route from current position
  Future<void> updateRouteFromCurrentPosition(String requestId) async {
    final trip = currentTrip.value;
    final position = currentPosition.value;
    if (trip == null || position == null) return;

    try {
      // Only update if trip started and destination not reached
      if (trip.tripStarted && !trip.destinationReached) {
        final destLat = trip.requestedDestinationLocation?['latitude']?.toDouble();
        final destLng = trip.requestedDestinationLocation?['longitude']?.toDouble();

        if (destLat != null && destLng != null) {
          final route = await _directionsService.getRoute(
            originLat: position.latitude,
            originLng: position.longitude,
            destLat: destLat,
            destLng: destLng,
            departureTime: 'now',
          );

          if (route != null) {
            currentRoute.value = route;
            navigationSteps.value = route.steps;
            // Don't reset step index - keep current progress
            // Only update if significantly different
            print('✅ [TripController] Route updated from current position');
          } else {
            print('⚠️ [TripController] Failed to update route - keeping existing route');
          }
        }
      } else if (trip.destinationReached && !trip.tripCompleted) {
        // Update return route
        final officeLat = trip.officeLocation?['latitude']?.toDouble();
        final officeLng = trip.officeLocation?['longitude']?.toDouble();

        if (officeLat != null && officeLng != null) {
          final route = await _directionsService.getRoute(
            originLat: position.latitude,
            originLng: position.longitude,
            destLat: officeLat,
            destLng: officeLng,
            departureTime: 'now',
          );

          if (route != null) {
            returnRoute.value = route;
            print('✅ [TripController] Return route updated from current position');
          } else {
            print('⚠️ [TripController] Failed to update return route - keeping existing route');
          }
        }
      }
    } catch (e) {
      print('❌ [TripController] Error updating route: $e');
      // Don't throw - keep existing route
    }
  }

  /// Start route refresh timer
  void _startRouteRefresh(String requestId) {
    _routeRefreshTimer?.cancel();
    _routeRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) async {
        try {
          await updateRouteFromCurrentPosition(requestId);
          print('🔄 [TripController] Route refreshed');
        } catch (e) {
          print('⚠️ [TripController] Error refreshing route: $e');
          // Continue with existing route if refresh fails
        }
      },
    );
  }

  /// Get next navigation step
  RouteStep? getNextStep() {
    if (currentStepIndex.value < navigationSteps.length - 1) {
      currentStepIndex.value++;
      return navigationSteps[currentStepIndex.value];
    }
    return null;
  }

  /// Get previous navigation step
  RouteStep? getPreviousStep() {
    if (currentStepIndex.value > 0) {
      currentStepIndex.value--;
      return navigationSteps[currentStepIndex.value];
    }
    return null;
  }

  /// Get current navigation step
  RouteStep? getCurrentStep() {
    if (navigationSteps.isNotEmpty && currentStepIndex.value < navigationSteps.length) {
      return navigationSteps[currentStepIndex.value];
    }
    return null;
  }

  @override
  void onClose() {
    stopTracking();
    _geofencingSubscription?.cancel();
    _geofencingSubscription = null;
    _routeRefreshTimer?.cancel();
    _routeRefreshTimer = null;
    // Clear map controller reference (don't dispose - let Flutter handle it)
    mapController = null;
    super.onClose();
  }
}

