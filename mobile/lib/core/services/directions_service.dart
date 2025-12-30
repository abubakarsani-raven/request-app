import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import '../../app/data/models/route_model.dart';

class DirectionsService {
  // Use the same API key from map_picker.dart
  static const String _apiKey = 'AIzaSyD3apWjzMf9iPAdZTSGR4ln2pU7U6Lo7_I';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Fetch route between origin and destination with traffic data
  Future<RouteModel?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<Map<String, double>>? waypoints,
    String? departureTime,
  }) async {
    try {
      // Build waypoints parameter
      String? waypointsParam;
      if (waypoints != null && waypoints.isNotEmpty) {
        waypointsParam = waypoints
            .map((wp) => '${wp['latitude']},${wp['longitude']}')
            .join('|');
      }

      // Build URL
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        if (waypointsParam != null) 'waypoints': waypointsParam,
        'key': _apiKey,
        'alternatives': 'false',
        'traffic_model': 'best_guess',
        if (departureTime != null) 'departure_time': departureTime,
        'mode': 'driving',
      });

      print('🗺️ [DirectionsService] Fetching route: ${uri.toString().replaceAll(_apiKey, 'API_KEY')}');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          return _parseRoute(data['routes'][0]);
        } else {
          print('⚠️ [DirectionsService] API returned status: ${data['status']}');
          print('⚠️ [DirectionsService] Error message: ${data['error_message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('❌ [DirectionsService] HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [DirectionsService] Error fetching route: $e');
      return null;
    }
  }

  /// Parse route from Google Directions API response
  RouteModel _parseRoute(Map<String, dynamic> routeData) {
    final legs = routeData['legs'] as List;
    final overviewPolyline = routeData['overview_polyline']['points'] as String;
    
    // Decode polyline
    final decodedPoints = decodePolyline(overviewPolyline);
    final polylinePoints = decodedPoints.map((point) => {
      'latitude': point[0].toDouble(),
      'longitude': point[1].toDouble(),
    }).toList();

    // Calculate total distance and duration
    int totalDistanceMeters = 0;
    int totalDurationSeconds = 0;
    int totalDurationInTrafficSeconds = 0;
    final List<RouteStep> steps = [];

    for (var leg in legs) {
      totalDistanceMeters += (leg['distance']['value'] as int);
      totalDurationSeconds += (leg['duration']['value'] as int);
      
      // Duration in traffic (if available)
      if (leg['duration_in_traffic'] != null) {
        totalDurationInTrafficSeconds += (leg['duration_in_traffic']['value'] as int);
      } else {
        totalDurationInTrafficSeconds += (leg['duration']['value'] as int);
      }

      // Parse steps
      if (leg['steps'] != null) {
        for (var stepData in leg['steps']) {
          final step = RouteStep(
            instruction: stepData['html_instructions'] as String? ?? '',
            distance: (stepData['distance']['value'] as int).toDouble() / 1000.0, // Convert to km
            duration: (stepData['duration']['value'] as int).toDouble() / 60.0, // Convert to minutes
            startLocation: {
              'latitude': (stepData['start_location']['lat'] as num).toDouble(),
              'longitude': (stepData['start_location']['lng'] as num).toDouble(),
            },
            endLocation: {
              'latitude': (stepData['end_location']['lat'] as num).toDouble(),
              'longitude': (stepData['end_location']['lng'] as num).toDouble(),
            },
            polyline: stepData['polyline']['points'] as String? ?? '',
          );
          steps.add(step);
        }
      }
    }

    // Calculate traffic level
    TrafficLevel trafficLevel = TrafficLevel.free;
    if (totalDurationInTrafficSeconds > 0 && totalDurationSeconds > 0) {
      final delayPercent = ((totalDurationInTrafficSeconds - totalDurationSeconds) / totalDurationSeconds) * 100;
      if (delayPercent > 30) {
        trafficLevel = TrafficLevel.heavy;
      } else if (delayPercent > 10) {
        trafficLevel = TrafficLevel.moderate;
      } else {
        trafficLevel = TrafficLevel.free;
      }
    }

    // Get bounds
    final bounds = routeData['bounds'];
    Map<String, double>? routeBounds;
    if (bounds != null) {
      routeBounds = {
        'northeastLat': (bounds['northeast']['lat'] as num).toDouble(),
        'northeastLng': (bounds['northeast']['lng'] as num).toDouble(),
        'southwestLat': (bounds['southwest']['lat'] as num).toDouble(),
        'southwestLng': (bounds['southwest']['lng'] as num).toDouble(),
      };
    }

    return RouteModel(
      polylinePoints: polylinePoints,
      distance: totalDistanceMeters / 1000.0, // Convert to km
      duration: totalDurationSeconds / 60.0, // Convert to minutes
      durationInTraffic: totalDurationInTrafficSeconds / 60.0, // Convert to minutes
      steps: steps,
      trafficLevel: trafficLevel,
      bounds: routeBounds,
    );
  }

  /// Get route with waypoints (convenience method)
  Future<RouteModel?> getRouteWithWaypoints({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required List<Map<String, double>> waypoints,
    String? departureTime,
  }) {
    return getRoute(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      waypoints: waypoints,
      departureTime: departureTime,
    );
  }
}

