# Trip Tracking & Geolocation Features

## Overview

The backend now includes comprehensive two-leg trip tracking with geolocation, distance calculation, fuel estimation, and real-time WebSocket updates. The trip consists of:
1. **Outbound Leg**: Office → Destination
2. **Return Leg**: Destination → Office

**Note**: Polyline generation is handled on the frontend (Flutter app) using Google Maps. The backend only stores location coordinates.

## Features Implemented

### 1. Trip Tracking (Two-Leg System)
- **Start Trip**: Driver manually starts trip from office location
- **Reach Destination**: Driver marks destination reached (auto or manual)
- **Return to Office**: Driver marks return to office, completing the trip
- **Actual vs Scheduled Time**: Tracks actual departure time vs scheduled trip time
- **Destination Reached Time**: Records when destination is reached
- **Return Time**: Records when vehicle returns to office

### 2. Geolocation
- **Start Location**: Office coordinates (where trip begins)
- **Destination Location**: Trip destination coordinates
- **Return Location**: Office coordinates (where trip ends)
- **Real-time Location Updates**: Continuous location tracking during trip (via WebSocket)
- **Distance Calculation**: Uses Haversine formula to calculate distance in kilometers

### 3. Fuel Consumption (Two-Leg Calculation)
- **Worst Case MPG**: 14 MPG (configurable)
- **Outbound Fuel**: Calculated for office → destination leg
- **Return Fuel**: Calculated for destination → office leg
- **Total Fuel**: Sum of outbound + return fuel consumption
- **Formula**: (Distance in km / 1.60934) / 14 MPG * 3.78541 liters/gallon

### 4. Frontend Polyline Generation
- **Backend**: Only stores location coordinates (lat/lng)
- **Frontend**: Flutter app generates polyline using Google Maps
- **Real-time Tracking**: Frontend updates polyline as vehicle moves
- **Map Display**: Google Maps shows vehicle position and route in real-time

### 5. WebSocket Real-Time Updates
- **Namespace**: `/updates`
- **Authentication**: JWT token required in handshake
- **Events**:
  - `trip:started` - When trip begins from office
  - `trip:destination:reached` - When destination is reached
  - `trip:location:updated` - Real-time location updates during trip
  - `trip:completed` - When vehicle returns to office (trip fully completed)
  - `request:status:changed` - Request status updates

## API Endpoints

### Start Trip (From Office)
```
POST /vehicles/requests/:id/trip/start
Body: {
  "latitude": 40.7128,  // Office location
  "longitude": -74.0060
}
```

### Reach Destination
```
POST /vehicles/requests/:id/trip/destination
Body: {
  "latitude": 40.7580,  // Destination location
  "longitude": -73.9855,
  "notes": "Optional notes"
}
```

### Return to Office
```
POST /vehicles/requests/:id/trip/return
Body: {
  "latitude": 40.7128,  // Office location (should match start)
  "longitude": -74.0060,
  "notes": "Optional notes"
}
```

### Update Location (Real-time)
```
POST /vehicles/requests/:id/trip/location
Body: {
  "latitude": 40.7300,
  "longitude": -73.9900
}
```
*Call this periodically during trip for real-time tracking*

### Get Trip Details
```
GET /vehicles/requests/:id/trip
```

Returns:
```json
{
  "startLocation": { "latitude": 40.7128, "longitude": -74.0060 },
  "destinationLocation": { "latitude": 40.7580, "longitude": -73.9855 },
  "returnLocation": { "latitude": 40.7128, "longitude": -74.0060 },
  "officeLocation": { "latitude": 40.7128, "longitude": -74.0060 },
  "actualDepartureTime": "2024-01-15T10:30:00Z",
  "destinationReachedTime": "2024-01-15T12:15:00Z",
  "actualReturnTime": "2024-01-15T14:45:00Z",
  "tripDate": "2024-01-15T09:00:00Z",
  "tripTime": "09:00",
  "outboundDistanceKm": 12.5,
  "returnDistanceKm": 12.5,
  "totalDistanceKm": 25.0,
  "outboundFuelLiters": 2.8,
  "returnFuelLiters": 2.8,
  "totalFuelLiters": 5.6,
  "tripStarted": true,
  "destinationReached": true,
  "tripCompleted": true
}
```

## WebSocket Connection

### Client Connection (Flutter/Web)
```dart
// Flutter example
final socket = io('http://localhost:3000/updates', {
  'auth': {'token': 'your-jwt-token'},
  'transports': ['websocket'],
});

socket.on('trip:started', (data) {
  print('Trip started: ${data['requestId']}');
  // Show map with vehicle at office location
});

socket.on('trip:destination:reached', (data) {
  print('Destination reached: ${data['requestId']}');
  print('Outbound distance: ${data['outboundDistance']} km');
  print('Outbound fuel: ${data['outboundFuel']} liters');
  // Update map to show destination reached
});

socket.on('trip:location:updated', (data) {
  // Update vehicle marker position on map in real-time
  updateVehicleMarker(data['location']);
});

socket.on('trip:completed', (data) {
  print('Trip completed: ${data['requestId']}');
  print('Total distance: ${data['totalDistance']} km');
  print('Total fuel: ${data['totalFuel']} liters');
  // Show complete trip summary
});
```

### Join Request Room
```dart
socket.emit('request:join', {'requestId': 'request-id'});
```

## Database Schema Updates

VehicleRequest schema now includes:
- `startLocation`: { latitude, longitude } - Office location
- `destinationLocation`: { latitude, longitude } - Trip destination
- `returnLocation`: { latitude, longitude } - Office return location
- `officeLocation`: { latitude, longitude } - Office coordinates
- `actualDepartureTime`: Date - When trip started from office
- `destinationReachedTime`: Date - When destination was reached
- `actualReturnTime`: Date - When returned to office
- `outboundDistanceKm`: number - Distance from office to destination
- `returnDistanceKm`: number - Distance from destination to office
- `totalDistanceKm`: number - Total distance (outbound + return)
- `outboundFuelLiters`: number - Fuel for outbound leg
- `returnFuelLiters`: number - Fuel for return leg
- `totalFuelLiters`: number - Total fuel (outbound + return)
- `tripStarted`: boolean
- `destinationReached`: boolean
- `tripCompleted`: boolean - Only true when returned to office

## Flutter Integration

### Required Packages
```yaml
dependencies:
  google_polyline_algorithm: ^3.1.0
  geolocator: ^10.1.0
  google_maps_flutter: ^2.5.0
  socket_io_client: ^2.0.3
```

### Trip Flow in Flutter App

1. **Start Trip**: Driver taps "Start Trip" → Captures current location → Calls API
2. **During Trip**: 
   - Periodically send location updates via `POST /trip/location`
   - Update Google Maps with vehicle marker position
   - Generate polyline on frontend as vehicle moves
3. **Reach Destination**: 
   - Auto-detect when near destination (geofencing) OR
   - Driver manually taps "Reach Destination"
   - Calls API to mark destination reached
4. **Return Journey**:
   - Continue location updates
   - Update map with return route
5. **Return to Office**:
   - Auto-detect when near office OR
   - Driver manually taps "Return to Office"
   - Calls API to complete trip

### Generate Polyline on Frontend
```dart
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// As vehicle moves, collect coordinates
List<LatLng> routePoints = [];

// When location updates
void onLocationUpdate(Position position) {
  routePoints.add(LatLng(position.latitude, position.longitude));
  
  // Generate polyline
  String encodedPolyline = encodePolyline(
    routePoints.map((p) => [p.latitude, p.longitude]).toList(),
  );
  
  // Update map polyline
  updateMapPolyline(encodedPolyline);
}

// Display on Google Maps
Polyline(
  polylineId: PolylineId('trip-route'),
  points: routePoints,
  color: Colors.blue,
  width: 5,
)
```

## Permissions

- **Start Trip**: Assigned driver, TO, or DGS
- **Reach Destination**: Assigned driver, TO, or DGS
- **Return to Office**: Assigned driver, TO, or DGS
- **Update Location**: Assigned driver, TO, or DGS
- **View Trip Details**: Any authenticated user with access to the request

## Trip States

1. **Not Started**: `tripStarted = false`
2. **In Progress (Outbound)**: `tripStarted = true`, `destinationReached = false`
3. **At Destination**: `destinationReached = true`, `tripCompleted = false`
4. **Returning**: `destinationReached = true`, `tripCompleted = false` (returning to office)
5. **Completed**: `tripCompleted = true` (returned to office)

## Implementation Notes

- **Polyline Generation**: Handled entirely on frontend using Google Maps
- **Real-time Updates**: Frontend sends location updates periodically during trip
- **Auto-completion**: Can be implemented on frontend using geofencing to auto-detect destination/office arrival
- **Fuel Calculation**: Automatically calculated for both legs separately and totaled

## Future Enhancements

1. **Geofencing**: Automatic destination/office detection
2. **Route Optimization**: Integration with Google Maps Directions API for route planning
3. **Speed Monitoring**: Track average speed during trip
4. **Idle Time Tracking**: Monitor vehicle idle time at destination
5. **Route Deviation Alerts**: Alert if vehicle deviates significantly from planned route

